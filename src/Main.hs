-----------------------------------------------------------------------------
-- | miso-mahjong: mahjong solitaire on the classic turtle.
-----------------------------------------------------------------------------
module Main where
-----------------------------------------------------------------------------
import           Control.Concurrent (threadDelay)
import           Control.Monad (forever, when)
-----------------------------------------------------------------------------
import           Miso hiding ((!!))
import qualified Miso.CSS as CSS
import qualified Miso.Html.Element as H
import qualified Miso.Html.Event as HE
import qualified Miso.Html.Property as HP
-----------------------------------------------------------------------------
import           Logic
import           Model
import           Sound
import           Styles (skin)
import           TileView
-----------------------------------------------------------------------------
main :: IO ()
main = startApp defaultEvents app
-----------------------------------------------------------------------------
app :: App Model Action
app = (component initialModel updateModel viewModel)
  { styles = [ Sheet skin ]
  , subs = [ timerSub ]
  }
-----------------------------------------------------------------------------
#ifdef WASM
foreign export javascript "hs_start" main :: IO ()
#endif
-----------------------------------------------------------------------------
timerSub :: Sub Model Action
timerSub sink _ = forever (threadDelay 1000000 >> sink Tick)
-----------------------------------------------------------------------------
type Fx = Effect () () Model Action
-----------------------------------------------------------------------------
-- * Update
-----------------------------------------------------------------------------
updateModel :: Action -> Fx
updateModel = \case
  NoOp -> pure ()

  ToggleSound ->
    modify (\m -> m { soundOn = not (soundOn m) })

  StartGame -> do
    io_ soundInit
    io (BoardSet <$> genDeal)

  NewGame ->
    io (BoardSet <$> genDeal)

  BoardSet newBoard -> do
    m <- get
    put initialModel
      { board = newBoard
      , phase = Playing
      , soundOn = soundOn m
      , animSeq = animSeq m
      }
    playFx "deal"

  Tick ->
    modify $ \m ->
      if phase m == Playing && not (showHelp m)
        then m { timeSec = timeSec m + 1 }
        else m

  ShowHelp ->
    modify (\m -> m { showHelp = True })

  CloseHelp ->
    modify (\m -> m { showHelp = False })

  ClickTile pos -> do
    m <- get
    case (phase m, tileAt (board m) pos) of
      (Playing, Just bt)
        | not (isFree (board m) bt) -> do
            put m { shakePos = Just pos
                  , animSeq = animSeq m + 1
                  , hintPair = Nothing
                  }
            playFx "deny"
        | selected m == Just pos -> do
            put m { selected = Nothing }
            playFx "clack"
        | Just sp <- selected m
        , Just sbt <- tileAt (board m) sp
        , matches (btKind sbt) (btKind bt) ->
            removePair sbt bt
        | otherwise -> do
            put m { selected = Just pos, shakePos = Nothing }
            playFx "clack"
      _ -> pure ()

  ClearVanish k ->
    modify (\m -> m { vanishing = filter ((/= k) . fst) (vanishing m) })

  Undo -> do
    m <- get
    case (phase m, history m) of
      (Playing, (a, b) : rest) -> do
        put m { board = a : b : board m
              , history = rest
              , selected = Nothing
              , hintPair = Nothing
              , shakePos = Nothing
              , stuck = False
              , moves = moves m - 1
              }
        playFx "draw"
      _ -> pure ()

  Hint -> do
    m <- get
    case (phase m, freePairs (board m)) of
      (Playing, prs@(_ : _)) -> do
        let (a, b) = prs !! (animSeq m `mod` length prs)
        put m { hintPair = Just (btPos a, btPos b)
              , animSeq = animSeq m + 1
              , selected = Nothing
              }
        playFx "draw"
      (Playing, []) -> playFx "deny"
      _ -> pure ()

  Shuffle -> do
    m <- get
    when (phase m == Playing && not (null (board m))) $ do
      playFx "deal"
      io (Shuffled <$> shuffleRemaining (board m))

  Shuffled newBoard ->
    modify $ \m -> m
      { board = newBoard
      , selected = Nothing
      , hintPair = Nothing
      , shakePos = Nothing
      , stuck = null (freePairs newBoard)
      }
