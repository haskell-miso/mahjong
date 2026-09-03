-----------------------------------------------------------------------------
-- | SVG artwork for mahjong tiles. The tile body (ivory face, shadows,
-- back) is styled in CSS on the wrapping @.tile@ div; this module renders
-- the face symbols into a @viewBox 0 0 60 84@ canvas.
-----------------------------------------------------------------------------
module TileView
  ( tileDiv
  , tileBackDiv
  , tileFace
  ) where
-----------------------------------------------------------------------------
import           Miso hiding ((!!))
import qualified Miso.Html.Element as H
import qualified Miso.Html.Property as HP
import qualified Miso.Svg.Element as S
import qualified Miso.Svg.Property as SP
-----------------------------------------------------------------------------
import           Logic (dragonChar, windChar)
import           Model
-----------------------------------------------------------------------------
-- Ink palette
ink, red, green :: MisoString
ink   = "#243a66"
red   = "#b23a48"
green = "#2f7d4f"
-----------------------------------------------------------------------------
-- width/height are not in Miso.Svg.Property; set them as plain attributes
w_, h_ :: MisoString -> Attribute model action
w_ = textProp "width"
h_ = textProp "height"
-----------------------------------------------------------------------------
-- | A face-up tile with extra classes on the wrapper div.
tileDiv :: MisoString -> [Attribute model action] -> Tile -> View c model action
tileDiv cls attrs t =
  H.div_ (HP.class_ ("tile " <> cls) : attrs) [ tileFace t ]
-----------------------------------------------------------------------------
-- | A face-down tile.
tileBackDiv :: MisoString -> [Attribute model action] -> View c model action
tileBackDiv cls attrs =
  H.div_ (HP.class_ ("tile back " <> cls) : attrs) []
-----------------------------------------------------------------------------
-- | The engraved face of a tile.
tileFace :: Tile -> View c model action
tileFace t = S.svg_ [ SP.viewBox_ "0 0 60 84" ] (faceOf t)
-----------------------------------------------------------------------------
faceOf :: Tile -> [View c model action]
faceOf (Suited Man n) =
  [ glyph 30 34 30 ink (manNumeral n)
  , glyph 30 72 27 red "萬"
  ]
faceOf (Suited Pin n) = pinFace n
faceOf (Suited Sou n) = souFace n
faceOf (WindTile w) =
  [ glyph 30 58 42 ink (windChar w)
  , glyph 10 14 9 "#8b95ad" (windLetter w)
  ]
faceOf (DragonTile White) =
  [ S.rect_
      [ SP.x_ "14", SP.y_ "17", w_ "32", h_ "50"
      , SP.rx_ "5", SP.fill_ "none"
      , SP.stroke_ "#3d5a97", SP.strokeWidth_ "3.5"
      ]
  , S.rect_
      [ SP.x_ "21", SP.y_ "24", w_ "18", h_ "36"
      , SP.rx_ "3", SP.fill_ "none"
      , SP.stroke_ "#9db2d8", SP.strokeWidth_ "2"
      ]
  ]
faceOf (DragonTile Green) = [ glyph 30 58 42 green (dragonChar Green) ]
faceOf (DragonTile Red)   = [ glyph 30 58 42 red (dragonChar Red) ]
-----------------------------------------------------------------------------
glyph :: Int -> Int -> Int -> MisoString -> MisoString -> View c model action
glyph x y size color str =
  S.text_
    [ SP.x_ (ms x), SP.y_ (ms y)
    , SP.fontSize_ (ms size)
    , SP.fill_ color
    , SP.textAnchor_ "middle"
    , SP.fontWeight_ "700"
    ] [ text str ]
-----------------------------------------------------------------------------
manNumeral :: Int -> MisoString
manNumeral n = ["一","二","三","四","五","六","七","八","九"] !! (n - 1)
-----------------------------------------------------------------------------
windLetter :: Wind -> MisoString
windLetter East  = "E"
windLetter South = "S"
windLetter West  = "W"
windLetter North = "N"
-----------------------------------------------------------------------------
-- * Pin (circle) faces
-----------------------------------------------------------------------------
pip :: Int -> Int -> Int -> MisoString -> View c model action
pip x y r color = S.g_ []
  [ S.circle_
      [ SP.cx_ (ms x), SP.cy_ (ms y), SP.r_ (ms r)
      , SP.fill_ color
      ]
  , S.circle_
      [ SP.cx_ (ms x), SP.cy_ (ms y), SP.r_ (ms (max 1 (r - 3)))
      , SP.fill_ "none", SP.stroke_ "#f6f1e2", SP.strokeWidth_ "1.4"
      , SP.opacity_ "0.85"
      ]
  , S.circle_
      [ SP.cx_ (ms (x - r `div` 3)), SP.cy_ (ms (y - r `div` 3))
      , SP.r_ (ms (max 1 (r `div` 4)))
      , SP.fill_ "#ffffff", SP.opacity_ "0.55"
      ]
  ]
