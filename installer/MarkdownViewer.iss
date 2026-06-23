; ====================================================================
;  Inno Setup script for Markdown Viewer
;  Builds a friendly, per-user Setup.exe (no admin / UAC prompt).
;
;  Expects the published app in ..\publish  (MarkdownViewer.exe + Assets\).
;  Build it with:  installer\build.ps1
;  or directly:    iscc /DMyAppVersion=1.0.0 installer\MarkdownViewer.iss
; ====================================================================

#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif

#define MyAppName "Markdown Viewer"
#define MyAppPublisher "Markdown Viewer"
#define MyAppExeName "MarkdownViewer.exe"
#define MyProgId "MarkdownViewer.Document"

[Setup]
AppId={{8F2A9C44-3E7B-4A1D-9C0E-1A2B3C4D5E6F}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
VersionInfoVersion={#MyAppVersion}

; --- Per-user install: no administrator rights required ---
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
DefaultDirName={localappdata}\Programs\Markdown Viewer
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
DisableDirPage=auto

; --- Output ---
OutputDir=..\dist
OutputBaseFilename=MarkdownViewer-Setup-{#MyAppVersion}
SetupIconFile=..\install\icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
WizardStyle=modern
Compression=lzma2
SolidCompression=yes

; Tell the shell that file associations changed when we add/remove them.
ChangesAssociations=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "associate"; Description: "Associate .md and .markdown files with Markdown Viewer"; GroupDescription: "File associations:"
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: unchecked

[Files]
Source: "..\publish\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\publish\Assets\*"; DestDir: "{app}\Assets"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{userdesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
; ProgId definition (per-user). uninsdeletekey removes it all on uninstall.
Root: HKCU; Subkey: "Software\Classes\{#MyProgId}"; ValueType: string; ValueName: ""; ValueData: "Markdown Document"; Flags: uninsdeletekey; Tasks: associate
Root: HKCU; Subkey: "Software\Classes\{#MyProgId}"; ValueType: string; ValueName: "FriendlyTypeName"; ValueData: "Markdown Document"; Tasks: associate
Root: HKCU; Subkey: "Software\Classes\{#MyProgId}\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\{#MyAppExeName},0"; Tasks: associate
Root: HKCU; Subkey: "Software\Classes\{#MyProgId}\shell\open"; ValueType: string; ValueName: ""; ValueData: "Open with Markdown Viewer"; Tasks: associate
Root: HKCU; Subkey: "Software\Classes\{#MyProgId}\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""; Tasks: associate

; Associate the extensions. OpenWithProgids lists us; the default value makes us the handler.
Root: HKCU; Subkey: "Software\Classes\.md\OpenWithProgids"; ValueType: string; ValueName: "{#MyProgId}"; ValueData: ""; Flags: uninsdeletevalue; Tasks: associate
Root: HKCU; Subkey: "Software\Classes\.md"; ValueType: string; ValueName: ""; ValueData: "{#MyProgId}"; Flags: uninsdeletevalue; Tasks: associate
Root: HKCU; Subkey: "Software\Classes\.markdown\OpenWithProgids"; ValueType: string; ValueName: "{#MyProgId}"; ValueData: ""; Flags: uninsdeletevalue; Tasks: associate
Root: HKCU; Subkey: "Software\Classes\.markdown"; ValueType: string; ValueName: ""; ValueData: "{#MyProgId}"; Flags: uninsdeletevalue; Tasks: associate

[Run]
Description: "Launch {#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Flags: nowait postinstall skipifsilent
