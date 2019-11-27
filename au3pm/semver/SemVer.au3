#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Version=Beta
#Tidy_Parameters=/sf
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****


; http://semver.org/spec/v2.0.0.html

Global Const $SVREL_MAJOR = 1
Global Const $SVREL_PREMAJOR = 2
Global Const $SVREL_MINOR = 3
Global Const $SVREL_PREMINOR = 4
Global Const $SVREL_PATCH = 5
Global Const $SVREL_PREPATCH = 6
Global Const $SVREL_PRERELEASE = 7
Global Const $SVREL_BUILD = 8

Global Const $__SVREGEX_VERSION = "^[\s=v]*(\d+)\.(\d+)\.(\d+)\s*(\-[A-Za-z0-9\-\.]+|)\s*(\+[A-Za-z0-9\-\.]+|)\s*$"
Global Const $__SVREGEX_CONDVERSION = "^[\s=v]*(\d+|x|\*)(\.(?:\d+|x|\*)|)(\.(?:\d+|x|\*)|)?\s*(\-[A-Za-z0-9\-\.]+|)\s*(\+[A-Za-z0-9\-\.]+|)\s*$"



; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __SemVer_ConditionParse
; Description ...: Parses a set of conditions
; Syntax ........: __SemVer_ConditionParse($sCond)
; Parameters ....: $sCond               - A condition string. See _SemVer_Satisfies for description of format.
; Return values .: An array or conditions.
; Author ........: Matt Diesel (Mat)
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __SemVer_ConditionParse($sCond)
	Local Static $aOps[] = ["<=", ">=", "!=", "=", "<", ">", "~", "^"]
	Local $aRet[10][3] = [[0, 0, 0]] ; Group, Comparison Type, Version

	Local $aOrs = StringSplit($sCond, "||", 1)

	Local $aAnds, $aVer, $sOp
	For $i = 1 To $aOrs[0]
		$aOrs[$i] = StringStripWS($aOrs[$i], 7)

		$aAnds = StringSplit($aOrs[$i], " ")

		For $n = 1 To $aAnds[0]
			$aAnds[$n] = StringStripWS($aAnds[$n], 8)
		Next

		For $n = 1 To $aAnds[0]
			If $n < $aAnds[0] And $aAnds[$n + 1] = "-" Then
				; Defining a range

				$aVer = __SemVer_Parse($aAnds[$n])
				If @error Then Return SetError(2, @error, 0) ; Badly formatted version

				$aRet[0][0] += 1
				If $aRet[0][0] >= UBound($aRet) Then
					ReDim $aRet[$aRet[0][0] + 10][UBound($aRet, 2)]
				EndIf

				$aRet[$aRet[0][0]][0] = $i
				$aRet[$aRet[0][0]][1] = ">="
				$aRet[$aRet[0][0]][2] = $aVer

				$n += 2

				$aVer = __SemVer_Parse($aAnds[$n])
				If @error Then Return SetError(2, @error, 0) ; Badly formatted version

				$aRet[0][0] += 1
				If $aRet[0][0] >= UBound($aRet) Then
					ReDim $aRet[$aRet[0][0] + 10][UBound($aRet, 2)]
				EndIf

				$aRet[$aRet[0][0]][0] = $i
				$aRet[$aRet[0][0]][1] = "<="
				$aRet[$aRet[0][0]][2] = $aVer
			Else
				$sOp = ""

				; Single condition
				For $o In $aOps
					If StringLeft($aAnds[$n], StringLen($o)) = $o Then
						$sOp = $o
						ExitLoop
					EndIf
				Next

				If $sOp = "" Then
					; Specific version
					$sOp = "="
				Else
					$aAnds[$n] = StringTrimLeft($aAnds[$n], 1)
				EndIf

				$aVer = __SemVer_ParseCondVer($aAnds[$n])
				If @error Then Return SetError(2, @error, 0) ; Badly formatted version

				$aRet[0][0] += 1
				If $aRet[0][0] >= UBound($aRet) Then
					ReDim $aRet[$aRet[0][0] + 10][UBound($aRet, 2)]
				EndIf

				$aRet[$aRet[0][0]][0] = $i
				$aRet[$aRet[0][0]][1] = $sOp
				$aRet[$aRet[0][0]][2] = $aVer
			EndIf
		Next
	Next

	Return $aRet
