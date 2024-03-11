@echo off

cls

setlocal

reg query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set BitVersion=32 || set BitVersion=64

IF BitVersion == 32 (set AutoItReg="HKEY_LOCAL_MACHINE\Software\AutoIt v3") ELSE (set AutoItReg="HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\AutoIt v3")

FOR /F "skip=2 tokens=2,*" %%A IN ('reg query "%AutoItReg:"=%\AutoIt" /v "InstallDir"') DO set "AutoItDir=%%B"

IF NOT EXIST "%~dp0\build\" (MD "%~dp0\build\")

IF EXIST "%~dp0\build\au3pm.exe" (DEL "%~dp0\build\au3pm.exe")

"%AutoItDir%\Aut2Exe\Aut2exe.exe" /in "%~dp0\src\au3pm.au3" /out "%~dp0\build\au3pm.exe" /icon "%~dp0\au3pm.ico" /x86 /console

"%AutoItDir%\AutoIt3.exe" "%~dp0\src\build.au3" "%~dp0\build\au3pm.exe" "%~dp0\au3pm.json"
