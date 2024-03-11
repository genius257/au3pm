#include-once

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

;FIXME: add function for adding folder or exe to user or global enviroment resolving (see _au3pm_addCommand)
