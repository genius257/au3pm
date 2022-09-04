@echo off

cls

setlocal

reg query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set BitVersion=32 || set BitVersion=64

IF BitVersion == 32 (set AutoItReg="HKEY_LOCAL_MACHINE\Software\AutoIt v3") ELSE (set AutoItReg="HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\AutoIt v3")

FOR /F "skip=2 tokens=2,*" %%A IN ('reg query "%AutoItReg:"=%\AutoIt" /v "InstallDir"') DO set "AutoItDir=%%B"

IF NOT EXIST "%~dp0\build\" (MD "%~dp0\build\")

CD "%~dp0\build\"

REM https://stackoverflow.com/a/54252275
"%AutoItDir%\AutoIt3.exe" "%~dp0\au3pm.au3" %* 2>&1|more
