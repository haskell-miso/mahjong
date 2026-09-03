-----------------------------------------------------------------------------
-- | CPU opponent: shanten-driven discards and claim decisions.
-----------------------------------------------------------------------------
module AI where
-----------------------------------------------------------------------------
import           Data.List ((\\), nub, sortOn)
import qualified Data.IntMap.Strict as IM
-----------------------------------------------------------------------------
import           Logic
import           Model
-----------------------------------------------------------------------------
-- | Choose the discard that minimizes shanten; break ties by keeping the
-- most connected tiles (isolated honors and terminals go first).
bestDiscard :: [Tile] -> [Meld] -> Tile
bestDiscard full ms =
  case sortOn rank (nub full) of
    (t : _) -> t
    [] -> error "bestDiscard: empty hand"
  where
    nMelds = length ms
    rank t =
      ( shanten (full \\ [t]) nMelds
      , negate (looseness t)
      )
    cnt = countsOf full
    countAt i = IM.findWithDefault 0 i cnt
    -- higher = more discardable
    looseness t@(Suited s n) =
      let neighbors = sum [ countAt (tileIx (Suited s k))
                          | k <- [n - 2 .. n + 2], k >= 1, k <= 9, k /= n ]
          dup = countAt (tileIx t) - 1
          edge = if n == 1 || n == 9 then 2 else abs (5 - n)
      in edge - 2 * neighbors - 3 * dup
    looseness t =
      let dup = countAt (tileIx t) - 1
      in 6 - 4 * dup
-----------------------------------------------------------------------------
-- | Claim a pon when it strictly improves shanten.
wantsPon :: Player -> Tile -> Bool
wantsPon p t =
  IM.findWithDefault 0 (tileIx t) (countsOf (hand p)) >= 2
    && after < before
  where
    before = shanten (hand p) (length (melds p))
    -- pon leaves 13 - 3 concealed with one more meld; then the player
    -- discards, so compare like-for-like on the pre-discard hand
    after = shanten (hand p \\ [t, t]) (length (melds p) + 1)
-----------------------------------------------------------------------------
-- | Claim a chi (next player only) when it strictly improves shanten.
wantsChi :: Player -> Tile -> Maybe (Tile, Tile)
wantsChi p t =
  case sortOn snd
    [ ((a, b), sh)
    | (a, b) <- chiOptions (hand p) t
    , let sh = shanten (hand p \\ [a, b]) (length (melds p) + 1)
    , sh < before
    ] of
    (((a, b), _) : _) -> Just (a, b)
    [] -> Nothing
  where
    before = shanten (hand p) (length (melds p))
-----------------------------------------------------------------------------
-- | Declare a concealed kan when four copies are held and it keeps the
-- hand at least as close to tenpai.
wantsAnkan :: Player -> Maybe Tile
wantsAnkan p =
  case [ t
       | (i, c) <- IM.toList (countsOf full)
       , c == 4
       , let t = ixTile i
       , shanten (full \\ [t, t, t, t]) (length (melds p) + 1)
           <= shanten full (length (melds p))
       ] of
    (t : _) -> Just t
    [] -> Nothing
  where
    full = fullHand p
-----------------------------------------------------------------------------
-- | Can this player win on the given tile?
canRon :: Player -> Tile -> Bool
canRon p t = isComplete (sortHand (hand p ++ [t])) (length (melds p))
