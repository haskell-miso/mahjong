-----------------------------------------------------------------------------
-- | miso-mahjong: riichi-style mahjong, one player vs. three CPU seats.
-----------------------------------------------------------------------------
module Main where
-----------------------------------------------------------------------------
import           Control.Concurrent (threadDelay)
import           Control.Monad (when)
import           Data.List ((\\), elemIndex, sortOn)
import           Data.Maybe (isJust, isNothing, listToMaybe)
import           Data.Ord (Down(..))
-----------------------------------------------------------------------------
import           Miso hiding ((!!))
import qualified Miso.CSS as CSS
import qualified Miso.Html.Element as H
import qualified Miso.Html.Event as HE
import qualified Miso.Html.Property as HP
-----------------------------------------------------------------------------
import           AI
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
  { styles = [ Sheet skin ] }
-----------------------------------------------------------------------------
#ifdef WASM
foreign export javascript "hs_start" main :: IO ()
#endif
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
    modify (\m -> m { phase = Dealing })
    io (BeginHand <$> shuffleIO)

  NewGame -> do
    m <- get
    put initialModel { soundOn = soundOn m, phase = Dealing }
    io (BeginHand <$> shuffleIO)

  BeginHand tiles -> do
    modify (dealHand tiles)
    playFx "deal"
    after 1300 StartTurns

  StartTurns -> do
    m <- get
    put m { phase = TurnDraw (dealer m) }
    issue DrawTile

  DrawTile -> do
    m <- get
    case phase m of
      TurnDraw i -> case wall m of
        [] -> do
          put m { phase = HandEnd Exhausted }
          playFx "lose"
        (t : rest) -> do
          put $ overPlayer i (\p -> p { drawn = Just t })
                  m { wall = rest, phase = TurnDiscard i }
          when (i == 0) (playFx "draw")
          when (i /= 0) (after 600 CpuMove)
      _ -> pure ()

  CpuMove -> do
    m <- get
    case phase m of
      TurnDiscard i | i /= 0 -> do
        let p = playerAt m i
            full = fullHand p
        if isJust (drawn p) && isComplete full (length (melds p))
          then winHand i Nothing (maybe (last full) id (drawn p))
          else case wantsAnkan p of
            Just t | not (null (kanWall m)), isJust (drawn p) ->
              doAnkan i t
            _ ->
              discardTile i (bestDiscard full (melds p))
      _ -> pure ()

  HumanDiscardAt k -> do
    m <- get
    case phase m of
      TurnDiscard 0 | k < length (hand (playerAt m 0)) ->
        discardTile 0 (hand (playerAt m 0) !! k)
      _ -> pure ()

  HumanDiscardDrawn -> do
    m <- get
    case (phase m, drawn (playerAt m 0)) of
      (TurnDiscard 0, Just t) -> discardTile 0 t
      _ -> pure ()

  HumanTsumo -> do
    m <- get
    let p = playerAt m 0
    case (phase m, drawn p) of
      (TurnDiscard 0, Just t)
        | isComplete (fullHand p) (length (melds p)) ->
            winHand 0 Nothing t
      _ -> pure ()

  HumanKan t -> do
    m <- get
    let p = playerAt m 0
    case phase m of
      TurnDiscard 0
        | not (null (kanWall m))
        , length (filter (== t) (fullHand p)) == 4 ->
            doAnkan 0 t
      _ -> pure ()

  HumanClaim opt -> do
    m <- get
    case phase m of
      AwaitClaim d t opts | opt `elem` opts || opt == ClaimSkip -> do
        let claims = pendingClaims m ++ [ (0, opt) | opt /= ClaimSkip ]
        applyClaims d t claims
      _ -> pure ()

  NextHand -> do
    m <- get
    if handNum m >= 4
      then put m { phase = GameOver }
      else do
        put m { handNum = handNum m + 1
              , dealer = nextSeat (dealer m)
              , phase = Dealing
              }
        io (BeginHand <$> shuffleIO)
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
callout :: Int -> MisoString -> Model -> Model
callout i txt m = m { lastCall = Just (i, txt), callSeq = callSeq m + 1 }
-----------------------------------------------------------------------------
dealHand :: [Tile] -> Model -> Model
dealHand ts m = m
  { players =
      [ p { hand = sortHand h, drawn = Nothing, melds = [], river = [] }
      | (p, h) <- zip (players m) [h0, h1, h2, h3]
      ]
  , wall = liveWall
  , kanWall = take 4 (drop 1 dead)
  , doraIndicator = listToMaybe dead
  , phase = Dealing
  , lastCall = Nothing
  , pendingClaims = []
  }
  where
    (h0, r0) = splitAt 13 ts
    (h1, r1) = splitAt 13 r0
    (h2, r2) = splitAt 13 r1
    (h3, r3) = splitAt 13 r2
    (liveWall, dead) = splitAt (length r3 - 14) r3
