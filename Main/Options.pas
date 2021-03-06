unit Options;

interface

uses
   Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
   Dialogs, StdCtrls, Buttons, ExtCtrls, ShellApi, ProcessViewer, Math,
   xmldom, XMLIntf, msxmldom, XMLDoc, System.UITypes, System.StrUtils,
   PngSpeedButton, PngBitBtn, ShLwApi, Vcl.ComCtrls;

type
   TfrmOptions = class(TForm)
      pnlAll: TPanel;
      pnlVirtualBoxAll: TPanel;
      lblVBExePath: TLabel;
      edtVBExePath: TEdit;
      cbUseVboxmanage: TCheckBox;
      cbDirectly: TCheckBox;
      odSearchQExe: TOpenDialog;
      gbUpdateMethod: TGroupBox;
      cbRemoveDrive: TCheckBox;
      cbAutoDetect: TCheckBox;
      fdListViewFont: TFontDialog;
      xmlTemp: TXMLDocument;
      cbPrecacheVBFiles: TCheckBox;
      cbPrestartVBExeFiles: TCheckBox;
      btnBrowseForVBExe: TPngSpeedButton;
      btnOK: TPngBitBtn;
      btnCancel: TPngBitBtn;
      cbLoadNetPortable: TCheckBox;
      cbLoadUSBPortable: TCheckBox;
      gbPortable: TGroupBox;
      gbApplicationStartup: TGroupBox;
      odSearchVBExe: TOpenDialog;
      cbuseLoadedFromInstalled: TCheckBox;
      PageControl: TPageControl;
      General: TTabSheet;
      VirtualBox: TTabSheet;
      QEMU: TTabSheet;
      pnlQemuAll: TPanel;
      lblQExePath: TLabel;
      lblDefaultParameters: TLabel;
      btnBrowseForQExe: TPngSpeedButton;
      edtQExePath: TEdit;
      edtDefaultParameters: TEdit;
      cmbExeVersion: TComboBox;
      cbHideConsoleWindow: TCheckBox;
      pnlGeneral: TPanel;
      lblWaitTime: TLabel;
      lblLanguage: TLabel;
      lblDefaultVMType: TLabel;
      lblKeyCombination: TLabel;
      cbLock: TCheckBox;
      cbSecondDrive: TCheckBox;
      edtWaitTime: TEdit;
      cbListOnlyUSBDrives: TCheckBox;
      cbAutomaticFont: TCheckBox;
      cmbLanguage: TComboBox;
      btnChooseFont: TPngBitBtn;
      pnlQEMU: TPanel;
      sbQEMU: TPngSpeedButton;
      pnlVirtualBox: TPanel;
      sbVirtualBox: TPngSpeedButton;
      hkStart: THotKey;
      gbEmulationBusType: TGroupBox;
      rbIDE: TRadioButton;
      rbSCSI: TRadioButton;
      procedure cbUseVboxmanageClick(Sender: TObject);
      procedure cbDirectlyClick(Sender: TObject);
      procedure btnBrowseForVBExeClick(Sender: TObject);
      procedure btnBrowseForQExeClick(Sender: TObject);
      procedure btnOKClick(Sender: TObject);
      procedure edtWaitTimeKeyPress(Sender: TObject; var Key: Char);
      procedure AllKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
      procedure edtDefaultParametersChange(Sender: TObject);
      procedure cbAutoDetectClick(Sender: TObject);
      procedure FormCreate(Sender: TObject);
      procedure btnChooseFontClick(Sender: TObject);
      procedure cbAutomaticFontClick(Sender: TObject);
      procedure sbVirtualBoxClick(Sender: TObject);
      procedure sbQEMUClick(Sender: TObject);
      procedure FormDestroy(Sender: TObject);
      procedure FormKeyPress(Sender: TObject; var Key: Char);
      procedure sbQEMUMouseActivate(Sender: TObject; Button: TMouseButton;
         Shift: TShiftState; X, Y, HitTest: Integer;
         var MouseActivate: TMouseActivate);
      procedure sbVirtualBoxMouseActivate(Sender: TObject; Button: TMouseButton;
         Shift: TShiftState; X, Y, HitTest: Integer;
         var MouseActivate: TMouseActivate);
      procedure pnlQEMUEnter(Sender: TObject);
      procedure pnlQEMUExit(Sender: TObject);
      procedure pnlVirtualBoxEnter(Sender: TObject);
      procedure pnlVirtualBoxExit(Sender: TObject);
      procedure cbuseLoadedFromInstalledClick(Sender: TObject);
   private
      originaledtVBExePathWindowProc: TWndMethod;
      originaledtQExePathWindowProc: TWndMethod;
      procedure edtVBExePathWindowProc(var Msg: TMessage);
      procedure edtQExePathWindowProc(var Msg: TMessage);
      { Private declarations }
   public
      { Public declarations }
   end;

