; UTF-8
#define MyAppName "百战异闻录助手"
#define MyAppPublisher "lynn.game.jx3"
#define MyAppExeName "baizhan_skill.exe"
#define MyAppId "{A5C0B6B2-8AF3-4B3B-9A4F-6A4D2D83E6B7}"

#ifndef MyAppVersion
#define MyAppVersion "0.0.0"
#endif

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL=https://github.com/cyan77/baizhan-skill
AppSupportURL=https://github.com/cyan77/baizhan-skill/issues
AppUpdatesURL=https://github.com/cyan77/baizhan-skill/releases
DefaultDirName={code:GetDefaultInstallPath}
UsePreviousAppDir=yes
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=output
OutputBaseFilename=BaizhanSkill-Windows-x64-Setup
Compression=lzma
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
WizardStyle=modern
ChangesAssociations=no

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加快捷方式："; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "启动 {#MyAppName}"; Flags: nowait postinstall skipifsilent

[Code]
procedure CurStepChanged(CurStep: TSetupStep);
var
  MarkerFile: string;
begin
  if CurStep = ssPostInstall then
  begin
    MarkerFile := ExpandConstant('{app}\.baizhanskill-installed');
    SaveStringToFile(MarkerFile, 'installed', False);
  end;
end;

function TryGetPreviousInstallPath(RootKey: Integer; var InstallPath: string): Boolean;
var
  UninstallKey: string;
begin
  UninstallKey := 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppId}_is1';
  Result := RegQueryStringValue(RootKey, UninstallKey, 'InstallLocation', InstallPath);
  if not Result then
    Result := RegQueryStringValue(RootKey, UninstallKey, 'Inno Setup: App Path', InstallPath);
  Result := Result and (Trim(InstallPath) <> '');
end;

function GetDefaultInstallPath(Param: string): string;
var
  PreviousPath: string;
begin
  if TryGetPreviousInstallPath(HKEY_LOCAL_MACHINE, PreviousPath) then
  begin
    Result := PreviousPath;
    exit;
  end;
  if TryGetPreviousInstallPath(HKEY_CURRENT_USER, PreviousPath) then
  begin
    Result := PreviousPath;
    exit;
  end;
  Result := ExpandConstant('{autopf}\BaizhanSkill');
end;

[UninstallDelete]
Type: files; Name: "{app}\.baizhanskill-installed"
