#include-once

#include "../../au3pm/au3json/json.au3"

Func au3pm_json_load($sFile = $__au3pm_json_path)
    Local $sJson = '{"version":"1.0.0","name":"","description":"","author":"","main":"","dependencies":{},"scripts":{},"licence":""}'
    If FileExists($sFile) Then
        $sJson = FileRead($sFile)
    EndIf
    Return _json_decode($sJson)
EndFunc

Func au3pm_json_save($json)
    If Not IsString($json) Then
        $json = json_stringify($json)
    EndIf

    Local $hFile = FileOpen($__au3pm_json_path, 2)
    FileWrite($hFile, $json)
    FileClose($hFile)
EndFunc

Func au3pm_lock_load($sFile = $__au3pm_lock_path)
    Local $sJson = '{"hash":"","packages":{},"packages-dev":{}}'
    If FileExists($sFile) Then
        $sJson = FileRead($sFile)
    EndIf
    Return _json_decode($sJson)
EndFunc

Func au3pm_lock_save($json)
    If Not IsString($json) Then
        $json = json_stringify($json)
    EndIf

    Local $hFile = FileOpen($__au3pm_lock_path, 2)
    FileWrite($hFile, $json)
    FileClose($hFile)
EndFunc
