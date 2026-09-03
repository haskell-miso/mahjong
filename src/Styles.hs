-----------------------------------------------------------------------------
-- | The look of the board: deep felt, chunky 3D ivory tiles, gold
-- accents, glass panels, and springy transitions everywhere.
-----------------------------------------------------------------------------
module Styles (skin) where
-----------------------------------------------------------------------------
import           Miso ((=:))
import qualified Miso.CSS as CSS
import           Miso.CSS
  ( StyleSheet, sheet_, selector_, keyframes_, from_, to_, at, pct
  , media_, rule_, screen_, and_, maxWidth_, maxHeight_, px
  )
import           Miso.CSS.Types (MediaQuery(..))
import           Miso.String (MisoString)
-----------------------------------------------------------------------------
skin :: StyleSheet
skin = sheet_
  [ selector_ ":root"
      [ "--gold"      =: "#e8c96a"
      , "--gold-deep" =: "#c9a227"
      , "--st"  =: "min(56px, calc((100vw - 48px) / 15.6), calc((100dvh - 170px) / 11.9))"
      , "--sth" =: "calc(var(--st) * 1.36)"
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
      , "-webkit-text-size-adjust" =: "100%"
      , "overscroll-behavior" =: "none"
      ]
  -- top chrome ------------------------------------------------------------
  , selector_ ".topbar"
      [ CSS.position "fixed"
      , "inset" =: "0 0 auto 0"
      , CSS.display "flex"
      , CSS.alignItems "center"
      , CSS.justifyContent "space-between"
      , CSS.padding "10px 18px"
      , CSS.zIndex 90
      , CSS.pointerEvents "none"
      , CSS.gap "12px"
      ]
  , selector_ ".topbar > *" [ CSS.pointerEvents "auto" ]
  , selector_ ".brand"
      [ CSS.fontWeight "800"
      , CSS.letterSpacing ".14em"
      , CSS.fontSize "15px"
      , "color" =: "var(--gold)"
      , CSS.textShadow "0 1px 10px rgba(0,0,0,.6)"
      , CSS.whiteSpace "nowrap"
      ]
  , selector_ ".brand small"
      [ "color" =: "#9fb8a9"
      , CSS.fontWeight "500"
      , CSS.letterSpacing ".08em"
      ]
  , selector_ ".hudStats"
      [ CSS.display "flex"
      , CSS.gap "clamp(8px, 2vw, 26px)"
      , CSS.alignItems "center"
      , CSS.fontSize "13px"
      , CSS.letterSpacing ".1em"
      , "color" =: "#9fb8a9"
      , CSS.whiteSpace "nowrap"
      ]
  , selector_ ".hudStats b"
      [ "color" =: "#e9e4d6"
      , "font-variant-numeric" =: "tabular-nums"
      , CSS.fontWeight "700"
      ]
  , selector_ ".tbBtns" [ CSS.display "flex", CSS.gap "8px", CSS.flexWrap "wrap", CSS.justifyContent "flex-end" ]
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
      , CSS.whiteSpace "nowrap"
      , "touch-action" =: "manipulation"
      ]
  -- board ------------------------------------------------------------------
  , selector_ ".boardWrap"
      [ CSS.position "fixed"
      , "inset" =: "56px 0 12px 0"
      , CSS.display "flex"
      , CSS.alignItems "center"
      , CSS.justifyContent "center"
      ]
  , selector_ ".board"
      [ CSS.position "relative"
      , CSS.width "calc(var(--st) * 15 + 30px)"
      , CSS.height "calc(var(--sth) * 8 + 36px)"
      ]
  -- tiles ------------------------------------------------------------------
  , selector_ ".tile"
      [ CSS.position "relative"
      , CSS.width "var(--st)"
      , "aspect-ratio" =: "60 / 84"
      , CSS.background tileFaceBg
      , CSS.borderRadius "10% / 7.5%"
      , CSS.boxShadow flatShadow
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
  , selector_ ".stile"
      [ CSS.position "absolute"
      , CSS.width "var(--st)"
      , CSS.height "var(--sth)"
      , "aspect-ratio" =: "auto"
      , CSS.boxShadow sideStack
      , CSS.animation "popIn .35s cubic-bezier(.2,.9,.3,1.3) backwards"
      , CSS.transition "filter .25s ease, box-shadow .15s ease"
      , "touch-action" =: "manipulation"
      ]
  , selector_ ".stile.free" [ CSS.cursor "pointer" ]
  , selector_ ".stile.locked"
      [ CSS.filter "brightness(.78) saturate(.92)" ]
  , selector_ ".stile.sel"
      [ CSS.filter "brightness(1.12)"
      , CSS.boxShadow (sideStack <> ", 0 0 0 3px var(--gold), 0 0 22px rgba(232,201,106,.8)")
      ]
  , selector_ ".stile.hintT" [ "animation" =: "hintA 1s ease-in-out infinite" ]
  , selector_ ".stile.hintT.alt" [ "animation-name" =: "hintA2" ]
  , selector_ ".stile.shakeT" [ "animation" =: "shakeA .4s ease" ]
  , selector_ ".stile.shakeT.alt" [ "animation-name" =: "shakeA2" ]
  , selector_ ".stile.vanish"
      [ "animation" =: "vanishA .45s ease forwards"
      , CSS.pointerEvents "none"
      ]
  -- buttons -----------------------------------------------------------------
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
      , "touch-action" =: "manipulation"
      ]
  , selector_ ".btn:active" [ CSS.transform "translateY(0) scale(.98)" ]
  -- hover effects only on devices that actually hover (no sticky
  -- highlights after taps on touch screens)
  , media_ (MediaQuery "(hover: hover)")
      [ rule_ ".iconBtn:hover"
          [ CSS.background "rgba(20,60,45,.75)"
          , "border-color" =: "rgba(232,201,106,.55)"
          , CSS.transform "translateY(-1px)"
          ]
      , rule_ ".btn:hover"
          [ CSS.transform "translateY(-2px)"
          , CSS.boxShadow "0 10px 26px rgba(0,0,0,.5), inset 0 1px 0 rgba(255,255,255,.6)"
          , CSS.filter "brightness(1.07)"
          ]
      , rule_ ".stile.free:hover"
          [ CSS.filter "brightness(1.08)"
          , CSS.boxShadow (sideStack <> ", 0 0 14px rgba(232,201,106,.35)")
          ]
      ]
  , selector_ ".btn.ghost"
      [ CSS.background "rgba(10,32,25,.6)"
      , "color" =: "#cfe0d5"
      , CSS.border "1px solid rgba(255,255,255,.2)"
      , CSS.backdropFilter "blur(8px)"
      ]
  -- stuck toast ---------------------------------------------------------------
  , selector_ ".toastBar"
      [ CSS.position "fixed"
      , CSS.bottom "26px"
      , CSS.left "50%"
      , CSS.transform "translateX(-50%)"
      , CSS.display "flex"
      , CSS.alignItems "center"
      , CSS.gap "14px"
      , CSS.zIndex 60
      , CSS.padding "12px 18px"
      , CSS.borderRadius (CSS.px 18)
      , CSS.background "rgba(8,26,20,.8)"
      , CSS.border "1px solid rgba(232,201,106,.4)"
      , CSS.backdropFilter "blur(12px)"
      , CSS.boxShadow "0 18px 50px rgba(0,0,0,.5)"
      , CSS.animation "panelIn .28s cubic-bezier(.2,.9,.25,1.2) backwards"
      ]
  , selector_ ".toastMsg"
      [ CSS.letterSpacing ".08em"
      , "color" =: "#f0e6c8"
      , CSS.fontWeight "600"
      ]
  -- overlays ------------------------------------------------------------------
  , selector_ ".overlay"
      [ CSS.position "fixed"
      , "inset" =: "0"
      , CSS.display "flex"
      , CSS.alignItems "center"
      , CSS.justifyContent "center"
      , CSS.background "rgba(2,10,8,.6)"
      , CSS.backdropFilter "blur(7px)"
      , CSS.zIndex 100
      , CSS.animation "overlayIn .25s ease"
      ]
  , selector_ ".panel"
      [ CSS.background "linear-gradient(165deg, rgba(14,40,31,.92), rgba(6,20,15,.95))"
      , CSS.border "1px solid rgba(232,201,106,.4)"
      , CSS.borderRadius (CSS.px 22)
      , CSS.padding "30px 44px"
      , CSS.boxShadow "0 40px 100px rgba(0,0,0,.65), inset 0 1px 0 rgba(255,255,255,.1)"
      , CSS.textAlign "center"
      , CSS.animation "panelIn .4s cubic-bezier(.2,.9,.25,1.2) backwards"
      , CSS.maxWidth "min(92vw, 560px)"
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
      , CSS.marginBottom "18px"
      ]
  , selector_ ".statRow"
      [ CSS.display "flex"
      , CSS.justifyContent "space-between"
      , CSS.gap "60px"
      , CSS.padding "8px 4px"
      , CSS.fontSize "16px"
      , CSS.borderBottom "1px solid rgba(255,255,255,.08)"
      , CSS.animation "riseIn .4s ease backwards"
      ]
  , selector_ ".statRow b" [ "color" =: "var(--gold)", "font-variant-numeric" =: "tabular-nums" ]
  , selector_ ".panel .btn" [ CSS.marginTop "22px" ]
  -- how-to-play modal ---------------------------------------------------------
  , selector_ ".overlay.help"
      [ CSS.zIndex 120
      , CSS.alignItems "flex-start"
      , CSS.padding "min(7vh, 60px) 14px 14px"
      ]
  , selector_ ".helpPanel"
      [ CSS.textAlign "left"
      , CSS.maxWidth "min(94vw, 640px)"
      , CSS.maxHeight "min(86dvh, 780px)"
      , CSS.overflowY "auto"
      , CSS.position "relative"
      , CSS.padding "26px 34px 28px"
      , CSS.animation "dropIn .45s cubic-bezier(.2,.9,.25,1.15) backwards"
      , "overscroll-behavior" =: "contain"
      , "scrollbar-width" =: "thin"
      , "scrollbar-color" =: "rgba(232,201,106,.4) transparent"
      ]
  , selector_ ".helpPanel::-webkit-scrollbar" [ CSS.width "8px" ]
  , selector_ ".helpPanel::-webkit-scrollbar-thumb"
      [ CSS.background "rgba(232,201,106,.35)"
      , CSS.borderRadius (CSS.px 8)
      ]
  , selector_ ".helpPanel::-webkit-scrollbar-track" [ CSS.background "transparent" ]
  , selector_ ".helpClose"
      [ CSS.position "absolute"
      , CSS.top "10px"
      , CSS.right "14px"
      , CSS.background "none"
      , CSS.border "none"
      , "color" =: "#9fb8a9"
      , CSS.fontSize "22px"
      , CSS.cursor "pointer"
      , CSS.padding "6px 8px"
      , CSS.transition "color .15s ease, transform .15s ease"
      ]
  , selector_ ".helpClose:hover"
      [ "color" =: "var(--gold)", CSS.transform "scale(1.15)" ]
  , selector_ ".helpH"
      [ CSS.fontSize "22px"
      , CSS.fontWeight "900"
      , CSS.letterSpacing ".2em"
      , "color" =: "var(--gold)"
      , CSS.margin "0 0 2px"
      ]
  , selector_ ".helpSub"
      [ "color" =: "#9fb8a9"
      , CSS.fontSize "13px"
      , CSS.letterSpacing ".1em"
      , CSS.marginBottom "10px"
      ]
  , selector_ ".helpSec"
      [ "color" =: "var(--gold)"
      , CSS.fontSize "12px"
      , CSS.fontWeight "800"
      , CSS.letterSpacing ".24em"
      , CSS.margin "18px 0 4px"
      ]
  , selector_ ".helpP"
      [ "color" =: "#dfe8e0"
      , CSS.fontSize "14px"
      , CSS.lineHeight "1.6"
      , CSS.margin "4px 0"
      ]
  , selector_ ".helpRow"
      [ CSS.display "flex"
      , CSS.alignItems "center"
      , CSS.gap "10px"
      , CSS.margin "9px 0"
      ]
  , selector_ ".helpRow .tile" [ CSS.width "32px" ]
  , selector_ ".helpCap"
      [ "color" =: "#cfe0d5", CSS.fontSize "13.5px" ]
  , selector_ ".mark" [ CSS.fontWeight "900", CSS.fontSize "18px" ]
  , selector_ ".mark.ok" [ "color" =: "#7fd49a" ]
  , selector_ ".mark.no" [ "color" =: "#e46a6a" ]
  , selector_ ".famStrip"
      [ CSS.display "flex"
      , CSS.gap "12px"
      , CSS.flexWrap "wrap"
      , CSS.marginTop "8px"
      ]
  , selector_ ".fam"
      [ CSS.display "flex"
      , CSS.flexDirection "column"
      , CSS.alignItems "center"
      , CSS.gap "5px"
      , CSS.fontSize "10px"
      , CSS.letterSpacing ".06em"
      , "color" =: "#9fb8a9"
      ]
  , selector_ ".fam .tile" [ CSS.width "30px" ]
  , selector_ ".howBtn"
      [ CSS.fontSize "13px"
      , CSS.padding "10px 30px"
      , CSS.marginTop "10px"
      , CSS.animation "riseIn .7s .4s cubic-bezier(.2,.9,.25,1.2) backwards"
      ]
  -- title screen ---------------------------------------------------------------
  , selector_ ".titleWrap"
      [ CSS.position "fixed"
      , "inset" =: "0"
      , CSS.display "flex"
      , CSS.flexDirection "column"
      , CSS.alignItems "center"
      , CSS.justifyContent "center"
      , CSS.gap "10px"
      , CSS.zIndex 110
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
  -- responsive ----------------------------------------------------------------
  -- compact phones: two-row chrome, icon-only buttons, tighter board margins
  , media_ (screen_ `and_` maxWidth_ (px 740))
      [ rule_ ":root"
          [ "--st" =: "min(56px, calc((100vw - 10px) / 15.4), calc((100dvh - 128px) / 12.1))" ]
      , rule_ ".topbar"
          [ CSS.flexWrap "wrap"
          , CSS.padding "6px 8px"
          , CSS.justifyContent "center"
          , "row-gap" =: "4px"
          , CSS.gap "8px"
          ]
      , rule_ ".btnLabel" [ CSS.display "none" ]
      , rule_ ".iconBtn" [ CSS.padding "7px 11px", CSS.fontSize "15px" ]
      , rule_ ".hudStats" [ CSS.fontSize "12px" ]
      , rule_ ".boardWrap" [ "inset" =: "86px 0 6px 0" ]
      , rule_ ".board"
          [ CSS.width "calc(var(--st) * 15 + 8px)"
          , CSS.height "calc(var(--sth) * 8 + 34px)"
          ]
      , rule_ ".panel" [ CSS.padding "22px 26px" ]
      , rule_ ".helpPanel" [ CSS.padding "18px 18px 20px" ]
      , rule_ ".overlay.help" [ CSS.padding "10px 8px 8px" ]
      , rule_ ".statRow" [ CSS.gap "30px" ]
      , rule_ ".toastBar" [ CSS.flexWrap "wrap", CSS.justifyContent "center", CSS.maxWidth "94vw" ]
      ]
  , media_ (screen_ `and_` maxWidth_ (px 480))
      [ rule_ ".brand" [ CSS.display "none" ]
      ]
  -- short landscape phones: single slim row, board gets the height back
  , media_ (screen_ `and_` maxHeight_ (px 520))
      [ rule_ ":root"
          [ "--st" =: "min(56px, calc((100vw - 10px) / 15.4), calc((100dvh - 70px) / 12.1))" ]
      , rule_ ".topbar" [ CSS.padding "4px 8px" ]
      , rule_ ".btnLabel" [ CSS.display "none" ]
      , rule_ ".brand" [ CSS.display "none" ]
      , rule_ ".boardWrap" [ "inset" =: "44px 0 4px 0" ]
      , rule_ ".board"
          [ CSS.width "calc(var(--st) * 15 + 8px)"
          , CSS.height "calc(var(--sth) * 8 + 34px)"
          ]
      ]
  -- keyframes ------------------------------------------------------------------
  , keyframes_ "popIn"
      [ from_ [ CSS.transform "scale(.4) translateY(-12px)", CSS.opacity 0 ]
      , at (pct 65) [ CSS.transform "scale(1.07)", CSS.opacity 1 ]
      , to_ [ CSS.transform "scale(1) translateY(0)", CSS.opacity 1 ]
      ]
  , keyframes_ "vanishA"
      [ from_ [ CSS.transform "scale(1)", CSS.opacity 1 ]
      , to_   [ CSS.transform "scale(1.3) translateY(-30px)", CSS.opacity 0 ]
      ]
  , keyframes_ "shakeA" shakeStops
  , keyframes_ "shakeA2" shakeStops
  , keyframes_ "hintA" (hintStops sideStack)
  , keyframes_ "hintA2" (hintStops sideStack)
  , keyframes_ "overlayIn"
      [ from_ [ CSS.opacity 0 ], to_ [ CSS.opacity 1 ] ]
  , keyframes_ "panelIn"
      [ from_ [ CSS.transform "translateY(26px) scale(.92)", CSS.opacity 0 ]
      , to_   [ CSS.transform "translateY(0) scale(1)", CSS.opacity 1 ]
      ]
  , keyframes_ "dropIn"
      [ from_ [ CSS.transform "translateY(-52px) scale(.97)", CSS.opacity 0 ]
      , to_   [ CSS.transform "translateY(0) scale(1)", CSS.opacity 1 ]
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
  where
    shakeStops =
      [ from_ [ CSS.transform "translateX(0)" ]
      , at (pct 20) [ CSS.transform "translateX(-6px)" ]
      , at (pct 40) [ CSS.transform "translateX(5px)" ]
      , at (pct 60) [ CSS.transform "translateX(-4px)" ]
      , at (pct 80) [ CSS.transform "translateX(3px)" ]
      , to_ [ CSS.transform "translateX(0)" ]
      ]
    hintStops stack =
      [ from_ [ CSS.boxShadow stack ]
      , at (pct 50)
          [ CSS.boxShadow (stack <> ", 0 0 0 3px rgba(232,201,106,.9), 0 0 24px 6px rgba(232,201,106,.6)")
          , CSS.filter "brightness(1.12)"
          ]
      , to_ [ CSS.boxShadow stack ]
      ]
-----------------------------------------------------------------------------
feltBackground :: MisoString
feltBackground = mconcat
  [ "radial-gradient(120% 90% at 50% 12%, rgba(255,255,255,.07), rgba(0,0,0,0) 55%), "
  , "radial-gradient(140% 120% at 50% 50%, #17604a 0%, #0f4736 48%, #082b20 100%)"
  ]
-----------------------------------------------------------------------------
tileFaceBg :: MisoString
tileFaceBg = "linear-gradient(165deg, #fdfbf4 0%, #f4eddb 55%, #e9dfc4 100%)"
-----------------------------------------------------------------------------
-- | Flat shadow for decorative tiles (title screen).
flatShadow :: MisoString
flatShadow = "0 2px 0 #c9bc9c, 0 5px 12px rgba(0,0,0,.5), inset 0 1px 1px rgba(255,255,255,.9)"
-----------------------------------------------------------------------------
-- | Chunky 3D side for board tiles: ridge to the bottom-left plus a soft
-- drop shadow, so stacked layers read as depth.
sideStack :: MisoString
sideStack = mconcat
  [ "-1px 1px 0 #d3c6a5, -2px 2px 0 #cbbc97, -3px 3px 0 #c3b189, "
  , "-4px 4px 0 #baa77c, -5px 5px 0 #b09b6e, "
  , "-8px 10px 18px rgba(0,0,0,.55), "
  , "inset 0 1px 1px rgba(255,255,255,.9)"
  ]
