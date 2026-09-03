-----------------------------------------------------------------------------
-- | Mahjong solitaire rules: the classic turtle layout, tile freedom,
-- matching, and guaranteed-solvable deals.
-----------------------------------------------------------------------------
module Logic where
-----------------------------------------------------------------------------
import           Data.List (sortOn, groupBy)
import           Data.Function (on)
-----------------------------------------------------------------------------
import           Miso.Random (replicateRM)
import           Miso.String (MisoString, ms)
-----------------------------------------------------------------------------
import           Model
-----------------------------------------------------------------------------
-- * Tile set (144 = 34 kinds x4 + 4 flowers + 4 seasons)
-----------------------------------------------------------------------------
allTiles :: [Tile]
allTiles =
  concatMap (replicate 4) standardKinds
    ++ [ FlowerTile n | n <- [1 .. 4] ]
    ++ [ SeasonTile n | n <- [1 .. 4] ]
  where
    standardKinds =
      [ Suited s n | s <- [Man, Pin, Sou], n <- [1 .. 9] ] ++
      [ WindTile w | w <- [East ..] ] ++
      [ DragonTile d | d <- [White ..] ]
-----------------------------------------------------------------------------
-- | Tiles match when their keys are equal: flowers all share one key,
-- seasons another, everything else matches identical kinds only.
matchKey :: Tile -> Int
matchKey (Suited s n)   = 9 * fromEnum s + n - 1
matchKey (WindTile w)   = 27 + fromEnum w
matchKey (DragonTile d) = 31 + fromEnum d
matchKey (FlowerTile _) = 40
matchKey (SeasonTile _) = 41
-----------------------------------------------------------------------------
matches :: Tile -> Tile -> Bool
matches a b = matchKey a == matchKey b
-----------------------------------------------------------------------------
-- * The turtle layout (144 positions, in half-tile units)
-----------------------------------------------------------------------------
-- | The classic turtle: an 87-tile base, then 6x6, 4x4, 2x2 decks and a
-- single crown tile centered over the middle.
turtle :: [Pos]
turtle = concat
  [ row 0 0  [1 .. 12]
  , row 2 0  [3 .. 10]
  , row 4 0  [2 .. 11]
  , row 6 0  [1 .. 12]
  , row 8 0  [1 .. 12]
  , row 10 0 [2 .. 11]
  , row 12 0 [3 .. 10]
  , row 14 0 [1 .. 12]
  , [ (0, 7, 0), (26, 7, 0), (28, 7, 0) ] -- head + double tail
  , [ (2 * c, y2, 1) | y2 <- [2, 4 .. 12], c <- [4 .. 9] ]
  , [ (2 * c, y2, 2) | y2 <- [4, 6 .. 10], c <- [5 .. 8] ]
  , [ (2 * c, y2, 3) | y2 <- [6, 8],       c <- [6, 7] ]
  , [ (13, 7, 4) ]                        -- the crown, half-offset
  ]
  where
    row y2 z cs = [ (2 * c, y2, z) | c <- cs ]
-----------------------------------------------------------------------------
-- * Freedom
-----------------------------------------------------------------------------
-- | Two 2x2 footprints overlap when both half-unit deltas are below 2.
overlaps :: Pos -> Pos -> Bool
overlaps (x, y, _) (x', y', _) = abs (x - x') < 2 && abs (y - y') < 2
-----------------------------------------------------------------------------
-- | A position is free when nothing rests on it and at least one of its
-- left/right sides is open.
isFreePos :: [Pos] -> Pos -> Bool
isFreePos ps p@(x, y, z) =
  not covered && not (blockedL && blockedR)
  where
    covered  = any (\p'@(_, _, z') -> z' == z + 1 && overlaps p p') ps
    sideAt dx = any (\(x', y', z') -> z' == z && x' == x + dx && abs (y' - y) < 2) ps
    blockedL = sideAt (-2)
    blockedR = sideAt 2