EndFunc   ;==>__SemVer_ConditionParse


; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __SemVer_Match
; Description ...: Applies an operator to two input version numbers
; Syntax ........: __SemVer_Match($aVerA, $sOp, $aVerB)
; Parameters ....: $aVerA               - Version number A, must be as an array.
;                  $sOp                 - The operator. Operators are: '=', '>', '<', '>=', '<=', '!=', '~' and '^'
;                  $aVerB               - Version number B, must be as an array.
; Return values .: The result of the comparison, as a boolean.
; Author ........: Matt Diesel(Mat)
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __SemVer_Match($aVerA, $sOp, $aVerB)
	Local $Predicate = Null

	Switch $sOp
		Case "="
			$Predicate = _SemVer_Eq
		Case ">"
			$Predicate = _SemVer_Gt
		Case "<"
			$Predicate = _SemVer_Lt
		Case ">="
			$Predicate = _SemVer_Gte
		Case "<="
			$Predicate = _SemVer_Lte
		Case "!="
			$Predicate = _SemVer_Neq
		Case "~"
			$Predicate = _SemVer_ReasonablyClose
		Case "^"
			$Predicate = _SemVer_Compatible
		Case Else
			Return SetError(1, 0, 0) ; Operator not recognised
	EndSwitch

	Return $Predicate($aVerA, $aVerB)
EndFunc   ;==>__SemVer_Match

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __SemVer_Parse
; Description ...: Parses a version number into an array.
; Syntax ........: __SemVer_Parse($sVer)
; Parameters ....: $sVer                - The string representation of the version number.
; Return values .: Success: An array with 5 elements:
;                  |[0] - The major version number
;                  |[1] - The minor version number
;                  |[2] - The patch version number
;                  |[3] - The pre-release tag
;                  |[4] - The build meta data
;                  Failure: Returns zero and sets @error to non zero.
; Author ........: Matt Diesel (Mat)
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __SemVer_Parse($sVer)
	Local $a = StringRegExp($sVer, $__SVREGEX_VERSION, 1)
	If @error Then Return SetError(@error, 0, 0) ; No match

	$a[0] = Int($a[0])
	$a[1] = Int($a[1])
	$a[2] = Int($a[2])
	$a[3] = StringTrimLeft($a[3], 1)
	$a[4] = StringTrimLeft($a[4], 1)

	Return $a
EndFunc   ;==>__SemVer_Parse

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __SemVer_ParseCondVer
; Description ...: Parses a version number to be used in a condition
; Syntax ........: __SemVer_ParseCondVer($sVer)
; Parameters ....: $sVer                - The string version number
; Return values .: An array in the same format as __SemVer_Parse.
; Author ........: Matt Diesel (Mat)
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __SemVer_ParseCondVer($sVer)
	Local $a = StringRegExp($sVer, $__SVREGEX_CONDVERSION, 1)
	If @error Then Return SetError(@error, 0, 0) ; No match

	$a[1] = StringTrimLeft($a[1], 1)
	$a[2] = StringTrimLeft($a[2], 1)
	$a[3] = StringTrimLeft($a[3], 1)
	$a[4] = StringTrimLeft($a[4], 1)

	Return $a
EndFunc   ;==>__SemVer_ParseCondVer

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __SemVer_ToStr
; Description ...: Converts a version number array to a string
; Syntax ........: __SemVer_ToStr($aVer)
; Parameters ....: $aVer                - A version array, as returned by __SemVer_Parse
; Return values .: The version number string
; Author ........: Matt Diesel(Mat)
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __SemVer_ToStr($aVer)
	If IsString($aVer) Then Return $aVer

	Local $sRet = $aVer[0] & "." & $aVer[1] & "." & $aVer[2]

	If $aVer[3] <> "" Then $sRet &= "-" & $aVer[3]
	If $aVer[4] <> "" Then $sRet &= "+" & $aVer[4]

	Return $sRet
EndFunc   ;==>__SemVer_ToStr

