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

If Not IsDeclared('registry') Then Global Const $registry = "https://raw.githubusercontent.com/au3pm/action-test/master/"

Func fetchPackage($name, $reference)
    ; In a pure JS fashion, if it looks like a path, it must be a path.
    If StringRegExp($reference, "^(/|\./|\.\./)", 0) Then Return FileRead($reference)

    $protocol = StringRegExp($name, "^([a-zA-Z+-9]+):(.*)", $STR_REGEXPARRAYMATCH)
    If @error = 0 Then
        Switch $protocol[0]
            Case 'github'
                __SemVer_ConditionParse($reference)
                If @error = 0 Then
                    $tags = _GitHub_GetTags(StringLeft($protocol[1], StringInStr($protocol[1], "/") - 1), StringMid($protocol[1], StringInStr($protocol[1], "/") + 1))
                    If @error <> 0 Then Return ConsoleWrite("ERROR: "&@error&@CRLF)
                    Local $versions = MapKeys($tags)
                    Local $maxSatisfying = _semver_MaxSatisfying($versions, $reference)
                    Local $return[]
                    $return['name'] = $protocol[1]
                    $return['reference'] = $reference
                    $return['url'] = $tags[$maxSatisfying].zipball_url
                    Return $return
                EndIf
                Local $return[]
                $return['name'] = $protocol[1]
                $return['reference'] = $reference
                $return['url'] = StringFormat('https://github.com/%s/archive/%s.zip', $protocol[1], $reference)
                ;Local $return = [$name, $reference, StringFormat('https://github.com/%s/archive/%s.zip', $protocol[1], $reference)]
                Return $return
            Case Else
                Return SetError(1, 0, StringFormat('Unsupported protocol: "%s" for dependency "%s"', $protocol[0], $protocol[1]))
        EndSwitch
    EndIf

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
        Local $pathName = $directory[$name]
        Local $sJson = StringStripWS(BinaryToString(InetRead(StringFormat("%s%s/%s", $registry, $name, "au3pm.json"), $INET_FORCEBYPASS)), BitOR($STR_STRIPLEADING, $STR_STRIPTRAILING))
        Local $packageDirectory = _json_decode($sJson)
        Local $versions = MapKeys($packageDirectory['versions'])
        Local $maxSatisfying = _semver_MaxSatisfying($versions, $reference)
        Local $sha = $packageDirectory['versions'][$maxSatisfying]
        Local $repo = $packageDirectory['repo']
        Local $return[]
        $return['name'] = $name
        $return['reference'] = $maxSatisfying
        $return['url'] = fetchPackage($name, StringFormat('https://github.com/%s/archive/%s.zip', $repo, $sha))
        Return $return
    EndIf

    Return $reference
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
            If MapExists($resolvedDependencies, $package['name']) Then
                ConsoleWrite("Package name collision: "&$package['name']&@CRLF)
                Return SetError(6)
            EndIf
            Local $maxSatisfying = $package['reference']
            #cs
            Local $packageDirectory = _json_decode(BinaryToString(InetRead(StringFormat("%s%s/%s", $registry, $key, "au3pm.json"), $INET_FORCEBYPASS)))
            Local $range = $entry.Item($key)
            Local $versions = $packageDirectory.Item('versions').keys
            Local $maxSatisfying = _SemVer_MaxSatisfying($versions, $range)
            #ce

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
            ;$resolvedDependency['integrity'] = 
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

            If RunWait(@ScriptDir & StringFormat('\7za.exe x -y -o"%s" "%s"', $tmp & '\out\', $tmp_file)) <> 0 Then
                Return SetError(3)
            EndIf

            #cs
            If DirMove(_FileListToArray($tmp&'\out\', '*', 2, True)[1], @WorkingDir & '\au3pm\'&$name&'\') <> 1 Then
                Return SetError(4)
            EndIf
            #ce

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
    $_sIntegrity = String($_sIntegrity)

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