-----------------------------------------------------------------------------
removePair :: BTile -> BTile -> Fx
removePair a b = do
  m <- get
  let board' = [ t | t <- board m
               , btPos t /= btPos a
               , btPos t /= btPos b
               ]
      k = moves m + 1
      won = null board'
      stuck' = not won && null (freePairs board')
  put m { board = board'
        , selected = Nothing
        , hintPair = Nothing
        , shakePos = Nothing
        , moves = k
        , history = (a, b) : history m
        , vanishing = vanishing m ++ [ (k, a), (k, b) ]
        , stuck = stuck'
        , phase = if won then Won else phase m
        }
  playFx (if won then "win" else "match")
  after 500 (ClearVanish k)
-----------------------------------------------------------------------------
-- | Schedule an action after a delay (milliseconds).
after :: Int -> Action -> Fx
after millis act = io (act <$ threadDelay (millis * 1000))
-----------------------------------------------------------------------------
playFx :: MisoString -> Fx
playFx name = do
  m <- get
  io_ (playSound (soundOn m) name)
-----------------------------------------------------------------------------
-- * View
-----------------------------------------------------------------------------
viewModel :: Model -> View () () Model Action
viewModel m = case phase m of
  Title -> H.div_ []
    ( titleView : [ helpOverlay | showHelp m ] )
  _ -> H.div_ []
    ( [ topbar m
      , boardView m
      ]
      ++ [ stuckToast | stuck m, phase m == Playing ]
      ++ [ winOverlay m | phase m == Won ]
      ++ [ helpOverlay | showHelp m ]
    )
-----------------------------------------------------------------------------
titleView :: View () () Model Action
titleView = H.div_ [ HP.class_ "titleWrap" ] $
  [ deco t x y r d
  | (t, x, y, r, d) <-
      [ (Suited Pin 1,      "8%",  "16%", "-9deg",  "0s")
      , (DragonTile Red,    "86%", "14%", "7deg",   ".9s")
      , (Suited Sou 5,      "13%", "72%", "6deg",   "1.7s")
      , (FlowerTile 3,      "84%", "70%", "-6deg",  ".4s")
      , (Suited Man 9,      "24%", "36%", "12deg",  "2.3s")
      , (SeasonTile 1,      "74%", "42%", "-12deg", "1.2s")
      ]
  ] ++
  [ H.h1_ [ HP.class_ "titleH" ] [ text "麻雀" ]
  , H.div_ [ HP.class_ "titleSub" ] [ text "MISO MAHJONG" ]
  , H.button_
      [ HP.class_ "btn startBtn", HE.onClick StartGame ]
      [ text "START GAME" ]
  , H.button_
      [ HP.class_ "btn ghost howBtn", HE.onClick ShowHelp ]
      [ text "HOW TO PLAY" ]
  , H.div_ [ HP.class_ "titleHint" ]
      [ text "clear the turtle · match free pairs · built with miso 🍜" ]
  ]
  where
    deco t x y r d = tileDiv "floatTile"
      [ CSS.style_
          [ CSS.left x, CSS.top y, "--fr" =: r, CSS.animationDelay d ]
      ] t
