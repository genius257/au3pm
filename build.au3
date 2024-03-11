#include <APIResConstants.au3>
#include <WinAPIRes.au3>
#include <Memory.au3>

#include "au3pm\au3json\json.au3"
#include "au3pm\semver\SemVer.au3"
#include "au3pm\html\HTMLParser.au3"

If $CmdLine[0] <= 1 Or Not FileExists($CmdLine[1]) Or Not FileExists($CmdLine[2]) Then Exit 1

$hInstance = _WinAPI_LoadLibraryEx($CmdLine[1], $LOAD_LIBRARY_AS_DATAFILE)

$hResource = _WinAPI_FindResourceEx($hInstance, $RT_VERSION, 1, 2057)
$iSize = _WinAPI_SizeOfResource($hInstance, $hResource)
$hData = _WinAPI_LoadResource($hInstance, $hResource)
$pData = _WinAPI_LockResource($hData)

$hData2 = _MemGlobalAlloc($iSize, $GMEM_MOVEABLE)
$pData2 = _MemGlobalLock($hData2)
_MemMoveMemory($pData, $pData2, $iSize)

_WinAPI_FreeLibrary($hInstance)

$tData = DllStructCreate("WORD wLength;WORD wValueLength;WORD wType;WCHAR szKey[16];WORD Padding1;BYTE Value[52];WORD Padding2;WORD Children;", $pData2)
$tFIXEDFILEINFO = DllStructCreate("DWORD dwSignature;DWORD dwStrucVersion;DWORD dwFileVersionMS;DWORD dwFileVersionLS;DWORD dwProductVersionMS;DWORD dwProductVersionLS;DWORD dwFileFlagsMask;DWORD dwFileFlags;DWORD dwFileOS;DWORD dwFileType;DWORD dwFileSubtype;DWORD dwFileDateMS;DWORD dwFileDateLS;", DllStructGetPtr($tData, "Value"))
#cs
MsgBox(0, "", StringFormat("File Version: %d.%d.%d.%d\n", _
	BitAND(BitShift($tFIXEDFILEINFO.dwFileVersionMS, 16), 0xffff), _
	BitAND(BitShift($tFIXEDFILEINFO.dwFileVersionMS, 0), 0xffff), _
	BitAND(BitShift($tFIXEDFILEINFO.dwFileVersionLS, 16), 0xffff), _
	BitAND(BitShift($tFIXEDFILEINFO.dwFileVersionLS, 0), 0xffff) _
))
#ce

$json = au3pm_json_load($CmdLine[2])

$version = $json.Item("version")
$semver = StringRegExp($version, "^(\d+)\.(\d+)\.(\d+)$", 1)

$major = Int(Execute("$semver[0]"))
$minor = Int(Execute("$semver[1]"))
$patch = Int(Execute("$semver[2]"))
$revision = 0

$tFIXEDFILEINFO.dwFileVersionMS = BitOR(BitShift(BitAND($major, 0xffff), -16), BitShift(BitAND($minor, 0xffff), -0))
$tFIXEDFILEINFO.dwFileVersionLS = BitOR(BitShift(BitAND($patch, 0xffff), -16), BitShift(BitAND($revision, 0xffff), -0))

$tFIXEDFILEINFO.dwProductVersionMS = BitOR(BitShift(BitAND($major, 0xffff), -16), BitShift(BitAND($minor, 0xffff), -0))
$tFIXEDFILEINFO.dwProductVersionLS = BitOR(BitShift(BitAND($patch, 0xffff), -16), BitShift(BitAND($revision, 0xffff), -0))

$hUpdate = _WinAPI_BeginUpdateResource($CmdLine[1], False)
$bSuccess = _WinAPI_UpdateResource($hUpdate, $RT_VERSION, 1, 2057, $pData2, $iSize)
_WinAPI_EndUpdateResource($hUpdate, False)

_memGlobalUnLock($pData2)
_memGlobalFree($hData2)
