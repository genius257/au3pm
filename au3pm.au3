#include <WinAPIProc.au3>
#include <WinAPIFiles.au3>
#include <File.au3>
#include <Array.au3>
#include <InetConstants.au3>

#include "au3pm\au3json\json.au3"
#include "au3pm\semver\SemVer.au3"
#include "au3pm\html\HTMLParser.au3"

#include "misc\File.au3"

FileInstall("7za.exe" , @ScriptDir & "\7za.exe")

;FIXME: support au3pm-lock.json

Global Const $registry = "https://raw.githubusercontent.com/au3pm/action-test/master/"

Global Const $__au3pm_json_path = @WorkingDir & "\au3pm.json"
Global Const $__au3pm_lock_path = @WorkingDir & "\au3pm-lock.json"

Global $commands = [ _
    'build', _
    'config', _
    'help', _
    'init', _
    'install', _
    'list', _
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
        Case 'build'
            #include "./commands/build.au3"
        Case 'config'
            #include "./commands/config.au3"
        Case 'help', ''
            ConsoleWriteLine('usage: au3pm (command)'&@CRLF)
            ConsoleWriteLine('Where (command) is one of: ')
            ConsoleWriteLine('    ' & _ArrayToString($commands, ', '))
        Case 'init'
            #include "./commands/init.au3"
        Case 'install'
            #include "./commands/install.au3"
        Case 'list'
            #include "./commands/list.au3"
        Case 'rebuild'
            #include "./commands/rebuild.au3"
        Case 'restart'
            #include "./commands/restart.au3"
        Case 'run'
            #include "./commands/run.au3"
        Case 'start'
            #include "./commands/start.au3"
        Case 'stop'
            #include "./commands/stop.au3"
        Case 'test'
            #include "./commands/test.au3"
        Case 'uninstall'
            #include "./commands/uninstall.au3"
        Case 'update'
            #include "./commands/update.au3"
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
        Local Static $directory = json_parse(json_lex(BinaryToString(InetRead($registry & "au3pm.json", $INET_FORCEBYPASS))))[0]
        Local $pathName = $directory.Item($name)
        Local $packageDirectory = json_parse(json_lex(BinaryToString(InetRead(StringFormat("%s%s/%s", $registry, $name, "au3pm.json"), $INET_FORCEBYPASS))))[0]
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
            Local $range = $entry.Item($keyEntry)
            Local $package = fetchPackage($keyEntry, $range)
            Local $maxSatisfying = $package[1]
            #cs
            Local $packageDirectory = json_parse(json_lex(BinaryToString(InetRead(StringFormat("%s%s/%s", $registry, $keyEntry, "au3pm.json"), $INET_FORCEBYPASS))))[0]
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

#cs
# fetch autoit with resolved reference.
#
# Getting AutoIt version with au3pm is a special case, so this function is made to handle this special case.
# @deprecated
#ce
Func fetchAutoIt($reference)
    If StringRegExp($reference, "^(>=)?[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$", $STR_REGEXPMATCH) = 0 Then Return SetError(1)
    Local $result = fetchAutoIt3(StringRegExpReplace($reference, "^(>=)?[0-9]+\.", "$1", 1))
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
    Local $versions = json_parse(json_lex(BinaryToString(InetRead('https://api.github.com/repos/genius257/au3pm/releases'))))[0]
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

    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "DisplayIcon", "REG_SZ", @LocalAppDataDir&"\au3pm\au3pm.exe")
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "DisplayName", "REG_SZ", "AutoIt3 Package Manager")
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "DisplayVersion", "REG_SZ", FileGetVersion(@ScriptFullPath))
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "EstimatedSize", "REG_DWORD", FileGetSize(@ScriptFullPath))
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "HelpLink", "REG_SZ", "https://github.com/genius257/au3pm/issues/")
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "InstallDate", "REG_SZ", StringFormat("%04i%02i%02i", @YEAR, @MON, @MDAY))
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "InstallLocation", "REG_SZ", @LocalAppDataDir&"\au3pm\")
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "MajorVersion", "REG_DWORD", 0)
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "MinorVersion", "REG_DWORD", 1)
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "NoModify", "REG_DWORD", 1)
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "NoRepair", "REG_DWORD", 1)
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "Publisher", "REG_SZ", "Anders Pedersen")
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "QuietUninstallString", "REG_SZ", '"'&@LocalAppDataDir&'\au3pm\au3pm.exe" uninstall au3pm -g -q')
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "UninstallString", "REG_SZ", '"'&@LocalAppDataDir&'\au3pm\au3pm.exe" uninstall au3pm -g')
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "URLInfoAbout", "REG_SZ", "https://github.com/genius257/au3pm/")
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "URLUpdateInfo", "REG_SZ", "https://github.com/genius257/au3pm/releases/latest/")
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "VersionMajor", "REG_DWORD", 0)
    RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\au3pm", "VersionMinor", "REG_DWORD", 1)
EndFunc

