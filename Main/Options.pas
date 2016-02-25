unit Options;

interface

uses
   Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
   Dialogs, StdCtrls, Buttons, ExtCtrls, ShellApi, ProcessViewer, Math,
   xmldom, XMLIntf, msxmldom, XMLDoc, System.UITypes, System.StrUtils,
   PngSpeedButton, PngBitBtn, ShLwApi;

type
   TfrmOptions = class(TForm)
      pnlAll: TPanel;
      gbGeneral: TGroupBox;
      cbLock: TCheckBox;
      gbVirtualBox: TGroupBox;
      gbQEMU: TGroupBox;
      lblVBExePath: TLabel;
      edtVBExePath: TEdit;
      cbSecondDrive: TCheckBox;
      cbUseVboxmanage: TCheckBox;
      cbDirectly: TCheckBox;
      lblQExePath: TLabel;
      edtQExePath: TEdit;
      edtDefaultParameters: TEdit;
      lblDefaultParameters: TLabel;
      odSearchQExe: TOpenDialog;
      lblWaitTime: TLabel;
      edtWaitTime: TEdit;
      gbDefaultVMType: TGroupBox;
      gbUpdateMethod: TGroupBox;
      cbRemoveDrive: TCheckBox;
      cbAutoDetect: TCheckBox;
      cbListOnlyUSBDrives: TCheckBox;
      fdListViewFont: TFontDialog;
      cbAutomaticFont: TCheckBox;
      cbEscapeKeyClosesMain: TCheckBox;
      lblLanguage: TLabel;
      cmbLanguage: TComboBox;
      xmlTemp: TXMLDocument;
      btnChooseFont: TPngBitBtn;
      imgVB: TImage;
      imgQEMU: TImage;
      cbPrecacheVBFiles: TCheckBox;
      cbPrestartVBExeFiles: TCheckBox;
      btnBrowseForQExe: TPngSpeedButton;
      btnBrowseForVBExe: TPngSpeedButton;
      btnOK: TPngBitBtn;
      btnCancel: TPngBitBtn;
      cmbExeVersion: TComboBox;
      cbHideConsoleWindow: TCheckBox;
      pnlQEMU: TPanel;
      sbQEMU: TPngSpeedButton;
      pnlVirtualBox: TPanel;
      sbVirtualBox: TPngSpeedButton;
      cbLoadNetPortable: TCheckBox;
      cbLoadUSBPortable: TCheckBox;
      gbPortable: TGroupBox;
      gbApplicationStartup: TGroupBox;
      odSearchVBExe: TOpenDialog;
      cbuseLoadedFromInstalled: TCheckBox;
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
            odSearchVBExe.InitialDir := ExtractFilePath(Application.ExeName);
   end
   else
      odSearchVBExe.InitialDir := FolderName;
   if odSearchVBExe.Execute(Self.Handle) then
   begin
      if isInstalledVersion or (LowerCase(ExtractFileDrive(odSearchVBExe.FileName)) <> LowerCase(ExtractFileDrive(Application.ExeName))) then
         edtVBExePath.Text := odSearchVBExe.FileName
      else
      begin
         PathRelativePathTo(@Path[0], PChar(ExtractFilePath(Application.ExeName)), FILE_ATTRIBUTE_DIRECTORY, PChar(ExtractFilePath(odSearchVBExe.FileName)), 0);
         edtVBExePath.Text := Path + ExtractFileName(odSearchVBExe.FileName);
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
            odSearchQExe.InitialDir := ExtractFilePath(Application.ExeName);
   end
   else
      odSearchQExe.InitialDir := FolderName;
   if odSearchQExe.Execute(Self.Handle) then
   begin
      if isInstalledVersion or (LowerCase(ExtractFileDrive(odSearchQExe.FileName)) <> LowerCase(ExtractFileDrive(Application.ExeName))) then
         edtQExePath.Text := ExtractFilePath(odSearchQExe.FileName)
      else
      begin
         PathRelativePathTo(@Path[0], PChar(ExtractFilePath(Application.ExeName)), FILE_ATTRIBUTE_DIRECTORY, PChar(ExtractFilePath(odSearchQExe.FileName)), 0);
         edtQExePath.Text := Path;
      end;
      edtQExePath.SelStart := Length(edtQExePath.Text);
      edtQExePath.SelLength := 0;
      PathCanonicalize(@Path[0], PChar(IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) + edtQExePath.Text));
      cmbExeVersion.Items.BeginUpdate;
      cmbExeVersion.Items.Clear;
      New(wfa);
      hFind := FindFirstFile(PChar(string(Path) + 'qemu*.exe'), wfa^);
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
      cmbExeVersion.Items.EndUpdate;
      cmbExeVersion.Invalidate;
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
      CustomMessageBox(Handle, (GetLangTextDef(idxOptions, ['Messages', 'ProperWaitTime'], 'Please set a proper value for the wait time (0..20000) !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
      edtWaitTime.SetFocus;
      Exit;
   end;
   if (Trim(edtVBExePath.Text) <> '') and (not FileExists(Trim(edtVBExePath.Text))) then
   begin
      CustomMessageBox(Handle, (GetLangTextFormatDef(idxOptions, ['Messages', 'FileDoesntExist'], [Trim(edtVBExePath.Text), 'VirtualBox'], 'The file "%s" doesn''t exist !'#13#10'Please clear the %s Exe Path from the edit box if you don''t want to use it...')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
      Exit;
   end;
   if (Trim(edtQExePath.Text) <> '') and (not FileExists(ExcludeTrailingPathDelimiter((Trim(edtQExePath.Text))) + '\' + Trim(cmbExeVersion.Text))) then
   begin
      CustomMessageBox(Handle, (GetLangTextFormatDef(idxOptions, ['Messages', 'FileDoesntExist'], [ExcludeTrailingPathDelimiter((Trim(edtQExePath.Text))) + '\' + Trim(cmbExeVersion.Text), 'QEMU'], 'The file "%s" doesn''t exist !'#13#10'Please clear the %s Exe Path from the edit box if you don''t want to use it...')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
      Exit;
   end;
   if cmbLanguage.ItemIndex = -1 then
   begin
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
   NewWidth: integer;
   OldText: string;
begin
   SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) and not WS_EX_TOOLWINDOW);
   frmMain.imlBtn16.GetIcon(5, Icon);
   NewWidth := Min(Max(StrToIntDef(GetLangTextDef(idxOptions, ['Width'], AnsiString(IntToStr(Width))), Width), 100), 1000);
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
   cbEscapeKeyClosesMain.Caption := GetLangTextDef(idxOptions, ['Checkboxes', 'EscapeKey'], 'Escape key closes the main window');
   cbAutoDetect.Caption := GetLangTextDef(idxOptions, ['Checkboxes', 'AutodetectMethod'], 'try to autodetect the most appropriate for the given situation');
   cbUseVboxmanage.Caption := GetLangTextDef(idxOptions, ['Checkboxes', 'UseVBMethod'], 'use VBoxManage.exe command line (slower)');
   cbDirectly.Caption := GetLangTextDef(idxOptions, ['Checkboxes', 'DirectWrtMethod'], 'directly (faster, but VB Manager must be closed)');
   cbRemoveDrive.Caption := GetLangTextDef(idxOptions, ['Checkboxes', 'RemDrives'], 'Remove the drive(s) from the VM after closing');
   cbPrecacheVBFiles.Caption := GetLangTextDef(idxOptions, ['Checkboxes', 'PrecacheVBFiles'], 'Precache the VirtualBox files at application start');
   cbPrestartVBExeFiles.Caption := GetLangTextDef(idxOptions, ['Checkboxes', 'PrestartVBFiles'], 'Prestart the VirtualBox files at application start');
   gbGeneral.Caption := GetLangTextDef(idxOptions, ['Groupboxes', 'General'], 'General');
   gbDefaultVMType.Caption := GetLangTextDef(idxOptions, ['Groupboxes', 'DefaultVMType'], 'Default VM type when adding a new entry');
   gbUpdateMethod.Caption := GetLangTextDef(idxOptions, ['Groupboxes', 'UpdateVMMethod'], 'Method to update the VM configuration file (*.vbox)');
   btnBrowseForVBExe.Hint := GetLangTextDef(idxOptions, ['Hints', 'BrowseForExe'], 'click to browse for exe');
   btnBrowseForQExe.Hint := GetLangTextDef(idxOptions, ['Hints', 'BrowseForExe'], 'click to browse for exe');
   edtDefaultParameters.Hint := GetLangTextDef(idxOptions, ['Hints', 'DefaultParam'], 'Basic parameters for x86/x64 version');
   cbHideConsoleWindow.Caption := GetLangTextDef(idxOptions, ['Checkboxes', 'HideConsoleWindow'], 'Hide console window');
   sbVirtualBox.PngImage := frmMain.imlBtn16.PngImages[4].PngImage;
   sbQEMU.PngImage := frmMain.imlBtn16.PngImages[8].PngImage;
   frmMain.imlBtn16.GetIcon(4, imgVB.Picture.Icon);
   frmMain.imlBtn16.GetIcon(8, imgQEMU.Picture.Icon);

   btnBrowseForVBExe.PngImage := frmMain.imlBtn24.PngImages[10].PngImage;
   btnBrowseForQExe.PngImage := frmMain.imlBtn24.PngImages[10].PngImage;
   btnOK.PngImage := frmMain.imlBtn16.PngImages[13].PngImage;
   btnCancel.PngImage := frmMain.imlBtn16.PngImages[14].PngImage;
   cmbLanguage.Width := cmbLanguage.Left + cmbLanguage.Width - lblLanguage.Left - lblLanguage.Width - 5 + NewWidth - Width;
   cmbLanguage.Left := lblWaitTime.Left + lblLanguage.Width + 5 - NewWidth + Width;
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

