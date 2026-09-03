-----------------------------------------------------------------------------
-- | Native correctness tests for the solitaire rules: turtle layout
-- validity, the freedom rule, matching, and the solvability guarantee of
-- the deal generator.
-----------------------------------------------------------------------------
module Main where
-----------------------------------------------------------------------------
import           Control.Monad (forM_, unless)
import           Data.IORef
import           Data.List (nub, sort)
import           System.Exit (exitFailure)
-----------------------------------------------------------------------------
import           Logic
import           Model
-----------------------------------------------------------------------------
main :: IO ()
main = do
  failures <- newIORef (0 :: Int)
  let check name ok = do
        putStrLn ((if ok then "  ok  " else " FAIL ") <> name)
        unless ok (modifyIORef failures (+ 1))

  -- layout ------------------------------------------------------------
  check "turtle has 144 positions" (length turtle == 144)
  check "turtle positions are distinct" (length (nub turtle) == 144)
  check "layer populations are 87/36/16/4/1"
    (map countLayer [0 .. 4] == [87, 36, 16, 4, 1])
  check "no two same-layer positions overlap"
    (and [ not (overlaps p q)
         | p@(_, _, z) <- turtle
         , q@(_, _, z') <- turtle
         , p /= q, z == z' ])
  check "every raised tile rests on the layer below"
    (and [ any (\q@(_, _, z') -> z' == z - 1 && overlaps p q) turtle
         | p@(_, _, z) <- turtle, z > 0 ])

  -- freedom -----------------------------------------------------------
  let freeNow = filter (isFreePos turtle) turtle
  check "full turtle has exactly 35 free tiles" (length freeNow == 35)
  check "the crown is free" ((13, 7, 4) `elem` freeNow)
  check "the crown seals all four layer-3 tiles"
    (all (\p@(_, _, z) -> z /= 3 || p `notElem` freeNow) turtle)
  check "the head is free" ((0, 7, 0) `elem` freeNow)
  check "the outer tail is free, the inner tail is blocked"
    ((28, 7, 0) `elem` freeNow && (26, 7, 0) `notElem` freeNow)
  check "the head blocks the row ends beside it"
    ((2, 6, 0) `notElem` freeNow && (2, 8, 0) `notElem` freeNow)

  -- tiles + matching ---------------------------------------------------
  check "tile set has 144 tiles" (length allTiles == 144)
  check "pairsOf yields 72 matching pairs"
    (let prs = pairsOf allTiles
     in length prs == 72 && all (uncurry matches) prs)
  check "pairsOf preserves the tile multiset"
    (sort (concat [ [a, b] | (a, b) <- pairsOf allTiles ]) == sort allTiles)
  check "flowers all match each other, seasons likewise, but not across"
    (matches (FlowerTile 1) (FlowerTile 4)
      && matches (SeasonTile 2) (SeasonTile 3)
      && not (matches (FlowerTile 1) (SeasonTile 1)))
  check "distinct standard kinds do not match"
    (not (matches (Suited Man 1) (Suited Pin 1))
      && not (matches (WindTile East) (WindTile West)))

  -- dealing -------------------------------------------------------------
  -- a single generation attempt may dead-end (the game retries with fresh
  -- randomness, up to 60 times); the tests mirror that.
  firstTries <- newIORef (0 :: Int)
  forM_ [1 .. 40 :: Int] $ \seed -> do
    let attempts =
          [ dealIntoWith (lcg (seed * 100 + k)) turtle allTiles
          | k <- [0 .. 9 :: Int]
          ]
        name s = "seed " <> show seed <> ": " <> s
    case attempts of
      (Just _ : _) -> modifyIORef firstTries (+ 1)
      _ -> pure ()
    case [ b | Just b <- attempts ] of
      [] -> check (name "deals within 10 attempts") False
      (b : _) -> do
        check (name "places every position exactly once")
          (sort (map btPos b) == sort turtle)
        check (name "preserves the tile multiset")
          (sort (map btKind b) == sort allTiles)
        check (name "assignment order is a legal winning play-through")
          (replayable (chronoPairs b))
  ft <- readIORef firstTries
  check ("first-attempt success rate is healthy (" <> show ft <> "/40)")
    (ft >= 30)

  -- misc ---------------------------------------------------------------
  check "formatTime pads" (formatTime 65 == "01:05" && formatTime 600 == "10:00")

  n <- readIORef failures
  if n == 0
    then putStrLn "\nAll tests passed."
    else do
      putStrLn ("\n" <> show n <> " test(s) failed.")
      exitFailure
  where
    countLayer l = length [ () | (_, _, z) <- turtle, z == l ]
-----------------------------------------------------------------------------
-- | Deterministic supply in [0, 1) for the pure deal generator.
lcg :: Int -> [Double]
lcg seed =
  map (\x -> fromIntegral x / 2147483648)
      (drop 1 (iterate step (seed * 7919 + 13)))
  where
    step x = (1103515245 * x + 12345) `mod` 2147483648
-----------------------------------------------------------------------------
-- | Rebuild the chronological pair-removal order from 'dealIntoWith'
-- output (which is reverse-chronological, two tiles per step).
chronoPairs :: [BTile] -> [(BTile, BTile)]
chronoPairs = reverse . pair
  where
    pair (a : b : rest) = (a, b) : pair rest
    pair _ = []
-----------------------------------------------------------------------------
-- | Play the given pair sequence forward on the full board, checking each
-- removed pair is free at its turn and actually matches.
replayable :: [(BTile, BTile)] -> Bool
replayable = go turtle
  where
    go remaining [] = null remaining
    go remaining ((a, b) : rest) =
      matches (btKind a) (btKind b)
        && isFreePos remaining (btPos a)
        && isFreePos (filter (/= btPos a) remaining) (btPos b)
        && go (filter (\p -> p /= btPos a && p /= btPos b) remaining) rest
