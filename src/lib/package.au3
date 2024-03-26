#include-once

If Not IsDeclared('registry') Then Global Const $registry = "https://raw.githubusercontent.com/au3pm/action-test/master/"

Func fetchPackage($name, $reference)
    ; In a pure JS fashion, if it looks like a path, it must be a path.
    If StringRegExp($reference, "^(/|\./|\.\./)", 0) Then Return FileRead($reference)

    Switch StringLower($name)
        Case 'au3pm'
            $reference = fetchAu3pm($reference)
            If @error <> 0 Then Return SetError(@error)
        Case 'autoit'
            ConsoleWrite('WARNING: au3pm dependency "autoit" is deprecated. please use "autoit3" instead to allow version ranges.'&@CRLF)
            $reference = fetchAutoIt($reference)
            If @error <> 0 Then Return SetError(@error)
        Case 'autoit1'
            $reference = fetchAutoIt1($reference)
            If @error <> 0 Then Return SetError(@error)
        Case 'autoit2'
            $reference = fetchAutoIt2($reference)
            If @error <> 0 Then Return SetError(@error)
        Case 'autoit3'
            $reference = fetchAutoIt3($reference)
            If @error <> 0 Then Return SetError(@error)
    EndSwitch

    If __SemVer_ConditionParse($reference) Or @error=0 Then; _SemVer_Valid($reference) Then
        Local Static $directory = _json_decode(BinaryToString(InetRead($registry & "au3pm.json", $INET_FORCEBYPASS)))
        Local $pathName = $directory.Item($name)
        Local $packageDirectory = _json_decode(BinaryToString(InetRead(StringFormat("%s%s/%s", $registry, $name, "au3pm.json"), $INET_FORCEBYPASS)))
        Local $versions = $packageDirectory.Item('versions').keys()
        Local $maxSatisfying = _semver_MaxSatisfying($versions, $reference)
        Local $sha = $packageDirectory.Item('versions').Item($maxSatisfying)
        Local $repo = $packageDirectory.Item('repo')
        Local $return = [ _
            $name, _
            $maxSatisfying, _
            fetchPackage($name, StringFormat('https://github.com/%s/archive/%s.zip', $repo, $sha)) _
        ]
        Return $return
    EndIf

    Return $reference
EndFunc