-----------------------------------------------------------------------------
topbar :: Model -> View () () Model Action
topbar m = H.div_ [ HP.class_ "topbar" ]
  [ H.div_ [ HP.class_ "brand" ]
      [ text "MISO MAHJONG ", H.small_ [] [ text "· solitaire" ] ]
  , H.div_ [ HP.class_ "hudStats" ]
      [ stat "⏱" (formatTime (timeSec m))
      , stat "🀄" (ms (length (board m)) <> " tiles")
      , stat "♟" (ms (length (freePairs (board m))) <> " moves")
      ]
  , H.div_ [ HP.class_ "tbBtns" ]
      [ iconBtn ShowHelp "❓" "how to play"
      , iconBtn Hint "💡" "hint"
      , iconBtn Undo "↩" "undo"
      , iconBtn Shuffle "🔀" "shuffle"
      , iconBtn ToggleSound
          (if soundOn m then "🔊" else "🔇")
          (if soundOn m then "sound" else "muted")
      , iconBtn NewGame "↺" "new game"
      ]
  ]
  where
    stat icon v = H.span_ [] [ text (icon <> " "), H.b_ [] [ text v ] ]
    iconBtn act icon label = H.button_
      [ HP.class_ "iconBtn", HE.onClick act ]
      [ text icon
      , H.span_ [ HP.class_ "btnLabel" ] [ text (" " <> label) ]
      ]
-----------------------------------------------------------------------------
boardView :: Model -> View () () Model Action
boardView m = H.div_ [ HP.class_ "boardWrap" ]
  [ H.div_ [ HP.class_ "board" ] $
      map (stileView m) (board m) ++ map vanishView (vanishing m)
  ]
-----------------------------------------------------------------------------
stileView :: Model -> BTile -> View () () Model Action
stileView m bt = tileDiv cls
  [ HE.onClick (ClickTile pos)
  , CSS.style_ (posStyle pos 0)
  ]
  (btKind bt)
  where
    pos = btPos bt
    alt = odd (animSeq m)
    hinted = case hintPair m of
      Just (p1, p2) -> pos == p1 || pos == p2
      Nothing -> False
    cls = joinCls
      [ "stile"
      , if isFree (board m) bt then "free" else "locked"
      , clsWhen (selected m == Just pos) "sel"
      , clsWhen hinted "hintT"
      , clsWhen (shakePos m == Just pos) "shakeT"
      , clsWhen ((hinted || shakePos m == Just pos) && alt) "alt"
      ]
-----------------------------------------------------------------------------
vanishView :: (Int, BTile) -> View () () Model Action
vanishView (_, bt) = tileDiv "stile vanish"
  [ CSS.style_ (posStyle (btPos bt) 50000 ++ [ CSS.animationDelay "0ms" ]) ]
  (btKind bt)
-----------------------------------------------------------------------------
-- | Absolute placement: half-unit grid scaled by the tile-size vars, with
-- each layer nudged up-right so the 3D bottom-left ridge reads as depth.
posStyle :: Pos -> Int -> [(MisoString, MisoString)]
posStyle (x, y, z) zBoost =
  [ CSS.left ("calc(var(--st) * " <> half x <> " + " <> ms (2 + z * 5) <> "px)")
  , CSS.top ("calc(var(--sth) * " <> half y <> " + " <> ms (30 - z * 7) <> "px)")
  , CSS.zIndex (zBoost + z * 10000 + y * 300 + (60 - x))
  , CSS.animationDelay (ms (((x * 7 + y * 13 + z * 31) `mod` 14) * 25) <> "ms")
  ]
  where
    half n = ms (fromIntegral n / 2 :: Double)
-----------------------------------------------------------------------------
joinCls :: [MisoString] -> MisoString
joinCls = mconcat . map (<> " ")
-----------------------------------------------------------------------------
clsWhen :: Bool -> MisoString -> MisoString
clsWhen True c = c
clsWhen False _ = ""
-----------------------------------------------------------------------------
stuckToast :: View () () Model Action
stuckToast = H.div_ [ HP.class_ "toastBar" ]
  [ H.span_ [ HP.class_ "toastMsg" ] [ text "行き詰まり — no moves left" ]
  , H.button_ [ HP.class_ "btn ghost", HE.onClick Undo ] [ text "UNDO" ]
  , H.button_ [ HP.class_ "btn", HE.onClick Shuffle ] [ text "SHUFFLE" ]
  ]