-----------------------------------------------------------------------------
discardTile :: Int -> Tile -> Fx
discardTile i t = do
  m <- get
  put $ overPlayer i
          (\p -> p { hand = sortHand (fullHand p \\ [t])
                   , drawn = Nothing
                   , river = river p ++ [t]
                   }) m
  playFx "clack"
  resolveDiscard i t
-----------------------------------------------------------------------------
resolveDiscard :: Int -> Tile -> Fx
resolveDiscard d t = do
  m <- get
  let cpuSeats = [ j | j <- seatsAfter d, j /= 0 ]
      cpuClaims = concat [ cpuClaimFor m j d t | j <- cpuSeats ]
      humanOpts = if d == 0 then [] else humanClaimsFor m d t
  if null humanOpts
    then applyClaims d t cpuClaims
    else do
      put m { phase = AwaitClaim d t (humanOpts ++ [ClaimSkip])
            , pendingClaims = cpuClaims
            }
-----------------------------------------------------------------------------
seatsAfter :: Int -> [Int]
seatsAfter d = [ (d + k) `mod` 4 | k <- [1, 2, 3] ]
-----------------------------------------------------------------------------
cpuClaimFor :: Model -> Int -> Int -> Tile -> [(Int, ClaimOption)]
cpuClaimFor m j d t
  | canRon p t = [(j, ClaimRon)]
  | wantsPon p t = [(j, ClaimPon)]
  | j == nextSeat d, Just (a, b) <- wantsChi p t = [(j, ClaimChi a b)]
  | otherwise = []
  where
    p = playerAt m j
-----------------------------------------------------------------------------
humanClaimsFor :: Model -> Int -> Tile -> [ClaimOption]
humanClaimsFor m d t = concat
  [ [ ClaimRon | canRon p t ]
  , [ ClaimPon | length (filter (== t) (hand p)) >= 2 ]
  , [ ClaimChi a b | 0 == nextSeat d, (a, b) <- chiOptions (hand p) t ]
  ]
  where
    p = playerAt m 0
-----------------------------------------------------------------------------
claimRank :: ClaimOption -> Int
claimRank ClaimRon = 0
claimRank ClaimPon = 1
claimRank ClaimChi{} = 2
claimRank ClaimSkip = 9
-----------------------------------------------------------------------------
applyClaims :: Int -> Tile -> [(Int, ClaimOption)] -> Fx
applyClaims d t claims =
  case ranked of
    [] -> do
      modify (\m -> m { phase = TurnDraw (nextSeat d), pendingClaims = [] })
      after 260 DrawTile
    ((j, ClaimRon) : _) -> winHand j (Just d) t
    ((j, ClaimPon) : _) -> doPon j d t
    ((j, ClaimChi a b) : _) -> doChi j d t a b
    _ -> pure ()
  where
    ranked = sortOn (\(j, c) -> (claimRank c, (j - d) `mod` 4))
      [ (j, c) | (j, c) <- claims, c /= ClaimSkip ]
-----------------------------------------------------------------------------
-- | Take the claimed tile off the discarder's river.
stealDiscard :: Int -> Model -> Model
stealDiscard d = overPlayer d (\p -> p { river = init (river p) })
-----------------------------------------------------------------------------
doPon :: Int -> Int -> Tile -> Fx
doPon j d t = do
  m <- get
  put $ callout j "PON"
      $ stealDiscard d
      $ overPlayer j
          (\p -> p { hand = hand p \\ [t, t]
                   , melds = melds p ++ [Meld MeldPon [t, t, t]]
                   })
          m { phase = TurnDiscard j, pendingClaims = [] }
  playFx "call"
  when (j /= 0) (after 800 CpuMove)
