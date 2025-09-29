; DCS Overlay Installer Script for Inno Setup
; Download Inno Setup from: https://jrsoftware.org/isdl.php

#define MyAppName "DCS Overlay"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "№15 | KillerDog"
#define MyAppURL "https://github.com/Dillen198/DCS-OVERLAYER"
#define MyAppExeName "DCS-Overlay.exe"

[Setup]
AppId={{DCS-OVERLAY-UNIQUE-ID}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=release
OutputBaseFilename=DCS-Overlay-Setup-v{#MyAppVersion}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\{#MyAppExeName}
PrivilegesRequired=lowest

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1; Check: not IsAdminInstallMode

[Files]
Source: "dist\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\overlay.html"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\Export.lua"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\mappings\*"; DestDir: "{app}\mappings"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "dist\images\*"; DestDir: "{app}\images"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
var
  DCSPathPage: TInputDirWizardPage;
  
procedure InitializeWizard;
begin
  // Create custom page for DCS path selection
  DCSPathPage := CreateInputDirPage(wpSelectDir,
    'Select DCS Installation', 'Where is your DCS Saved Games folder?',
    'Setup will automatically install the Export.lua script to your DCS installation.' + #13#10 +
    'Select your DCS Saved Games folder, then click Next.',
    False, '');
  DCSPathPage.Add('');
  
  // Try to auto-detect DCS path
  if DirExists(ExpandConstant('{userdocs}\Saved Games\DCS')) then
    DCSPathPage.Values[0] := ExpandConstant('{userdocs}\Saved Games\DCS')
  else if DirExists(ExpandConstant('{userdocs}\Saved Games\DCS.openbeta')) then
    DCSPathPage.Values[0] := ExpandConstant('{userdocs}\Saved Games\DCS.openbeta')
  else
    DCSPathPage.Values[0] := ExpandConstant('{userdocs}\Saved Games\DCS');
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  DCSPath: string;
  ScriptsPath: string;
  ExportPath: string;
  BackupPath: string;
  ExistingContent: AnsiString;
  NewContent: AnsiString;
  BackupNum: Integer;
begin
  if CurStep = ssPostInstall then
  begin
    DCSPath := DCSPathPage.Values[0];
    ScriptsPath := DCSPath + '\Scripts';
    ExportPath := ScriptsPath + '\Export.lua';
    BackupPath := ScriptsPath + '\Export.lua.backup';
    
    // Create Scripts directory if it doesn't exist
    if not DirExists(ScriptsPath) then
      CreateDir(ScriptsPath);
    
    // Check if Export.lua already exists
    if FileExists(ExportPath) then
    begin
      // Read existing content
      if LoadStringFromFile(ExportPath, ExistingContent) then
      begin
        // Check if our overlay is already installed
        if Pos('DCS-OVERLAY', ExistingContent) > 0 then
        begin
          MsgBox('DCS Overlay Export.lua is already installed.' + #13#10 + 
                 'Skipping installation to preserve your configuration.', 
                 mbInformation, MB_OK);
        end
        else
        begin
          // Create backup with unique name if backup already exists
          BackupNum := 1;
          while FileExists(BackupPath) do
          begin
            BackupPath := ScriptsPath + '\Export.lua.backup' + IntToStr(BackupNum);
            BackupNum := BackupNum + 1;
          end;
          
          // Save backup
          SaveStringToFile(BackupPath, ExistingContent, False);
          
          // Append our Export.lua to existing file
          if LoadStringFromFile(ExpandConstant('{app}\Export.lua'), NewContent) then
          begin
            // Add a separator and our content
            ExistingContent := ExistingContent + #13#10 + 
                              '-- DCS Overlay Export Script (Auto-installed)' + #13#10 +
                              NewContent;
            
            SaveStringToFile(ExportPath, ExistingContent, False);
            
            MsgBox('DCS Overlay has been added to your existing Export.lua.' + #13#10 +
                   'Your previous Export.lua has been backed up to:' + #13#10 +
                   BackupPath + #13#10#13#10 +
                   'Location: ' + ExportPath, 
                   mbInformation, MB_OK);
          end;
        end;
      end;
    end
    else
    begin
      // No existing Export.lua, just copy ours
      if LoadStringFromFile(ExpandConstant('{app}\Export.lua'), NewContent) then
      begin
        SaveStringToFile(ExportPath, NewContent, False);
        
        MsgBox('Export.lua has been installed to:' + #13#10 + ExportPath + #13#10#13#10 +
               'You can now run DCS Overlay from the Start Menu or Desktop shortcut.', 
               mbInformation, MB_OK);
      end;
    end;
  end;
end;