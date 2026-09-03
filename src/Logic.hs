-----------------------------------------------------------------------------
-- | Pure mahjong rules: tile set, shuffling, shanten, win detection,
-- yaku recognition and scoring.
-----------------------------------------------------------------------------
module Logic where
-----------------------------------------------------------------------------
import           Data.List (sort, sortOn, nub)
import qualified Data.IntMap.Strict as IM
-----------------------------------------------------------------------------
import           Miso.Random (replicateRM)
import           Miso.String (MisoString)
-----------------------------------------------------------------------------
import           Model
-----------------------------------------------------------------------------
-- * Tile set
-----------------------------------------------------------------------------
-- | All 136 tiles (each of the 34 kinds four times).
allTiles :: [Tile]
allTiles = concatMap (replicate 4) tileKinds
-----------------------------------------------------------------------------
-- | The 34 distinct tile kinds in canonical order.
tileKinds :: [Tile]
tileKinds =
  [ Suited s n | s <- [Man, Pin, Sou], n <- [1..9] ] ++
  [ WindTile w | w <- [East ..] ] ++
  [ DragonTile d | d <- [White ..] ]
-----------------------------------------------------------------------------
-- | Canonical index (0..33) of a tile kind.
tileIx :: Tile -> Int
tileIx (Suited s n)    = 9 * fromEnum s + n - 1
tileIx (WindTile w)    = 27 + fromEnum w
tileIx (DragonTile d)  = 31 + fromEnum d
-----------------------------------------------------------------------------
ixTile :: Int -> Tile
ixTile i
  | i < 27    = Suited (toEnum (i `div` 9)) (i `mod` 9 + 1)
  | i < 31    = WindTile (toEnum (i - 27))
  | otherwise = DragonTile (toEnum (i - 31))
-----------------------------------------------------------------------------
-- | Histogram over tile kind indices.
countsOf :: [Tile] -> IM.IntMap Int
countsOf = IM.fromListWith (+) . map (\t -> (tileIx t, 1))
-----------------------------------------------------------------------------
isTerminalOrHonor :: Tile -> Bool
isTerminalOrHonor (Suited _ n) = n == 1 || n == 9
isTerminalOrHonor _            = True
-----------------------------------------------------------------------------
-- | The tile a dora indicator points at (its successor).
doraOf :: Tile -> Tile
doraOf (Suited s n)   = Suited s (if n == 9 then 1 else n + 1)
doraOf (WindTile w)   = WindTile (if w == North then East else succ w)
doraOf (DragonTile d) = DragonTile (if d == Red then White else succ d)
-----------------------------------------------------------------------------
-- | Fisher–Yates-equivalent shuffle keyed on miso's splitmix32 PRNG.
shuffleIO :: IO [Tile]
shuffleIO = do
  keys <- replicateRM (length allTiles)
  pure (map snd (sortOn fst (zip keys allTiles)))
-----------------------------------------------------------------------------
-- * Shanten
-----------------------------------------------------------------------------
-- | Number of tiles away from tenpai (-1 = complete hand). Considers
-- standard hands, seven pairs, and thirteen orphans (the latter two only
-- for fully concealed hands).
shanten :: [Tile] -> Int -> Int
shanten tiles fixedMelds = minimum $
  [ standardShanten (countsOf tiles) fixedMelds ] ++
  [ chiitoiShanten (countsOf tiles) | fixedMelds == 0 ] ++
  [ kokushiShanten (countsOf tiles) | fixedMelds == 0 ]
-----------------------------------------------------------------------------
-- | Complete winning hand?
isComplete :: [Tile] -> Int -> Bool
isComplete tiles fixedMelds = shanten tiles fixedMelds == (-1)
-----------------------------------------------------------------------------
-- | Standard-form shanten: @8 - 2*melds - partials - pair@, maximized over
-- all decompositions, capped at four blocks total.
standardShanten :: IM.IntMap Int -> Int -> Int
standardShanten cnt0 fixed = 8 - best
  where
    best = go 0 cnt0 fixed 0 False
    val m d p = 2 * m + min d (4 - m) + (if p then 1 else 0)
    go i cnt m d pair
      | m > 4     = val 4 0 pair
      | i > 33    = val m d pair
      | c == 0    = go (i + 1) cnt m d pair
      | otherwise = maximum (skip : options)
      where
        c = IM.findWithDefault 0 i cnt
        c1 = IM.findWithDefault 0 (i + 1) cnt
        c2 = IM.findWithDefault 0 (i + 2) cnt
        suitedRun = i < 27 && i `mod` 9 <= 6
        suitedNeighbor = i < 27 && i `mod` 9 <= 7
        dec k n = IM.adjust (subtract n) k
        skip = go (i + 1) (IM.delete i cnt) m d pair
        options = concat
          [ [ go i (dec i 3 cnt) (m + 1) d pair | c >= 3 ]
          , [ go i (dec (i + 2) 1 (dec (i + 1) 1 (dec i 1 cnt))) (m + 1) d pair
            | suitedRun, c1 > 0, c2 > 0 ]
          , [ go i (dec i 2 cnt) m d True | c >= 2, not pair ]
          , [ go i (dec i 2 cnt) m (d + 1) pair | c >= 2 ]
          , [ go i (dec (i + 1) 1 (dec i 1 cnt)) m (d + 1) pair
            | suitedNeighbor, c1 > 0 ]
          , [ go i (dec (i + 2) 1 (dec i 1 cnt)) m (d + 1) pair
            | suitedRun, c2 > 0 ]
          ]
-----------------------------------------------------------------------------
chiitoiShanten :: IM.IntMap Int -> Int
chiitoiShanten cnt = 6 - pairs + max 0 (7 - kinds)
  where
    pairs = length [ () | c <- IM.elems cnt, c >= 2 ]
    kinds = IM.size cnt
