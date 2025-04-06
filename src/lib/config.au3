#include-once

#include "../../au3pm/au3json/json.au3"

Global Enum $_au3pm_config_noFile, $_au3pm_config_lockFile, $_au3pm_config_configFile

Func au3pm_config_load($sDirectory = @WorkingDir)
    $sDirectory = StringRegExpReplace($sDirectory, "(\/)*$", "/")

    If FileExists($sDirectory&"au3pm-lock.json") Then
        Local $json = au3pm_lock_load($sDirectory&"au3pm-lock.json")
        Return SetError(@error, $_au3pm_config_lockFile, $json)
    ElseIf FileExists($sDirectory&"au3pm.json") Then
        Local $json = au3pm_json_load($sDirectory)
        Return SetError(@error, $_au3pm_config_configFile, $json)
    EndIf

    Local $json = _json_decode('{"dependencies":{}}')
    Return SetError(@error, $_au3pm_config_noFile, $json)
EndFunc

Func au3pm_json_load($sDirectory = @WorkingDir)
    $sDirectory = StringRegExpReplace($sDirectory, "(\/)*$", "/")
    $sFile = $sDirectory & "au3pm.json"
    ;Local $sJson = '{"version":"1.0.0","name":"","description":"","author":"","main":"","dependencies":{},"scripts":{},"licence":""}'
    If Not FileExists($sFile) Then
        Return SetError(1, 0, Null)
    EndIf
    Local $sJson = FileRead($sFile)
    Return _json_decode($sJson)
EndFunc

Func au3pm_json_save($json)
    If Not IsString($json) Then
        $json = _json_encode_pretty($json)
    EndIf

    Local $hFile = FileOpen($__au3pm_json_path, 2)
    FileWrite($hFile, $json)
    FileClose($hFile)
EndFunc

Func au3pm_lock_exists($sDirectory = @WorkingDir)
    $sDirectory = StringRegExpReplace($sDirectory, "(\/)*$", "/")

    Return FileExists($sDirectory&"au3pm-lock.json")
EndFunc

Func au3pm_lock_load($sFile = $__au3pm_lock_path)
    Local $sJson = '{"hash":"","packages":{},"packages-dev":{}}'
    If FileExists($sFile) Then
        $sJson = FileRead($sFile)
    EndIf
    Return _json_decode($sJson)
EndFunc

Func au3pm_lock_save($json, $sDirectory = @WorkingDir)
    $sDirectory = StringRegExpReplace($sDirectory, "(\/)*$", "/")

    If Not IsString($json) Then
        $json = _json_encode_pretty($json)
    EndIf

    Local $hFile = FileOpen($sDirectory&"au3pm-lock.json", 2)
    FileWrite($hFile, $json)
    FileClose($hFile)
EndFunc
