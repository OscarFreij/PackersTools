#include "version.iss"

#define AppName "PackersTools"
#define AppSourceDir "..\build\app"
#define IconSourceDir "..\src\icons"
#define ExternalBinDir "..\externalBins"

#define CommandStoreEntryPrefix "PackersTools"
#define CommandStorePath "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell"
#define ContextDirectoryPath "SOFTWARE\Classes\Directory\Background\shell\PackersTools"
#define ContextFolderPath "SOFTWARE\Classes\Folder\shell\PackersTools"

[Setup]
AppId=f0fedeaf-cfbf-45cb-93ad-27f255783d13
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=OscarFreij
AppPublisherURL=https://github.com/OscarFreij/PackersTools
AppSupportURL=https://github.com/OscarFreij/PackersTools/issues
AppUpdatesURL=https://github.com/OscarFreij/PackersTools/releases
DefaultDirName={autopf}\PackersTools
DefaultGroupName=PackersTools
DisableDirPage=auto
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\PackersTools.exe
CreateUninstallRegKey=yes
OutputBaseFilename=PackersTools-{#AppVersion}-Setup
Compression=lzma
SolidCompression=yes
LicenseFile=license.txt
Uninstallable=yes

;[Types]
;Name: "full"; Description: "Full installation (downloads latest PSADT v4 as template)";
;Name: "advanced"; Description: "Custom installation (choose template to copy from)";

[Dirs]
Name: "{app}\template"; Permissions: users-modify
Name: "{app}\icons";

[Files]
Source: "{#AppSourceDir}\PackersTools.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#AppSourceDir}\PackersTools.pdb"; DestDir: "{app}"; Flags: ignoreversion
Source: "license.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#ExternalBinDir}\IntuneWinAppUtil.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#IconSourceDir}\*"; DestDir: "{app}\icons"; Flags: ignoreversion

[Registry]
; Add CommandStore entries for context menu
; Build Package
Root: HKLM; Subkey: "{#CommandStorePath}\{#AppName}.BuildPackageDir"; Flags: uninsdeletekey
Root: HKLM; Subkey: "{#CommandStorePath}\{#AppName}.BuildPackageDir"; ValueType: string; ValueName: "MUIVerb"; ValueData: "Build Package Directory"; Flags: uninsdeletevalue
Root: HKLM; Subkey: "{#CommandStorePath}\{#AppName}.BuildPackageDir"; ValueType: string; ValueName: "Icon"; ValueData: """{app}\icons\build.ico"""; Flags: uninsdeletevalue
Root: HKLM; Subkey: "{#CommandStorePath}\{#AppName}.BuildPackageDir\command"; ValueType: string; ValueName: ""; ValueData: """{app}\PackersTools.exe"" build ""%V"""; Flags: uninsdeletevalue

; New Package
Root: HKLM; Subkey: "{#CommandStorePath}\{#AppName}.NewPackage"; Flags: uninsdeletekey
Root: HKLM; Subkey: "{#CommandStorePath}\{#AppName}.NewPackage"; ValueType: string; ValueName: "MUIVerb"; ValueData: "New Package"; Flags: uninsdeletevalue
Root: HKLM; Subkey: "{#CommandStorePath}\{#AppName}.NewPackage"; ValueType: string; ValueName: "Icon"; ValueData: """{app}\icons\add.ico"""; Flags: uninsdeletevalue
Root: HKLM; Subkey: "{#CommandStorePath}\{#AppName}.NewPackage\command"; ValueType: string; ValueName: ""; ValueData: """{app}\PackersTools.exe"" new ""%V"""; Flags: uninsdeletevalue

; Open Template Directory
Root: HKLM; Subkey: "{#CommandStorePath}\{#AppName}.Template"; Flags: uninsdeletekey
Root: HKLM; Subkey: "{#CommandStorePath}\{#AppName}.Template"; ValueType: string; ValueName: "MUIVerb"; ValueData: "Open Template Directory"; Flags: uninsdeletevalue
Root: HKLM; Subkey: "{#CommandStorePath}\{#AppName}.Template"; ValueType: string; ValueName: "Icon"; ValueData: """{app}\icons\cog.ico"""; Flags: uninsdeletevalue
Root: HKLM; Subkey: "{#CommandStorePath}\{#AppName}.Template\command"; ValueType: string; ValueName: ""; ValueData: """{app}\PackersTools.exe"" template ""%V"""; Flags: uninsdeletevalue


Root: HKLM; Subkey: "{#ContextDirectoryPath}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "{#ContextDirectoryPath}"; ValueType: string; ValueName: "MUIVerb"; ValueData: "PackersTools"; Flags: uninsdeletevalue
Root: HKLM; Subkey: "{#ContextDirectoryPath}"; ValueType: string; ValueName: "SubCommands"; ValueData:"{#AppName}.BuildPackageDir;{#AppName}.NewPackage;|;{#AppName}.Template"; Flags: uninsdeletevalue

Root: HKLM; Subkey: "{#ContextFolderPath}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "{#ContextFolderPath}"; ValueType: string; ValueName: "MUIVerb"; ValueData: "PackersTools"; Flags: uninsdeletevalue
Root: HKLM; Subkey: "{#ContextFolderPath}"; ValueType: string; ValueName: "SubCommands"; ValueData:"{#AppName}.BuildPackageDir;|;{#AppName}.Template"; Flags: uninsdeletevalue

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

#include "code.iss"