-----------------------------------------------------------------------------
kokushiShanten :: IM.IntMap Int -> Int
kokushiShanten cnt = 13 - kinds - (if hasPair then 1 else 0)
  where
    orphanIxs = [ tileIx t | t <- tileKinds, isTerminalOrHonor t ]
    counts = [ IM.findWithDefault 0 i cnt | i <- orphanIxs ]
    kinds = length [ () | c <- counts, c >= 1 ]
    hasPair = any (>= 2) counts
-----------------------------------------------------------------------------
-- * Yaku + scoring
-----------------------------------------------------------------------------
-- | Winning-hand evaluation context.
data WinInfo = WinInfo
  { wiTsumo    :: Bool
  , wiSeatWind :: Wind
  , wiConcealed:: [Tile]  -- ^ concealed part incl. winning tile
  , wiMelds    :: [Meld]
  , wiDora     :: [Tile]  -- ^ actual dora tiles (not indicators)
  , wiDealer   :: Bool
  }
-----------------------------------------------------------------------------
-- | Recognized yaku (name, han) plus the point value of the hand.
scoreWin :: WinInfo -> ([(MisoString, Int)], Int)
scoreWin WinInfo{..} = (baseYaku ++ doraHan, points)
  where
    allTs = wiConcealed ++ concatMap meldTiles wiMelds
    cnt = countsOf wiConcealed
    closed = all concealedMeld wiMelds
    concealedMeld (Meld (MeldKan True) _) = True
    concealedMeld _ = False

    isChiitoi = null wiMelds && chiitoiShanten cnt == (-1)
    isKokushi = null wiMelds && kokushiShanten cnt == (-1)

    -- all triplets: concealed counts split into one pair + triplets/quads,
    -- and no chi melds (counts-based check is exact for toitoi)
    isToitoi = not isChiitoi && not isKokushi
      && all (\(Meld k _) -> k /= MeldChi) wiMelds
      && length [ () | c <- IM.elems cnt, c == 2 ] == 1
      && all (\c -> c == 2 || c == 3 || c == 4) (IM.elems cnt)

    suits = nub [ s | Suited s _ <- allTs ]
    hasHonors = any isHonor allTs
    isHonor (Suited _ _) = False
    isHonor _ = True

    tripleOf t =
      IM.findWithDefault 0 (tileIx t) cnt >= 3 ||
      any (\md -> meldType md /= MeldChi && t `elem` meldTiles md) wiMelds

    yaku = concat
      [ [ ("Kokushi Musou 国士無双", 13) | isKokushi ]
      , [ ("Menzen Tsumo 門前清自摸和", 1) | wiTsumo, closed, not isKokushi ]
      , [ ("Chiitoitsu 七対子", 2) | isChiitoi ]
      , [ ("Toitoi 対々和", 2) | isToitoi ]
      , [ ("Tanyao 断幺九", 1) | not (any isTerminalOrHonor allTs) ]
      , [ ("Yakuhai 白", 1) | tripleOf (DragonTile White), not isKokushi ]
      , [ ("Yakuhai 發", 1) | tripleOf (DragonTile Green), not isKokushi ]
      , [ ("Yakuhai 中", 1) | tripleOf (DragonTile Red), not isKokushi ]
      , [ ("Round Wind 東", 1) | tripleOf (WindTile East), not isKokushi ]
      , [ ("Seat Wind " <> windChar wiSeatWind, 1)
        | wiSeatWind /= East, tripleOf (WindTile wiSeatWind), not isKokushi ]
      , [ ("Chinitsu 清一色", 6) | length suits == 1, not hasHonors ]
      , [ ("Honitsu 混一色", 3) | length suits == 1, hasHonors, not isKokushi ]
      ]

    doraCount = length [ () | t <- allTs, t `elem` wiDora ]
    doraHan = [ ("Dora ドラ", doraCount) | doraCount > 0 ]

    baseYaku = if null yaku then [("Chicken Hand 雞胡", 1)] else yaku
    han = sum (map snd (baseYaku ++ doraHan))

    base
      | han >= 13 = 32000
      | han >= 8  = 16000
      | han >= 6  = 12000
      | han == 5  = 8000
      | han == 4  = 7700
      | han == 3  = 3900
      | han == 2  = 2000
      | otherwise = 1000
    points
      | wiDealer  = roundTo100 (base * 3 `div` 2)
      | otherwise = base
-----------------------------------------------------------------------------
roundTo100 :: Int -> Int
roundTo100 n = ((n + 99) `div` 100) * 100
-----------------------------------------------------------------------------
windChar :: Wind -> MisoString
windChar East  = "東"
windChar South = "南"
windChar West  = "西"
windChar North = "北"
-----------------------------------------------------------------------------
dragonChar :: Dragon -> MisoString
dragonChar White = "白"
dragonChar Green = "發"
dragonChar Red   = "中"
-----------------------------------------------------------------------------
-- | All distinct (a, b) pairs from the hand forming a run with tile @t@.
chiOptions :: [Tile] -> Tile -> [(Tile, Tile)]
chiOptions hs (Suited s n) = nub
  [ (Suited s a, Suited s b)
  | (a, b) <- [ (n - 2, n - 1), (n - 1, n + 1), (n + 1, n + 2) ]
  , a >= 1, b <= 9
  , Suited s a `elem` hs
  , Suited s b `elem` hs
  ]
chiOptions _ _ = []
-----------------------------------------------------------------------------
-- | Sorted insertion helper for hands.
sortHand :: [Tile] -> [Tile]
sortHand = sort
