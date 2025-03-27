#include-once
#include <InetConstants.au3>
#include <StringConstants.au3>
#include <File.au3>
#include <Crypt.au3>
#include "file.au3"
#include "config.au3"
#include "repository.au3"
#include "../../au3pm/au3json/json.au3"
#include "../../au3pm/semver/SemVer.au3"
#include "github.au3"
#include "path.au3"

If Not IsDeclared('registry') Then Global Const $registry = "https://raw.githubusercontent.com/au3pm/action-test/master/"

Func fetchPackage($name, $reference)
    ; In a pure JS fashion, if it looks like a path, it must be a path.
    If StringRegExp($reference, "^(/|\./|\.\./)", 0) Then Return FileRead($reference); TODO: this may need to be removed

    If Not ValidatePackageName($name) Then
        ConsoleWriteError('Invalid package name: "' & $name & '"' & @CRLF)
        Return SetError(1)
    EndIf

    ; Special cases, hard-coded dependencies
    Switch $name
        Case 'au3pm'
            $reference = fetchAu3pm($reference)
            If @error <> 0 Then Return SetError(@error)
            Return $reference
        Case 'autoit'
            ConsoleWrite('WARNING: au3pm dependency "autoit" is deprecated. please use "autoit3" instead to allow version ranges.'&@CRLF)
            $reference = fetchAutoIt($reference)
            If @error <> 0 Then Return SetError(@error)
            Return $reference
        Case 'autoit1'
            $reference = fetchAutoIt1($reference)
            If @error <> 0 Then Return SetError(@error)
            Return $reference
        Case 'autoit2'
            $reference = fetchAutoIt2($reference)
            If @error <> 0 Then Return SetError(@error)
            Return $reference
        Case 'autoit3'
            $reference = fetchAutoIt3($reference)
            If @error <> 0 Then Return SetError(@error)
            Return $reference
    EndSwitch

    Select
        Case _shlwapi_PathIsURLW($reference)
            Local $return[]
            $return['name'] = $name
            $return['reference'] = $reference
            $return['url'] = $reference
            Return $return
        Case StringRegExp($reference, '(?i)^[0-9a-f]{7}|[0-9a-f]{40}$', 0); commit hash reference
            Local $return[]
            $return['name'] = $name
            $return['reference'] = $reference
            $return['url'] = 'https://github.com/' & $name & '/archive/' & $reference & '.zip'
            Return $return
        Case _SemVer_ValidRange($reference)
            ;Legacy support for dependencies that previously was available via an online global registry
            Switch $name
                Case 'au3json'
                    Local $package = fetchPackage('genius257/au3json', $reference)
                    If @error <> 0 Then Return SetError(@error)
                    $package['name'] = $name
                    Return $package
                Case 'au3obj'
                    Local $package = fetchPackage('genius257/AutoItObject-Internal', $reference)
                    If @error <> 0 Then Return SetError(@error)
                    $package['name'] = $name
                    Return $package
                Case 'semver'
                    Local $package = fetchPackage('genius257/au3-semver', $reference)
                    If @error <> 0 Then Return SetError(@error)
                    $package['name'] = $name
                    Return $package
                Case 'StringRegExpSplit'
                    Local $package = fetchPackage('genius257/StringRegExpSplit', $reference)
                    If @error <> 0 Then Return SetError(@error)
                    $package['name'] = $name
                    Return $package
                Case 'au3unit'
                    Local $package = fetchPackage('genius257/au3unit', $reference)
                    If @error <> 0 Then Return SetError(@error)
                    $package['name'] = $name
                    Return $package
                Case 'au3class'
                    Local $package = fetchPackage('genius257/au3class', $reference)
                    If @error <> 0 Then Return SetError(@error)
                    $package['name'] = $name
                    Return $package
                Case 'acro.au3'
                    Local $package = fetchPackage('seadoggie01/Acro.au3', $reference)
                    If @error <> 0 Then Return SetError(@error)
                    $package['name'] = $name
                    Return $package
                Case 'LinkedList'
                    Local $package = fetchPackage('genius257/au3LinkedList', $reference)
                    If @error <> 0 Then Return SetError(@error)
                    $package['name'] = $name
                    Return $package
            EndSwitch

            If Not StringRegExp($name, "^[a-zA-Z0-9-]+\/[a-zA-Z0-9-_.]+$", $STR_REGEXPMATCH) Then
                ConsoleWriteError("Invalid github package name: " & $name & @CRLF)
                Return SetError(1)
            EndIf

            $mTags = _GitHub_GetTags(StringLeft($name, StringInStr($name, "/") - 1), StringMid($name, StringInStr($name, "/") + 1))
            For $tag In MapKeys($mTags)
                If Not _SemVer_Valid($tag) Then MapRemove($mTags, $tag)
            Next
            $maxSatisfying = _semver_MaxSatisfying(MapKeys($mTags), $reference)
            If $maxSatisfying = Null Then
                ConsoleWrite("ERROR: No matching version found for: "&$name&"@"&$reference&@CRLF)
            EndIf
            Local $return[]
            $return['name'] = $name
            $return['reference'] = $maxSatisfying
            $return['url'] = $mTags[$maxSatisfying].zipball_url
            Return $return
        Case Else
            ConsoleWrite("invalid dependecy: "&$name&"@"&$reference&@CRLF)
    EndSelect
    Return SetError(1)
EndFunc