; #FUNCTION# ====================================================================================================================
; Name ..........: _SemVer_Clean
; Description ...: Cleans up a version number string
; Syntax ........: _SemVer_Clean($sVer)
; Parameters ....: $sVer                - The string version number
; Return values .: Success: The version number, cleaned to the standard format.
;                  Failure: Returns "" and sets @error to non-zero.
; Author ........: Matt Diesel (Mat)
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _SemVer_Clean($sVer)
	If Not IsArray($sVer) Then
		$sVer = __SemVer_Parse($sVer)
		If @error Then Return SetError(1, @error, "") ; Invalid $sVer argument
	EndIf

	Return __SemVer_ToStr($sVer)
EndFunc   ;==>_SemVer_Clean

; #FUNCTION# ====================================================================================================================
; Name ..........: _SemVer_Compare
; Description ...: Compares two version numbers
; Syntax ........: _SemVer_Compare($sVerA, $sVerB)
; Parameters ....: $sVerA               - The version A string
;                  $sVerB               - The version B string
; Return values .: Success: One of the following:
;                  |-1 - A < B
;                  |0 - A = B
;                  |1 - A > b
;                  |2 - A = B, apart from the pre-release tags which differ.
;                  Failure: Returns 0 and sets @error:
;                  |1 - Invalid $aVerA argument
;                  |2 - Invalid $sVerB argument
; Author ........: Matt Diesel (Mat)
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _SemVer_Compare($sVerA, $sVerB)
	If Not IsArray($sVerA) Then
		$sVerA = __SemVer_Parse($sVerA)
		If @error Then Return SetError(1, @error, 0) ; Invalid $sVerA argument
	EndIf

	If Not IsArray($sVerB) Then
		$sVerB = __SemVer_ParseCondVer($sVerB)
		If @error Then Return SetError(2, @error, 0) ; Invalid $sVerB argument
	EndIf

	; Test Major, Minor, Patch
	For $i = 0 To 2
		If $sVerB[$i] = "x" Or $sVerB[$i] = "*" Or $sVerB[$i] = "" Then
			Return 0
		ElseIf $sVerA[$i] < $sVerB[$i] Then
			Return -1
		ElseIf $sVerA[$i] > $sVerB[$i] Then
			Return 1
		EndIf
	Next

	; Test for pre-release
	If $sVerA[3] <> "" And $sVerB[3] = "" Then
		Return -1
	ElseIf $sVerA[3] = "" And $sVerB[3] <> "" Then
		Return 1
	ElseIf $sVerA[3] <> $sVerB[3] Then
		; TODO: Comparison of prerelease versions
		Return 2
	EndIf

	Return 0
EndFunc   ;==>_SemVer_Compare

; #FUNCTION# ====================================================================================================================
; Name ..........: _SemVer_Compatible
; Description ...: Tests if two versions are compatible (share the same major version)
; Syntax ........: _SemVer_Compatible($sVerA, $sVerB)
; Parameters ....: $sVerA               - The version A string
;                  $sVerB               - The version B string
; Return values .: Success: True if the two versions are compatible, False otherwise
;                  Failure: Returns false and sets @error:
;                  |2 - Invalid $sVerB argument
; Author ........: Matt Diesel (Mat)
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _SemVer_Compatible($sVerA, $sVerB)
	Local $aVerC[5] = [0, "*", "*", "", ""]

	If Not IsArray($sVerB) Then
		$sVerB = __SemVer_Parse($sVerB)
		If @error Then Return SetError(2, @error, False) ; Invalid $sVerB argument
	EndIf

	$aVerC[0] = $sVerB[0]

	If $sVerB[0] = 0 Then ; For 0.x.x version numbers, only the exact versions are compatible.
		$aVerC[1] = $sVerB[1]
		$aVerC[2] = $sVerB[2]
	EndIf

	Return _SemVer_Eq($sVerA, $aVerC)
EndFunc   ;==>_SemVer_Compatible

; #FUNCTION# ====================================================================================================================
; Name ..........: _SemVer_Eq
; Description ...: Tests if two versions are equal
; Syntax ........: _SemVer_Eq($sVerA, $sVerB)
; Parameters ....: $sVerA               - The version A string
;                  $sVerB               - The version B string
; Return values .: Success: True if the two versions are equal, False otherwise
;                  Failure: Returns false and sets @error.
; Author ........: Matt Diesel (Mat)
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _SemVer_Eq($sVerA, $sVerB)
	Return _SemVer_Compare($sVerA, $sVerB) = 0
