#pragma compile(Icon, ../assets/au3pm.ico)

FileInstall("../assets/7za.exe" , @ScriptDir & "\7za.exe")

Global Const $__au3pm_json_path = @WorkingDir & "\au3pm.json"
Global Const $__au3pm_lock_path = @WorkingDir & "\au3pm-lock.json"

#include "./commands/build.au3"
#include "./commands/config.au3"
#include "./commands/init.au3"
#include "./commands/install.au3"
#include "./commands/list.au3"
#include "./commands/rebuild.au3"
#include "./commands/restart.au3"
#include "./commands/run.au3"
#include "./commands/start.au3"
#include "./commands/stop.au3"
#include "./commands/test.au3"
#include "./commands/uninstall.au3"
#include "./commands/update.au3"
#include "./commands/version.au3"

HttpSetUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:65.0) Gecko/20100101 Firefox/65.0')

ConsoleWriteLine('AutoIt3 package manager by genius257. Prebuild.')
ConsoleWriteLine('Disclaimer: this is a prebuild. NOTHING is guaranteed to work or be completed at this stage.')
ConsoleWriteLine()

Global $argc = $CmdLine[0]

Global $command = $argc > 0 ? $CmdLine[1] : ''

; FIXME: add error handling for wrong number of parameters to the different commands.

Switch StringLower($command)
    Case 'build'
        Command_Build()
    Case 'config'
        Command_Config()
    Case 'init'
        Command_Init()
    Case 'install'
        Local $package = $argc > 1 ? $CmdLine[2] : Null

        Command_Install($package)
    Case 'list'
        Command_List()
    Case 'rebuild'
        Command_Rebuild()
    Case 'restart'
        Command_Restart()
    Case 'run'
        Local $name = $argc > 1 ? $CmdLine[2] : Null

        Command_Run($name)
    Case 'start'
        Command_Start()
    Case 'stop'
        Command_Stop()
    Case 'test'
        Command_Test()
    Case 'uninstall'
        Local $package = $argc > 1 ? $CmdLine[2] : Null

        Command_Uninstall($package)
    Case 'update'
        Local $package = $argc > 1 ? $CmdLine[2] : Null

        Command_Update($package)
    Case 'version'
        Command_Version()
EndSwitch

;Exit with error code from the command result
Exit @error
