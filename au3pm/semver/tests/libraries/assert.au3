Func Assert($expected, $actual, $message = "", $iLine = @ScriptLineNumber)
	Local Static $iTestNum = 1
	$equal = ($expected == $actual)

	If $equal Then
		$iTestNum += 1
		Return
	EndIf

	ConsoleWriteError("Assert #" & $iTestNum & " on line " & $iLine & " failed. Expected <" & $expected & "> Actual <" & $actual & ">")
	If $message <> "" Then
		ConsoleWriteError("Msg: " & $message)
	EndIf
	ConsoleWriteError(@CRLF)
	Exit 1
EndFunc

Func AssertIsType($var, $type, $message = "")
	Assert(VarGetType($var), $type, $message)
EndFunc

Func AssertRegisterCleanup($func)

EndFunc