-----------------------------------------------------------------------------
doChi :: Int -> Int -> Tile -> Tile -> Tile -> Fx
doChi j d t a b = do
  m <- get
  put $ callout j "CHI"
      $ stealDiscard d
      $ overPlayer j
          (\p -> p { hand = hand p \\ [a, b]
                   , melds = melds p ++ [Meld MeldChi (sortHand [a, b, t])]
                   })
          m { phase = TurnDiscard j, pendingClaims = [] }
  playFx "call"
  when (j /= 0) (after 800 CpuMove)
-----------------------------------------------------------------------------
doAnkan :: Int -> Tile -> Fx
doAnkan i t = do
  m <- get
  case kanWall m of
    [] -> pure ()
    (kt : kws) -> do
      put $ callout i "KAN"
          $ overPlayer i
              (\p -> p { hand = sortHand (fullHand p \\ [t, t, t, t])
                       , drawn = Just kt
                       , melds = melds p ++ [Meld (MeldKan True) [t, t, t, t]]
                       })
              m { kanWall = kws }
      playFx "kan"
      when (i /= 0) (after 800 CpuMove)
-----------------------------------------------------------------------------
winHand :: Int -> Maybe Int -> Tile -> Fx
winHand w mFrom winTile = do
  m <- get
  let p = playerAt m w
      concealed = sortHand $ case mFrom of
        Nothing -> fullHand p
        Just _  -> hand p ++ [winTile]
      dora = map doraOf (maybe [] pure (doraIndicator m))
      (yaku, pts) = scoreWin WinInfo
        { wiTsumo = isNothing mFrom
        , wiSeatWind = seatWind m w
        , wiConcealed = concealed
        , wiMelds = melds p
        , wiDora = dora
        , wiDealer = w == dealer m
        }
      outcome = Victory
        { vWinner = w, vFrom = mFrom, vTiles = concealed
        , vLast = winTile, vMelds = melds p, vYaku = yaku, vPoints = pts
        }
  put $ callout w (if isNothing mFrom then "TSUMO" else "RON")
      $ applyPayments w mFrom pts
        m { phase = HandEnd outcome, pendingClaims = [] }
  playFx (if w == 0 then "win" else "lose")
-----------------------------------------------------------------------------
applyPayments :: Int -> Maybe Int -> Int -> Model -> Model
applyPayments w (Just d) pts m =
  overPlayer w (\p -> p { score = score p + pts })
    (overPlayer d (\p -> p { score = score p - pts }) m)
applyPayments w Nothing pts m =
  m { players =
      [ if j == w
          then p { score = score p + 3 * share }
          else p { score = score p - share }
      | (j, p) <- zip [0 ..] (players m)
      ]
    }
  where
    share = roundTo100 (pts `div` 3)
-----------------------------------------------------------------------------
-- * View
-----------------------------------------------------------------------------
viewModel :: () -> () -> Model -> View () Model Action
viewModel _ _ m = case phase m of
  Title -> titleView
  _ -> H.div_ []
    ( [ topbar m
      , H.div_ [ HP.class_ "app" ] [ tableView m ]
      , handView m
      ]
      ++ actionBar m
      ++ claimBar m
      ++ endOverlay m
    )
-----------------------------------------------------------------------------
titleView :: View () Model Action
titleView = H.div_ [ HP.class_ "titleWrap" ] $
  [ deco t x y r d
  | (t, x, y, r, d) <-
      [ (Suited Pin 1,      "8%",  "16%", "-9deg",  "0s")
      , (DragonTile Red,    "86%", "14%", "7deg",   ".9s")
      , (Suited Sou 5,      "13%", "72%", "6deg",   "1.7s")
      , (WindTile East,     "84%", "70%", "-6deg",  ".4s")
      , (Suited Man 9,      "24%", "36%", "12deg",  "2.3s")
      , (Suited Pin 7,      "74%", "42%", "-12deg", "1.2s")
      ]
  ] ++
  [ H.h1_ [ HP.class_ "titleH" ] [ text "麻雀" ]
  , H.div_ [ HP.class_ "titleSub" ] [ text "MISO MAHJONG" ]
  , H.button_
      [ HP.class_ "btn startBtn", HE.onClick StartGame ]
      [ text "START GAME" ]
  , H.div_ [ HP.class_ "titleHint" ]
      [ text "you vs. three cpu players · east round · built with miso 🍜" ]
  ]
  where
    deco t x y r d = tileDiv "floatTile"
      [ CSS.style_
          [ CSS.left x, CSS.top y, "--fr" =: r, CSS.animationDelay d ]
      ] t
