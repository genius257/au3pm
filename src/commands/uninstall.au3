#include-once

Func Command_Uninstall($sPackage = Null)
    ;FIXME: currently package dependecies are not handled! they should be removed too! (if unused after package in question is removed!)
    ;FIXME: use UninstallPackage function to determine related packages.

    If $sPackage = Null Then
        If Not FileExists(@WorkingDir & '\au3pm.json') Then
            ConsoleWriteLine('au3pm.json not found.')
            Return SetError(0)
        EndIf

        $json = au3pm_json_load()
        $lock = au3pm_lock_load()

        $dependencies = $json.Item('dependencies')
        If @error <> 0 Then
            ConsoleWriteLine('no dependencies found in au3pm.json')
            Return SetError(0)
        EndIf

        For $dependency In $dependencies
            DirRemove(@WorkingDir & '\au3pm\' & $dependency & "\", 1)
            If $json.Item('dependencies').Exists($dependency) Then $json.Item('dependencies').Remove($dependency)
            If $lock.Item('packages').Exists($dependency) Then $lock.Item('packages').Remove($dependency)
        Next

        au3pm_json_save($json)
        au3pm_lock_save($lock)

        Return SetError(0)
    EndIf

    If StringRegExp($CmdLine[2], "^[a-zA-Z \-_0-9]+$", 0) Then
        $dependency = $CmdLine[2]
    Else
        ConsoleWriteError(StringFormat('Dont know how to handle install parameter: "%s"\n', $CmdLine[2]))
        Return SetError(1)
    EndIf

    If Not FileExists(@WorkingDir & '\au3pm.json') Then
        ConsoleWriteLine('au3pm.json not found.')
        Return SetError(0)
    EndIf

    $json = au3pm_json_load()
    $lock = au3pm_lock_load()

    $dependencies = $json.Item('dependencies')
    If @error <> 0 Then
        ConsoleWriteLine('no dependencies found in au3pm.json')
        Return SetError(0)
    EndIf

    DirRemove(@WorkingDir & '\au3pm\' & $dependency & "\", 1)
    If $json.Item('dependencies').Exists($dependency) Then $json.Item('dependencies').Remove($dependency)
    If $lock.Item('packages').Exists($dependency) Then $lock.Item('packages').Remove($dependency)

    au3pm_json_save($json)
    au3pm_lock_save($lock)

    Return SetError(0)
EndFunc