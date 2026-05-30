; Automatically switch the keyboard layout to the one layout when a user activates a new window.
; Authors: perplexity.ai🧙‍♂️, GLM-5🧙‍♂️, scillidan🤡

scriptDir := A_ScriptDir
iniPath := scriptDir . "\keyboard_autoswitch.ini"

if (!FileExist(iniPath)) {
    MsgBox, 0x10, Error, Configuration file not found:`n%iniPath%`n`nPlease ensure keyboard_autoswitch.ini exists in the same folder.
    ExitApp
}

IniRead, switchDelay, %iniPath%, General, SwitchDelay, 600
IniRead, targetLayout, %iniPath%, Layout, TargetLayout, 0x04090409
IniRead, checkInterval, %iniPath%, Options, CheckInterval, 200

targetLayout := targetLayout + 0

startupDir := A_StartMenu . "\Programs\Startup"
shortcutPath := startupDir . "\keyboard_autoswitch.lnk"
isStartup := FileExist(shortcutPath)

Menu, Tray, NoStandard
Menu, Tray, DeleteAll

if (isStartup) {
    Menu, Tray, Add, Start with Windows, ToggleStartup
    Menu, Tray, Check, Start with Windows
} else {
    Menu, Tray, Add, Start with Windows, ToggleStartup
}

Menu, Tray, Add, Suspend Hotkeys, SuspendHotkeys
Menu, Tray, Add, Pause Script, PauseScript
Menu, Tray, Add, Exit, ExitScript
Menu, Tray, Tip, Keyboard Autoswitch`nTarget: EN-US

lastWinID := 0

#Persistent
SetTimer, CheckActiveWindow, %checkInterval%
return

ToggleStartup:
    global shortcutPath
    if (FileExist(shortcutPath)) {
        FileDelete, %shortcutPath%
        if !ErrorLevel {
            Menu, Tray, Uncheck, Start with Windows
        }
    } else {
        FileCreateShortcut, %A_ScriptFullPath%, %shortcutPath%, %A_ScriptDir%
        if !ErrorLevel {
            Menu, Tray, Check, Start with Windows
        }
    }
return

SuspendHotkeys:
    Suspend, Toggle
    if (A_IsSuspended) {
        Menu, Tray, Check, Suspend Hotkeys
    } else {
        Menu, Tray, Uncheck, Suspend Hotkeys
    }
return

PauseScript:
    Pause, Toggle
    if (A_IsPaused) {
        Menu, Tray, Check, Pause Script
    } else {
        Menu, Tray, Uncheck, Pause Script
    }
return

ExitScript:
    ExitApp
return

CheckActiveWindow:
    global lastWinID, switchDelay

    WinGet, thisID, ID, A
    if (thisID = "")
        return

    if (thisID != lastWinID) {
        lastWinID := thisID
        SetTimer, EnsureTargetLayout, % "-" . switchDelay
    }
return

EnsureTargetLayout:
    global lastWinID, targetLayout

    WinGet, curID, ID, A
    if (curID != lastWinID)
        return

    threadID := DllCall("GetWindowThreadProcessId", "UInt", curID, "UInt", 0)
    curLayout := DllCall("GetKeyboardLayout", "UInt", threadID, "UInt")

    langID := curLayout & 0xFFFF
    targetLangID := targetLayout & 0xFFFF

    if (langID != targetLangID) {
        PostMessage, 0x50, 0, targetLayout,, ahk_id %curID%
    }
return