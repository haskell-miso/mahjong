-----------------------------------------------------------------------------
-- | Core types for miso-mahjong: tiles, melds, players, phases, model.
-----------------------------------------------------------------------------
module Model where
-----------------------------------------------------------------------------
import           Miso.String (MisoString)
-----------------------------------------------------------------------------
-- | The three numbered suits.
data Suit
  = Man -- ^ characters 萬
  | Pin -- ^ circles 筒
  | Sou -- ^ bamboo 索
  deriving (Eq, Ord, Show, Enum, Bounded)
-----------------------------------------------------------------------------
-- | The four winds, in turn order.
data Wind = East | South | West | North
  deriving (Eq, Ord, Show, Enum, Bounded)
-----------------------------------------------------------------------------
-- | The three dragons.
data Dragon = White | Green | Red
  deriving (Eq, Ord, Show, Enum, Bounded)
-----------------------------------------------------------------------------
-- | A mahjong tile. Suited ranks are 1..9.
data Tile
  = Suited Suit Int
  | WindTile Wind
  | DragonTile Dragon
  deriving (Eq, Ord, Show)
-----------------------------------------------------------------------------
-- | How a meld was formed.
data MeldType
  = MeldChi
  | MeldPon
  | MeldKan Bool -- ^ 'True' when concealed (ankan)
  deriving (Eq, Show)
-----------------------------------------------------------------------------
-- | A declared meld, tiles kept sorted.
data Meld = Meld
  { meldType  :: MeldType
  , meldTiles :: [Tile]
  } deriving (Eq, Show)
-----------------------------------------------------------------------------
-- | One seat at the table. Index 0 is the human.
data Player = Player
  { hand  :: [Tile]      -- ^ concealed tiles, kept sorted
  , drawn :: Maybe Tile  -- ^ freshly drawn tile, kept apart for display
  , melds :: [Meld]
  , river :: [Tile]      -- ^ discards, in order
  , score :: Int
  } deriving (Eq, Show)
-----------------------------------------------------------------------------
-- | A claim the human (or a CPU) can make on a discard.
data ClaimOption
  = ClaimRon
  | ClaimPon
  | ClaimChi Tile Tile -- ^ the two hand tiles completing the run
  | ClaimSkip
  deriving (Eq, Show)
-----------------------------------------------------------------------------
-- | How a hand concluded.
data Outcome
  = Victory
    { vWinner :: Int
    , vFrom   :: Maybe Int -- ^ 'Just' discarder when won by ron
    , vTiles  :: [Tile]    -- ^ concealed part incl. winning tile, sorted
    , vLast   :: Tile      -- ^ the winning tile
    , vMelds  :: [Meld]
    , vYaku   :: [(MisoString, Int)]
    , vPoints :: Int
    }
  | Exhausted
  deriving (Eq, Show)
-----------------------------------------------------------------------------
-- | Game state machine.
data Phase
  = Title
  | Dealing
  | TurnDraw Int
  | TurnDiscard Int
  | AwaitClaim Int Tile [ClaimOption] -- ^ discarder, tile, human options
  | HandEnd Outcome
  | GameOver
  deriving (Eq, Show)
-----------------------------------------------------------------------------
data Model = Model
  { players       :: [Player] -- ^ exactly four, seat 0 = human (bottom)
  , wall          :: [Tile]   -- ^ live wall
  , kanWall       :: [Tile]   -- ^ replacement tiles for kan
  , doraIndicator :: Maybe Tile
  , phase         :: Phase
  , dealer        :: Int
  , handNum       :: Int      -- ^ 1..4 (East 1 .. East 4)
  , lastCall      :: Maybe (Int, MisoString) -- ^ seat + call text (PON! etc.)
  , callSeq       :: Int      -- ^ bumped per call, remounts the callout node
  , soundOn       :: Bool
  , pendingClaims :: [(Int, ClaimOption)] -- ^ CPU claims parked on human input
  } deriving (Eq, Show)
-----------------------------------------------------------------------------
data Action
  = NoOp
  | StartGame
  | NewGame
  | BeginHand [Tile]
  | StartTurns
  | DrawTile
  | CpuMove
  | HumanDiscardDrawn
  | HumanDiscardAt Int
  | HumanTsumo
  | HumanKan Tile
  | HumanClaim ClaimOption
  | NextHand
  | ToggleSound
-----------------------------------------------------------------------------
initialModel :: Model
initialModel = Model
  { players       = replicate 4 emptyPlayer
  , wall          = []
  , kanWall       = []
  , doraIndicator = Nothing
  , phase         = Title
  , dealer        = 0
  , handNum       = 1
  , lastCall      = Nothing
  , callSeq       = 0
  , soundOn       = True
  , pendingClaims = []
  }
-----------------------------------------------------------------------------
emptyPlayer :: Player
emptyPlayer = Player
  { hand  = []
  , drawn = Nothing
  , melds = []
  , river = []
  , score = 25000
  }
-----------------------------------------------------------------------------
-- | Seat wind of seat @i@ given the current dealer.
seatWind :: Model -> Int -> Wind
seatWind m i = toEnum ((i - dealer m) `mod` 4)
-----------------------------------------------------------------------------
-- | Next seat in turn order (counter-clockwise).
nextSeat :: Int -> Int
nextSeat i = (i + 1) `mod` 4
-----------------------------------------------------------------------------
-- | Apply a function to one player.
overPlayer :: Int -> (Player -> Player) -> Model -> Model
overPlayer i f m = m
  { players = [ if j == i then f p else p | (j, p) <- zip [0..] (players m) ] }
-----------------------------------------------------------------------------
playerAt :: Model -> Int -> Player
playerAt m i = players m !! i
-----------------------------------------------------------------------------
-- | Concealed hand plus the drawn tile, if any.
fullHand :: Player -> [Tile]
fullHand p = hand p ++ maybe [] pure (drawn p)
-----------------------------------------------------------------------------
-- | 'True' when every meld is concealed (hand counts as closed).
isClosed :: Player -> Bool
isClosed p = all concealed (melds p)
  where
    concealed (Meld (MeldKan True) _) = True
    concealed _                       = False
