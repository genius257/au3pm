$sPath = "c:\www\something;"

MsgBox(0, "", _
    StringRegExpReplace($sPath, ";$", "")&";"&@LocalAppDataDir&"\au3pm;" _
)