Func getPackageDependencyTree($dependencies)
    Local Static $directory = _json_decode(BinaryToString(InetRead($registry & "au3pm.json", $INET_FORCEBYPASS)))
    Local $resolvedDependencies[]
    Local $iQueueSize = 1
    Local $iQueuePosition = 0
    Local $aQueue[16]
    $aQueue[0] = $dependencies

    While 1
        If $iQueueSize <= $iQueuePosition Then ExitLoop
        Local $entry = $aQueue[$iQueuePosition]
        $iQueuePosition += 1
        For $key In MapKeys($entry)
            Local $range = $entry[$key]
            Local $package = fetchPackage($key, $range)
            If @error <> 0 Then
                ConsoleWrite("Failed to fetch package: "&$key&"@"&$range&@CRLF)
                Return SetError(7)
            EndIf
            Local $maxSatisfying = $package['reference']

            If MapExists($resolvedDependencies, $key) Then
                If $key = "AutoIt" Then $range = StringRegExpReplace($range, "(?:[0-9]+\.)?([0-9]+\.[0-9]+\.[0-9]+)", "$1")
                ;TODO: we need atleast the previous range to find a commen acceptable range (i would imagine all the ranges are needed)
                If Not _SemVer_Satisfies($resolvedDependencies[$key], $range) Then
                    Exit MsgBox(0, "", "dependency version conflict");FIXME: retrun error isntead
                EndIf
                ContinueLoop
                ;solve diff, if possible or throw "exception"
            EndIf
            Local $resolvedDependency[]
            $resolvedDependency['version'] = $maxSatisfying
            $resolvedDependency['url'] = $package['url']
            $resolvedDependencies[$package['name']] = $resolvedDependency

            ;pretend we get package file from package with the version we matched
            ;Local $__ref = $directory.Keys()
            ;_ArrayDisplay($__ref)
            ;If _ArraySearch($__ref, $key) = -1 Then Exit MsgBox(0, "", "no match")
            ;Local $package = ObjCreate("Scripting.Dictionary"); FIXME: get au3json file from package repo
            ;    $package.Add('dependencies', ObjCreate("Scripting.Dictionary")) ;NOTE: quickfix for not getting the au3json from the package repo
            ;$queue.Add($package.Item('dependencies'))

            If $key = "autoit" Or $key = "autoit1" Or $key = "autoit2" Or $key = "autoit3" Then ContinueLoop

            Local $tmp = generateTempDir()
            If DirCreate($tmp) <> 1 Then Return SetError(1)

            Local $tmp_file = _TempFile($tmp, '~')
            ;Local $tmp_file = $tmp & '\files\' & ''

            ;Downloading

            ConsoleWrite("Downloading url: " & $package['url'] & @CRLF)
            InetGet($package['url'], $tmp_file, $INET_FORCEBYPASS, $INET_DOWNLOADWAIT)
            If @error <> 0 Then
                ConsoleWrite('Download failed!'&@CRLF)
                Return SetError(2)
            EndIf

            ;Extracting...

            If RunWait(@ScriptDir & StringFormat('\7za.exe x -bso0 -y -o"%s" "%s"', $tmp & '\out\', $tmp_file)) <> 0 Then
                Return SetError(3)
            EndIf

            Local $sFile = _FileListToArray($tmp&'\out\', '*', 2, True)[1]&'\au3pm.json'
            If FileExists($sFile) Then
                local $json = _json_decode(StringStripWS(FileRead($sFile), BitOR($STR_STRIPLEADING, $STR_STRIPTRAILING)))
                If @error <> 0 Then Return SetError(@error, @extended, $json)
                $iQueueSize += 1
                If $iQueueSize >= UBound($aQueue) Then Redim $aQueue[UBound($aQueue)*2]
                $aQueue[$iQueueSize - 1] = $json['dependencies']
            EndIf

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
Func InstallPackage($url, $name, $bInstallDependencies = False, $sIntegrity = Null)
    Local $tmp = generateTempDir()
    If DirCreate($tmp) <> 1 Then Return SetError(1)

    Local $tmp_file = _TempFile($tmp, '~')

    ;Downloading

    InetGet($url, $tmp_file, 16, 0)
    If @error <> 0 Then
        Return SetError(2)
    EndIf

    Local $_sIntegrity = _Crypt_HashFile($tmp_file, $CALG_SHA1)
    If @error <> 0 Then
        ConsoleWrite(StringFormat("Error occured when generating package hash for: %s\n", $name))
        Return SetError(7)
    EndIf
    $_sIntegrity = StringMid(String($_sIntegrity), 3); Remove leading "0x"

    If (Not ($sIntegrity = Null)) And (Not ($sIntegrity == $_sIntegrity)) Then
        ConsoleWrite(StringFormat("Package integrity check failed for: ""%s"". ""%s"" != ""%s""\n", $name, $sIntegrity, $_sIntegrity))
        Return SetError(6)
    EndIf

    ;Extracting...

    If RunWait(@ScriptDir & StringFormat('\7za.exe x -bso0 -y -o"%s" "%s"', $tmp & '\out\', $tmp_file)) <> 0 Then
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

    Return $_sIntegrity
EndFunc

Func UninstallPackage($name)
    $path = @WorkingDir & '\au3pm\' & $name & '\'
    If Not FileExists($path) Then Return SetError(1)
    DirRemove($path)
EndFunc

Func ValidatePackageName($name)
    Return StringRegExp($name, '(?(DEFINE)(?<segment>(?:[^\\\/:*?"<>|.]+|\.(?!\.))+))^(?&segment)(?:\/(?&segment))*$', $STR_REGEXPMATCH) = 1
EndFunc