-----------------------------------------------------------------------------
topbar :: Model -> View () Model Action
topbar m = H.div_ [ HP.class_ "topbar" ]
  [ H.div_ [ HP.class_ "brand" ]
      [ text "MISO MAHJONG "
      , H.small_ [] [ text ("· " <> roundName m) ]
      ]
  , H.div_ [ HP.class_ "tbBtns" ]
      [ H.button_ [ HP.class_ "iconBtn", HE.onClick ToggleSound ]
          [ text (if soundOn m then "🔊 sound" else "🔇 muted") ]
      , H.button_ [ HP.class_ "iconBtn", HE.onClick NewGame ]
          [ text "↺ new game" ]
      ]
  ]
-----------------------------------------------------------------------------
roundName :: Model -> MisoString
roundName m = "東" <> (["一", "二", "三", "四"] !! (handNum m - 1)) <> "局"
-----------------------------------------------------------------------------
tableView :: Model -> View () Model Action
tableView m = H.div_ [ HP.class_ "table" ] $
  [ seatView m i | i <- [0 .. 3] ]
  ++ [ centerView m ]
  ++ calloutView m
-----------------------------------------------------------------------------
seatView :: Model -> Int -> View () Model Action
seatView m i = H.div_ [ HP.class_ ("seat seat" <> ms i) ] $
  [ riverView m i
  , meldRowView m i
  ] ++ [ opponentHand m i | i /= 0 ]
-----------------------------------------------------------------------------
riverView :: Model -> Int -> View () Model Action
riverView m i = H.div_ [ HP.class_ "river" ]
  [ tileDiv (if hot k then "hot" else "") [] t
  | (k, t) <- zip [0 ..] tiles
  ]
  where
    tiles = river (playerAt m i)
    hot k = case phase m of
      AwaitClaim d _ _ -> d == i && k == length tiles - 1
      _ -> False
-----------------------------------------------------------------------------
meldRowView :: Model -> Int -> View () Model Action
meldRowView m i = H.div_ [ HP.class_ "meldRow" ]
  [ H.div_ [ HP.class_ "meld" ] (meldTilesView md) | md <- melds (playerAt m i) ]
  where
    meldTilesView (Meld (MeldKan True) (t : _)) =
      [ tileBackDiv "" [], tileDiv "" [] t, tileDiv "" [] t, tileBackDiv "" [] ]
    meldTilesView (Meld _ ts) = [ tileDiv "" [] t | t <- ts ]
-----------------------------------------------------------------------------
opponentHand :: Model -> Int -> View () Model Action
opponentHand m i = H.div_ [ HP.class_ "oh" ]
  (replicate n (tileBackDiv "" []))
  where
    p = playerAt m i
    n = length (hand p) + maybe 0 (const 1) (drawn p)
-----------------------------------------------------------------------------
centerView :: Model -> View () Model Action
centerView m = H.div_ [ HP.class_ "center" ] $
  [ H.div_ [ HP.class_ "centerInner" ]
      [ H.div_ [ HP.class_ "roundBadge" ] [ text (roundName m) ]
      , H.div_ [ HP.class_ "centerLow" ] $
          [ H.div_ [ HP.class_ "wallInfo" ]
              [ text ("山 " <> ms (length (wall m)) <> " tiles") ]
          ] ++
          [ H.div_ [ HP.class_ "doraBox" ]
              [ H.span_ [ HP.class_ "doraLabel" ] [ text "ドラ" ]
              , tileDiv "" [] ind
              ]
          | Just ind <- [doraIndicator m]
          ]
      ]
  ] ++ [ scorePlate m i | i <- [0 .. 3] ]
