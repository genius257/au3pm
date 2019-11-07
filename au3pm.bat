@echo off

cls

setlocal

reg query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set BitVersion=32 || set BitVersion=64

IF BitVersion == 32 (set AutoItReg="HKEY_LOCAL_MACHINE\Software\AutoIt v3") ELSE (set AutoItReg="HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\AutoIt v3")

FOR /F "skip=2 tokens=2,*" %%A IN ('reg query "%AutoItReg:"=%\AutoIt" /v "InstallDir"') DO set "AutoItDir=%%B"

IF EXIST ".\build\au3pm.exe" (DEL ".\build\au3pm.exe")

"%AutoItDir%\Aut2Exe\Aut2exe.exe" /in "au3pm.au3" /out ".\build\au3pm.exe" /x86 /console

CD ".\build\"

"au3pm.exe" %*