Func _au3pm_addCommand()
    #cs
    RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\au3pm.exe", "")
    If @error = 0 Then Return SetError(1);the registry key already exists!
    RegWrite("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\au3pm.exe", "", "REG_SZ", @LocalAppDataDir&"\au3pm\au3pm.exe")
    RegWrite("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\au3pm.exe", "Path", "REG_SZ", @LocalAppDataDir&"\au3pm\")
    #ce
    Local $sPath = RegRead("HKEY_CURRENT_USER\Environment", "PATH") ;FIxME: currently key will not be made, if the key does not already exists.
    If @error <> 0 Then Return SetError(1)
    Local $iType = @extended
    If StringInStr($sPath, "\au3pm", @LocalAppDataDir&"\au3pm") Then Return SetError(2);the entry is already added!
    Local Static $aTypes = ["REG_NONE", "REG_SZ", "REG_EXPAND_SZ", "REG_BINARY", "REG_DWORD", "REG_DWORD_BIG_ENDIAN", "REG_LINK", "REG_MULTI_SZ", "REG_RESOURCE_LIST", "REG_FULL_RESOURCE_DESCRIPTOR", "REG_RESOURCE_REQUIREMENTS_LIST", "REG_QWORD"]
    Local $sType = Execute("$aTypes[$iType]")
    If @error <> 0 Then Return SetError(3)
    $sPath = StringRegExpReplace($sPath, ";$", "") & ";"&@LocalAppDataDir&"\au3pm;"
    RegWrite("HKEY_CURRENT_USER\Environment", "PATH", $sType, $sPath)
    If @error <> 0 Then Return SetError(4)
    EnvUpdate()
    If @error <> 0 Then Return SetError(5)
EndFunc

Func json_stringify($json)
    Local Static $CLSID_Dictionary = ObjName(ObjCreate("Scripting.Dictionary"), 6)
    Local Static $CLSID_ArrayList = ObjName(ObjCreate("System.Collections.ArrayList"), 6)
    Local $sJson = ""

    Switch VarGetType($json)
        Case "Array"
            $sJson = "["
            Local $value
            For $value In $json
                $sJson &= json_stringify($value) & ","
            Next
            $sJson = StringRegExpReplace($sJson, '[,]$', '') & "]"
        Case "Bool"
            $sJson = $json ? "true" : "false"
        Case "DLLStruct"
            $sJson = '"[object DLLStruct]"'
        Case "Int32", "Int64", "Double"
            $sJson = String($json)
        Case "Keyword"
            Switch $json
                Case Null
                    $sJson = "null"
                Case Default
                    $sJson = '""'
                Case Else
                    ContinueCase 2
            EndSwitch
        Case "Object"
            Switch ObjName($json, 6)
                Case $CLSID_ArrayList
                    $sJson = "["
                    Local $value
                    For $value In $json
                        $sJson &= json_stringify($value) & ","
                    Next
                    $sJson = StringRegExpReplace($sJson, '[,]$', '') & "]"
                Case $CLSID_Dictionary
                    $sJson &= "{"
                    Local $key
                    For $key In $json
                        $sJson &= json_stringify($key) & ':' & json_stringify($json.Item($key)) & ","
                    Next
                    $sJson = StringRegExpReplace($sJson, '[,]$', '') & "}"
                Case Else
                    Return StringFormat('"[object %s]"', ObjName($json, 1))
            EndSwitch
        Case "String"
            $json = StringRegExpReplace($json, '\\|"', '\\$0');JSON escape string chars
            $sJson = StringFormat('"%s"', $json)
        Case Else
            ConsoleWrite(VarGetType($json)&@CRLF)
            Exit MsgBox(0, "", VarGetType($json))
    EndSwitch
    Return $sJson
EndFunc

Func au3pm_json_load($sFile = $__au3pm_json_path)
    Local $sJson = '{"version":"1.0.0","name":"","description":"","author":"","main":"","dependencies":{},"scripts":{},"licence":""}'
    If FileExists($sFile) Then
        $sJson = FileRead($sFile)
    EndIf
    Return json_parse(json_lex($sJson))[0]
EndFunc

Func au3pm_json_save($json)
    If Not IsString($json) Then
        $json = json_stringify($json)
    EndIf

    Local $hFile = FileOpen($__au3pm_json_path, 2)
    FileWrite($hFile, $json)
    FileClose($hFile)
EndFunc

Func au3pm_lock_load($sFile = $__au3pm_lock_path)
    Local $sJson = '{"hash":"","packages":{},"packages-dev":{}}'
    If FileExists($sFile) Then
        $sJson = FileRead($sFile)
    EndIf
    Return json_parse(json_lex($sJson))[0]
EndFunc

Func au3pm_lock_save($json)
    If Not IsString($json) Then
        $json = json_stringify($json)
    EndIf

    Local $hFile = FileOpen($__au3pm_lock_path, 2)
    FileWrite($hFile, $json)
    FileClose($hFile)
EndFunc
