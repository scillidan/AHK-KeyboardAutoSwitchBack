set shell := ["pwsh", "-NoLogo", "-Command"]

dist:
	Ahk2Exe /in "KeyboardAutoSwitchBack.ahk" /icon "assets/icon.ico" /out "KeyboardAutoSwitchBack.exe"

clean:
	rm KeyboardAutoSwitchBack.exe