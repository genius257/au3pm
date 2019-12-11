#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile=build\au3pm.exe
#AutoIt3Wrapper_Outfile_x64=build\au3pm_x64.exe
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <WinAPIProc.au3>
#include <WinAPIFiles.au3>
#include <File.au3>
#include <Array.au3>
#include <InetConstants.au3>

#include "au3pm\au3json\json.au3"
#include "au3pm\semver\SemVer.au3"
#include "au3pm\html\HTMLParser.au3"

FileInstall("7za.exe" , @ScriptDir & "\7za.exe")

;FIXME: support au3pm-lock.json

Global Const $registry = "https://raw.githubusercontent.com/au3pm/action-test/master/"

Global $commands = [ _
    'bin', _
    'bugs', _
    'build', _
    'config', _
    'explore', _
    'help', _
    'init', _
    'install', _
    'list', _
    'pack', _
    'rebuild', _
    'restart', _
    'run', _
    'start', _
    'stop', _
    'test', _
    'uninstall', _
    'update', _
    'version' _
]

HttpSetUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:65.0) Gecko/20100101 Firefox/65.0')

ConsoleWriteLine('AutoIt3 package manager by genius257. Prebuild.')
ConsoleWriteLine('Disclaimer: this is a prebuild. NOTHING is guaranteed to work or be completed at this stage.')
ConsoleWriteLine()

au3pm($CmdLine)
Exit @error

Func au3pm($CmdLine = Null)
    If $CmdLine == Null Then Local $CmdLine = [0]
    Local $command = $CmdLine[0] > 0 ? $CmdLine[1] : ''
    $command = StringLower($command)

    Switch ($command)
        Case 'bin' ;FIXME: review
        Case 'bugs' ;FIXME: review
        Case 'build'
            #include "./commands/build.au3"
        Case 'config'
            #include "./commands/config.au3"
        Case 'explore' ;FIXME: review
        Case 'help', ''
            ConsoleWriteLine('usage: au3pm (command)'&@CRLF)
            ConsoleWriteLine('Where (command) is one of: ')
            ConsoleWriteLine('    ' & _ArrayToString($commands, ', '))
        Case 'init'
            #include "./commands/init.au3"
        Case 'install'
            #include "./commands/install.au3"
        Case 'list' ;FIXME: implement
        Case 'pack' ;FIXME: review
        Case 'rebuild' ;FIXME: review
        Case 'restart' ;FIXME: review
        Case 'run'
            #include "./commands/run.au3"
        Case 'start' ;FIXME: review
        Case 'stop' ;FIXME: review
        Case 'test'
            #include "./commands/test.au3"
        Case 'uninstall' ;FIXME: implement
        Case 'update' ;FIXME: implement
        Case 'version'
            #include "./commands/version.au3"
        Case Else
            ConsoleWriteLine(StringFormat('The command %s is not supported.', $command))
            Local $match
            Local $p, $q
            $p = levenshtein($command, $commands[0])
            $match = $commands[0]
            For $c In $commands
                $q = levenshtein($command, $c)
                If $q < $p Then
                    $match = $c
                    $p = $q
                EndIf
            Next
            ConsoleWriteLine(@CRLF&"Did you mean: "&$match)
    EndSwitch
EndFunc

Func ConsoleWriteLine($data='')
    ConsoleWrite($data&@CRLF)
EndFunc

Func ConsoleWriteErrorLine($data='')
    ConsoleWriteError($data&@CRLF)
EndFunc

Func levenshtein($a, $b); source: https://www.autoitscript.com/forum/topic/179886-comparing-strings/
    Local $i, $j, $cost, $d[1], $min1, $min2, $min3

    If StringLen($a) = 0 Then Return StringLen($b)
    If StringLen($b) = 0 Then Return StringLen($a)

    ReDim $d[StringLen($a) + 1][StringLen($b) + 1]

    For $i = 0 To StringLen($a)
        $d[$i][0] = $i
    Next

    For $j = 0 To StringLen($b)
        $d[ 0][$j] = $j
    Next

    For $i = 1 To StringLen($a)
        For $j = 1 To StringLen($b)
            $cost = (StringMid($a, $i, 1) = StringMid($b, $j, 1) ? 0 : 1)

            $min1 = $d[$i - 1][$j] + 1
            $min2 = $d[$i][$j - 1] + 1
            $min3 = $d[$i - 1][$j - 1] + $cost

            If $min1 <= $min2 And $min1 <= $min3 Then
                $d[$i][$j] = $min1
            ElseIf $min2 <= $min1 And $min2 <= $min3 Then
                $d[$i][$j] = $min2
            Else
                $d[$i][$j] = $min3
            EndIf
        Next
    Next

    Return $d[StringLen($a)][StringLen($b)]
EndFunc