-----------------------------------------------------------------------------
isFree :: [BTile] -> BTile -> Bool
isFree bts bt = isFreePos (map btPos bts) (btPos bt)
-----------------------------------------------------------------------------
freeTiles :: [BTile] -> [BTile]
freeTiles bts = filter (isFree bts) bts
-----------------------------------------------------------------------------
-- | All matching pairs among the currently free tiles.
freePairs :: [BTile] -> [(BTile, BTile)]
freePairs bts =
  [ (a, b)
  | (a : rest) <- tailsOf (freeTiles bts)
  , b <- rest
  , matches (btKind a) (btKind b)
  ]
  where
    tailsOf [] = []
    tailsOf l@(_ : t) = l : tailsOf t
-----------------------------------------------------------------------------
-- * Dealing
-----------------------------------------------------------------------------
-- | Group the tile multiset into matching pairs (every match-group has an
-- even population, so this is total).
pairsOf :: [Tile] -> [(Tile, Tile)]
pairsOf ts = concatMap chunk (groupBy ((==) `on` matchKey) (sortOn matchKey ts))
  where
    chunk (a : b : rest) = (a, b) : chunk rest
    chunk _ = []
-----------------------------------------------------------------------------
shuffleList :: [a] -> IO [a]
shuffleList xs = do
  keys <- replicateRM (length xs)
  pure (shuffleWith keys xs)
-----------------------------------------------------------------------------
shuffleWith :: [Double] -> [a] -> [a]
shuffleWith keys xs = map snd (sortOn fst (zip keys xs))
-----------------------------------------------------------------------------
-- | Deal by playing the game in reverse: repeatedly pull two random /free/
-- positions off the full board and assign them the next matching pair.
-- The removal order is itself a solution, so every deal is winnable.
-- Pure so the test-suite can drive it with a deterministic supply; the
-- result is in reverse-chronological assignment order.
dealIntoWith :: [Double] -> [Pos] -> [Tile] -> Maybe [BTile]
dealIntoWith supply positions tiles = go prs positions rest []
  where
    prs0 = pairsOf tiles
    (keys, rest) = splitAt (length prs0) supply
    prs = shuffleWith keys prs0
    go [] _ _ acc = Just acc
    go ((t1, t2) : more) remaining (r1 : r2 : rs) acc
      | length free < 2 = Nothing
      | otherwise =
          go more
             (filter (\p -> p /= p1 && p /= p2) remaining)
             rs
             (BTile p1 t1 : BTile p2 t2 : acc)
      where
        free = filter (isFreePos remaining) remaining
        p1 = free !! floor (r1 * fromIntegral (length free))
        free' = filter (/= p1) free
        p2 = free' !! floor (r2 * fromIntegral (length free'))
    go _ _ _ _ = Nothing -- randomness supply exhausted
-----------------------------------------------------------------------------
dealInto :: [Pos] -> [Tile] -> IO (Maybe [BTile])
dealInto positions tiles = do
  supply <- replicateRM (2 * length tiles)
  pure (dealIntoWith supply positions tiles)
-----------------------------------------------------------------------------
-- | A fresh, solvable turtle deal.
genDeal :: IO [BTile]
genDeal = withRetries 60 (dealInto turtle allTiles) fallback
  where
    fallback = do
      ts <- shuffleList allTiles
      pure (zipWith BTile turtle ts)
-----------------------------------------------------------------------------
-- | Re-deal the remaining tiles over the remaining positions, keeping the
-- result solvable whenever the generator finds an ordering.
shuffleRemaining :: [BTile] -> IO [BTile]
shuffleRemaining bts =
  withRetries 60 (dealInto ps ts) fallback
  where
    ps = map btPos bts
    ts = map btKind bts
    fallback = do
      ts' <- shuffleList ts
      pure (zipWith BTile ps ts')
-----------------------------------------------------------------------------
withRetries :: Int -> IO (Maybe a) -> IO a -> IO a
withRetries n gen fallback
  | n <= 0 = fallback
  | otherwise = do
      r <- gen
      case r of
        Just x -> pure x
        Nothing -> withRetries (n - 1) gen fallback
-----------------------------------------------------------------------------
-- * Display helpers
-----------------------------------------------------------------------------
formatTime :: Int -> MisoString
formatTime s = pad (s `div` 60) <> ":" <> pad (s `mod` 60)
  where
    pad n
      | n < 10 = "0" <> ms n
      | otherwise = ms n
