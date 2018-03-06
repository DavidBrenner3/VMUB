program Virtual_Machine_USB_Boot;

uses
  Forms,
  ShellApi,
  Windows,
  ProcessViewer,
  Messages,
  Math,
  Sysutils,
  Classes,
  Dialogs,
  Controls,
  VirtualTrees,
  Vcl.StdCtrls,
  System.Uitypes,
  MainForm in 'MainForm.pas' {frmMain},
  AddEdit in 'AddEdit.pas' {frmAddEdit},
  Options in 'Options.pas' {frmOptions},
  uPrestartThread in 'uPrestartThread.pas',
  uPrecacheThread in 'uPrecacheThread.pas',
  uEjectThread in 'uEjectThread.pas',
  uFLDThread in 'uFLDThread.pas',
  uRegisterThread in 'uRegisterThread.pas',
  uUnregisterThread in 'uUnregisterThread.pas';

// {$R *.res}
{$R AdminComctl6.res}
{$R Languages.res}
{$R MainIcon.res}
{$R VersionInfo.res}
{$SETPEFLAGS IMAGE_FILE_RELOCS_STRIPPED}

function CheckTokenMembership(TokenHandle: THandle; SidToCheck: PSID; var IsMember: BOOL): BOOL; stdcall; external advapi32;

function IsNotUserAdmin: Boolean;
const
   SECURITY_NT_AUTHORITY: TSIDIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 5));
   SECURITY_BUILTIN_DOMAIN_RID = $00000020;
   DOMAIN_ALIAS_RID_ADMINS = $00000220;
var
   b: BOOL;
   AdministratorsGroup: PSID;
begin
   b := AllocateAndInitializeSid(SECURITY_NT_AUTHORITY, 2, // 2 sub-authorities
      SECURITY_BUILTIN_DOMAIN_RID, // sub-authority 0
      DOMAIN_ALIAS_RID_ADMINS, // sub-authority 1
      0, 0, 0, 0, 0, 0, // sub-authorities 2-7 not passed
      AdministratorsGroup);
   if (b) then
   begin
      if not CheckTokenMembership(0, AdministratorsGroup, b) then
         b := False;
      FreeSid(AdministratorsGroup);
   end;

   Result := not b;
end;

function SHGetFolderPathW(Ahwnd: HWND; Csidl: longint; Token: THandle; Flags: DWord; Path: PWideChar): HRESULT; stdcall; external 'SHFolder.dll';

function GetSpecialFolderPath(folder: integer): string;
const
   SHGFP_TYPE_CURRENT = 0;
var
   Path: array[0..MAX_PATH] of WideChar;
begin
   try
      if SUCCEEDED(SHGetFolderPathW(0, folder, 0, SHGFP_TYPE_CURRENT, @Path[0])) then
         Result := Path
      else
         Result := '';
   except
      Result := '';
   end;
end;

const
   CSIDL_APPDATA = $001A;

var
   i: integer;
   Appdata, AppGenExePath: string;
   ThreadID: THandle;

label
   TryAgain;