-----------------------------------------------------------------------------
helpOverlay :: View () () Model Action
helpOverlay = H.div_ [ HP.class_ "overlay help" ]
  [ H.div_ [ HP.class_ "panel helpPanel" ]
      [ H.button_ [ HP.class_ "helpClose", HE.onClick CloseHelp ] [ text "✕" ]
      , H.div_ [ HP.class_ "helpH" ] [ text "HOW TO PLAY" ]
      , H.div_ [ HP.class_ "helpSub" ]
          [ text "mahjong solitaire · the classic turtle" ]
      , sec "THE OBJECTIVE"
      , para $
          "Clear all 144 tiles from the board by removing them two at a "
          <> "time as matching pairs. The tiles are stacked five layers "
          <> "deep — you win when nothing is left."
      , sec "FREE TILES"
      , para $
          "Only free tiles can be picked up: nothing may rest on top of "
          <> "them, and at least one side — left or right — must be open. "
          <> "Locked tiles are dimmed until you dig them out."
      , sec "MATCHING PAIRS"
      , matchRow True (Suited Sou 7) (Suited Sou 7)
          "identical tiles always match"
      , matchRow True (DragonTile Red) (DragonTile Red)
          "…winds and dragons too"
      , matchRow True (FlowerTile 1) (FlowerTile 3)
          "any flower matches any flower 梅蘭菊竹"
      , matchRow True (SeasonTile 1) (SeasonTile 4)
          "any season matches any season 春夏秋冬"
      , matchRow False (Suited Man 1) (Suited Pin 1)
          "same number, different suit — never a match"
      , sec "THE TILES"
      , H.div_ [ HP.class_ "famStrip" ]
          [ fam (Suited Man 5) "characters"
          , fam (Suited Pin 5) "circles"
          , fam (Suited Sou 5) "bamboo"
          , fam (WindTile East) "winds"
          , fam (DragonTile Green) "dragons"
          , fam (FlowerTile 2) "flowers"
          , fam (SeasonTile 2) "seasons"
          ]
      , sec "HELPERS"
      , para $
          "💡 hint shows an available pair · ↩ undo rewinds as far as "
          <> "you like · 🔀 shuffle re-deals the remaining tiles and always "
          <> "leaves a winnable board. Every fresh deal is guaranteed "
          <> "solvable — and the clock pauses while you read this."
      , H.button_ [ HP.class_ "btn", HE.onClick CloseHelp ] [ text "GOT IT" ]
      ]
  ]
  where
    sec s = H.div_ [ HP.class_ "helpSec" ] [ text s ]
    para s = H.p_ [ HP.class_ "helpP" ] [ text s ]
    matchRow ok a b caption = H.div_ [ HP.class_ "helpRow" ]
      [ tileDiv "" [] a
      , tileDiv "" [] b
      , H.span_ [ HP.class_ (if ok then "mark ok" else "mark no") ]
          [ text (if ok then "✓" else "✕") ]
      , H.span_ [ HP.class_ "helpCap" ] [ text caption ]
      ]
    fam t label = H.div_ [ HP.class_ "fam" ]
      [ tileDiv "" [] t, H.span_ [] [ text label ] ]
-----------------------------------------------------------------------------
winOverlay :: Model -> View () () Model Action
winOverlay m = H.div_ [ HP.class_ "overlay" ]
  [ H.div_ [ HP.class_ "panel" ]
      [ H.div_ [ HP.class_ "winTitle" ] [ text "CLEARED!" ]
      , H.div_ [ HP.class_ "winSub" ] [ text "the turtle is no more 🐢" ]
      , statRow 0 "Time" (formatTime (timeSec m))
      , statRow 1 "Pairs matched" (ms (moves m))
      , statRow 2 "Tiles" "144"
      , H.button_ [ HP.class_ "btn", HE.onClick NewGame ] [ text "NEW GAME" ]
      ]
  ]
  where
    statRow :: Int -> MisoString -> MisoString -> View () () Model Action
    statRow k label v = H.div_
      [ HP.class_ "statRow"
      , CSS.style_ [ CSS.animationDelay (ms (200 + k * 130) <> "ms") ]
      ]
      [ H.span_ [] [ text label ], H.b_ [] [ text v ] ]