-----------------------------------------------------------------------------
scorePlate :: Model -> Int -> View () Model Action
scorePlate m i = H.div_
  [ HP.class_ $ "scorePlate plate" <> ms i <> (if active then " active" else "") ]
  [ H.span_
      [ HP.class_ ("plateWind" <> (if isDealer then " dealerWind" else "")) ]
      [ text (windChar (seatWind m i)) ]
  , H.span_ [ HP.class_ "plateScore" ]
      [ text (label <> ms (score (playerAt m i))) ]
  ]
  where
    isDealer = i == dealer m
    label = if i == 0 then "you " else ""
    active = case phase m of
      TurnDraw j -> j == i
      TurnDiscard j -> j == i
      _ -> False
-----------------------------------------------------------------------------
seatName :: Int -> MisoString
seatName 0 = "you"
seatName i = "cpu " <> ms i
-----------------------------------------------------------------------------
calloutView :: Model -> [View () Model Action]
calloutView m =
  [ H.div_
      [ HP.class_ $ "callout c" <> ms i
          <> (if odd (callSeq m) then " alt" else "") ]
      [ text (txt <> "!") ]
  | Just (i, txt) <- [lastCall m]
  ]
-----------------------------------------------------------------------------
handView :: Model -> View () Model Action
handView m = H.div_ [ HP.class_ "hand" ] $
  [ tileDiv cls (attrs (HumanDiscardAt k) (delay k)) t
  | (k, t) <- zip [0 ..] (hand p)
  ] ++
  [ tileDiv (if clickable then "drawnTile live" else "drawnTile")
      (attrs HumanDiscardDrawn []) t
  | Just t <- [drawn p]
  ]
  where
    p = playerAt m 0
    clickable = phase m == TurnDiscard 0
    dealing = phase m == Dealing
    cls = mconcat
      [ if dealing then "deal " else ""
      , if clickable then "live" else ""
      ]
    delay k =
      [ CSS.style_ [ CSS.animationDelay (ms (k * 45 :: Int) <> "ms") ]
      | dealing
      ]
    attrs act extra = [ HE.onClick act | clickable ] ++ extra
-----------------------------------------------------------------------------
actionBar :: Model -> [View () Model Action]
actionBar m =
  [ H.div_ [ HP.class_ "actionBar" ] btns
  | phase m == TurnDiscard 0
  , not (null btns)
  ]
  where
    p = playerAt m 0
    full = fullHand p
    canTsumo = isJust (drawn p) && isComplete full (length (melds p))
    kans =
      [ t
      | not (null (kanWall m))
      , t <- tileKinds
      , length (filter (== t) full) == 4
      ]
    btns = concat
      [ [ H.button_ [ HP.class_ "btn ron", HE.onClick HumanTsumo ]
            [ text "TSUMO 自摸" ]
        | canTsumo ]
      , [ H.button_ [ HP.class_ "btn kan", HE.onClick (HumanKan t) ]
            [ text "KAN 槓", H.div_ [ HP.class_ "chiTiles" ] [ tileDiv "" [] t ] ]
        | t <- kans ]
      ]
-----------------------------------------------------------------------------
claimBar :: Model -> [View () Model Action]
claimBar m =
  [ H.div_ [ HP.class_ "claimBar" ] (map claimBtn opts)
  | AwaitClaim _ _ opts <- [phase m]
  ]
  where
    claimBtn opt = case opt of
      ClaimRon -> H.button_
        [ HP.class_ "btn ron", HE.onClick (HumanClaim opt) ]
        [ text "RON 和了" ]
      ClaimPon -> H.button_
        [ HP.class_ "btn pon", HE.onClick (HumanClaim opt) ]
        [ text "PON ポン" ]
      ClaimChi a b -> H.button_
        [ HP.class_ "btn chi", HE.onClick (HumanClaim opt) ]
        [ text "CHI"
        , H.div_ [ HP.class_ "chiTiles" ] [ tileDiv "" [] a, tileDiv "" [] b ]
        ]
      ClaimSkip -> H.button_
        [ HP.class_ "btn ghost", HE.onClick (HumanClaim opt) ]
        [ text "SKIP" ]