var
   frmOptions: TfrmOptions;

implementation

uses MainForm;

{$R *.dfm}

procedure TfrmOptions.cbUseVboxmanageClick(Sender: TObject);
begin
   cbDirectly.Checked := not cbUseVboxmanage.Checked and (not cbAutoDetect.Checked);
   cbAutoDetect.Checked := not cbDirectly.Checked and (not cbUseVboxmanage.Checked);
end;

procedure TfrmOptions.cbDirectlyClick(Sender: TObject);
begin
   cbUseVboxmanage.Checked := not cbDirectly.Checked and (not cbAutoDetect.Checked);
   cbAutoDetect.Checked := not cbDirectly.Checked and (not cbUseVboxmanage.Checked);
end;

procedure TfrmOptions.cbuseLoadedFromInstalledClick(Sender: TObject);
begin
   cbLoadNetPortable.Enabled := not (isVBInstalledToo and FileExists(exeVBPathToo) and cbuseLoadedFromInstalled.Checked);
   cbLoadUSBPortable.Enabled := not (isVBInstalledToo and FileExists(exeVBPathToo) and cbuseLoadedFromInstalled.Checked);
end;

procedure TfrmOptions.btnBrowseForVBExeClick(Sender: TObject);
var
   FolderName: string;
   Path: array[0..MAX_PATH - 1] of Char;
begin
   btnBrowseForVBExe.Repaint;
   FolderName := ExtractFilePath(odSearchVBExe.FileName);
   odSearchVBExe.FileName := '';
   if FolderName = '' then
   begin
      if odSearchVBExe.InitialDir = '' then
         if isInstalledVersion then
            odSearchVBExe.InitialDir := envProgramFiles
         else
         begin
            FillMemory(@Path[0], Length(Path), 0);
            PathCombine(@Path[0], PChar(ExtractFilePath(Application.ExeName)), PChar(edtVBExePath.Text));
            if FileExists(string(Path)) then
               odSearchVBExe.InitialDir := ExtractFilePath(string(Path))
            else
               odSearchVBExe.InitialDir := ExtractFilePath(Application.ExeName);
         end;
   end
   else
      odSearchVBExe.InitialDir := FolderName;
   if odSearchVBExe.Execute(Self.Handle) then
   begin
      if isInstalledVersion or (LowerCase(ExtractFileDrive(odSearchVBExe.FileName)) <> LowerCase(ExtractFileDrive(Application.ExeName))) then
         edtVBExePath.Text := odSearchVBExe.FileName
      else
      begin
         FillMemory(@Path[0], Length(Path), 0);
         if PathRelativePathTo(@Path[0], PChar(ExtractFilePath(Application.ExeName)), FILE_ATTRIBUTE_DIRECTORY, PChar(ExtractFilePath(odSearchVBExe.FileName)), 0) then
            edtVBExePath.Text := string(Path) + ExtractFileName(odSearchVBExe.FileName)
         else
            edtVBExePath.Text := odSearchVBExe.FileName;
      end;
      edtVBExePath.SelStart := Length(edtVBExePath.Text);
      edtVBExePath.SelLength := 0;
   end;
   SetFocus;
end;

procedure TfrmOptions.btnBrowseForQExeClick(Sender: TObject);
var
   FolderName: string;
   hFind: THandle;
   wfa: ^WIN32_FIND_DATAW;
   i: Integer;
   ws: string;
   Path: array[0..MAX_PATH - 1] of Char;