EndFunc   ;==>_SemVer_Eq

; #FUNCTION# ====================================================================================================================
; Name ..........: _SemVer_Gt
; Description ...: Tests if a version A is greater than version B
; Syntax ........: _SemVer_Gt($sVerA, $sVerB)
; Parameters ....: $sVerA               - The version A string
;                  $sVerB               - The version B string
; Return values .: Success: True if A > B, False otherwise
;                  Failure: Returns false and sets @error.
; Author ........: Matt Diesel (Mat)
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _SemVer_Gt($sVerA, $sVerB)
	Return _SemVer_Compare($sVerA, $sVerB) = 1
EndFunc   ;==>_SemVer_G

; #FUNCTION# ====================================================================================================================
; Name ..........: _SemVer_Gte
; Description ...: Tests if a version A is greater than or equal to version B
; Syntax ........: _SemVer_Gte($sVerA, $sVerB)
; Parameters ....: $sVerA               - The version A string
;                  $sVerB               - The version B string
; Return values .: Success: True if A >= B, False otherwise
;                  Failure: Returns false and sets @error.
; Author ........: Matt Diesel (Mat)
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _SemVer_Gte($sVerA, $sVerB)
	Local $cmp = _SemVer_Compare($sVerA, $sVerB)
	Return ($cmp = 0) Or ($cmp = 1)
EndFunc   ;==>_SemVer_Gte

; #FUNCTION# ====================================================================================================================
; Name ..........: _SemVer_Inc
; Description ...: Increments a version number.
; Syntax ........: _SemVer_Inc($sVer, $iRelease[, $sBuildMeta = ""[, $sPreReleaseMeta = ""]])
; Parameters ....: $sVer                - The string version number
;                  $iRelease            - The release type. This can be one of:
;                  |$SVREL_MAJOR - Major version
;                  |$SVREL_PREMAJOR - Major pre-release version. This increments the major version, then adds pre-release notes.
;                  |$SVREL_MINOR - Minor version
;                  |$SVREL_PREMINOR - Minor version pre-release. This increments the minor version, then adds pre-release notes.
;                  |$SVREL_PATCH - Patch version
;                  |$SVREL_PREPATCH - Patch version pre-release. This increments the patch version, then adds pre-release notes.
;                  |$SVREL_PRERELEASE - Pre-release version. If the current version is a pre-release, then this only changes the
;                                       pre-release tag. If not then it increments the patch and adds the tag (same as
;                                       $SVREL_PREPATCH)
;                  |$SVREL_BUILD - Only changes the build notes.
;                  $sBuildMeta          - [optional] The build notes. Default is "".
;                  $sPreReleaseMeta     - [optional] The pre-release tag, this should be used if release is one of the PRE
;                                         release types. Default is "".
; Return values .: Success: The incremented version number string.
;                  Failure: Returns "" and sets @error:
;                  |1 - Invalid $sVer argument
;                  |2 - Invalid $iRelease argument
; Author ........: Matt Diesel (Mat)
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _SemVer_Inc($sVer, $iRelease, $sBuildMeta = "", $sPreReleaseMeta = "")
	If Not IsArray($sVer) Then
		$sVer = __SemVer_Parse($sVer)
		If @error Then Return SetError(1, @error, "") ; Invalid $sVer argument
	EndIf


	Switch $iRelease
		Case $SVREL_MAJOR
			$sVer[0] += 1
			$sVer[1] = 0
			$sVer[2] = 0
			$sVer[3] = ""
		Case $SVREL_MINOR
			$sVer[1] += 1
			$sVer[2] = 0
			$sVer[3] = ""
		Case $SVREL_PATCH
			$sVer[2] += 1
			$sVer[3] = ""

		Case $SVREL_PREMAJOR
			$sVer[0] += 1
			$sVer[1] = 0
			$sVer[2] = 0
			$sVer[3] = $sPreReleaseMeta
		Case $SVREL_PREMINOR
			$sVer[1] += 1
			$sVer[2] = 0
			$sVer[3] = $sPreReleaseMeta
		Case $SVREL_PREPATCH
			$sVer[2] += 1
			$sVer[3] = $sPreReleaseMeta

		Case $SVREL_PRERELEASE
			If $sVer[3] = "" Then
				$sVer[2] += 1
				$sVer[3] = $sPreReleaseMeta
			Else
				$sVer[3] = $sPreReleaseMeta
			EndIf

		Case $SVREL_BUILD
			; Nothing is changed

		Case Else
			Return SetError(2, 0, 0) ; Invalid $iRelease Argument
	EndSwitch

	$sVer[4] = $sBuildMeta

	Return __SemVer_ToStr($sVer)