-----------------------------------------------------------------------------
endOverlay :: Model -> [View () Model Action]
endOverlay m = case phase m of
  HandEnd outcome -> [ handEndPanel m outcome ]
  GameOver -> [ gameOverPanel m ]
  _ -> []
-----------------------------------------------------------------------------
handEndPanel :: Model -> Outcome -> View () Model Action
handEndPanel m outcome = H.div_ [ HP.class_ "overlay" ]
  [ H.div_ [ HP.class_ "panel" ] inner ]
  where
    nextLabel = if handNum m >= 4 then "RESULTS" else "NEXT HAND"
    nextBtn = H.button_
      [ HP.class_ "btn", HE.onClick NextHand ] [ text nextLabel ]
    inner = case outcome of
      Exhausted ->
        [ H.div_ [ HP.class_ "winTitle" ] [ text "流局" ]
        , H.div_ [ HP.class_ "winSub" ]
            [ text ("exhaustive draw · " <> roundName m) ]
        , nextBtn
        ]
      Victory{..} ->
        [ H.div_ [ HP.class_ "winTitle" ]
            [ text (if vWinner == 0 then "YOU WIN" else seatName vWinner <> " wins") ]
        , H.div_ [ HP.class_ "winSub" ]
            [ text $ (if isNothing vFrom then "tsumo 自摸" else "ron 和了")
                <> " · " <> roundName m ]
        , H.div_ [ HP.class_ "winTiles" ] $
            [ winTile (cssDelay k) t (Just k == winIx)
            | (k, t) <- zip [0 ..] vTiles
            ] ++
            [ winTile (cssDelay (nTiles + k)) t False
            | (k, t) <- zip [0 ..] (concatMap meldTiles vMelds)
            ]
        , H.div_ [ HP.class_ "yakuList" ]
            [ H.div_
                [ HP.class_ "yakuRow"
                , CSS.style_ [ CSS.animationDelay (ms (500 + k * 120 :: Int) <> "ms") ]
                ]
                [ H.span_ [] [ text name ]
                , H.b_ []
                    [ text (if han >= 13 then "役満" else ms han <> " han") ]
                ]
            | (k, (name, han)) <- zip [0 ..] vYaku
            ]
        , H.div_
            [ HP.class_ "points"
            , CSS.style_ [ CSS.animationDelay "900ms" ]
            ]
            [ text (ms vPoints <> " pts") ]
        , nextBtn
        ]
        where
          nTiles = length vTiles
          winIx = elemIndex vLast vTiles
    winTile d t winning =
      tileDiv (if winning then "winning" else "") [ d ] t
    cssDelay k = CSS.style_
      [ CSS.animationDelay (ms (k * 60 :: Int) <> "ms") ]
-----------------------------------------------------------------------------
gameOverPanel :: Model -> View () Model Action
gameOverPanel m = H.div_ [ HP.class_ "overlay" ]
  [ H.div_ [ HP.class_ "panel" ] $
      [ H.div_ [ HP.class_ "winTitle" ] [ text "GAME OVER" ]
      , H.div_ [ HP.class_ "winSub" ] [ text "east round complete" ]
      ] ++
      [ H.div_
          [ HP.class_ ("rankRow" <> (if i == 0 then " human" else ""))
          , CSS.style_ [ CSS.animationDelay (ms (k * 130 :: Int) <> "ms") ]
          ]
          [ H.b_ [] [ text (medal k <> " " <> seatName i) ]
          , H.span_ [] [ text (ms (score p) <> " pts") ]
          ]
      | (k, (i, p)) <- zip [0 :: Int ..]
          (sortOn (Down . score . snd) (zip [0 ..] (players m)))
      ] ++
      [ H.button_
          [ HP.class_ "btn"
          , HE.onClick NewGame
          , CSS.style_ [ CSS.marginTop "18px" ]
          ]
          [ text "PLAY AGAIN" ]
      ]
  ]
  where
    medal 0 = "🥇"
    medal 1 = "🥈"
    medal 2 = "🥉"
    medal _ = "④"
