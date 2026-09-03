-----------------------------------------------------------------------------
-- | The look of the table: deep felt, ivory tiles, gold accents, glass
-- panels, and springy transitions everywhere.
-----------------------------------------------------------------------------
module Styles (skin) where
-----------------------------------------------------------------------------
import           Miso ((=:))
import qualified Miso.CSS as CSS
import           Miso.CSS (StyleSheet, sheet_, selector_, keyframes_, from_, to_, at, pct)
import           Miso.String (MisoString)
-----------------------------------------------------------------------------
skin :: StyleSheet
skin = sheet_
  [ selector_ ":root"
      [ "--gold"      =: "#e8c96a"
      , "--gold-deep" =: "#c9a227"
      , "--felt"      =: "#11543f"
      , "--ht" =: "clamp(46px, 7.4vmin, 66px)"
      , "--rt" =: "clamp(20px, 3.4vmin, 30px)"
      , "--ot" =: "clamp(17px, 2.9vmin, 25px)"
      , "--mt" =: "clamp(17px, 2.9vmin, 25px)"
      , "--dt" =: "clamp(22px, 3.6vmin, 32px)"
      , "--wt" =: "clamp(30px, 5vmin, 44px)"
      , "--side" =: "min(96vmin, 860px, calc(100vh - var(--ht) * 1.55 - 84px), 100vw)"
      ]
  , selector_ "*" [ CSS.boxSizing "border-box" ]
  , selector_ "html, body"
      [ CSS.margin "0"
      , CSS.height "100%"
      , CSS.overflow "hidden"
      ]
  , selector_ "body"
      [ CSS.background feltBackground
      , "color" =: "#e9e4d6"
      , CSS.fontFamily "'Avenir Next', 'Segoe UI', system-ui, sans-serif"
      , CSS.userSelect "none"
      , "-webkit-tap-highlight-color" =: "transparent"
      ]
  -- top chrome ------------------------------------------------------------
  , selector_ ".topbar"
      [ CSS.position "fixed"
      , "inset" =: "0 0 auto 0"
      , CSS.display "flex"
      , CSS.alignItems "center"
      , CSS.justifyContent "space-between"
      , CSS.padding "10px 18px"
      , CSS.zIndex 20
      , CSS.pointerEvents "none"
      ]
  , selector_ ".topbar > *" [ CSS.pointerEvents "auto" ]
  , selector_ ".brand"
      [ CSS.fontWeight "800"
      , CSS.letterSpacing ".14em"
      , CSS.fontSize "15px"
      , "color" =: "var(--gold)"
      , CSS.textShadow "0 1px 10px rgba(0,0,0,.6)"
      ]
  , selector_ ".brand small"
      [ "color" =: "#9fb8a9"
      , CSS.fontWeight "500"
      , CSS.letterSpacing ".08em"
      ]
  , selector_ ".tbBtns" [ CSS.display "flex", CSS.gap "8px" ]
  , selector_ ".iconBtn"
      [ CSS.background "rgba(6,26,20,.55)"
      , CSS.border "1px solid rgba(255,255,255,.12)"
      , "color" =: "#e9e4d6"
      , CSS.borderRadius (CSS.px 999)
      , CSS.padding "7px 14px"
      , CSS.fontSize "13px"
      , CSS.letterSpacing ".06em"
      , CSS.cursor "pointer"
      , CSS.backdropFilter "blur(10px)"
      , CSS.transition "transform .15s ease, background .2s ease, border-color .2s ease"
      ]
  , selector_ ".iconBtn:hover"
      [ CSS.background "rgba(20,60,45,.75)"
      , "border-color" =: "rgba(232,201,106,.55)"
      , CSS.transform "translateY(-1px)"
      ]
  -- table geometry ---------------------------------------------------------
  , selector_ ".app"
      [ CSS.position "fixed"
      , "inset" =: "44px 0 calc(var(--ht) * 1.55 + 26px) 0"
      , CSS.display "flex"
      , CSS.alignItems "center"
      , CSS.justifyContent "center"
      ]
  , selector_ ".table"
      [ CSS.position "relative"
      , CSS.width "var(--side)"
      , CSS.height "var(--side)"
      ]
  , selector_ ".seat"
      [ CSS.position "absolute"
      , "inset" =: "0"
      , CSS.pointerEvents "none"
      ]
  , selector_ ".seat1" [ CSS.transform "rotate(-90deg)" ]
  , selector_ ".seat2" [ CSS.transform "rotate(180deg)" ]
  , selector_ ".seat3" [ CSS.transform "rotate(90deg)" ]
  -- tiles ------------------------------------------------------------------
  , selector_ ".tile"
      [ CSS.position "relative"
      , CSS.width "var(--rt)"
      , "aspect-ratio" =: "60 / 84"
      , CSS.background "linear-gradient(165deg, #fdfbf4 0%, #f4eddb 55%, #e9dfc4 100%)"
      , CSS.borderRadius "12% / 9%"
      , CSS.boxShadow tileShadow
      , "flex" =: "0 0 auto"
      ]
  , selector_ ".tile svg"
      [ CSS.position "absolute"
      , "inset" =: "5% 6%"
      , CSS.width "88%"
      , CSS.height "90%"
      ]
  , selector_ ".tile svg text"
      [ CSS.fontFamily "'Hiragino Mincho ProN', 'Yu Mincho', 'Noto Serif CJK JP', 'Noto Serif SC', serif"
      ]
  , selector_ ".tile.back"
      [ CSS.background "linear-gradient(165deg, #2fa273 0%, #187a52 55%, #0e5c3c 100%)"
      , CSS.boxShadow backShadow
      ]
  , selector_ ".tile.back::after"
      [ "content" =: "''"
      , CSS.position "absolute"
      , "inset" =: "14%"
      , CSS.borderRadius "14%"
      , CSS.border "1.5px solid rgba(255,255,255,.22)"
      ]
  -- rivers, opponent hands, melds -------------------------------------------
  , selector_ ".river"
      [ CSS.position "absolute"
      , CSS.top "58.5%"
      , CSS.left "50%"
      , CSS.transform "translateX(-50%)"
      , CSS.display "grid"
      , CSS.gridTemplateColumns "repeat(6, var(--rt))"
      , CSS.gap "4px"
      , CSS.width "calc(6 * var(--rt) + 20px)"
      ]
  , selector_ ".river .tile" [ CSS.animation "popIn .3s cubic-bezier(.2,.9,.3,1.3) backwards" ]
  , selector_ ".tile.hot"
      [ CSS.animation "hotPulse 1.1s ease-in-out infinite"
      , CSS.zIndex 5
      ]
  , selector_ ".oh"
      [ CSS.position "absolute"
      , CSS.bottom "1%"
      , CSS.left "50%"
      , CSS.transform "translateX(-50%)"
      , CSS.display "flex"
      , CSS.gap "3px"
      ]
  , selector_ ".oh .tile" [ CSS.width "var(--ot)" ]
  , selector_ ".meldRow"
      [ CSS.position "absolute"
      , CSS.bottom "1%"
      , CSS.right "1%"
      , CSS.display "flex"
      , CSS.gap "8px"
      ]
  , selector_ ".meld" [ CSS.display "flex", CSS.gap "2px" ]
  , selector_ ".meld .tile"
      [ CSS.width "var(--mt)"
      , CSS.animation "popIn .35s cubic-bezier(.2,.9,.3,1.3) backwards"
      ]
  -- center panel -------------------------------------------------------------
  , selector_ ".center"
      [ CSS.position "absolute"
      , CSS.left "50%"
      , CSS.top "50%"
      , CSS.transform "translate(-50%, -50%)"
      , CSS.width "37%"
      , CSS.height "37%"
      , CSS.borderRadius (CSS.px 18)
      , CSS.background "linear-gradient(160deg, rgba(6,30,22,.72), rgba(3,16,12,.78))"
      , CSS.border "1px solid rgba(255,255,255,.08)"
      , CSS.boxShadow "0 18px 50px rgba(0,0,0,.45), inset 0 1px 0 rgba(255,255,255,.08)"
      , CSS.backdropFilter "blur(12px)"
      , CSS.display "flex"
      , CSS.alignItems "center"
      , CSS.justifyContent "center"
      ]
  , selector_ ".centerInner"
      [ CSS.display "flex"
      , CSS.flexDirection "column"
      , CSS.alignItems "center"
      , CSS.justifyContent "space-between"
      , CSS.height "100%"
      , CSS.width "100%"
      , CSS.padding "14% 6%"
      ]
  , selector_ ".centerLow"
      [ CSS.display "flex"
      , CSS.flexDirection "column"
      , CSS.alignItems "center"
      , CSS.gap "clamp(2px, .8vmin, 8px)"
      ]
  , selector_ ".roundBadge"
      [ CSS.fontSize "clamp(15px, 2.6vmin, 24px)"
      , CSS.fontWeight "800"
      , CSS.letterSpacing ".2em"
      , "color" =: "var(--gold)"
      , CSS.textShadow "0 1px 12px rgba(0,0,0,.7)"
      ]
  , selector_ ".wallInfo"
      [ CSS.fontSize "clamp(10px, 1.7vmin, 13px)"
      , "color" =: "#9fb8a9"
      , CSS.letterSpacing ".12em"
      ]
  , selector_ ".doraBox"
      [ CSS.display "flex"
      , CSS.alignItems "center"
      , CSS.gap "8px"
      , CSS.marginTop "2px"
      ]
  , selector_ ".doraBox .tile" [ CSS.width "var(--dt)" ]
  , selector_ ".doraLabel"
      [ CSS.fontSize "clamp(10px, 1.7vmin, 13px)"
      , "color" =: "#9fb8a9"
      , CSS.letterSpacing ".2em"
      ]
  , selector_ ".scorePlate"
      [ CSS.position "absolute"
      , CSS.display "flex"
      , CSS.alignItems "center"
      , CSS.gap "5px"
      , CSS.padding "2px 8px"
      , CSS.borderRadius (CSS.px 999)
      , CSS.background "rgba(255,255,255,.05)"
      , CSS.border "1px solid transparent"
      , CSS.fontSize "clamp(10px, 1.9vmin, 14px)"
      , CSS.transition "background .3s ease, border-color .3s ease, box-shadow .3s ease"
      , CSS.whiteSpace "nowrap"
      ]
  , selector_ ".scorePlate.active"
      [ CSS.background "rgba(232,201,106,.14)"
      , "border-color" =: "rgba(232,201,106,.6)"
      , CSS.animation "glowPulse 1.6s ease-in-out infinite"
      ]
  , selector_ ".plate0" [ CSS.bottom "5px", CSS.left "50%", CSS.transform "translateX(-50%)" ]
  , selector_ ".plate1" [ CSS.right "5px", CSS.top "50%", CSS.transform "translateY(-50%)" ]
  , selector_ ".plate2" [ CSS.top "5px", CSS.left "50%", CSS.transform "translateX(-50%)" ]
  , selector_ ".plate3" [ CSS.left "5px", CSS.top "50%", CSS.transform "translateY(-50%)" ]
  , selector_ ".plateWind"
      [ CSS.fontWeight "800"
      , CSS.fontSize "clamp(12px, 2.2vmin, 17px)"
      , "color" =: "#cfe0d5"
      ]
  , selector_ ".plateWind.dealerWind" [ "color" =: "var(--gold)" ]
  , selector_ ".plateScore" [ "color" =: "#e9e4d6", "font-variant-numeric" =: "tabular-nums" ]
  -- human hand ----------------------------------------------------------------
  , selector_ ".hand"
      [ CSS.position "fixed"
      , CSS.bottom "max(12px, env(safe-area-inset-bottom))"
      , CSS.left "50%"
      , CSS.transform "translateX(-50%)"
      , CSS.display "flex"
      , CSS.alignItems "flex-end"
      , CSS.gap "clamp(3px, .7vmin, 7px)"
      , CSS.zIndex 15
      ]
  , selector_ ".hand .tile"
      [ CSS.width "var(--ht)"
      , CSS.transition "transform .18s cubic-bezier(.2,.9,.3,1.4), box-shadow .18s ease, filter .18s ease"
      ]
  , selector_ ".hand .tile.deal" [ CSS.animation "dealIn .5s cubic-bezier(.2,.9,.3,1.2) backwards" ]
  , selector_ ".hand .tile.live" [ CSS.cursor "pointer" ]
  , selector_ ".hand .tile.live:hover"
      [ CSS.transform "translateY(-12px)"
      , CSS.boxShadow hoverShadow
      , CSS.filter "brightness(1.05)"
      ]
  , selector_ ".hand .tile.drawnTile"
      [ CSS.marginLeft "clamp(10px, 2vmin, 22px)"
      , CSS.animation "drawnIn .35s cubic-bezier(.2,.9,.3,1.3)"
      , CSS.boxShadow drawnGlow
      ]
  , selector_ ".actionBar"
      [ CSS.position "fixed"
      , CSS.bottom "calc(var(--ht) * 1.55 + 34px)"
      , CSS.left "50%"
      , CSS.transform "translateX(-50%)"
      , CSS.display "flex"
      , CSS.gap "12px"
      , CSS.zIndex 25
      , CSS.animation "panelIn .3s cubic-bezier(.2,.9,.25,1.2) backwards"
      ]
  -- buttons -------------------------------------------------------------------
  , selector_ ".btn"
      [ CSS.padding "11px 26px"
      , CSS.borderRadius (CSS.px 999)
      , CSS.border "1px solid #f5e3a0"
      , CSS.background "linear-gradient(180deg, #f0d98c, #c9a227)"
      , "color" =: "#241a02"
      , CSS.fontWeight "800"
      , CSS.fontSize "15px"
      , CSS.letterSpacing ".14em"
      , CSS.cursor "pointer"
      , CSS.boxShadow "0 6px 18px rgba(0,0,0,.45), inset 0 1px 0 rgba(255,255,255,.6)"
      , CSS.transition "transform .15s ease, box-shadow .15s ease, filter .15s ease"
      ]
  , selector_ ".btn:hover"
      [ CSS.transform "translateY(-2px)"
      , CSS.boxShadow "0 10px 26px rgba(0,0,0,.5), inset 0 1px 0 rgba(255,255,255,.6)"
      , CSS.filter "brightness(1.07)"
      ]
  , selector_ ".btn:active" [ CSS.transform "translateY(0) scale(.98)" ]
  , selector_ ".btn.ghost"
      [ CSS.background "rgba(10,32,25,.6)"
      , "color" =: "#cfe0d5"
      , CSS.border "1px solid rgba(255,255,255,.2)"
      , CSS.backdropFilter "blur(8px)"
      ]
  , selector_ ".btn.ron" [ CSS.background "linear-gradient(180deg, #e46a6a, #a12626)", "color" =: "#fff", CSS.border "1px solid #ffb3b3" ]
  , selector_ ".btn.pon" [ CSS.background "linear-gradient(180deg, #6aa4e4, #2657a1)", "color" =: "#fff", CSS.border "1px solid #b3d0ff" ]
  , selector_ ".btn.chi" [ CSS.background "linear-gradient(180deg, #6fc794, #23784a)", "color" =: "#fff", CSS.border "1px solid #b9e8cb" ]
  , selector_ ".btn.kan" [ CSS.background "linear-gradient(180deg, #b98ae0, #6d3ba1)", "color" =: "#fff", CSS.border "1px solid #dcc3f5" ]
  -- claim bar -----------------------------------------------------------------
  , selector_ ".claimBar"
      [ CSS.position "fixed"
      , CSS.bottom "calc(var(--ht) * 1.55 + 34px)"
      , CSS.left "50%"
      , CSS.transform "translateX(-50%)"
      , CSS.display "flex"
      , CSS.alignItems "center"
      , CSS.gap "12px"
      , CSS.zIndex 30
      , CSS.padding "12px 16px"
      , CSS.borderRadius (CSS.px 18)
      , CSS.background "rgba(8,26,20,.7)"
      , CSS.border "1px solid rgba(232,201,106,.35)"
      , CSS.backdropFilter "blur(12px)"
      , CSS.boxShadow "0 18px 50px rgba(0,0,0,.5)"
      , CSS.animation "panelIn .28s cubic-bezier(.2,.9,.25,1.2) backwards"
      ]
  , selector_ ".chiTiles" [ CSS.display "flex", CSS.gap "2px", CSS.marginLeft "8px" ]
  , selector_ ".chiTiles .tile" [ CSS.width "26px" ]
  -- callouts ------------------------------------------------------------------
  , selector_ ".callout"
      [ CSS.position "absolute"
      , CSS.zIndex 40
      , CSS.fontSize "clamp(30px, 5.4vmin, 48px)"
      , CSS.fontWeight "900"
      , CSS.letterSpacing ".12em"
      , "color" =: "#ffdf80"
      , CSS.textShadow "0 3px 20px rgba(0,0,0,.85), 0 0 34px rgba(255,200,60,.5)"
      , CSS.animation "calloutAnim 1.5s ease forwards"
      , CSS.pointerEvents "none"
      ]
  -- identical twin animation so toggling the class replays the callout
  -- (positioning avoids transform: the animation keyframes own that property)
  , selector_ ".callout.alt" [ "animation-name" =: "calloutAnim2" ]
  , selector_ ".callout.c0"
      [ CSS.bottom "15%", CSS.left "0", CSS.right "0", CSS.textAlign "center" ]
  , selector_ ".callout.c1"
      [ CSS.right "12%", CSS.top "0", CSS.bottom "0"
      , CSS.display "flex", CSS.alignItems "center" ]
  , selector_ ".callout.c2"
      [ CSS.top "15%", CSS.left "0", CSS.right "0", CSS.textAlign "center" ]
  , selector_ ".callout.c3"
      [ CSS.left "12%", CSS.top "0", CSS.bottom "0"
      , CSS.display "flex", CSS.alignItems "center" ]
  -- overlays ------------------------------------------------------------------
  , selector_ ".overlay"
      [ CSS.position "fixed"
      , "inset" =: "0"
      , CSS.display "flex"
      , CSS.alignItems "center"
      , CSS.justifyContent "center"
      , CSS.background "rgba(2,10,8,.6)"
      , CSS.backdropFilter "blur(7px)"
      , CSS.zIndex 50
      , CSS.animation "overlayIn .25s ease"
      ]
  , selector_ ".panel"
      [ CSS.background "linear-gradient(165deg, rgba(14,40,31,.92), rgba(6,20,15,.95))"
      , CSS.border "1px solid rgba(232,201,106,.4)"
      , CSS.borderRadius (CSS.px 22)
      , CSS.padding "30px 40px"
      , CSS.boxShadow "0 40px 100px rgba(0,0,0,.65), inset 0 1px 0 rgba(255,255,255,.1)"
      , CSS.textAlign "center"
      , CSS.animation "panelIn .4s cubic-bezier(.2,.9,.25,1.2) backwards"
      , CSS.maxWidth "min(92vw, 640px)"
      ]
  , selector_ ".winTitle"
      [ CSS.fontSize "clamp(26px, 5vmin, 40px)"
      , CSS.fontWeight "900"
      , CSS.letterSpacing ".22em"
      , "color" =: "var(--gold)"
      , CSS.textShadow "0 2px 22px rgba(0,0,0,.8)"
      , CSS.marginBottom "6px"
      ]
  , selector_ ".winSub"
      [ "color" =: "#9fb8a9"
      , CSS.letterSpacing ".1em"
      , CSS.fontSize "14px"
      , CSS.marginBottom "16px"
      ]
  , selector_ ".winTiles"
      [ CSS.display "flex"
      , CSS.justifyContent "center"
      , CSS.flexWrap "wrap"
      , CSS.gap "4px"
      , CSS.marginBottom "16px"
      ]
  , selector_ ".winTiles .tile"
      [ CSS.width "var(--wt)"
      , CSS.animation "flipIn .45s cubic-bezier(.2,.9,.3,1.2) backwards"
      ]
  , selector_ ".winTiles .tile.winning"
      [ CSS.boxShadow drawnGlow ]
  , selector_ ".yakuList"
      [ CSS.display "flex"
      , CSS.flexDirection "column"
      , CSS.gap "4px"
      , CSS.marginBottom "14px"
      ]
  , selector_ ".yakuRow"
      [ CSS.display "flex"
      , CSS.justifyContent "space-between"
      , CSS.gap "40px"
      , CSS.fontSize "15px"
      , "color" =: "#dfe8e0"
      , CSS.animation "riseIn .4s ease backwards"
      ]
  , selector_ ".yakuRow b" [ "color" =: "var(--gold)" ]
  , selector_ ".points"
      [ CSS.fontSize "clamp(24px, 4.6vmin, 36px)"
      , CSS.fontWeight "900"
      , "color" =: "#fff"
      , CSS.textShadow "0 0 26px rgba(232,201,106,.6)"
      , CSS.marginBottom "18px"
      , "font-variant-numeric" =: "tabular-nums"
      , CSS.animation "riseIn .4s ease backwards"
      ]
  , selector_ ".rankRow"
      [ CSS.display "flex"
      , CSS.justifyContent "space-between"
      , CSS.gap "60px"
      , CSS.padding "8px 4px"
      , CSS.fontSize "17px"
      , CSS.borderBottom "1px solid rgba(255,255,255,.08)"
      , CSS.animation "riseIn .4s ease backwards"
      ]
  , selector_ ".rankRow.human b" [ "color" =: "var(--gold)" ]
  -- title screen ---------------------------------------------------------------
  , selector_ ".titleWrap"
      [ CSS.position "fixed"
      , "inset" =: "0"
      , CSS.display "flex"
      , CSS.flexDirection "column"
      , CSS.alignItems "center"
      , CSS.justifyContent "center"
      , CSS.gap "10px"
      , CSS.zIndex 60
      , CSS.background feltBackground
      , CSS.overflow "hidden"
      ]
  , selector_ ".floatTile"
      [ CSS.position "absolute"
      , CSS.width "clamp(44px, 6vmin, 62px)"
      , CSS.opacity 0.55
      , CSS.animation "floaty 7s ease-in-out infinite"
      , CSS.pointerEvents "none"
      ]
  , selector_ ".titleH"
      [ CSS.fontSize "clamp(52px, 12vmin, 110px)"
      , CSS.fontWeight "900"
      , CSS.fontFamily "'Hiragino Mincho ProN', 'Yu Mincho', 'Noto Serif CJK JP', serif"
      , CSS.background "linear-gradient(180deg, #f7e7b0 10%, #e8c96a 45%, #a97d15 90%)"
      , "-webkit-background-clip" =: "text"
      , CSS.backgroundClip "text"
      , "color" =: "transparent"
      , CSS.textShadow "0 20px 60px rgba(0,0,0,.55)"
      , CSS.margin "0"
      , CSS.animation "riseIn .7s cubic-bezier(.2,.9,.25,1.2) backwards"
      ]
  , selector_ ".titleSub"
      [ CSS.letterSpacing ".5em"
      , "color" =: "#9fb8a9"
      , CSS.fontSize "clamp(12px, 2vmin, 16px)"
      , CSS.marginBottom "26px"
      , CSS.animation "riseIn .7s .15s cubic-bezier(.2,.9,.25,1.2) backwards"
      ]
  , selector_ ".startBtn"
      [ CSS.fontSize "17px"
      , CSS.padding "14px 46px"
      , CSS.animation "riseIn .7s .3s cubic-bezier(.2,.9,.25,1.2) backwards"
      ]
  , selector_ ".titleHint"
      [ CSS.marginTop "22px"
      , "color" =: "#7f9a8c"
      , CSS.fontSize "12px"
      , CSS.letterSpacing ".14em"
      , CSS.animation "riseIn .7s .45s ease backwards"
      ]
  -- keyframes ------------------------------------------------------------------
  , keyframes_ "dealIn"
      [ from_ [ CSS.transform "translateY(46px) rotate(5deg) scale(.7)", CSS.opacity 0 ]
      , to_   [ CSS.transform "translateY(0) rotate(0) scale(1)", CSS.opacity 1 ]
      ]
  , keyframes_ "popIn"
      [ from_ [ CSS.transform "scale(.4) translateY(-12px)", CSS.opacity 0 ]
      , at (pct 65) [ CSS.transform "scale(1.07)", CSS.opacity 1 ]
      , to_ [ CSS.transform "scale(1) translateY(0)", CSS.opacity 1 ]
      ]
  , keyframes_ "drawnIn"
      [ from_ [ CSS.transform "translateY(-26px) scale(.85)", CSS.opacity 0 ]
      , to_   [ CSS.transform "translateY(0) scale(1)", CSS.opacity 1 ]
      ]
  , keyframes_ "calloutAnim"
      [ from_ [ CSS.transform "scale(.2)", CSS.opacity 0 ]
      , at (pct 14) [ CSS.transform "scale(1.18)", CSS.opacity 1 ]
      , at (pct 24) [ CSS.transform "scale(1)" ]
      , at (pct 75) [ CSS.opacity 1 ]
      , to_ [ CSS.opacity 0, CSS.transform "translateY(-14px)" ]
      ]
  , keyframes_ "calloutAnim2"
      [ from_ [ CSS.transform "scale(.2)", CSS.opacity 0 ]
      , at (pct 14) [ CSS.transform "scale(1.18)", CSS.opacity 1 ]
      , at (pct 24) [ CSS.transform "scale(1)" ]
      , at (pct 75) [ CSS.opacity 1 ]
      , to_ [ CSS.opacity 0, CSS.transform "translateY(-14px)" ]
      ]
  , keyframes_ "glowPulse"
      [ from_ [ CSS.boxShadow "0 0 0 rgba(232,201,106,0)" ]
      , at (pct 50) [ CSS.boxShadow "0 0 18px rgba(232,201,106,.55)" ]
      , to_ [ CSS.boxShadow "0 0 0 rgba(232,201,106,0)" ]
      ]
  , keyframes_ "hotPulse"
      [ from_ [ CSS.boxShadow "0 0 0 2px rgba(232,201,106,.9), 0 4px 10px rgba(0,0,0,.45)" ]
      , at (pct 50) [ CSS.boxShadow "0 0 16px 4px rgba(232,201,106,.6), 0 4px 10px rgba(0,0,0,.45)" ]
      , to_ [ CSS.boxShadow "0 0 0 2px rgba(232,201,106,.9), 0 4px 10px rgba(0,0,0,.45)" ]
      ]
  , keyframes_ "overlayIn"
      [ from_ [ CSS.opacity 0 ], to_ [ CSS.opacity 1 ] ]
  , keyframes_ "panelIn"
      [ from_ [ CSS.transform "translateY(26px) scale(.92)", CSS.opacity 0 ]
      , to_   [ CSS.transform "translateY(0) scale(1)", CSS.opacity 1 ]
      ]
  , keyframes_ "flipIn"
      [ from_ [ CSS.transform "rotateY(90deg) scale(.8)", CSS.opacity 0 ]
      , to_   [ CSS.transform "rotateY(0) scale(1)", CSS.opacity 1 ]
      ]
  , keyframes_ "riseIn"
      [ from_ [ CSS.transform "translateY(18px)", CSS.opacity 0 ]
      , to_   [ CSS.transform "translateY(0)", CSS.opacity 1 ]
      ]
  , keyframes_ "floaty"
      [ from_ [ CSS.transform "translateY(0) rotate(var(--fr, 0deg))" ]
      , at (pct 50) [ CSS.transform "translateY(-18px) rotate(var(--fr, 0deg))" ]
      , to_ [ CSS.transform "translateY(0) rotate(var(--fr, 0deg))" ]
      ]
  ]
