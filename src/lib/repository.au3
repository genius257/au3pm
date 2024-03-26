#include-once

#cs
# fetch autoit with resolved reference.
#
# Getting AutoIt version with au3pm is a special case, so this function is made to handle this special case.
# @deprecated
#ce
Func fetchAutoIt($reference)
    If StringRegExp($reference, "^(>=)?[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$", $STR_REGEXPMATCH) = 0 Then Return SetError(1)
    Local $result = fetchAutoIt3(StringRegExpReplace($reference, "^(>=)?[0-9]+\.", "$1", 1))
    If @error=0 Then
        $result[0] = 'autoit'
        $result[1] = "3."&$result[1]
    EndIf
    Return SetError(@error, @extended, $result)
EndFunc

Func fetchAutoIt1($reference)
    Local Static $sVersion = "1.8"
    If Not _SemVer_Satisfies($sVersion, $reference) Then Return SetError(1)
    Local $return = ['autoit1', __SemVer_Parse($sVersion), "http://www.autoitscript.com/files/AutoIt/AutoIt_v1_8.zip"]
    Return $return
EndFunc

Func fetchAutoIt2($reference)
    Local Static $sVersion = "2.64"
    If Not _SemVer_Satisfies($sVersion, $reference) Then Return SetError(1)
    Local $return = ['autoit2', __SemVer_Parse($sVersion), "http://www.autoitscript.com/files/AutoIt/AutoIt.zip"]
    Return $return
EndFunc

Func fetchAutoIt3($reference)
    Local $versions = _HTMLParser_GetElementsByTagName("a", _HTMLParser_GetFirstStartTag(_HTMLParser(BinaryToString(InetRead('https://www.autoitscript.com/autoit3/files/archive/autoit/', 3))).head))
    Local $iCount = 0
    Local $aVersions[UBound($versions, 1)][2]
    Local $i
    For $i = 0 To UBound($versions)-1
        Local $sInnerText = ""
        Local $aInnerText = _HTMLParser_Element_GetText($versions[$i])
        For $j = 0 To UBound($aInnerText)-1 Step +1
            $sInnerText &= __HTMLParser_GetString(__doublyLinkedList_Node($aInnerText[$j]).data)
        Next
        If StringRegExp($sInnerText, "(?i)^autoit") And (Not StringRegExp($sInnerText, "(?i)(docs|setup)")) And StringRegExp($sInnerText, "(?i)(\.zip|-sfx\.exe)$") Then
            $aVersions[$iCount][0] = autoit3VerToSemver($sInnerText); StringRegExp($sInnerText, "v(?:[0-9]+\.)?([0-9]+\.[0-9]+\.[0-9]+)", 1)[0]
            $aVersions[$iCount][1] = "https://www.autoitscript.com/autoit3/files/archive/autoit/" & _HTMLParser_Element_GetAttribute("href", $versions[$i])
            $iCount += 1
        EndIf
    Next
    ReDim $aVersions[$iCount][2]
    ;TODO: get autoit versions (release and beta), resolve reference, download and extract autoit, inject special au3pm.json file into extracted content, return path to folder?
    Local $sVersion = _SemVer_MaxSatisfying(_ArrayExtract($aVersions, 0, -1, 0, 0), $reference)
    For $i = 0 To UBound($aVersions, 1) - 1
        If $aVersions[$i][0] == $sVersion Then
            Local $return = ['autoit3', $sVersion, $aVersions[$i][1]]
            Return $return
        EndIf
    Next
    Return SetError(1)
EndFunc

Func fetchAu3pm($reference)
    Local $versions = _json_decode(BinaryToString(InetRead('https://api.github.com/repos/genius257/au3pm/releases')))
    Local $aVersions[UBound($versions)][2]
    Local $i
    For $i = 0 To UBound($versions)-1
        $aVersions[$i][0] = $versions[$i].Item('tag_name')
        $aVersions[$i][1] = $versions[$i].Item('assets')[0].Item('browser_download_url')
    Next
    Local $sVersion = _SemVer_MaxSatisfying(_ArrayExtract($aVersions, 0, -1, 0, 0), $reference)
    For $i = 0 To UBound($aVersions, 1) - 1
        If $aVersions[$i][0] == $sVersion Then
            Local $return = ['au3pm', $sVersion, $aVersions[$i][1]]
            Return $return
        EndIf
    Next
    Return SetError(1)
EndFunc