EndFunc   ;==>_SemVer_Inc

; #FUNCTION# ====================================================================================================================
; Name ..........: _SemVer_Lt
; Description ...: Tests if a version A is less than version B
; Syntax ........: _SemVer_Lt($sVerA, $sVerB)
; Parameters ....: $sVerA               - The version A string
;                  $sVerB               - The version B string
; Return values .: Success: True if A < B, False otherwise
;                  Failure: Returns false and sets @error.
; Author ........: Matt Diesel (Mat)
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _SemVer_Lt($sVerA, $sVerB)
	Return _SemVer_Compare($sVerA, $sVerB) = -1
EndFunc   ;==>_SemVer_Lt

; #FUNCTION# ====================================================================================================================
; Name ..........: _SemVer_Lte
; Description ...: Tests if a version A is less than or equal to version B
; Syntax ........: _SemVer_Lte($sVerA, $sVerB)
; Parameters ....: $sVerA               - The version A string
;                  $sVerB               - The version B string
; Return values .: Success: True if A <= B, False otherwise
;                  Failure: Returns false and sets @error.
; Author ........: Matt Diesel (Mat)
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _SemVer_Lte($sVerA, $sVerB)
	Return _SemVer_Compare($sVerA, $sVerB) <= 0
EndFunc   ;==>_SemVer_Lte

; #FUNCTION# ====================================================================================================================
; Name ..........: _SemVer_Neq
; Description ...: Tests if two versions are not equal
; Syntax ........: _SemVer_Neq($sVerA, $sVerB)
; Parameters ....: $sVerA               - The version A string
;                  $sVerB               - The version B string
; Return values .: Success: True if the two versions are not equal, False otherwise
;                  Failure: Returns false and sets @error.
; Author ........: Matt Diesel (Mat)
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _SemVer_Neq($sVerA, $sVerB)
	Return _SemVer_Compare($sVerA, $sVerB) <> 0
EndFunc   ;==>_SemVer_Neq

; #FUNCTION# ====================================================================================================================
; Name ..........: _SemVer_ReasonablyClose
; Description ...: Tests if a version is reasonably close to another.
; Syntax ........: _SemVer_ReasonablyClose($sVerA, $sVerB)
; Parameters ....: $sVerA               - The version A string
;                  $sVerB               - The version B string
; Return values .: Success: True if A is reasonably close to B, False otherwise
;                  Failure: Returns false and sets @error:
;                  | 1 - Invalid $sVerB argument
; Author ........: Matt Diesel (Mat)
; Modified ......:
; Remarks .......: A is reasonably close to B, if they are the same minor version, and A is a higher, or equal, patch to B.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _SemVer_ReasonablyClose($sVerA, $sVerB)
	Local $aVerC[5] = [0, 0, "*", "", ""]

	If Not IsArray($sVerB) Then
		$sVerB = __SemVer_Parse($sVerB)
		If @error Then Return SetError(1, @error, False) ; Invalid $sVerB argument
	EndIf

	If Not _SemVer_Gte($sVerA, $sVerB) Then Return False

	$aVerC[0] = $sVerB[0]
	$aVerC[1] = $sVerB[1]

	Return _SemVer_Eq($sVerA, $aVerC)
EndFunc   ;==>_SemVer_ReasonablyClose

