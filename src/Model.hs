-----------------------------------------------------------------------------
-- | Core types for miso-mahjong (mahjong solitaire): tiles, board
-- positions, model.
-----------------------------------------------------------------------------
module Model where
-----------------------------------------------------------------------------
-- | The three numbered suits.
data Suit
  = Man -- ^ characters 萬
  | Pin -- ^ circles 筒
  | Sou -- ^ bamboo 索
  deriving (Eq, Ord, Show, Enum, Bounded)
-----------------------------------------------------------------------------
data Wind = East | South | West | North
  deriving (Eq, Ord, Show, Enum, Bounded)
-----------------------------------------------------------------------------
data Dragon = White | Green | Red
  deriving (Eq, Ord, Show, Enum, Bounded)
-----------------------------------------------------------------------------
-- | A mahjong tile. Suited ranks are 1..9; flowers and seasons are 1..4.
data Tile
  = Suited Suit Int
  | WindTile Wind
  | DragonTile Dragon
  | FlowerTile Int -- ^ 梅蘭菊竹 — any flower matches any flower
  | SeasonTile Int -- ^ 春夏秋冬 — any season matches any season
  deriving (Eq, Ord, Show)
-----------------------------------------------------------------------------
-- | Board position in half-tile units (a tile spans 2×2), plus layer.
type Pos = (Int, Int, Int) -- ^ (x2, y2, z)
-----------------------------------------------------------------------------
-- | A tile sitting on the board.
data BTile = BTile
  { btPos  :: Pos
  , btKind :: Tile
  } deriving (Eq, Show)
-----------------------------------------------------------------------------
data Phase
  = Title
  | Playing
  | Won
  deriving (Eq, Show)
-----------------------------------------------------------------------------
data Model = Model
  { board     :: [BTile]           -- ^ tiles still on the board
  , selected  :: Maybe Pos
  , history   :: [(BTile, BTile)]  -- ^ undo stack, most recent first
  , vanishing :: [(Int, BTile)]    -- ^ tiles animating out, keyed for pruning
  , hintPair  :: Maybe (Pos, Pos)
  , shakePos  :: Maybe Pos         -- ^ tile shaking after an invalid click
  , animSeq   :: Int               -- ^ parity remounts shake/hint animations
  , moves     :: Int               -- ^ pairs removed this game
  , timeSec   :: Int
  , stuck     :: Bool              -- ^ no matching free pair remains
  , phase     :: Phase
  , soundOn   :: Bool
  , showHelp  :: Bool              -- ^ the how-to-play modal is open
  } deriving (Eq, Show)
-----------------------------------------------------------------------------
data Action
  = NoOp
  | StartGame
  | NewGame
  | BoardSet [BTile]
  | ClickTile Pos
  | ClearVanish Int
  | Undo
  | Hint
  | Shuffle
  | Shuffled [BTile]
  | Tick
  | ToggleSound
  | ShowHelp
  | CloseHelp
-----------------------------------------------------------------------------
initialModel :: Model
initialModel = Model
  { board     = []
  , selected  = Nothing
  , history   = []
  , vanishing = []
  , hintPair  = Nothing
  , shakePos  = Nothing
  , animSeq   = 0
  , moves     = 0
  , timeSec   = 0
  , stuck     = False
  , phase     = Title
  , soundOn   = True
  , showHelp  = False
  }
-----------------------------------------------------------------------------
-- | Find the board tile at a position.
tileAt :: [BTile] -> Pos -> Maybe BTile
tileAt bts p = case [ bt | bt <- bts, btPos bt == p ] of
  (bt : _) -> Just bt
  [] -> Nothing
