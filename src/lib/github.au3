#include-once
#include <InetConstants.au3>
#include "../../au3pm/au3json/json.au3"
#include "../../au3pm/winhttp/WinHttp.au3"
#include <StringConstants.au3>

Global Const $Github_Api_Base = "https://api.github.com"

Func _GitHub_GetTags($sOwner, $sRepo)
    Local $sUrl = "https://api.github.com/repos/" & $sOwner & "/" & $sRepo & "/tags"
    Local $aTags = _GitHub_GetPaginatedData($sUrl)
    Local $mTags[]
    For $i = 0 To UBound($aTags) - 1
        $mTags[$aTags[$i].name] = $aTags[$i]
    Next
    Return $mTags
EndFunc

Func _GitHub_GetPaginatedData($sUrl)
    Local $result[0]
    Local $aUrl = _WinHttpCrackUrl($sUrl)
    Local Const $nextnextPattern = '(?i)(?<=<)([\S]*)(?=>; rel="Next")'
    Local $pagesRemaining = True
    local $hOpen = _WinHttpOpen()
    Local $hConnect = _WinHttpConnect($hOpen, $aUrl[2])
    While $pagesRemaining
        Local $hRequest = _WinHttpOpenRequest($hConnect, "GET", $aUrl[6]&$aUrl[7])
        _WinHttpSendRequest($hRequest)
        _WinHttpReceiveResponse($hRequest)
        $linkHeader = _WinHttpQueryHeaders($hRequest, $WINHTTP_QUERY_CUSTOM, "Link")
        $pagesRemaining = $pagesRemaining And (@error = 0)
        If _WinHttpQueryDataAvailable($hRequest) Then
            Local $sBody = "", $sChunk
            While 1
                $sChunk = _WinHttpReadData($hRequest)
                If @error <> 0 Then ExitLoop
                $sBody &= $sChunk
            WEnd
            Local $v = _json_decode($sBody)
            Local $i = UBound($result)
            Redim $result[UBound($result) + UBound($v)]
            For $j = 0 To UBound($v) - 1
                $result[$i+$j] = $v[$j]
            Next
        EndIf
        $pagesRemaining = $pagesRemaining And (StringInStr($linkHeader, 'rel="next"') > 0)
        If $pagesRemaining Then
            $sUrl = StringRegExp($linkHeader, $nextnextPattern, 1)[0]
            $aUrl = _WinHttpCrackUrl($sUrl)
        EndIf
        _WinHttpCloseHandle($hRequest)
    WEnd
    _WinHttpCloseHandle($hConnect)
    _WinHttpCloseHandle($hOpen)

    Return $result
EndFunc