; #FUNCTION# ====================================================================================================================
; Name ..........: _SemVer_Satisfies
; Description ...: Tests if a version number satisfies a set of conditions.
; Syntax ........: _SemVer_Satisfies($sVer, $sCond)
; Parameters ....: $sVer                - The version number string.
;                  $sCond               - The condition string.
; Return values .: Success: True if the version number satisfies sufficient conditions. False otherwise.
;                  Failure: Returns False, and sets @error:
;                  |1 - Invalid condition string
; Author ........: Matt Diesel (Mat)
; Modified ......:
; Remarks .......: The condition string is a space separated list of conditions. A condition is an operator followed by a version
;                  number, for example "<1.2.3" tests for versions less than 1.2.3. A version number on its own will only match
;                  equal version. Wildcards can be added with '*' or 'x', so "1.1.*" will match 1.1.1, 1.1.2, 1.1.3 etc. Omitting
;                  part of the version is the same as wildcarding it, so "1.1" would be the same as "1.1.*". Space separated
;                  conditions are anded together, so ">=1.1.1 <=1.1.3" will match version numbers in the range 1.1.1 to 1.1.3
;                  inclusive. Conditions can be ORed with "||", so "1.1 || 1.5" will match any version that is 1.1.* OR 1.5.*.
;                  Ranges are defined using '-', so "1.1.1 - 1.1.3" matches anything in that range (inclusive). Note that the
;                  spaces around the dash are required, as "1.1.1-1.1.3" is a valid version number, with pre-release tag "1.1.3".
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _SemVer_Satisfies($sVer, $sCond)
	If $sCond = "" Then Return True ; "" matches anything.

	Local $aCond = __SemVer_ConditionParse($sCond)
	If @error Then Return SetError(1, @error, False) ; Invalid condition string

	If $aCond[0][0] = 0 Then Return True

	Local $g = $aCond[1][0] ; First group

	For $i = 1 To $aCond[0][0]
		If $aCond[$i][0] <> $g Then Return True

		If Not __SemVer_Match($sVer, $aCond[$i][1], $aCond[$i][2]) Then
			While $aCond[$i][0] = $g
				$i += 1
				If $i > $aCond[0][0] Then Return False
			WEnd
			$g = $aCond[$i][0]
			$i -= 1
		EndIf
	Next

	Return True
EndFunc   ;==>_SemVer_Satisfies

; #FUNCTION# ====================================================================================================================
; Name ..........: _SemVer_Valid
; Description ...: Checks if a version number string is valid.
; Syntax ........: _SemVer_Valid($sVer)
; Parameters ....: $sVer                - The version number string.
; Return values .: True if the version number is valid, False otherwise.
; Author ........: Matt Diesel (Mat)
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _SemVer_Valid($sVer)
	Return StringRegExp($sVer, $__SVREGEX_VERSION)
EndFunc   ;==>_SemVer_Valid

#cs
# Return the highest version in the list that satisfies the range, or null if none of them do.
#
# @author Anders Pedersen (genius257)
#
# @param array $versions array of versions
# @param string $range The version number string
#
# @return string|null
#ce
Func _SemVer_MaxSatisfying($versions, $range)
    Local $i
    Local $max = Null

    For $i = 0 To UBound($versions)-1
        If Not _SemVer_Satisfies($versions[$i], $range) Then ContinueLoop
        If (Not $max) Or _SemVer_Compare($max, $versions[$i]) = -1 Then $max = $versions[$i]
    Next

    Return $max
EndFunc

Func _SemVer_ValidRange($range)
	#cs
	# @see https://docs.npmjs.com/misc/semver#range-grammar
	#ce
	Local Static $re = '(?(DEFINE)(?<rangeSet>(?&range)((?&logicalOr)(?&range))*)(?<logicalOr>( )*\|\|( )*)(?<range>(?&hyphen)|(?&simple)( (?&simple))*|)(?<hyphen>(?&partial) - (?&partial))(?<simple>(?&primitive)|(?&partial)|(?&tilde)|(?&caret))(?<primitive>(<|>|>=|<=|=)(?&partial))(?<partial>(?&xr)(\.(?&xr)(\.(?&xr)(?&qualifier)?)?)?)(?<xr>x|X|\*|(?&nr))(?<nr>0|[1-9]([0-9])*)(?<tilde>~(?&partial))(?<caret>\^(?&partial))(?<qualifier>(-(?&pre))?(\+(?&build))?)(?<pre>(?&parts))(?<build>(?&parts))(?<parts>(?&part)(\.(?&part))*)(?<part>(?&nr)|[-0-9A-Za-z]+))^(?&rangeSet)$'
	Return Not Not StringRegExp($range, $re)
EndFunc
