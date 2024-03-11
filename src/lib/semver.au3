#include-once

Func autoit3VerToSemver($sVer)
    Local $aFileVersionInfo = StringRegExp($sVer, "(?<major>[0-9]+)(?:\.(?<minor>[0-9]+))?(?:\.(?<build>[0-9]+))?(?:\.(?<private>[0-9]+))?", $STR_REGEXPARRAYMATCH)
    Local $iLength = UBound($aFileVersionInfo)
    If $iLength <> 4 Then
        Redim $aFileVersionInfo[4]
        For $i = 1 To 3
            $aFileVersionInfo[$i] = StringIsDigit($aFileVersionInfo[$i]) ? $aFileVersionInfo[$i] : "0"
        Next
    EndIf

    Return StringFormat("%u.%u.%u", $aFileVersionInfo[1], $aFileVersionInfo[2], $aFileVersionInfo[3])
EndFunc