-----------------------------------------------------------------------------
feltBackground :: MisoString
feltBackground = mconcat
  [ "radial-gradient(120% 90% at 50% 12%, rgba(255,255,255,.07), rgba(0,0,0,0) 55%), "
  , "radial-gradient(140% 120% at 50% 50%, #17604a 0%, #0f4736 48%, #082b20 100%)"
  ]
-----------------------------------------------------------------------------
tileShadow :: MisoString
tileShadow = "0 2px 0 #c9bc9c, 0 5px 12px rgba(0,0,0,.5), inset 0 1px 1px rgba(255,255,255,.9)"
-----------------------------------------------------------------------------
backShadow :: MisoString
backShadow = "0 2px 0 #0a3f2a, 0 5px 12px rgba(0,0,0,.5), inset 0 1px 1px rgba(255,255,255,.25)"
-----------------------------------------------------------------------------
hoverShadow :: MisoString
hoverShadow = "0 2px 0 #c9bc9c, 0 14px 26px rgba(0,0,0,.55), inset 0 1px 1px rgba(255,255,255,.9)"
-----------------------------------------------------------------------------
drawnGlow :: MisoString
drawnGlow = "0 2px 0 #c9bc9c, 0 5px 12px rgba(0,0,0,.5), 0 0 18px rgba(232,201,106,.75), inset 0 1px 1px rgba(255,255,255,.9)"