begin
   btnBrowseForQExe.Repaint;
   FolderName := ExtractFilePath(odSearchQExe.FileName);
   odSearchQExe.FileName := '';
   if FolderName = '' then
   begin
      if odSearchQExe.InitialDir = '' then
         if isInstalledVersion then
            odSearchQExe.InitialDir := envProgramFiles
         else
         begin
            FillMemory(@Path[0], Length(Path), 0);
            PathCombine(@Path[0], PChar(ExtractFilePath(Application.ExeName)), PChar(edtQExePath.Text));
            if DirectoryExists(string(Path)) then
               odSearchQExe.InitialDir := string(Path)
            else
               odSearchQExe.InitialDir := ExtractFilePath(Application.ExeName);
         end;
   end
   else
      odSearchQExe.InitialDir := FolderName;
   if odSearchQExe.Execute(Self.Handle) then
   begin
      if isInstalledVersion or (LowerCase(ExtractFileDrive(odSearchQExe.FileName)) <> LowerCase(ExtractFileDrive(Application.ExeName))) then
      begin
         edtQExePath.Text := ExtractFilePath(odSearchQExe.FileName);
         FillMemory(@Path[0], Length(Path), 0);
         PathCanonicalize(@Path[0], PChar(edtQExePath.Text));
      end
      else
      begin
         FillMemory(@Path[0], Length(Path), 0);
         if PathRelativePathTo(@Path[0], PChar(ExtractFilePath(Application.ExeName)), FILE_ATTRIBUTE_DIRECTORY, PChar(ExtractFilePath(odSearchQExe.FileName)), 0) then
         begin
            edtQExePath.Text := Path;
            PathCombine(@Path[0], PChar(ExtractFilePath(Application.ExeName)), PChar(edtQExePath.Text));
         end
         else
         begin
            FillMemory(@Path[0], Length(Path), 0);
            edtQExePath.Text := ExtractFilePath(odSearchQExe.FileName);
            PathCanonicalize(@Path[0], PChar(edtQExePath.Text));
         end;
      end;
      edtQExePath.SelStart := Length(edtQExePath.Text);
      edtQExePath.SelLength := 0;
      cmbExeVersion.Items.BeginUpdate;
      cmbExeVersion.Items.Clear;
      try
         New(wfa);
         hFind := FindFirstFile(PChar(string(Path) + '*.exe'), wfa^);
         if hFind = INVALID_HANDLE_VALUE then
            Exit;
         repeat
            if wfa.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY = 0 then
               cmbExeVersion.Items.Append(wfa.cFileName);
         until not Windows.FindNextFile(hFind, wfa^);
         Windows.FindClose(hFind);
         if FileExists(odSearchQExe.FileName) then
         begin
            ws := ExtractFileName(odSearchQExe.FileName);
            i := cmbExeVersion.Items.IndexOf(ws);
            if i > -1 then
               cmbExeVersion.ItemIndex := i
            else
               cmbExeVersion.ItemIndex := -1;
         end
         else
            cmbExeVersion.ItemIndex := -1;
      finally
         cmbExeVersion.Items.EndUpdate;
         cmbExeVersion.Invalidate;
      end;
   end;
   SetFocus;
end;

procedure TfrmOptions.btnOKClick(Sender: TObject);
var
   i: integer;