-----------------------------------------------------------------------------
pinFace :: Int -> [View c model action]
pinFace 1 =
  [ S.circle_
      [ SP.cx_ "30", SP.cy_ "42", SP.r_ "19"
      , SP.fill_ "none", SP.stroke_ green, SP.strokeWidth_ "2.5" ]
  , pip 30 42 14 red
  ]
pinFace n = [ pip x y r c | (x, y, c) <- spots ]
  where
    (r, spots) = case n of
      2 -> (11, [ (30,22,green), (30,62,red) ])
      3 -> (10, [ (16,20,ink), (30,42,red), (44,64,green) ])
      4 -> (10, [ (19,23,ink), (41,23,green), (19,61,green), (41,61,ink) ])
      5 -> (9,  [ (17,21,ink), (43,21,green), (30,42,red)
                , (17,63,green), (43,63,ink) ])
      6 -> (8,  [ (19,18,green), (41,18,green)
                , (19,42,red), (41,42,red)
                , (19,66,red), (41,66,red) ])
      7 -> (7,  [ (14,14,green), (26,19,green), (38,24,green)
                , (19,48,red), (41,48,red), (19,68,red), (41,68,red) ])
      8 -> (7,  [ (19,14,ink), (41,14,ink), (19,33,ink), (41,33,ink)
                , (19,52,ink), (41,52,ink), (19,71,ink), (41,71,ink) ])
      _ -> (7,  [ (15,18,green), (30,18,green), (45,18,green)
                , (15,42,red), (30,42,red), (45,42,red)
                , (15,66,ink), (30,66,ink), (45,66,ink) ])
-----------------------------------------------------------------------------
-- * Sou (bamboo) faces
-----------------------------------------------------------------------------
stick :: Int -> Int -> MisoString -> View c model action
stick x y color = S.g_ []
  [ S.rect_
      [ SP.x_ (ms (x - 4)), SP.y_ (ms (y - 9))
      , w_ "8", h_ "18", SP.rx_ "3.2"
      , SP.fill_ color
      ]
  , S.rect_
      [ SP.x_ (ms (x - 4)), SP.y_ (ms (y - 2))
      , w_ "8", h_ "3"
      , SP.fill_ "#f6f1e2", SP.opacity_ "0.8"
      ]
  , S.circle_
      [ SP.cx_ (ms x), SP.cy_ (ms (y - 6)), SP.r_ "1.4"
      , SP.fill_ "#f6f1e2", SP.opacity_ "0.65"
      ]
  ]
-----------------------------------------------------------------------------
souFace :: Int -> [View c model action]
souFace 1 =
  -- a stylized bamboo shoot with two leaves
  [ S.rect_
      [ SP.x_ "27", SP.y_ "30", w_ "6", h_ "36"
      , SP.rx_ "2.6", SP.fill_ green ]
  , S.rect_ [ SP.x_ "26", SP.y_ "42", w_ "8", h_ "2.4"
            , SP.fill_ "#f6f1e2", SP.opacity_ "0.85" ]
  , S.rect_ [ SP.x_ "26", SP.y_ "54", w_ "8", h_ "2.4"
            , SP.fill_ "#f6f1e2", SP.opacity_ "0.85" ]
  , S.path_ [ SP.d_ "M30 30 Q16 18 7 25 Q15 34 30 33 Z", SP.fill_ green ]
  , S.path_ [ SP.d_ "M30 30 Q44 18 53 25 Q45 34 30 33 Z", SP.fill_ green ]
  , S.circle_ [ SP.cx_ "30", SP.cy_ "24", SP.r_ "4.5", SP.fill_ red ]
  ]
souFace n = [ stick x y c | (x, y, c) <- spots ]
  where
    spots = case n of
      2 -> [ (30,26,green), (30,58,green) ]
      3 -> [ (30,20,green), (19,60,green), (41,60,green) ]
      4 -> [ (19,22,green), (41,22,green), (19,62,green), (41,62,green) ]
      5 -> [ (17,20,green), (43,20,green), (30,42,red)
           , (17,64,green), (43,64,green) ]
      6 -> [ (14,24,green), (30,24,green), (46,24,green)
           , (14,60,green), (30,60,green), (46,60,green) ]
      7 -> [ (30,16,red)
           , (16,44,green), (30,44,green), (44,44,green)
           , (16,68,green), (30,68,green), (44,68,green) ]
      8 -> [ (16,20,green), (30,20,green), (44,20,green)
           , (23,42,red), (37,42,red)
           , (16,64,green), (30,64,green), (44,64,green) ]
      _ -> [ (15,20,red), (30,20,green), (45,20,ink)
           , (15,42,green), (30,42,red), (45,42,green)
           , (15,64,ink), (30,64,green), (45,64,red) ]
