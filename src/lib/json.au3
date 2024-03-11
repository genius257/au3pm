#include-once

Func json_stringify($json)
    Local Static $CLSID_Dictionary = ObjName(ObjCreate("Scripting.Dictionary"), 6)
    Local Static $CLSID_ArrayList = ObjName(ObjCreate("System.Collections.ArrayList"), 6)
    Local $sJson = ""

    Switch VarGetType($json)
        Case "Array"
            $sJson = "["
            Local $value
            For $value In $json
                $sJson &= json_stringify($value) & ","
            Next
            $sJson = StringRegExpReplace($sJson, '[,]$', '') & "]"
        Case "Bool"
            $sJson = $json ? "true" : "false"
        Case "DLLStruct"
            $sJson = '"[object DLLStruct]"'
        Case "Int32", "Int64", "Double"
            $sJson = String($json)
        Case "Keyword"
            Switch $json
                Case Null
                    $sJson = "null"
                Case Default
                    $sJson = '""'
                Case Else
                    ConsoleWriteErrorLine(StringFormat("json_stringify: Unexpected keyword: %s", $json))
                    Exit 1
            EndSwitch
        Case "Object"
            Switch ObjName($json, 6)
                Case $CLSID_ArrayList
                    $sJson = "["
                    Local $value
                    For $value In $json
                        $sJson &= json_stringify($value) & ","
                    Next
                    $sJson = StringRegExpReplace($sJson, '[,]$', '') & "]"
                Case $CLSID_Dictionary
                    $sJson &= "{"
                    Local $key
                    For $key In $json
                        $sJson &= json_stringify($key) & ':' & json_stringify($json.Item($key)) & ","
                    Next
                    $sJson = StringRegExpReplace($sJson, '[,]$', '') & "}"
                Case Else
                    Return StringFormat('"[object %s]"', ObjName($json, 1))
            EndSwitch
        Case "String"
            $json = StringRegExpReplace($json, '\\|"', '\\$0');JSON escape string chars
            $sJson = StringFormat('"%s"', $json)
        Case Else
            ConsoleWriteErrorLine(StringFormat("json_stringify: Unexpected var type: %s", VarGetType($json)))
            Exit 1
    EndSwitch
    Return $sJson
EndFunc