begin
   Application.Initialize;
   Application.MainFormOnTaskbar := False;
   Application.Title := 'Virtual Machine USB Boot';
   isInstalledVersion := False;

   {$IFDEF WIN32}
   AppGenExePath := ExtractFilePath(ParamStr(0)) + StringReplace(StringReplace(ExtractFileName(ParamStr(0)), '_', ' ', [rfReplaceAll, rfIgnoreCase]), '.x86.exe', '.exe', [rfIgnoreCase]);
   {$ENDIF}
   {$IFDEF WIN64}
   AppGenExePath := ExtractFilePath(ParamStr(0)) + StringReplace(StringReplace(ExtractFileName(ParamStr(0)), '_', ' ', [rfReplaceAll, rfIgnoreCase]), '.x64.exe', '.exe', [rfIgnoreCase]);
   {$ENDIF}
   if isInstalledVersion then
   begin
      Appdata := GetSpecialFolderPath(CSIDL_APPDATA);
      if Appdata = '' then
         VMentriesFile := AppGenExePath
      else
         VMentriesFile := Appdata + '\' + ChangeFileExt(ExtractFileName(AppGenExePath), '') + '\' + ExtractFileName(AppGenExePath);
   end
   else
      VMentriesFile := AppGenExePath;

   CfgFile := ChangeFileExt(VMentriesFile, '.cfg');
   VMentriesFile := ChangeFileExt(VMentriesFile, '.vml');
   LngFolder := ExtractFilePath(AppGenExePath) + 'Languages';

   Application.CreateForm(TfrmMain, frmMain);
  TryAgain:

   if CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READONLY, 0, 32, 'VirtualMachineUSBBoot') <> 0 then
   begin
      if GetLastError = ERROR_ALREADY_EXISTS then
      begin
         GetAllWindowsList('TfrmMain');
         for i := 0 to High(AllWindowsList) do
            if Pos(string('Virtual Machine USB Boot '), AllWindowsList[i].WCaption) = 1 then
               if AllWindowsList[i].WCaption <> 'Virtual Machine USB Boot' then
                  if AllWindowsList[i].Handle <> frmMain.Handle then
                  begin
                     if IsIconic(AllWindowsList[i].Handle) then
                        SendMessage(AllWindowsList[i].Handle, WM_SYSCOMMAND, SC_RESTORE, 0);
                     if IsWindowVisible(AllWindowsList[i].Handle) then
                        SetForegroundWindow(AllWindowsList[i].Handle)
                     else if CustomMessageBox(Application.Handle, GetLangTextDef(idxMain, ['Messages', 'AlreadyStarted'], 'The application is already started but the interface is hidden.'#13#10'Do you want to forcibly close that session (not recommended)?'), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbYes, mbNo], mbYes) = mrYes then
                     begin
                        if IsWindow(AllWindowsList[i].Handle) then
                        begin
                           GetFileNameAndThreadFromHandle(AllWindowsList[i].Handle, ThreadID);
                           try
                              TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), ThreadID), 0);
                           except
                           end;
                        end;
                        goto TryAgain;
                     end;
                     frmMain.OnDestroy := nil;
                     frmMain.Free;
                     Exit;
                  end;
      end;
   end;

   if IsNotUserAdmin then
   begin
      CustomMessageBox(Application.Handle, GetLangTextDef(idxMain, ['Messages', 'StartAsAdministrator'], 'In order to be able to properly detect and use the computer''s capabilities,'#13#10'this application requires administrator privileges.'#13#10'You can start it directly with "Run as administrator" or you can modify the shortcut''s or exe''s properties.'), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
      frmMain.OnDestroy := nil;
      frmMain.Free;
      Exit;
   end;

   with frmMain do
   begin
      vstVMs.Header.Columns.BeginUpdate;
      if CFGFoundAndLoaded then
      begin
         if AddSecondDrive then
         begin
            pmHeaders.Items[3].Visible := True;
            pmHeaders.Items[2].Caption := GetLangTextDef(idxMain, ['List', 'Header', 'FirstDrive'], 'First drive');
            vstVMs.Header.Columns[2].Text := pmHeaders.Items[2].Caption;
            pmHeaders.Items[3].Caption := GetLangTextDef(idxMain, ['List', 'Header', 'SecondDrive'], 'Second drive');
            vstVMs.Header.Columns[3].Text := pmHeaders.Items[3].Caption;
         end;
         if ListOnlyUSBDrives then
         begin
            vstVMs.Header.Columns[2].ImageIndex := 1;
            vstVMs.Header.Columns[3].ImageIndex := 1;
         end;
         try
            for i := 0 to vstVMs.Header.Columns.Count - 1 do
               with vstVMs.Header.Columns[i] do
               begin
                  if i > 0 then
                     Width := pmHeaders.Items[i].Tag;
                  if pmHeaders.Items[i].Checked and pmHeaders.Items[i].Visible then
                  begin
                     if not (coVisible in Options) then
                        Options := Options + [coVisible];
                  end
                  else if coVisible in Options then
                     Options := Options - [coVisible];
               end;
         except
         end;
      end;
      vstVMs.Header.Columns.EndUpdate;
      GetVBVersion;
      Application.OnActivate := AppAct;
      Application.OnDeactivate := AppDeact;
      Application.OnModalBegin := ModBeg;
      Application.OnModalEnd := ModEnd;
      Application.OnMinimize := AppMinimize;
      Application.OnRestore := AppRestore;
      SetBounds(MainLeft, MainTop, MainWidth, MainHeight);
      IntLeft := Left;
      IntTop := Top;
      IntWidth := Width;
      IntHeight := Height;
      if not EscapeKeyClosesMain then
         mmEsc.ShortCut := 0;
   end;
   Application.Run;
end.