Func getPackageDependencyTree($dependencies)
    Local Static $directory = _json_decode(BinaryToString(InetRead($registry & "au3pm.json", $INET_FORCEBYPASS)))
    Local $resolvedDependencies = ObjCreate("Scripting.Dictionary")
    Local $queue = ObjCreate("System.Collections.ArrayList")
    $queue.Add($dependencies)
    ;Local $cache = ObjCreate("Scripting.Dictionary")

    While 1
        If $queue.Count() <= 0 Then ExitLoop
        Local $entry = $queue.Item(0)
        $queue.RemoveAt(0)
        Local $keys = $entry.Keys(); FIXME: Array_AsList($entry.Keys())
        For $keyEntry In $keys
            Local $range = $entry.Item($keyEntry)
            Local $package = fetchPackage($keyEntry, $range)
            Local $maxSatisfying = $package[1]
            #cs
            Local $packageDirectory = _json_decode(BinaryToString(InetRead(StringFormat("%s%s/%s", $registry, $keyEntry, "au3pm.json"), $INET_FORCEBYPASS)))
            Local $range = $entry.Item($keyEntry)
            Local $versions = $packageDirectory.Item('versions').keys
            Local $maxSatisfying = _SemVer_MaxSatisfying($versions, $range)
            #ce
            Local $__ref = $resolvedDependencies.Keys()
            If _ArraySearch($__ref, $keyEntry) > -1 Then ;Not $resolvedDependencies.__get($keyEntry) = "" Then
                If $keyEntry = "AutoIt" Then $range = StringRegExpReplace($range, "(?:[0-9]+\.)?([0-9]+\.[0-9]+\.[0-9]+)", "$1")
                ;TODO: we need atleast the previous range to find a commen acceptable range (i would imagine all the ranges are needed)
                If Not _SemVer_Satisfies($resolvedDependencies.Item($keyEntry), $range) Then
                    Exit MsgBox(0, "", "dependency version conflict")
                EndIf
                ContinueLoop
                ;solve diff, if possible or throw "exception"
            EndIf
            $resolvedDependencies.Add($keyEntry, $maxSatisfying)

            ;pretend we get package file from package with the version we matched
            ;Local $__ref = $directory.Keys()
            ;_ArrayDisplay($__ref)
            ;If _ArraySearch($__ref, $keyEntry) = -1 Then Exit MsgBox(0, "", "no match")
            ;Local $package = ObjCreate("Scripting.Dictionary"); FIXME: get au3json file from package repo
            ;    $package.Add('dependencies', ObjCreate("Scripting.Dictionary")) ;NOTE: quickfix for not getting the au3json from the package repo
            ;$queue.Add($package.Item('dependencies'))

            If StringLower($keyEntry) == "autoit" Then ContinueLoop

            Local $tmp = generateTempDir()
            If DirCreate($tmp) <> 1 Then Return SetError(1)

            Local $tmp_file = _TempFile($tmp, '~')

            ;Downloading

            InetGet($package[2], $tmp_file, 16, 0)
            If @error <> 0 Then
                Return SetError(2)
            EndIf

            ;Extracting...

            If RunWait(@ScriptDir & StringFormat('\7za.exe x -y -o"%s" "%s"', $tmp & '\out\', $tmp_file)) <> 0 Then
                Return SetError(3)
            EndIf

            #cs
            If DirMove(_FileListToArray($tmp&'\out\', '*', 2, True)[1], @WorkingDir & '\au3pm\'&$name&'\') <> 1 Then
                Return SetError(4)
            EndIf
            #ce

            local $json = au3pm_json_load(_FileListToArray($tmp&'\out\', '*', 2, True)[1]&'\au3pm.json')
            $queue.Add($json.Item('dependencies'))

            If DirRemove($tmp, 1) <> 1 Then Return SetError(5)
        Next
    WEnd

    return $resolvedDependencies
EndFunc

Func getPackageDependencies($dependency, $range)
    ;TODO
EndFunc

#cs
# Download and extracts package from url
#
# @param string $url                  Package url
# @param string $name                 Package name
# @param bool   $bInstallDependencies If true, installs nested dependecies
#
# @error 1 Failure creating %tmp% folder
# @error 2 Failure downloading
# @error 3 Failure extracting
# @error 4 Failure moving extracted content to au3pm folder
# @error 5 Failure removing %tmp% folder
#ce
Func InstallPackage($url, $name, $bInstallDependencies = False)
    Local $tmp = generateTempDir()
    If DirCreate($tmp) <> 1 Then Return SetError(1)

    Local $tmp_file = _TempFile($tmp, '~')

    ;Downloading

    InetGet($url, $tmp_file, 16, 0)
    If @error <> 0 Then
        Return SetError(2)
    EndIf

    ;Extracting...

    If RunWait(@ScriptDir & StringFormat('\7za.exe x -y -o"%s" "%s"', $tmp & '\out\', $tmp_file)) <> 0 Then
        Return SetError(3)
    EndIf

    If Not FileExists(@WorkingDir & '\au3pm\') Then DirCreate(@WorkingDir & '\au3pm\') ;TODO: test for failure

    If FileExists(@WorkingDir & '\au3pm\'&$name&'\') Then DirRemove(@WorkingDir & '\au3pm\'&$name&'\', 1)

    Local $aFileList = _FileListToArray($tmp&'\out\', '*', 2, True)

    If $aFileList[0] = 1 And isDirectory($aFileList[1]) Then
        If DirMove(_FileListToArray($tmp&'\out\', '*', 2, True)[1], @WorkingDir & '\au3pm\'&$name&'\') <> 1 Then
            Return SetError(4)
        EndIf
    Else
        If DirMove($tmp&'\out\', @WorkingDir & '\au3pm\'&$name&'\') <> 1 Then
            Return SetError(4)
        EndIf
    EndIf

    If FileExists(@WorkingDir & '\au3pm\'&$name&'\au3pm\') Then
        ConsoleWriteErrorLine('WARNING: au3pm dependency folder within dependency"'&$name&'" already exists! this may cause unexpected results!')
    Else
        RunWait(StringFormat('%s "%s" "%s"', @ComSpec & " /c mklink /J", @WorkingDir & '\au3pm\'&$name&'\au3pm\', @WorkingDir & '\au3pm\'))
    EndIf

    If DirRemove($tmp, 1) <> 1 Then Return SetError(5)
EndFunc

Func UninstallPackage($name)
    $path = @WorkingDir & '\au3pm\' & $name & '\'
    If Not FileExists($path) Then Return SetError(1)
    DirRemove($path)
EndFunc