Func fetchPackage($name, $reference)
    ;FIXME: if $name = "autoit", resolve reference with AutoIt's weird versioning and inject a au3pm.json into the extracted archive, for add symlink to bin folder and such.
    ; In a pure JS fashion, if it looks like a path, it must be a path.
    If StringRegExp($reference, "^(/|\./|\.\./)", 0) Then Return FileRead($reference)

    Switch StringLower($name)
        Case 'au3pm'
            $reference = fetchAu3pm($reference)
            If @error <> 0 Then Return SetError(@error)
        Case 'autoit'
            $reference = fetchAutoIt($reference)
            If @error <> 0 Then Return SetError(@error)
    EndSwitch

    If __SemVer_ConditionParse($reference) Or @error=0 Then; _SemVer_Valid($reference) Then
        Local Static $directory = json_parse(json_lex(BinaryToString(InetRead($registry & "au3pm.json", $INET_FORCEBYPASS))))[0]
        Local $pathName = $directory.Item($name)
        Local $packageDirectory = json_parse(json_lex(BinaryToString(InetRead(StringFormat("%s%s/%s", $registry, $name, "au3pm.json"), $INET_FORCEBYPASS))))[0]
        Local $versions = $packageDirectory.Item('versions').keys()
        Local $maxSatisfying = _semver_MaxSatisfying($versions, $reference)
        Local $sha = $packageDirectory.Item('versions').Item($maxSatisfying)
        Local $repo = $packageDirectory.Item('repo')
        Return fetchPackage($name, StringFormat('https://github.com/%s/archive/%s.zip', $repo, $sha))
    EndIf

    Return $reference
    Local $response = BinaryToString(InetRead($reference, 16))
    If @error<> 0 Then
        ConsoleWriteErrorLine(StringFormat('Couldn''''t fetch package "%s"', $response))
        Return SetError(1)
    EndIf

    Return $response
EndFunc

Func getPackageDependencyTree($dependencies)
    Local Static $directory = json_parse(json_lex(BinaryToString(InetRead($registry & "au3pm.json", $INET_FORCEBYPASS))))[0]
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
            Local $packageDirectory = json_parse(json_lex(BinaryToString(InetRead(StringFormat("%s%s/%s", $registry, $keyEntry, "au3pm.json"), $INET_FORCEBYPASS))))[0]
            Local $range = $entry.Item($keyEntry)
            Local $versions = $packageDirectory.Item('versions').keys
            Local $maxSatisfying = _SemVer_MaxSatisfying($versions, $range)
            Local $__ref = $resolvedDependencies.Keys()
            If _ArraySearch($__ref, $keyEntry) > -1 Then ;Not $resolvedDependencies.__get($keyEntry) = "" Then
                ;TODO: we need atleast the previous range to find a commen acceptable range (i would imagine all the ranges are needed)
                If Not _SemVer_Satisfies($resolvedDependencies.__get($keyEntry), $range) Then Exit MsgBox(0, "", "dependency version conflict")
                ContinueLoop
                ;solve diff, if possible or throw "exception"
            EndIf
            $resolvedDependencies.Add($keyEntry, $maxSatisfying)

            ;pretend we get package file from package with the version we matched
            Local $__ref = $directory.Keys()
            If _ArraySearch($__ref, $keyEntry) = -1 Then Exit MsgBox(0, "", "no match")
            Local $package = ObjCreate("Scripting.Dictionary"); FIXME: get au3json file from package repo
                $package.Add('dependencies', ObjCreate("Scripting.Dictionary")) ;NOTE: quickfix for not getting the au3json from the package repo
            $queue.Add($package.Item('dependencies'))
        Next
    WEnd

    return $resolvedDependencies
EndFunc

Func getPackageDependencies()
    ;
EndFunc

#cs
# fetch autoit with resolved reference.
#
# Getting AutoIt version with au3pm is a special case, so this function is made to handle this special case.
#ce
Func fetchAutoIt($reference)
    If StringRegExp($reference, "(?:[0-9]+\.)?([0-9]+\.[0-9]+\.[0-9]+)", 0) And IsArray(__SemVer_ConditionParse(StringRegExpReplace($reference, "(?:[0-9]+\.)?([0-9]+\.[0-9]+\.[0-9]+)", "$1"))) Then $reference = StringRegExpReplace($reference, "(?:[0-9]+\.)?([0-9]+\.[0-9]+\.[0-9]+)", "$1")
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
        If StringRegExp($sInnerText, "(?i)^autoit") And (Not StringRegExp($sInnerText, "(?i)docs")) And StringRegExp($sInnerText, "(?i)\.zip$") Then
            $aVersions[$iCount][0] = StringRegExp($sInnerText, "v(?:[0-9]+\.)?([0-9]+\.[0-9]+\.[0-9]+)", 1)[0]
            $aVersions[$iCount][1] = "https://www.autoitscript.com/autoit3/files/archive/autoit/" & _HTMLParser_Element_GetAttribute("href", $versions[$i])
            $iCount += 1
        EndIf
    Next
    ReDim $aVersions[$iCount][2]
    ;TODO: get autoit versions (release and beta), resolve reference, download and extract autoit, inject special au3pm.json file into extracted content, return path to folder?
    $sVersion = _SemVer_MaxSatisfying(_ArrayExtract($aVersions, 0, -1, 0, 0), $reference)
    For $i = 0 To UBound($aVersions, 1) - 1
        If $aVersions[$i][0] == $sVersion Then Return $aVersions[$i][1]
    Next
    Return SetError(1)
EndFunc

Func fetchAu3pm($reference)
    Local $versions = json_parse(json_lex(BinaryToString(InetRead('https://api.github.com/repos/genius257/au3pm/releases'))))
    Local $aVersions[$versions.Count][2]
    Local $i
    For $i = 0 To $versions.Count-1
        $aVersions[$i][0] = $versions.Item($i).Item('tag_name')
        $aVersions[$i][0] = $versions.Item($i).Item('assets').Item(0).Item('browser_download_url')
    Next
    Local $sVersion = _SemVer_MaxSatisfying(_ArrayExtract($aVersions, 0, -1, 0, 0), $reference)
    For $i = 0 To UBound($aVersions, 1) - 1
        If $aVersions[$i][0] == $sVersion Then Return $aVersions[$i][1]
    Next
    Return SetError(1)
EndFunc

#cs
# Generate au3pm tmp dir string
#
# @return string
#ce
Func generateTempDir()
    $tmp = @TempDir & '\' & StringFormat('au3pm %s-%s-%s %s-%s-%s %s', @MDAY, @MON, @YEAR, @HOUR, @MIN, @SEC, @MSEC); & '\'
    Return $tmp
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

    If DirMove(_FileListToArray($tmp&'\out\', '*', 2, True)[1], @WorkingDir & '\au3pm\'&$name&'\') <> 1 Then
        Return SetError(4)
    EndIf

    If DirRemove($tmp, 1) <> 1 Then Return SetError(5)

    ;FIXME: update au3pm.json
    ;FIXME: update au3pm.lock
EndFunc

Func ConsoleReadLineSync()
    Local $hFile = _WinAPI_CreateFile('CON', 2, 2)
    Local $input = ""
    Local $tBuffer = DllStructCreate('char')
    Local $nRead = 0
    While 1
        _WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer), 1, $nRead)
        If DllStructGetData($tBuffer, 1) = @CR Then ExitLoop
        If $nRead > 0 Then $input &= DllStructGetData($tBuffer, 1)
    WEnd
    FileClose($hFile)
    Return $input
EndFunc

Func _WindowsInstaller_registerSoftware()
    ;TODO: fix version information.
    RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "")
    ;If @error = 0 Then Return SetError(1);the registry key already exists!

    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "DisplayIcon", "REG_SZ", @LocalAppDataDir&"\Programs\au3pm\au3pm.exe")
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "DisplayName", "REG_SZ", "AutoIt3 Package Manager")
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "DisplayVersion", "REG_SZ", "0.1.0")
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "EstimatedSize", "REG_DWORD", FileGetSize(@ScriptFullPath))
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "HelpLink", "REG_SZ", "https://github.com/genius257/au3pm/issues/")
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "InstallDate", "REG_SZ", StringFormat("%04i%02i%02i", @YEAR, @MON, @MDAY))
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "InstallLocation", "REG_SZ", @LocalAppDataDir&"\Programs\au3pm\")
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "MajorVersion", "REG_DWORD", 0)
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "MinorVersion", "REG_DWORD", 1)
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "NoModify", "REG_DWORD", 1)
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "NoRepair", "REG_DWORD", 1)
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "Publisher", "REG_SZ", "Anders Pedersen")
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "QuietUninstallString", "REG_SZ", '"'&@LocalAppDataDir&'\Programs\au3pm\au3pm.exe" uninstall au3pm -g -q')
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "UninstallString", "REG_SZ", '"'&@LocalAppDataDir&'\Programs\au3pm\au3pm.exe" uninstall au3pm -g')
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "URLInfoAbout", "REG_SZ", "https://github.com/genius257/au3pm/")
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "URLUpdateInfo", "REG_SZ", "https://github.com/genius257/au3pm/releases/latest/")
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "VersionMajor", "REG_DWORD", 0)
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "VersionMinor", "REG_DWORD", 1)
EndFunc

Func _au3pm_addCommand()
    RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\au3pm.exe", "")
    If @error = 0 Then Return SetError(1);the registry key already exists!
    RegWrite("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\au3pm.exe", "", "REG_SZ", @LocalAppDataDir&"\Programs\au3pm\au3pm.exe")
    RegWrite("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\au3pm.exe", "Path", "REG_SZ", @LocalAppDataDir&"\Programs\au3pm\")
EndFunc
