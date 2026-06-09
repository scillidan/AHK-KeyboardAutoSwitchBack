scriptDir := A_ScriptDir
iniPath := scriptDir . "\KeyboardAutoSwitchBack.ini"
trayIcon := scriptDir . "\assets\icon.ico"

if (!FileExist(iniPath)) {
    MsgBox, 0x10, Error, Configuration file not found:`n%iniPath%`n`nPlease ensure KeyboardAutoSwitchBack.ini exists in the same folder.
    ExitApp
}

IniRead, switchDelay, %iniPath%, General, SwitchDelay, 600
IniRead, targetLayout, %iniPath%, Layout, TargetLayout, 0x04090409
IniRead, checkInterval, %iniPath%, Options, CheckInterval, 200

EnvGet, envEditor, EDITOR
IniRead, scriptEditor, %iniPath%, AutoHotkey, ScriptEditor, __MISSING__
if (scriptEditor = "__MISSING__" || scriptEditor = "")
    scriptEditor := envEditor != "" ? envEditor : "notepad"

targetLayout := targetLayout + 0

layoutID := Format("{:08X}", targetLayout & 0xFFFF)
RegRead, layoutName, HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\%layoutID%, Layout Text
if (ErrorLevel || !layoutName)
    layoutName := targetLayout

startupDir := A_StartMenu . "\Programs\Startup"
shortcutPath := startupDir . "\Keyboard Auto Switch Back.lnk"
isStartup := FileExist(shortcutPath)

Menu, Tray, NoStandard
Menu, Tray, DeleteAll
if (isStartup) {
    Menu, Tray, Add, Start with Windows, ToggleStartup
    Menu, Tray, Check, Start with Windows
} else {
    Menu, Tray, Add, Start with Windows, ToggleStartup
}
Menu, Tray, Add, Edit Config, EditConfig
Menu, Tray, Add, Reload, ReloadApp
Menu, Tray, Add, Exit, ExitScript
Menu, Tray, Tip, Keyboard Auto Switch Back`nTarget keyboard: %layoutName%
Menu, Tray, Icon, %trayIcon%

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

EditConfig:
    global scriptEditor, iniPath
    Run, %scriptEditor% "%iniPath%"
return

ReloadApp:
    TrayTip, Keyboard Auto Switch Back, Config reloaded, 2, 1
    SetTimer, DoReload, -500
return

DoReload:
    Reload
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