begin
   i := StrToIntDef(Trim(edtWaitTime.Text), -1);
   if (i < 0) or (i > 20000) then
   begin
      PageControl.ActivePageIndex := 0;
      CustomMessageBox(Handle, (GetLangTextDef(idxOptions, ['Messages', 'ProperWaitTime'], 'Please set a proper value for the wait time (0..20000) !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
      edtWaitTime.SetFocus;
      Exit;
   end;
   if (Trim(edtVBExePath.Text) <> '') and (not FileExists(Trim(edtVBExePath.Text))) then
   begin
      PageControl.ActivePageIndex := 1;
      CustomMessageBox(Handle, (GetLangTextFormatDef(idxOptions, ['Messages', 'FileDoesntExist'], [Trim(edtVBExePath.Text), 'VirtualBox'], 'The file "%s" doesn''t exist !'#13#10'Please clear the %s Exe Path from the edit box if you don''t want to use it...')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
      Exit;
   end;
   if (Trim(edtQExePath.Text) <> '') and (not FileExists(ExcludeTrailingPathDelimiter((Trim(edtQExePath.Text))) + '\' + Trim(cmbExeVersion.Text))) then
   begin
      PageControl.ActivePageIndex := 2;
      CustomMessageBox(Handle, (GetLangTextFormatDef(idxOptions, ['Messages', 'FileDoesntExist'], [ExcludeTrailingPathDelimiter((Trim(edtQExePath.Text))) + '\' + Trim(cmbExeVersion.Text), 'QEMU'], 'The file "%s" doesn''t exist !'#13#10'Please clear the %s Exe Path from the edit box if you don''t want to use it...')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
      Exit;
   end;
   if cmbLanguage.ItemIndex = -1 then
   begin
      PageControl.ActivePageIndex := 0;
      CustomMessageBox(Handle, PWideChar(string('A language for the interface must be selected...!')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
      Exit;
   end;
   ModalResult := mrOk;
end;

procedure TfrmOptions.edtWaitTimeKeyPress(Sender: TObject; var Key: Char);
begin
   if not CharInSet(Key, ['0'..'9', #8]) then
      Key := #0;
end;

procedure TfrmOptions.AllKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
   if (Shift = []) and (Key = VK_F1) then
      frmMain.OpenInternetHelp(Self.Handle, DefSiteHelp);
end;

procedure TfrmOptions.edtDefaultParametersChange(Sender: TObject);
begin
   edtDefaultParameters.ShowHint := Trim(edtDefaultParameters.Text) = string('-name "USB Boot Test" -boot c -m 512 -soundhw sb16');
end;

procedure TfrmOptions.cbAutoDetectClick(Sender: TObject);
begin
   cbUseVboxmanage.Checked := not cbDirectly.Checked and (not cbAutoDetect.Checked);
   cbDirectly.Checked := not cbUseVboxmanage.Checked and (not cbAutoDetect.Checked);
end;

procedure TfrmOptions.FormCreate(Sender: TObject);
var
   i, NewWidth: integer;
   OldText: string;
begin
   SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) and not WS_EX_TOOLWINDOW);

   NewWidth := Round(0.0001 * Width * Min(Max(StrToIntDef(GetLangTextDef(idxOptions, ['Width'], IntToStr(10000)), 10000), 1000), 100000));

   Caption := GetLangTextDef(idxOptions, ['Caption'], 'Options');
   lblWaitTime.Caption := GetLangTextDef(idxOptions, ['Labels', 'WaitTime'], 'Wait time to flush system data before dismounting (ms):');
   edtWaitTime.Width := edtWaitTime.Left + edtWaitTime.Width - lblWaitTime.Left - lblWaitTime.Width - 5 + NewWidth - Width;
   edtWaitTime.Left := lblWaitTime.Left + lblWaitTime.Width + 5 - NewWidth + Width;
   lblVBExePath.Caption := GetLangTextDef(idxOptions, ['Labels', 'ExePath'], 'Exe path:');
   edtVBExePath.Width := edtVBExePath.Left + edtVBExePath.Width - lblVBExePath.Left - lblVBExePath.Width - 5 + NewWidth - Width;
   edtVBExePath.Left := lblVBExePath.Left + lblVBExePath.Width + 5 - NewWidth + Width;
   lblQExePath.Caption := GetLangTextDef(idxOptions, ['Labels', 'ExePath'], 'Exe path:');
   lblDefaultParameters.Caption := GetLangTextDef(idxOptions, ['Labels', 'DefCommParam'], 'The default command line parameters:');
   odSearchVBExe.Title := GetLangTextDef(idxOptions, ['Dialogs', 'LoadExe', 'Title'], 'Open');
   odSearchVBExe.Filter := GetLangTextDef(idxOptions, ['Dialogs', 'LoadExe', 'Filter'], 'Exe files (*.exe)|*.exe|All files (*.*)|*.*');
   odSearchQExe.Title := GetLangTextDef(idxOptions, ['Dialogs', 'LoadExe', 'Title'], 'Open');
   odSearchQExe.Filter := GetLangTextDef(idxOptions, ['Dialogs', 'LoadExe', 'Filter'], 'Exe files (*.exe)|*.exe|All files (*.*)|*.*');
   OldText := btnChooseFont.Caption;
   btnChooseFont.Caption := GetLangTextDef(idxOptions, ['Buttons', 'ChooseFont'], 'Choose font');
   Canvas.Font.Assign(btnChooseFont.Font);
   btnChooseFont.Left := btnChooseFont.Left + Canvas.TextWidth(OldText) - Canvas.TextWidth(btnChooseFont.Caption);
   btnChooseFont.Width := btnChooseFont.Width - Canvas.TextWidth(OldText) + Canvas.TextWidth(btnChooseFont.Caption);
   cbAutomaticFont.Width := btnChooseFont.Left - 5 - cbAutomaticFont.Left;
   btnOK.Caption := ReplaceStr(GetLangTextDef(idxMessages, ['Buttons', 'OK'], 'OK'), '&', '');
   btnCancel.Caption := ReplaceStr(GetLangTextDef(idxMessages, ['Buttons', 'Cancel'], 'Cancel'), '&', '');
   cbLock.Caption := GetLangTextDef(idxOptions, ['Checkboxes', 'LockVol'], 'Lock the volumes on the drive before dismounting (safe but sometimes slow)');
   cbSecondDrive.Caption := GetLangTextDef(idxOptions, ['Checkboxes', 'SecDrive'], 'Show a second drive option');
   cbListOnlyUSBDrives.Caption := GetLangTextDef(idxOptions, ['Checkboxes', 'OnlyUSB'], 'List only USB drives');
   cbAutomaticFont.Caption := GetLangTextDef(idxOptions, ['Checkboxes', 'AutomaticFont'], 'Font size, style and color will be set automatically');
   cbAutoDetect.Caption := GetLangTextDef(idxOptions, ['Checkboxes', 'AutodetectMethod'], 'try to autodetect the most appropriate for the given situation');
   cbUseVboxmanage.Caption := GetLangTextDef(idxOptions, ['Checkboxes', 'UseVBMethod'], 'use VBoxManage.exe command line (slower)');
   cbDirectly.Caption := GetLangTextDef(idxOptions, ['Checkboxes', 'DirectWrtMethod'], 'directly (faster, but VB Manager must be closed)');
   cbRemoveDrive.Caption := GetLangTextDef(idxOptions, ['Checkboxes', 'RemDrives'], 'Remove the drive(s) from the VM after closing');
   cbPrecacheVBFiles.Caption := GetLangTextDef(idxOptions, ['Checkboxes', 'PrecacheVBFiles'], 'Precache the VirtualBox files at application start');
   cbPrestartVBExeFiles.Caption := GetLangTextDef(idxOptions, ['Checkboxes', 'PrestartVBFiles'], 'Prestart the VirtualBox files at application start');
   PageControl.Pages[0].Caption := GetLangTextDef(idxOptions, ['Groupboxes', 'General'], 'General');
   lblDefaultVMType.Caption := GetLangTextDef(idxOptions, ['Groupboxes', 'DefaultVMType'], 'Default VM type when adding a new entry:');
   gbUpdateMethod.Caption := GetLangTextDef(idxOptions, ['Groupboxes', 'UpdateVMMethod'], 'Method to update the VM configuration file (*.vbox)');
   btnBrowseForVBExe.Hint := GetLangTextDef(idxOptions, ['Hints', 'BrowseForExe'], 'click to browse for exe');
   btnBrowseForQExe.Hint := GetLangTextDef(idxOptions, ['Hints', 'BrowseForExe'], 'click to browse for exe');
   edtDefaultParameters.Hint := GetLangTextDef(idxOptions, ['Hints', 'DefaultParam'], 'Basic parameters for x86/x64 version');
   cbHideConsoleWindow.Caption := GetLangTextDef(idxOptions, ['Checkboxes', 'HideConsoleWindow'], 'Hide console window');
   gbEmulationBusType.Caption := GetLangTextDef(idxOptions, ['Groupboxes', 'EmulationBusType'], 'Emulation bus type:');
   rbIDE.Caption := GetLangTextDef(idxOptions, ['Groupboxes', 'IDEBusType'], 'IDE (slow, more compatible)');
   rbSCSI.Caption := GetLangTextDef(idxOptions, ['Groupboxes', 'SCSIBusType'], 'SCSI (fast, less compatible)');

   case SystemIconSize of
      -2147483647..18:
         begin
            frmMain.imlBtn16.GetIcon(5, Icon);
            sbVirtualBox.PngImage := frmMain.imlBtn16.PngImages[8].PngImage;
            sbQEMU.PngImage := frmMain.imlBtn16.PngImages[9].PngImage;
            btnOK.PngImage := frmMain.imlBtn16.PngImages[14].PngImage;
            btnCancel.PngImage := frmMain.imlBtn16.PngImages[15].PngImage;
            btnBrowseForVBExe.PngImage := frmMain.imlBtn24.PngImages[30].PngImage;
            btnBrowseForQExe.PngImage := frmMain.imlBtn24.PngImages[30].PngImage;
         end;
      19..22:
         begin
            frmMain.imlBtn20.GetIcon(5, Icon);
            sbVirtualBox.PngImage := frmMain.imlBtn20.PngImages[8].PngImage;
            sbQEMU.PngImage := frmMain.imlBtn20.PngImages[9].PngImage;
            PageControl.Images := frmMain.imlBtn20;
            btnOK.PngImage := frmMain.imlBtn20.PngImages[14].PngImage;
            btnCancel.PngImage := frmMain.imlBtn20.PngImages[15].PngImage;
            btnBrowseForVBExe.PngImage := frmMain.imlBtn28.PngImages[0].PngImage;
            btnBrowseForQExe.PngImage := frmMain.imlBtn28.PngImages[0].PngImage;
         end;
      23..2147483647:
         begin
            frmMain.imlBtn24.GetIcon(5, Icon);
            sbVirtualBox.PngImage := frmMain.imlBtn24.PngImages[8].PngImage;
            sbQEMU.PngImage := frmMain.imlBtn24.PngImages[9].PngImage;
            PageControl.Images := frmMain.imlBtn24;
            btnOK.PngImage := frmMain.imlBtn24.PngImages[14].PngImage;
            btnCancel.PngImage := frmMain.imlBtn24.PngImages[15].PngImage;
            btnBrowseForVBExe.PngImage := frmMain.imlBtn32.PngImages[1].PngImage;
            btnBrowseForQExe.PngImage := frmMain.imlBtn32.PngImages[1].PngImage;
         end;
   end;

   for i := 0 to ComponentCount - 1 do
      if Components[i] is TComboBox then
         (Components[i] as TComboBox).ItemHeight := Round(1.0 * Screen.PixelsPerInch / 96 * (Components[i] as TComboBox).ItemHeight);

   btnOK.Glyph.Canvas.Font.Assign(btnOK.Font);
   btnOK.Width := Max(btnOK.Glyph.Canvas.TextWidth(btnOK.Caption), btnOK.Glyph.Canvas.TextWidth(btnCancel.Caption));
   btnOK.Margin := Round(sqrt(btnOK.Width)) + 5;
   btnOK.Width := 3 * btnOK.Margin + btnOK.PngImage.Width + btnOK.Width;
   btnOK.Spacing := Max(0, btnOK.Width - btnOK.Margin - btnOK.PngImage.Width - btnOK.Glyph.Canvas.TextWidth(btnOK.Caption)) div 2;
   btnCancel.Width := btnOK.Width;
   btnCancel.Margin := btnOK.Margin;
   btnCancel.Spacing := Max(0, btnCancel.Width - btnCancel.Margin - btnCancel.PngImage.Width - btnOK.Glyph.Canvas.TextWidth(btnCancel.Caption)) div 2;

   Width := NewWidth;
   Left := frmMain.Left + ((frmMain.Width - Width) div 2) - DlgOffsPos;
   if Left < Screen.WorkAreaLeft then
      Left := Screen.WorkAreaLeft + DlgOffsPos
   else if Left + Width > Screen.WorkAreaRect.Right then
      Left := Screen.WorkAreaRect.Right - Width - DlgOffsPos;

   if Screen.WorkAreaHeight >= Height then
   begin
      Top := frmMain.Top + Round((frmMain.Height - Height) / 2) - DlgOffsPos;
      if (Top + Height) > Screen.WorkAreaRect.Bottom then
         Top := Screen.WorkAreaRect.Bottom - Height - DlgOffsPos
      else if Top < Screen.WorkAreaTop then
         Top := Screen.WorkAreaTop + DlgOffsPos;
   end
   else
      Top := Round((Screen.WorkAreaHeight - ClientHeight) / 2) + Top - ClientOrigin.Y - DlgOffsPos;
   btnOK.Left := Round(0.4 * (ClientWidth - btnOK.Width - btnCancel.Width));
   btnCancel.Left := Round(0.6 * (ClientWidth - btnOK.Width - btnCancel.Width)) + btnOK.Width;

   i := Round(0.5 * ((-edtQExePath.Left - edtQExePath.Width + cmbExeVersion.Left) - (3 * Screen.PixelsPerInch / 96)));
   edtQExePath.Width := edtQExePath.Width + i;
   cmbExeVersion.Left := cmbExeVersion.Left - i;
   cmbExeVersion.Width := cmbExeVersion.Width + i;

   btnBrowseForQExe.Top := edtQExePath.Top;
   btnBrowseForQExe.Height := edtQExePath.Height;
   btnBrowseForVBExe.Top := edtVBExePath.Top;
   btnBrowseForVBExe.Height := edtVBExePath.Height;

   originaledtVBExePathWindowProc := edtVBExePath.WindowProc;
   edtVBExePath.WindowProc := edtVBExePathWindowProc;
   originaledtQExePathWindowProc := edtQExePath.WindowProc;
   edtQExePath.WindowProc := edtQExePathWindowProc;
   DragAcceptFiles(edtVBExePath.Handle, True);
   DragAcceptFiles(edtQExePath.Handle, True);
end;

procedure TfrmOptions.FormDestroy(Sender: TObject);
begin
   DragAcceptFiles(edtVBExePath.Handle, False);
   DragAcceptFiles(edtQExePath.Handle, False);
end;

procedure TfrmOptions.FormKeyPress(Sender: TObject; var Key: Char);
begin
   if pnlQEMU.Focused then
   begin
      if Key = #32 then
      begin
         ActiveControl := nil;
         if sbVirtualBox.Down then
            sbQEMU.Click
         else
            sbVirtualBox.Click;
         pnlQEMU.SetFocus;
      end;
   end
   else if pnlVirtualBox.Focused then
   begin
      if Key = #32 then
      begin
         Self.ActiveControl := nil;
         if sbVirtualBox.Down then
            sbQEMU.Click
         else
            sbVirtualBox.Click;
         pnlVirtualBox.SetFocus;
      end;
   end;
end;

procedure TfrmOptions.pnlQEMUEnter(Sender: TObject);
begin
   sbQEMU.Repaint;
end;

procedure TfrmOptions.pnlQEMUExit(Sender: TObject);
begin
   sbQEMU.Repaint;
end;

procedure TfrmOptions.pnlVirtualBoxEnter(Sender: TObject);
begin
   sbVirtualBox.Repaint;
end;

procedure TfrmOptions.pnlVirtualBoxExit(Sender: TObject);
begin
   sbVirtualBox.Repaint;
end;

procedure TfrmOptions.btnChooseFontClick(Sender: TObject);
var
   FontName: AnsiString;
   FontSize: Word;
   FontBold, FontItalic, FontUnderline, FontStrikeOut: Boolean;
   FontColor: TColor;
   FontScript: Word;
begin
   with fdListViewFont.Font do
   begin
      FontName := AnsiString(Name);
      FontSize := Size;
      FontBold := fsBold in Style;
      FontItalic := fsItalic in Style;
      FontUnderline := fsUnderline in Style;
      FontStrikeOut := fsStrikeOut in Style;
      FontColor := Color;
      FontScript := Charset;
   end;
   if not fdListViewFont.Execute(Self.Handle) then
      with fdListViewFont.Font do
      begin
         Name := string(FontName);
         Size := FontSize;
         Style := [];
         if FontBold then
            Style := Style + [fsBold];
         if FontItalic then
            Style := Style + [fsItalic];
         if FontUnderline then
            Style := Style + [fsUnderline];
         if FontStrikeOut then
            Style := Style + [fsStrikeOut];
         Color := FontColor;
         Charset := FontScript;
      end;
end;

procedure TfrmOptions.cbAutomaticFontClick(Sender: TObject);
begin
   btnChooseFont.Enabled := not cbAutomaticFont.Checked;
end;

procedure TfrmOptions.edtVBExePathWindowProc(var Msg: TMessage);
var
   Buffer: array[0..MAX_PATH] of WideChar;
   wstrTemp: string;
begin
   if Msg.Msg = WM_DROPFILES then
   begin
      Application.BringToFront;
      frmMain.Repaint;
      Repaint;
      case DragQueryFileW(Msg.WParam, $FFFFFFFF, nil, 0) of
         1:
            begin
               DragQueryFileW(Msg.WParam, 0, @Buffer, sizeof(Buffer));
               DragFinish(Msg.WParam);
               wstrTemp := string(Buffer);
               if FileExists(wstrTemp) then
               begin
                  odSearchVBExe.FileName := wstrTemp;
                  edtVBExePath.Text := wstrTemp;
                  edtVBExePath.SetFocus;
                  edtVBExePath.SelStart := Length(edtVBExePath.Text);
                  edtVBExePath.SelLength := 0;
               end
               else
               begin
                  CustomMessageBox(Handle, (GetLangTextDef(idxOptions, ['Messages', 'NotAFile'], 'This is not a file !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
               end;
            end;
         else
            DragFinish(Msg.WParam);
            CustomMessageBox(Handle, (GetLangTextDef(idxOptions, ['Messages', 'JustOneItem'], 'Just one item at a time !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
      end;
   end
   else
      originaledtVBExePathWindowProc(Msg);
end;

procedure TfrmOptions.edtQExePathWindowProc(var Msg: TMessage);
var
   Buffer: array[0..MAX_PATH] of WideChar;
   wstrTemp: string;
begin
   if Msg.Msg = WM_DROPFILES then
   begin
      Application.BringToFront;
      frmMain.Repaint;
      Repaint;
      case DragQueryFileW(Msg.WParam, $FFFFFFFF, nil, 0) of
         1:
            begin
               DragQueryFileW(Msg.WParam, 0, @Buffer, sizeof(Buffer));
               DragFinish(Msg.WParam);
               wstrTemp := string(Buffer);
               if FileExists(wstrTemp) then
               begin
                  odSearchQExe.FileName := wstrTemp;
                  edtQExePath.Text := wstrTemp;
                  edtQExePath.SetFocus;
                  edtQExePath.SelStart := Length(edtQExePath.Text);
                  edtQExePath.SelLength := 0;
               end
               else
               begin
                  CustomMessageBox(Handle, (GetLangTextDef(idxOptions, ['Messages', 'NotAFile'], 'This is not a file !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
               end;
            end;
         else
            DragFinish(Msg.WParam);
            CustomMessageBox(Handle, (GetLangTextDef(idxOptions, ['Messages', 'JustOneItem'], 'Just one item at a time !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
      end;
   end
   else
      originaledtQExePathWindowProc(Msg);
end;

procedure TfrmOptions.sbVirtualBoxClick(Sender: TObject);
begin
   sbVirtualBox.Down := True;
   if not sbQEMU.Down then
      Exit;
   sbQEMU.Down := False;
end;

procedure TfrmOptions.sbVirtualBoxMouseActivate(Sender: TObject;
   Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer;
   var MouseActivate: TMouseActivate);
begin
   if (ActiveControl = nil) or (ActiveControl = pnlQEMU) then
      pnlVirtualBox.SetFocus;
end;

procedure TfrmOptions.sbQEMUClick(Sender: TObject);
begin
   sbQEMU.Down := True;
   if not sbVirtualBox.Down then
      Exit;
   sbVirtualBox.Down := False;
end;

procedure TfrmOptions.sbQEMUMouseActivate(Sender: TObject; Button: TMouseButton;
   Shift: TShiftState; X, Y, HitTest: Integer;
   var MouseActivate: TMouseActivate);
begin
   if (ActiveControl = nil) or (ActiveControl = pnlVirtualBox) then
      pnlQEMU.SetFocus;
end;

end.

