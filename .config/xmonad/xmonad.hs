import XMonad

import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.StatusBar
import XMonad.Hooks.StatusBar.PP

import XMonad.Layout.Magnifier
import XMonad.Layout.Renamed
import XMonad.Layout.ThreeColumns

import XMonad.Util.EZConfig
import XMonad.Util.Loggers
import XMonad.Util.SpawnOnce
import XMonad.Util.Ungrab

main :: IO ()
main =
    xmonad
        . ewmhFullscreen
        . ewmh
        . withEasySB
            (statusBarProp
                "xmobar ~/.config/xmonad/.xmobarrc"
                (pure myXmobarPP))
            defToggleStrutsKey
        $ myConfig

myConfig = def
    { terminal    = "urxvt"
    , modMask     = mod4Mask
    , borderWidth = 3
    , layoutHook  = myLayout
    , manageHook  = myManageHook
    , startupHook = myStartupHook
    }
    `additionalKeysP`
    [ ("M-S-z", spawn "xscreensaver-command -lock")
    , ("M-C-s", unGrab *> spawn "scrot -s")

    -- Terminal shortcuts
    , ("M-a <Return>", spawn "alacritty")
    , ("M-w <Return>", spawn "wezterm")
    , ("M-<Return>", spawn "urxvt")
    , ("M-x <Return>", spawn "xterm")
    ]

myLayout =
    tiled ||| Mirror tiled ||| Full ||| threeCol
  where
    threeCol = renamed [Replace "ThreeCol"] $ magnifiercz' 1.3 $ ThreeColMid nmaster delta ratio
    nmaster = 1
    ratio   = 1 / 2
    delta   = 3 / 100
    tiled = Tall nmaster delta ratio

myManageHook :: ManageHook
myManageHook = composeAll
    [ className =? "Gimp" --> doFloat
    , className =? "Texmacs" --> doFloat
    , isDialog --> doFloat
    ]

myStartupHook :: X ()
myStartupHook = do
    spawnOnce "xrdb -merge ~/.Xresources"
    spawnOnce "xsetroot -cursor_name left_ptr"
    spawnOnce "feh --bg-fill --no-fehbg ~/.wallpapers/bliss.jpg"
    spawnOnce "xscreensaver -no-splash"
    spawnOnce "command -v nm-applet >/dev/null && nm-applet --sm-disable" 
    spawnOnce "trayer --edge top --align right --SetDockType true --SetPartialStrut true --expand true --width 10 --transparent true --tint 0x5f5f5f --height 18"

myXmobarPP :: PP
myXmobarPP = def
    { ppSep             = magenta " • "
    , ppTitleSanitize   = xmobarStrip
    , ppCurrent         =
        wrap " " "" . xmobarBorder "Top" "#8be9fd" 2
    , ppHidden          = white . wrap " " ""
    , ppHiddenNoWindows = lowWhite . wrap " " ""
    , ppUrgent          =
        red . wrap (yellow "!") (yellow "!")
    , ppOrder           = \[ws, l, _, wins] -> [ws, l, wins]
    , ppExtras          =
        [logTitles formatFocused formatUnfocused]
    }
  where
    formatFocused =
        wrap (white "[") (white "]") . magenta . ppWindow

    formatUnfocused =
        wrap (lowWhite "[") (lowWhite "]") . blue . ppWindow

    ppWindow =
        xmobarRaw
        . (\w -> if null w then "untitled" else w)
        . shorten 30

    blue, lowWhite, magenta, red, white, yellow :: String -> String
    magenta  = xmobarColor "#ff79c6" ""
    blue     = xmobarColor "#bd93f9" ""
    white    = xmobarColor "#f8f8f2" ""
    yellow   = xmobarColor "#f1fa8c" ""
    red      = xmobarColor "#ff5555" ""
    lowWhite = xmobarColor "#bbbbbb" ""
