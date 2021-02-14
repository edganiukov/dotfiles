import XMonad

import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks

import XMonad.Layout.NoBorders

import XMonad.Util.Run(spawnPipe)
import XMonad.Util.EZConfig(additionalKeys)

import System.IO

myWorkspaces = ["1","2","3","4","5","6","7","8","9"]

main = do
    xmproc <- spawnPipe "xmobar"
    xmonad $ docks defaultConfig
        { terminal   = myTerminal
        , layoutHook = avoidStruts . smartBorders  $  layoutHook defaultConfig
        , modMask    = mod4Mask
        , logHook    = dynamicLogWithPP xmobarPP
                        { ppOutput = hPutStrLn xmproc
                        , ppTitle = xmobarColor "green" "" . shorten 50
                        }
        , borderWidth = 4
        } `additionalKeys`
        [ ((mod4Mask .|. shiftMask, xK_r),      spawn "xmonad --restart")
        ]

