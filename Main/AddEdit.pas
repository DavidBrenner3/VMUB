unit AddEdit;

interface

uses
   Windows, SysUtils, Classes, Graphics, Forms,
   Menus, StrUtils, Math, Buttons, ExtCtrls, StdCtrls, Controls, Dialogs,
   ShellApi, Messages, ProcessViewer,
   Spin, ActiveX, ComObj, Variants, VirtualTrees, PngSpeedButton, PngBitBtn;

function isGUID(const ws: string): Boolean;

type
   DriveLetters = record
      Number: ShortInt;
      BusType: Byte;
      VolPaths: array of string;
   end;

   VMID = record
      Name: string;
      ID: AnsiString;
   end;

   CDROMInfo = record
      Letter: AnsiChar;
      Name: AnsiString;
   end;

   TMyObj = class(TObject)
      Text: string;
   end;

   TMemoryStatusEx = record
      dwLength: dword;
      dwMemoryLoad: dword;
      ullTotalPhys: int64;
      ullAvailPhys: int64;
      ullTotalPageFile: int64;
      ullAvailPageFile: int64;
      ullTotalVirtual: int64;
      ullAvailVirtual: int64;
      ullAvailExtendedVirtual: int64;
   end;

   TGlobalMemoryStatusEx = function(var mse: TMemoryStatusEx): bool; stdcall;

type
   TfrmAddEdit = class(TForm)
      pnlAll: TPanel;
      edtExeParams: TEdit;
      cmbWS: TComboBox;
      cmbPriority: TComboBox;
      lblType: TLabel;
      lblExeParams: TLabel;
      lblFirstDrive: TLabel;
      lblRun: TLabel;
      lblSecondDrive: TLabel;
      lblVMName: TLabel;
      lblPriority: TLabel;
      lblVMPath: TLabel;
      lblMode: TLabel;
      cmbMode: TComboBox;
      edtVMPath: TEdit;
      odSearchVM: TOpenDialog;
      cmbFirstDrive: TComboBox;
      cmbSecondDrive: TComboBox;
      cmbVMName: TComboBox;
      lblEnableCPUVirtualization: TLabel;
      cmbEnableCPUVirtualization: TComboBox;
      lblAudio: TLabel;
      cmbAudio: TComboBox;
      lblMemory: TLabel;
      lblHDD: TLabel;
      edtHDD: TEdit;
      odSearchHDD: TOpenDialog;
      edtMemory: TSpinEdit;
      lblCDROM: TLabel;
      cmbCDROM: TComboBox;
      odOpenISO: TOpenDialog;
      pnlVirtualBox: TPanel;
      sbQEMU: TPngSpeedButton;
      sbVirtualBox: TPngSpeedButton;
      btnBrowseForHDD: TPngSpeedButton;
      btnBrowseForVM: TPngSpeedButton;
      btnOK: TPngBitBtn;
      btnCancel: TPngBitBtn;
      pnlQEMU: TPanel;
      lblCache: TLabel;
      cmbCache: TComboBox;
      procedure sbVirtualBoxClick(Sender: TObject);
      procedure sbQEMUClick(Sender: TObject);
      procedure btnOKClick(Sender: TObject);
      procedure FormShow(Sender: TObject);
      procedure cmbModeChange(Sender: TObject);
      procedure btnBrowseForVMClick(Sender: TObject);
      procedure edtExeParamsChange(Sender: TObject);
      procedure cmbDriveChange(Sender: TObject);
      procedure cmbVMNameDropDown(Sender: TObject);
      procedure FormCreate(Sender: TObject);
      procedure AllKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
      procedure btnBrowseForHDDClick(Sender: TObject);
      procedure edtMemoryKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
      procedure cmbCDROMChange(Sender: TObject);
      procedure FormActivate(Sender: TObject);
      procedure cmbFirstDriveDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
      procedure cmbSecondDriveDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
      procedure cmbCDROMDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
      procedure FormDestroy(Sender: TObject);
      procedure FormKeyPress(Sender: TObject; var Key: Char);
      procedure pnlVirtualBoxEnter(Sender: TObject);
      procedure pnlVirtualBoxExit(Sender: TObject);
      procedure pnlQEMUEnter(Sender: TObject);
      procedure pnlQEMUExit(Sender: TObject);
      procedure sbQEMUMouseActivate(Sender: TObject; Button: TMouseButton;
         Shift: TShiftState; X, Y, HitTest: Integer;
         var MouseActivate: TMouseActivate);
      procedure sbVirtualBoxMouseActivate(Sender: TObject; Button: TMouseButton;
         Shift: TShiftState; X, Y, HitTest: Integer;
         var MouseActivate: TMouseActivate);
      procedure cmbVMNameChange(Sender: TObject);
   private
      { Private declarations }
      meParams: Boolean;
      originaledtHDDWindowProc: TWndMethod;
      originalcmbCDROMWindowProc: TWndMethod;
      originalcmbFirstDriveWindowProc: TWndMethod;
      originalcmbSecondDriveWindowProc: TWndMethod;
      procedure edtHDDWindowProc(var Msg: TMessage);
      procedure cmbCDROMWindowProc(var Msg: TMessage);
      procedure cmbFirstDriveWindowProc(var Msg: TMessage);
      procedure cmbSecondDriveWindowProc(var Msg: TMessage);
   public
      { Public declarations }
      aDL: array of DriveLetters;
      VMIDs: array of VMID;
      aCDROMInfo: array of CDROMInfo;
      ShowedThisSession: Boolean;
      CDDVDType: Byte;
      isEdit: Boolean;
      nCDROMS: Word;
      CBClientWidth: Integer;
      CBMaxLetSize: Integer;
      CBFirstDriveName, CBFirstDriveSize, CBFirstDriveLetters: array of string;
      CBSecondDriveName, CBSecondDriveSize, CBSecondDriveLetters: array of string;
      procedure GetNamesAndIDs;
      procedure GetCDROMS;
      procedure GetDrives(Sender: TObject);
      function FindCDROMFromLetter(const CDROMLetter: AnsiChar): AnsiString;
   end;

var
   frmAddEdit: TfrmAddEdit;
   RectDrawned: Boolean = False;
   HMargin: Integer = 12;
   ItemHeight: Integer = 32;
   lblToEditDiff: Integer = 2;

implementation

uses MainForm;

{$R *.dfm}

function isGUID(const ws: string): Boolean;
var
   i, l: Integer;
begin
   Result := False;
   l := Length(ws);
   if l <> 36 then
      Exit;
   for i := 1 to 36 do
      if i in [9, 14, 19, 24] then
      begin
         if ws[i] <> '-' then
            Exit;
      end
      else if ((ws[i] < '0') or (ws[i] > '9')) and ((ws[i] < 'A') or (ws[i] > 'F')) and ((ws[i] < 'a') or (ws[i] > 'f')) then
         Exit;
   Result := True;
end;

procedure TfrmAddEdit.sbVirtualBoxClick(Sender: TObject);
var
   p: Integer;
   OrgFocused: TWinControl;
begin
   sbVirtualBox.Down := True;
   if not sbQEMU.Down then
      Exit;
   sbQEMU.Down := False;
   if Visible then
   begin
      OrgFocused := ActiveControl;
      ActiveControl := nil;
   end
   else
      OrgFocused := nil;
   lblMode.Visible := True;
   cmbMode.Visible := True;
   if not meParams then
   begin
      edtExeParams.Text := '';
      meParams := False;
   end;
   if Visible then
      cmbMode.ItemIndex := 0;
   cmbModeChange(cmbMode);
   p := cmbWS.ItemIndex;
   cmbWS.Items.Text := GetLangTextDef(idxAddEdit, ['Comboboxes', 'WindowSize', 'VirtualBox'], 'Normal'#13#10'Minimized'#13#10'Maximized'#13#10'Fullscreen');
   cmbWS.ItemIndex := p;
   lblAudio.Visible := False;
   cmbAudio.Visible := False;
   lblMemory.Visible := False;
   edtMemory.Visible := False;
   lblHDD.Visible := False;
   edtHDD.Visible := False;
   btnBrowseForHDD.Visible := False;
   lblCDROM.Visible := False;
   cmbCDROM.Visible := False;
   Height := Height - 2 * ItemHeight;
   lblEnableCPUVirtualization.Visible := True;
   cmbEnableCPUVirtualization.Visible := True;
   lblFirstDrive.Top := lblFirstDrive.Top + 3 * ItemHeight;
   cmbFirstDrive.Top := cmbFirstDrive.Top + 3 * ItemHeight;
   lblExeParams.Top := lblExeParams.Top + 3 * ItemHeight;
   edtExeParams.Top := edtExeParams.Top + 3 * ItemHeight;
   lblVMPath.Top := lblVMPath.Top + 3 * ItemHeight;
   btnBrowseForVM.Top := btnBrowseForVM.Top + 3 * ItemHeight;
   edtVMPath.Top := edtVMPath.Top + 3 * ItemHeight;
   lblVMName.Top := lblVMName.Top + 3 * ItemHeight;
   cmbVMName.Top := cmbVMName.Top + 3 * ItemHeight;
   if AddSecondDrive then
   begin
      lblSecondDrive.Top := lblSecondDrive.Top + 3 * ItemHeight;
      cmbSecondDrive.Top := cmbSecondDrive.Top + 3 * ItemHeight;
      lblCache.Top := HMargin + 5 * ItemHeight;
      cmbCache.Top := HMargin + 5 * ItemHeight - lblToEditDiff;
   end
   else
   begin
      lblCache.Top := HMargin + 4 * ItemHeight;
      cmbCache.Top := HMargin + 4 * ItemHeight - lblToEditDiff;
   end;
   if Visible then
   begin
      if OrgFocused <> nil then
         if OrgFocused.Visible then
            OrgFocused.SetFocus
         else
            cmbMode.SetFocus;
      RedrawWindow(Handle, nil, 0, RDW_ERASE or RDW_FRAME or RDW_INVALIDATE or RDW_ALLCHILDREN or RDW_UPDATENOW);
   end;
end;

procedure TfrmAddEdit.sbVirtualBoxMouseActivate(Sender: TObject;
   Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer;
   var MouseActivate: TMouseActivate);
begin
   if (ActiveControl = nil) or (ActiveControl = pnlQEMU) then
      pnlVirtualBox.SetFocus;
end;

procedure TfrmAddEdit.sbQEMUClick(Sender: TObject);
var
   i, j, p, l: Integer;
   ws, r: string;
   OrgFocused: TWinControl;
begin
   sbQEMU.Down := True;
   if not sbVirtualBox.Down then
      Exit;
   sbVirtualBox.Down := False;
   if Visible then
   begin
      SendMessage(Handle, WM_SETREDRAW, WPARAM(False), 0);
      OrgFocused := ActiveControl;
      ActiveControl := nil;
   end
   else
      OrgFocused := nil;
   lblMode.Visible := False;
   cmbMode.Visible := False;
   if not meParams then
   begin
      ws := QEMUDefaultParameters;
      p := Pos(string('-m '), ws, 1);
      if (p = 1) or ((p > 1) and (ws[p - 1] = ' ')) then
      begin
         r := '';
         l := Length(ws);
         for i := p + 3 to l do
            if (ws[i] >= '0') and (ws[i] <= '9') then
               r := r + ws[i]
            else
               Break;
         edtMemory.Text := IntToStr(Min(Max(StrToIntDef(r, 512), 0), 65535));
         Delete(ws, Max(1, p - 1), i - Max(1, p - 1));
      end;
      p := Pos(string('-soundhw '), ws, 1);
      if (p = 1) or ((p > 1) and (ws[p - 1] = ' ')) then
      begin
         r := '';
         l := Length(ws);
         for i := p + 9 to l do
            if (ws[i] <> ' ') and (ws[i] <> '-') then
               r := r + ws[i]
            else
               Break;
         if r = 'sb16' then
            j := 1
         else if r = 'pcspk' then
            j := 2
         else if r = 'hda' then
            j := 3
         else if r = 'gus' then
            j := 4
         else if r = 'es1370' then
            j := 5
         else if r = 'cs4231a' then
            j := 6
         else if r = 'adlib' then
            j := 7
         else if r = 'ac97' then
            j := 8
         else
            j := 0;
         cmbAudio.ItemIndex := j;
         Delete(ws, Max(1, p - 1), i - Max(1, p - 1));
      end;
      edtExeParams.Text := ws;
      meParams := False;
   end;
   cmbMode.ItemIndex := 2;
   cmbModeChange(cmbMode);
   p := cmbWS.ItemIndex;
   cmbWS.Items.Text := GetLangTextDef(idxAddEdit, ['Comboboxes', 'WindowSize', 'QEMU'], 'Normal'#13#10'Minimized'#13#10'Maximized'#13#10'Fullscreen');
   cmbWS.ItemIndex := p;
   lblMemory.Visible := True;
   edtMemory.Visible := True;
   lblAudio.Visible := True;
   cmbAudio.Visible := True;
   lblHDD.Visible := True;
   edtHDD.Visible := True;
   btnBrowseForHDD.Visible := True;
   lblCDROM.Visible := True;
   cmbCDROM.Visible := True;
   Height := Height + 2 * ItemHeight;
   lblEnableCPUVirtualization.Visible := False;
   cmbEnableCPUVirtualization.Visible := False;
   lblVMPath.Top := lblVMPath.Top - 3 * ItemHeight;
   lblVMName.Top := lblVMName.Top - 3 * ItemHeight;
   btnBrowseForVM.Top := btnBrowseForVM.Top - 3 * ItemHeight;
   edtVMPath.Top := edtVMPath.Top - 3 * ItemHeight;
   cmbVMName.Top := cmbVMName.Top - 3 * ItemHeight;
   lblFirstDrive.Top := lblFirstDrive.Top - 3 * ItemHeight;
   cmbFirstDrive.Top := cmbFirstDrive.Top - 3 * ItemHeight;
   lblExeParams.Top := lblExeParams.Top - 3 * ItemHeight;
   edtExeParams.Top := edtExeParams.Top - 3 * ItemHeight;
   btnBrowseForHDD.Top := edtHDD.Top;
   if AddSecondDrive then
   begin
      lblSecondDrive.Top := lblSecondDrive.Top - 3 * ItemHeight;
      cmbSecondDrive.Top := cmbSecondDrive.Top - 3 * ItemHeight;
      lblCache.Top := HMargin + 4 * ItemHeight;
      cmbCache.Top := HMargin + 4 * ItemHeight - lblToEditDiff;
      lblHDD.Top := HMargin + 5 * ItemHeight;
      edtHDD.Top := HMargin + 5 * ItemHeight - lblToEditDiff;
   end
   else
   begin
      lblCache.Top := HMargin + 3 * ItemHeight;
      cmbCache.Top := HMargin + 3 * ItemHeight - lblToEditDiff;
      lblHDD.Top := HMargin + 4 * ItemHeight;
      edtHDD.Top := HMargin + 4 * ItemHeight - lblToEditDiff;
   end;
   btnBrowseForHDD.Top := edtHDD.Top;
   if Visible then
   begin
      SendMessage(Handle, WM_SETREDRAW, WPARAM(True), 0);
      if OrgFocused <> nil then
         if OrgFocused.Visible then
            OrgFocused.SetFocus
         else
            edtExeParams.SetFocus;
      RedrawWindow(Handle, nil, 0, RDW_ERASE or RDW_FRAME or RDW_INVALIDATE or RDW_ALLCHILDREN or RDW_UPDATENOW);
      GetCDROMS;
   end;
end;

procedure TfrmAddEdit.sbQEMUMouseActivate(Sender: TObject; Button: TMouseButton;
   Shift: TShiftState; X, Y, HitTest: Integer;
   var MouseActivate: TMouseActivate);
begin
   if (ActiveControl = nil) or (ActiveControl = pnlVirtualBox) then
      pnlQEMU.SetFocus;
end;

function GlobalMemoryStatusEx(var lpBuffer: TMemoryStatusEx): bool; stdcall; external kernel32;

procedure TfrmAddEdit.btnOKClick(Sender: TObject);
var
   i, p, l, cp, n1, n2, n3, a1: Integer;
   ws, wst: string;
   MemStatEx: TMemoryStatusEx;
begin
   ModalResult := mrNone;
   if sbVirtualBox.Down then
   begin
      case cmbMode.ItemIndex of
         1:
            if Trim(edtVMPath.Text) = '' then
            begin
               CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'SetVMPath'], 'Please set the VM Path !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
               edtVMPath.SetFocus;
               Exit;
            end
            else
            begin
               ws := ChangeFileExt(ExtractFileName(Trim(edtVMPath.Text)), '');
               GetNamesAndIDs;
               i := 0;
               while i <= High(VMIDs) do
               begin
                  if VMIDs[i].Name = ws then
                     Break;
                  Inc(i);
               end;
               if i > High(VMIDs) then
               begin
                  CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'VMNotFound'], 'Could not find this VM in the VirtualBox configuration files !'#13#10'Please make sure that VirtualBox is properly installed'#13#10'and the VM is properly registered in the VirtualBox Manager.')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
                  edtVMPath.SetFocus;
                  Exit;
               end;
            end;
         2:
            if (Trim(edtExeParams.Text) = '') then
            begin
               CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'SetExeParam'], 'Please set the exe parameters !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
               edtExeParams.SetFocus;
               Exit;
            end
            else
            begin
               ws := Trim(edtExeParams.Text);
               p := Pos(string('--startvm "'), ws, 1);
               l := Length(ws);
               if (p > 0) and ((p + 11) < l) then
               begin
                  cp := PosEx('"', ws, p + 11);
                  if cp > 0 then
                     ws := Trim(Copy(ws, p + 11, cp - p - 11))
                  else
                     ws := '';
               end
               else
                  ws := '';
               if FileExists(ws) then
               begin
                  wst := ChangeFileExt(ExtractFileName(wst), '');
                  GetNamesAndIDs;
                  i := 0;
                  while i <= High(VMIDs) do
                  begin
                     if VMIDs[i].Name = wst then
                        Break;
                     Inc(i);
                  end;
                  if i > High(VMIDs) then
                     ws := '';
               end
               else
               begin
                  with frmMain.xmlGen do
                  begin
                     if Tag = 1 then
                     try
                        Active := True;
                        n1 := ChildNodes.IndexOf('VirtualBox');
                        if n1 > -1 then
                        begin
                           n2 := ChildNodes[n1].ChildNodes.IndexOf('Global');
                           if n2 > -1 then
                           begin
                              n3 := ChildNodes[n1].ChildNodes[n2].ChildNodes.IndexOf('SystemProperties');
                              if n3 > -1 then
                              begin
                                 a1 := ChildNodes[n1].ChildNodes[n2].ChildNodes[n3].AttributeNodes.IndexOf('defaultMachineFolder');
                                 if a1 > -1 then
                                 begin
                                    wst := ChildNodes[n1].ChildNodes[n2].ChildNodes[n3].AttributeNodes[a1].Text;
                                    Replacebks(wst, Length(wst));
                                 end;
                              end;
                           end;
                        end;
                     except
                     end;
                     Active := False;
                  end;

                  if (ExtractFileName(ws) = ws) and (ExtractFileExt(ws) <> '') and FileExists(wst + '\' + ChangeFileExt(ws, '') + '\' + ws) then
                  else if (ExtractFileName(ws) = ws) and (ExtractFileExt(ws) = '') and FileExists(wst + '\' + ws + '\' + ws + '.vbox') then
                  else if isGUID(ws) then
                  begin
                     i := 0;
                     while i <= High(VMIDs) do
                     begin
                        if string(VMIDs[i].ID) = ws then
                           Break;
                        Inc(i);
                     end;
                     if i > High(VMIDs) then
                        ws := '';
                  end
                  else
                     ws := '';
               end;
               if ws = '' then
               begin
                  CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'SetExeParamCor'], 'Please set the exe parameters correctly !'#13#10'Just use <<--startvm "Path_to_VM or GUID">> (without the <<>>)')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
                  edtExeParams.SetFocus;
                  Exit;
               end;
            end
         else
            if cmbVMName.ItemIndex <= 1 then
            begin
               if cmbVMName.Items.Count > 2 then
               begin
                  CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'SetVMName'], 'Please set a VM name !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
                  cmbVMName.SetFocus;
                  Exit;
               end
               else
               begin
                  CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'NoVMsFound'], 'Please add a VM in VirtualBox Manager or solve the problem'#13#10'with VirtualBox installation so you can set a VM name !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
                  cmbVMName.SetFocus;
                  Exit;
               end;
            end;
      end;
   end
   else if Trim(edtExeParams.Text) = '' then
   begin
      CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'SetExeParam'], 'Please set the exe parameters !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
      edtExeParams.SetFocus;
      Exit;
   end;
   if cmbFirstDrive.ItemIndex < 1 then
   begin
      if AddSecondDrive then
         CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'ChooseFirstDrive'], 'Please choose the first drive !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk)
      else
         CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'ChooseDrive'], 'Please choose the drive !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
      cmbFirstDrive.SetFocus;
      Exit;
   end;
   if AddSecondDrive then
      if cmbFirstDrive.Items[cmbFirstDrive.ItemIndex] = cmbSecondDrive.Items[cmbSecondDrive.ItemIndex] then
      begin
         CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'DifSecDrive'], 'Please set a different second drive !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
         cmbSecondDrive.SetFocus;
         Exit;
      end;
   if sbQEMU.Down then
   begin
      i := StrToIntDef(edtMemory.Text, -1);
      if (i < 1) or (i > 65535) then
      begin
         CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'MemoryRange'], 'Please set a memory value in the 1..65535 interval !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
         edtMemory.SetFocus;
         Exit;
      end;
      FillChar(MemStatEx, SizeOf(MemStatEx), 0);
      try
         MemStatEx.dwLength := SizeOf(MemStatEx);
         GlobalMemoryStatusEx(MemStatEx);
      except
         i := 0;
      end;
      if MemStatEx.ullTotalPhys >= 134217728 then
         if i > Round(0.5 * MemStatEx.ullTotalPhys / 1048576) then
         begin
            if CustomMessageBox(Handle, (GetLangTextFormatDef(idxAddEdit, ['Messages', 'MoreThanHalfRam'], [i, Round(1.0 * MemStatEx.ullTotalPhys / 1048576)], 'You have assigned more than 50%% of the'#13#10'total physical RAM size (%d from %d MB) !'#13#10#13#10'Are you sure that''s wise...?')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbYes, mbNo], mbNo) <> mrYes then
            begin
               edtMemory.SetFocus;
               Exit;
            end;
         end;

      if Trim(edtHDD.Text) <> '' then
         if (not FileExists(Trim(edtHDD.Text))) and ((Pos('-L .', edtExeParams.Text) > 0) and (not FileExists(ExtractFilePath(ExeQPath) + Trim(edtHDD.Text)))) then
         begin
            if CustomMessageBox(Handle, (GetLangTextFormatDef(idxAddEdit, ['Messages', 'HDDNotFound'], [Trim(edtHDD.Text)], '"%s" doesn''t seem to exist !'#13#10'Are you sure you want to use it...?'#13#10'Tip: if you don''t want to set an internal HDD, just clear the edit box...')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk) <> mrYes then
            begin
               edtHDD.SetFocus;
               Exit;
            end;
         end;
   end;
   ModalResult := mrOK;
end;

procedure TfrmAddEdit.FormShow(Sender: TObject);
begin
   case SystemIconSize of
      -2147483647..18:
         begin
            frmMain.imlBtn16.GetIcon(1 + Integer(isEdit), Icon);
            btnBrowseForVM.PngImage := frmMain.imlBtn24.PngImages[30].PngImage;
            btnBrowseForHDD.PngImage := frmMain.imlBtn24.PngImages[30].PngImage;
            sbVirtualBox.PngImage := frmMain.imlBtn16.PngImages[8].PngImage;
            sbQEMU.PngImage := frmMain.imlBtn16.PngImages[9].PngImage;
            btnOK.PngImage := frmMain.imlBtn16.PngImages[14].PngImage;
            btnCancel.PngImage := frmMain.imlBtn16.PngImages[15].PngImage;
         end;
      19..22:
         begin
            frmMain.imlBtn20.GetIcon(1 + Integer(isEdit), Icon);
            btnBrowseForVM.PngImage := frmMain.imlBtn28.PngImages[0].PngImage;
            btnBrowseForHDD.PngImage := frmMain.imlBtn28.PngImages[0].PngImage;
            sbVirtualBox.PngImage := frmMain.imlBtn20.PngImages[8].PngImage;
            sbQEMU.PngImage := frmMain.imlBtn20.PngImages[9].PngImage;
            btnOK.PngImage := frmMain.imlBtn20.PngImages[14].PngImage;
            btnCancel.PngImage := frmMain.imlBtn20.PngImages[15].PngImage;
         end;
      23..2147483647:
         begin
            frmMain.imlBtn24.GetIcon(1 + Integer(isEdit), Icon);
            btnBrowseForVM.PngImage := frmMain.imlBtn32.PngImages[1].PngImage;
            btnBrowseForHDD.PngImage := frmMain.imlBtn32.PngImages[1].PngImage;
            sbVirtualBox.PngImage := frmMain.imlBtn24.PngImages[8].PngImage;
            sbQEMU.PngImage := frmMain.imlBtn24.PngImages[9].PngImage;
            btnOK.PngImage := frmMain.imlBtn24.PngImages[14].PngImage;
            btnCancel.PngImage := frmMain.imlBtn24.PngImages[15].PngImage;
         end;
   end;
   btnBrowseForVM.Top := edtVMPath.Top;
   btnBrowseForVM.Height := edtVMPath.Height;
   btnBrowseForHDD.Top := edtHDD.Top;
   btnBrowseForHDD.Height := edtHDD.Height;
   if FocusFirstDrive then
      cmbFirstDrive.SetFocus
   else if FocusSecDrive then
      cmbSecondDrive.SetFocus
   else if cmbMode.Visible then
      cmbMode.SetFocus
   else if edtExeParams.Visible then
      edtExeParams.SetFocus;
end;

procedure TfrmAddEdit.cmbModeChange(Sender: TObject);
begin
   case cmbMode.ItemIndex of
      1:
         begin
            lblVMName.Visible := False;
            cmbVMName.Visible := False;
            lblVMPath.Visible := True;
            edtVMPath.Visible := True;
            btnBrowseForVM.Visible := True;
            lblExeParams.Visible := False;
            edtExeParams.Visible := False;
            if Visible then
            begin
               edtVMPath.SetFocus;
               edtVMPath.SelStart := Length(edtVMPath.Text);
               edtVMPath.SelLength := 0;
            end;
         end;
      2:
         begin
            lblVMName.Visible := False;
            cmbVMName.Visible := False;
            lblVMPath.Visible := False;
            edtVMPath.Visible := False;
            btnBrowseForVM.Visible := False;
            lblExeParams.Visible := True;
            edtExeParams.Visible := True;
            if Visible then
            begin
               edtExeParams.SetFocus;
               edtExeParams.SelStart := Length(edtExeParams.Text);
               edtExeParams.SelLength := 0;
            end;
         end;
      else
         begin
            lblVMName.Visible := True;
            cmbVMName.Visible := True;
            lblVMPath.Visible := False;
            edtVMPath.Visible := False;
            btnBrowseForVM.Visible := False;
            lblExeParams.Visible := False;
            edtExeParams.Visible := False;
            if Visible then
               cmbVMName.SetFocus;
         end;
   end;
end;

procedure TfrmAddEdit.btnBrowseForVMClick(Sender: TObject);
var
   FolderName: string;
   n1, n2, n3, a, i, l: Integer;
begin
   btnBrowseForVM.Repaint;
   FolderName := ExtractFilePath(odSearchVM.FileName);
   odSearchVM.FileName := '';
   if FolderName = '' then
   begin
      if odSearchVM.InitialDir = '' then
      begin

         with frmMain.xmlGen do
         begin
            if Tag = 1 then
            try
               Active := True;
               n1 := ChildNodes.IndexOf('VirtualBox');
               if n1 > -1 then
               begin
                  n2 := ChildNodes[n1].ChildNodes.IndexOf('Global');
                  if n2 > -1 then
                  begin
                     n3 := ChildNodes[n1].ChildNodes[n2].ChildNodes.IndexOf('SystemProperties');
                     if n3 > -1 then
                     begin
                        a := ChildNodes[n1].ChildNodes[n2].ChildNodes[n3].AttributeNodes.IndexOf('defaultMachineFolder');
                        if a > -1 then
                        begin
                           FolderName := ChildNodes[n1].ChildNodes[n2].ChildNodes[n3].AttributeNodes[a].Text;
                           l := Length(FolderName);
                           if l > 2 then
                           begin
                              i := 1;
                              while i <= l do
                              begin
                                 if FolderName[i] = '/' then
                                    FolderName[i] := '\';
                                 Inc(i);
                              end;
                           end;
                        end;
                     end;
                  end;
               end;
            except
            end;
            Active := False;
         end;

         if DirectoryExists(FolderName) then
            odSearchVM.InitialDir := FolderName;
      end;
   end
   else
      odSearchVM.InitialDir := FolderName;

   if odSearchVM.Execute(Self.Handle) then
   begin
      edtVMPath.Text := odSearchVM.FileName;
      edtVMPath.SetFocus;
      edtVMPath.SelStart := Length(edtVMPath.Text);
      edtVMPath.SelLength := 0;
   end;
   SetFocus;
end;

procedure TfrmAddEdit.edtExeParamsChange(Sender: TObject);
begin
   meParams := True;
end;

procedure TfrmAddEdit.cmbDriveChange(Sender: TObject);
begin
   try
      if not sbQEMU.Down then
         if (Sender as TComboBox).ItemIndex > 0 then
            if (not DriveMessageShowed) and (not ShowedThisSession) and (Sender <> cmbSecondDrive) then
            begin
               try
                  cbConfirmationSt := True;
                  CustomMessageBox(Handle, GetLangTextFormatDef(idxAddEdit, ['Messages', 'AddFirstPort'], [btnOK.Caption], 'It will add the drive to the first available port in the VirtualBox VM''s storage controller(s).'#13#10'If it will not find one available it will fail...'#13#10#13#10 + 'If you want to boot from this drive make sure the available port'#13#10'is prior to other ports with HDDs and the VirtualBox VM is set to boot from HDD.'), GetLangTextDef(idxMessages, ['Types', 'Information'], 'Information'), mtInformation, [mbOk], mbOk, GetLangTextDef(idxMessages, ['Checkboxes', 'DontShow'], 'Don''t show this next time'));
                  DriveMessageShowed := cbConfirmationSt;
                  ShowedThisSession := True;
               except
               end;
            end;
   except
   end;
end;

procedure TfrmAddEdit.GetNamesAndIDs;
var
   i, p1, l, n1, n2, n3: Integer;
   wn, wid: string;
begin
   SetLength(VMIDs, 0);
   with frmMain.xmlGen do
   begin
      if Tag = 1 then
      try
         Active := True;
         n1 := ChildNodes.IndexOf('VirtualBox');
         if n1 > -1 then
         begin
            n2 := ChildNodes[n1].ChildNodes.IndexOf('Global');
            if n2 > -1 then
            begin
               n3 := ChildNodes[n1].ChildNodes[n2].ChildNodes.IndexOf('MachineRegistry');
               if n3 > -1 then
                  for i := 0 to ChildNodes[n1].ChildNodes[n2].ChildNodes[n3].ChildNodes.Count - 1 do
                  try
                     p1 := ChildNodes[n1].ChildNodes[n2].ChildNodes[n3].ChildNodes[i].AttributeNodes.IndexOf('src');
                     if p1 = -1 then
                        Continue;
                     wn := ChildNodes[n1].ChildNodes[n2].ChildNodes[n3].ChildNodes[i].AttributeNodes[p1].Text;
                     l := Length(wn);
                     if l < 9 then
                        Continue;
                     p1 := l;
                     while p1 > 0 do
                     begin
                        if (wn[p1] = '\') or (wn[p1] = '/') then
                           Break;
                        Dec(p1);
                     end;
                     wn := ChangeFileExt(Copy(wn, p1 + 1, l - p1), '');
                     p1 := ChildNodes[n1].ChildNodes[n2].ChildNodes[n3].ChildNodes[i].AttributeNodes.IndexOf('uuid');
                     if p1 = -1 then
                        Continue;
                     wid := ChildNodes[n1].ChildNodes[n2].ChildNodes[n3].ChildNodes[i].AttributeNodes[p1].Text;
                     l := Length(wid);
                     if l < 3 then
                        Continue;
                     SetLength(VMIDs, Length(VMIDs) + 1);
                     VMIDs[High(VMIDs)].Name := wn;
                     VMIDs[High(VMIDs)].ID := AnsiString(Copy(wid, 2, l - 2));
                  except
                  end;
            end;
         end;
      except
      end;
      Active := False;
   end;
end;

procedure TfrmAddEdit.pnlQEMUEnter(Sender: TObject);
begin
   sbQEMU.Repaint;
end;

procedure TfrmAddEdit.pnlQEMUExit(Sender: TObject);
begin
   sbQEMU.Repaint;
end;

procedure TfrmAddEdit.pnlVirtualBoxEnter(Sender: TObject);
begin
   sbVirtualBox.Repaint;
end;

procedure TfrmAddEdit.pnlVirtualBoxExit(Sender: TObject);
begin
   sbVirtualBox.Repaint;
end;

procedure TfrmAddEdit.cmbVMNameChange(Sender: TObject);
begin
   if not Visible then
      Exit;
   if not cmbVMName.Visible then
      Exit;
   if cmbVMName.ItemIndex = 1 then
   begin
      frmMain.StartVBNewMachineWizzard;
      cmbVMName.ItemIndex := 0;
   end;
end;

procedure TfrmAddEdit.cmbVMNameDropDown(Sender: TObject);
var
   i: Integer;
   t: TStrings;
begin
   GetNamesAndIDs;
   try
      t := TStringList.Create;
      t.Add(GetLangTextDef(idxAddEdit, ['Comboboxes', 'NoneText'], 'None'));
      t.Add(GetLangTextDef(idxAddEdit, ['Comboboxes', 'CreateNewVM'], 'Create new VM'));
      for i := 0 to High(VMIDs) do
         t.Add('"' + VMIDs[i].Name + '"');
      if not cmbVMName.Items.Equals(t) then
      begin
         i := cmbVMName.ItemIndex;
         cmbVMName.Items.Assign(t);
         cmbVMName.ItemIndex := Min(cmbVMName.Items.Count - 1, i);
      end;
      t.Free;
   except
   end;
end;

procedure TfrmAddEdit.GetDrives(Sender: TObject);
var
   i, j, k: Integer;
   sz: Double;
   hVolume, hDrive, hSrcVol: THandle;
   dwBytesReturned, dwBytesRead, dwBytesSize: DWORD;
   sdn: STORAGE_DEVICE_NUMBER;
   ErrorMode: Word;
   ws, wsAdd, vap, size: string;
   csz, mu: AnsiString;
   tsl: TStrings;
   Switched, bSuccess: Boolean;
   BusType: Byte;
   acTemp: DriveLetters;
   volName, volBuffer: array[0..MAX_PATH] of WideChar;
   VolPaths: PWideChar;

   procedure Round3;
   var
      k, n: Integer;
   begin
      k := 0;
      if sz < 100 then
      begin
         while sz < 1000 do
         begin
            sz := sz * 10;
            Inc(k);
         end;
         Dec(k);
         csz := AnsiString(IntToStr(Round(sz / 10)));
         if k <= 2 then
            Insert('.', csz, 4 - k)
         else
         begin
            for n := 1 to k - 2 do
               csz := '0' + csz;
            Insert('.', csz, 2);
         end;
      end
      else if sz > 1000 then
      begin
         while sz > 100 do
         begin
            sz := sz / 10;
            Inc(k);
         end;
         Dec(k);
         csz := AnsiString(IntToStr(Round(sz * 10)));
         for n := 1 to k do
            csz := csz + '0';
      end
      else
         csz := AnsiString(IntToStr(Round(sz)));
   end;

begin
   if DriveToAdd > -1 then
   begin
      try
         hDrive := CreateFile(PWideChar('\\.\PHYSICALDRIVE' + IntToStr(DriveToAdd)), GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
      except
         hDrive := INVALID_HANDLE_VALUE;
      end;
      if hDrive = INVALID_HANDLE_VALUE then
         DriveToAdd := -1
      else
      begin
         vap := string(GetDriveVendorAndProductID(hDrive));
         if vap = '' then
         begin
            DriveToAdd := -1;
            try
               CloseHandle(hDrive);
            except
            end;
         end
         else
         begin
            sz := GetDriveSize(hDrive) / 1073741824;
            BusType := GetBusType(hDrive);
            try
               CloseHandle(hDrive);
            except
            end;
            if sz <= 0 then
            begin
               DriveToAdd := -1;
               CustomMessageBox(Handle, (GetLangTextFormatDef(idxAddEdit, ['Messages', 'CantReadDrive'], [SysErrorMessage(LastError)], 'Can''t read from drive !'#13#10#13#10'System message: %s')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
            end
            else
            begin
               if sz < 1 then
               begin
                  sz := sz * 1024;
                  mu := 'MB';
               end
               else if sz > 1000 then
               begin
                  sz := sz / 1024;
                  mu := 'TB';
               end
               else
                  mu := 'GB';
               Round3;
               size := string(csz + ' ' + mu);
               if size = '' then
                  DriveToAdd := -1;
               wsAdd := GetStrBusType(BusType);
               if wsAdd <> '' then
                  vap := wsAdd + '  ' + vap;
               wsAdd := vap + string(', ' + csz + ' ' + mu);

               if (Sender = nil) or ((Sender as TComboBox).Name = 'cmbFirstDrive') then
               begin
                  SetLength(CBFirstDriveName, cmbFirstDrive.Items.Count);
                  SetLength(CBFirstDriveSize, cmbFirstDrive.Items.Count);
                  SetLength(CBFirstDriveLetters, cmbFirstDrive.Items.Count);
                  CBFirstDriveName[High(CBFirstDriveName)] := vap;
                  CBFirstDriveSize[High(CBFirstDriveSize)] := string(csz) + HalfSpaceCharCMB + string(mu);
                  CBFirstDriveLetters[High(CBFirstDriveLetters)] := '[ ]';
                  CBMaxLetSize := cmbFirstDrive.Canvas.TextWidth('  [ ]');
                  cmbFirstDrive.Items.Append(wsAdd + ' ]');
                  cmbFirstDrive.ItemIndex := cmbFirstDrive.Items.Count - 1;
                  cmbFirstDrive.Invalidate;
               end;
               if AddSecondDrive and ((Sender = nil) or ((Sender as TComboBox).Name = 'cmbSecondDrive')) then
               begin
                  SetLength(CBSecondDriveName, cmbSecondDrive.Items.Count);
                  SetLength(CBSecondDriveSize, cmbSecondDrive.Items.Count);
                  SetLength(CBSecondDriveLetters, cmbSecondDrive.Items.Count);
                  CBSecondDriveName[High(CBSecondDriveName)] := vap;
                  CBSecondDriveSize[High(CBSecondDriveSize)] := string(csz) + HalfSpaceCharCMB + string(mu);
                  CBSecondDriveLetters[High(CBSecondDriveLetters)] := '[ ]';
                  CBMaxLetSize := cmbSecondDrive.Canvas.TextWidth('  [ ]');
                  cmbSecondDrive.Items.Append(wsAdd + ' ]');
                  cmbSecondDrive.ItemIndex := cmbSecondDrive.Items.Count - 1;
                  cmbSecondDrive.Invalidate;
               end;
            end;
         end;
      end;
   end;

   tsl := TStringList.Create;
   tsl.BeginUpdate;
   tsl.Add(GetLangTextDef(idxAddEdit, ['Comboboxes', 'NoneText'], 'None'));
   ErrorMode := SetErrorMode(SEM_FailCriticalErrors);
   SetLength(aDL, 1);
   aDL[0].Number := -1;
   { for i := Byte('C') to Byte('Z') do
    begin
       try
          case GetDriveType(PWideChar(AnsiChar(i) + ':\')) of
             DRIVE_REMOVABLE, DRIVE_FIXED:
                begin
                   try
                      hVolume := CreateFile(PWideChar('\\.\' + Char(i) + ':'), 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
                   except
                      hVolume := INVALID_HANDLE_VALUE;
                   end;
                   if hVolume <> INVALID_HANDLE_VALUE then
                   begin
                      BusType := GetBusType(hVolume);
                      if ListOnlyUSBDrives and (BusType <> 7) then
                      begin
                         try
                            CloseHandle(hVolume);
                         except
                         end;
                         Continue;
                      end;
                      dwBytesReturned := 0;
                      try
                         if DeviceIoControl(hVolume, IOCTL_STORAGE_GET_DEVICE_NUMBER, nil, 0, @sdn, SizeOf(sdn), dwBytesReturned, nil) then
                            if sdn.DeviceNumber <> OSDrive then
                            begin
                               j := 0;
                               while j <= High(aDL) do
                               begin
                                  if Cardinal(aDL[j].Number) = sdn.DeviceNumber then
                                     Break;
                                  Inc(j);
                               end;
                               if j > High(aDL) then
                               begin
                                  SetLength(aDL, Length(aDL) + 1);
                                  aDL[j].Number := sdn.DeviceNumber;
                                  aDL[j].BusType := BusType;
                               end;
                               SetLength(aDL[j].VolPaths, Length(aDL[j].VolPaths) + 1);
                               aDL[j].VolPaths[High(aDL[j].VolPaths)] := WideChar(i);
                            end;
                      except
                      end;
                      try
                         CloseHandle(hVolume);
                      except
                      end;
                   end;
                end
          else
             Continue;
          end;
       except
       end;
    end;      }

   SetLength(VolumesInfo, 0);
   try
      hSrcVol := FindFirstVolumeW(@volName, SizeOf(volName));
      LastError := GetLastError;
   except
      hSrcVol := INVALID_HANDLE_VALUE;
   end;
   if hSrcVol <> INVALID_HANDLE_VALUE then
   begin
      repeat
         if Copy(volName, 1, 4) = '\\?\' then
         begin
            try
               GetVolumePathNamesForVolumeNameW(volName, nil, 0, dwBytesRead);
               LastError := GetLastError;
            except
               on E: Exception do
            end;
            if (LastError = ERROR_MORE_DATA) and (dwBytesRead >= 5) then
            begin
               dwBytesSize := 2 * dwBytesRead;
               VolPaths := AllocMem(dwBytesSize);
               try
                  bSuccess := GetVolumePathNamesForVolumeNameW(volName, VolPaths, dwBytesSize, dwBytesRead);
                  LastError := GetLastError;
               except
                  bSuccess := False;
               end;
               if bSuccess then
               begin
                  while VolName[StrLen(VolName) - 1] = '\' do
                     VolName[StrLen(VolName) - 1] := #0;
                  i := 0;
                  while i < (Integer(dwBytesRead) - 1) do
                  begin
                     if ((i > 1) and (VolPaths[i - 1] = #0) and (VolPaths[i] <> #0)) or (i = 0) then
                     begin
                        VolBuffer[0] := VolPaths[i];
                        j := i;
                        repeat
                           Inc(i);
                           VolBuffer[i - j] := VolPaths[i];
                        until VolPaths[i] = #0;
                        try
                           case GetDriveType(VolBuffer) of
                              DRIVE_REMOVABLE, DRIVE_FIXED:
                                 begin
                                    try
                                       hVolume := CreateFile(VolName, 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
                                    except
                                       hVolume := INVALID_HANDLE_VALUE;
                                    end;
                                    if hVolume <> INVALID_HANDLE_VALUE then
                                    begin
                                       BusType := GetBusType(hVolume);
                                       if ListOnlyUSBDrives and (BusType <> 7) then
                                       begin
                                          try
                                             CloseHandle(hVolume);
                                          except
                                          end;
                                          Continue;
                                       end;
                                       dwBytesReturned := 0;
                                       try
                                          if DeviceIoControl(hVolume, IOCTL_STORAGE_GET_DEVICE_NUMBER, nil, 0, @sdn, SizeOf(sdn), dwBytesReturned, nil) and (sdn.DeviceNumber <> OSDrive) then
                                          begin
                                             j := 0;
                                             while j <= High(aDL) do
                                             begin
                                                if Cardinal(aDL[j].Number) = sdn.DeviceNumber then
                                                   Break;
                                                Inc(j);
                                             end;
                                             if j > High(aDL) then
                                             begin
                                                SetLength(aDL, Length(aDL) + 1);
                                                aDL[j].Number := sdn.DeviceNumber;
                                                aDL[j].BusType := BusType;
                                             end;
                                             SetLength(aDL[j].VolPaths, Length(aDL[j].VolPaths) + 1);
                                             aDL[j].VolPaths[High(aDL[j].VolPaths)] := ExcludeTrailingPathDelimiter(WideString(VolBuffer));
                                          end;
                                       finally
                                          try
                                             CloseHandle(hVolume);
                                          except
                                          end;
                                       end;
                                    end;
                                 end
                              else
                                 Continue;
                           end;
                        except
                        end
                     end;
                     Inc(i);
                  end;
               end;
               FreeMem(VolPaths);
            end;
         end;
         try
            bSuccess := FindNextVolumeW(hSrcVol, @volName, SizeOf(volName));
         except
            bSuccess := False;
         end;
      until not bSuccess;
      FindVolumeClose(hSrcVol);
   end;

   for i := 0 to MAX_IDE_DRIVES - 1 do
   begin
      if i = OSDrive then
         Continue;
      j := 0;
      while j <= High(aDL) do
      begin
         if aDL[j].Number = i then
            Break;
         Inc(j);
      end;
      if j > High(aDL) then
      begin
         try
            hDrive := CreateFile(PWideChar('\\.\PHYSICALDRIVE' + IntToStr(i)), 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
         except
            hDrive := INVALID_HANDLE_VALUE;
         end;
         if hDrive <> INVALID_HANDLE_VALUE then
         begin
            BusType := GetBusType(hDrive);
            try
               CloseHandle(hDrive);
            except
            end;
            if ListOnlyUSBDrives and (BusType <> 7) then
               Continue;
            SetLength(aDL, Length(aDL) + 1);
            aDL[High(aDL)].Number := i;
            aDL[High(aDL)].BusType := BusType;
         end;
      end;
   end;
   if Length(aDL) > 2 then
   begin
      repeat
         Switched := False;
         for i := 1 to High(aDL) - 1 do
            if aDL[i].Number > aDL[i + 1].Number then
            begin
               acTemp.VolPaths := Copy(aDL[i].VolPaths, Low(aDL[i].VolPaths), Length(aDL[i].VolPaths));
               aDL[i].VolPaths := Copy(aDL[i + 1].VolPaths, Low(aDL[i + 1].VolPaths), Length(aDL[i + 1].VolPaths));
               aDL[i + 1].VolPaths := Copy(acTemp.VolPaths, Low(acTemp.VolPaths), Length(acTemp.VolPaths));
               j := aDL[i].Number;
               aDL[i].Number := aDL[i + 1].Number;
               aDL[i + 1].Number := j;
               j := aDL[i].BusType;
               aDL[i].BusType := aDL[i + 1].BusType;
               aDL[i + 1].BusType := j;
               Switched := True;
            end;
      until not Switched;
      SetLength(actemp.VolPaths, 1);
      for i := 1 to High(aDL) do
         if Length(aDL[i].VolPaths) > 1 then
            repeat
               Switched := False;
               for j := 0 to High(aDL[i].VolPaths) - 1 do
                  if aDL[i].VolPaths[j][1] > aDL[i].VolPaths[j + 1][1] then
                  begin
                     actemp.VolPaths[0] := aDL[i].VolPaths[j];
                     aDL[i].VolPaths[j] := aDL[i].VolPaths[j + 1];
                     aDL[i].VolPaths[j + 1] := acTemp.VolPaths[0];
                     Switched := True;
                  end;
            until not Switched;
   end;
   if (Sender = nil) or ((Sender as TComboBox).Name = 'cmbFirstDrive') then
   begin
      SetLength(CBFirstDriveName, 0);
      SetLength(CBFirstDriveSize, 0);
      SetLength(CBFirstDriveLetters, 0);
      CBMaxLetSize := 0;

      if Length(aDL) > 1 then
      begin
         SetLength(CBFirstDriveName, Length(aDL) - 1);
         SetLength(CBFirstDriveSize, Length(aDL) - 1);
         SetLength(CBFirstDriveLetters, Length(aDL) - 1);
         j := 0;
         for i := 1 to High(aDL) do
         begin
            if i <> DriveToAdd then
            begin
               try
                  hDrive := CreateFile(PWideChar('\\.\PHYSICALDRIVE' + IntToStr(aDL[i].Number)), GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
               except
                  hDrive := INVALID_HANDLE_VALUE;
               end;
               if hDrive = INVALID_HANDLE_VALUE then
               begin
                  try
                     CloseHandle(hDrive);
                  except
                  end;
                  aDL[i].Number := -1;
                  SetLength(CBFirstDriveName, Length(CBFirstDriveName) - 1);
                  SetLength(CBFirstDriveSize, Length(CBFirstDriveSize) - 1);
                  SetLength(CBFirstDriveLetters, Length(CBFirstDriveLetters) - 1);
                  Continue;
               end;
               ws := GetStrBusType(aDL[i].BusType);
               if ws <> '' then
                  ws := ws + '  ';
               ws := ws + string(GetDriveVendorAndProductID(hDrive));
               CBFirstDriveName[j] := ws;
               sz := GetDriveSize(hDrive) / 1073741824;
               try
                  CloseHandle(hDrive);
               except
               end;
               if sz <= 0 then
               begin
                  aDL[i].Number := -1;
                  SetLength(CBFirstDriveName, Length(CBFirstDriveName) - 1);
                  SetLength(CBFirstDriveSize, Length(CBFirstDriveSize) - 1);
                  SetLength(CBFirstDriveLetters, Length(CBFirstDriveLetters) - 1);
                  Continue;
               end
               else
               begin
                  if sz < 1 then
                  begin
                     sz := sz * 1024;
                     mu := 'MB';
                  end
                  else if sz > 1000 then
                  begin
                     sz := sz / 1024;
                     mu := 'TB';
                  end
                  else
                     mu := 'GB';
                  Round3;
                  ws := ws + string(', ' + csz + ' ' + mu);
                  CBFirstDriveSize[j] := string(csz) + HalfSpaceCharCMB + string(mu);
               end;
               ws := ws + ',  [';
            end
            else
            begin
               ws := wsAdd;
               CBFirstDriveName[j] := vap;
               CBFirstDriveSize[j] := ReplaceStr(Size, ' ', HalfSpaceCharCMB);
            end;
            CBFirstDriveLetters[j] := '[';
            if Length(aDL[i].VolPaths) > 0 then
            begin
               k := 0;
               while k < High(aDL[i].VolPaths) do
               begin
                  ws := ws + aDL[i].VolPaths[k] + ', ';
                  CBFirstDriveLetters[j] := CBFirstDriveLetters[j] + aDL[i].VolPaths[k] + ', ';
                  Inc(k);
               end;
               ws := ws + aDL[i].VolPaths[k];
               CBFirstDriveLetters[j] := CBFirstDriveLetters[j] + aDL[i].VolPaths[k];
            end
            else
            begin
               ws := ws + ' ';
               CBFirstDriveLetters[j] := CBFirstDriveLetters[j] + ' ';
            end;
            ws := ws + ']';
            CBFirstDriveLetters[j] := CBFirstDriveLetters[j] + ']';
            CBMaxLetSize := Max(CBMaxLetSize, cmbFirstDrive.Canvas.TextWidth(CBFirstDriveLetters[j] + '  '));
            tsl.Add(ws);
            Inc(j);
         end;
      end;
   end;
   if AddSecondDrive and ((Sender = nil) or ((Sender as TComboBox).Name = 'cmbSecondDrive')) then
   begin
      if Sender = nil then
      begin
         SetLength(CBSecondDriveName, Length(CBFirstDriveName));
         SetLength(CBSecondDriveSize, Length(CBFirstDriveName));
         SetLength(CBSecondDriveLetters, Length(CBFirstDriveName));
         for i := 0 to High(CBFirstDriveName) do
         begin
            CBSecondDriveName[i] := CBFirstDriveName[i];
            CBSecondDriveSize[i] := CBFirstDriveSize[i];
            CBSecondDriveLetters[i] := CBFirstDriveLetters[i];
         end;
      end
      else
      begin
         SetLength(CBSecondDriveName, 0);
         SetLength(CBSecondDriveSize, 0);
         SetLength(CBSecondDriveLetters, 0);
         CBMaxLetSize := 0;

         if Length(aDL) > 1 then
         begin
            SetLength(CBSecondDriveName, Length(aDL) - 1);
            SetLength(CBSecondDriveSize, Length(aDL) - 1);
            SetLength(CBSecondDriveLetters, Length(aDL) - 1);
            j := 0;
            for i := 1 to High(aDL) do
            begin
               if i <> DriveToAdd then
               begin
                  try
                     hDrive := CreateFile(PWideChar('\\.\PHYSICALDRIVE' + IntToStr(aDL[i].Number)), GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
                  except
                     hDrive := INVALID_HANDLE_VALUE;
                  end;
                  if hDrive = INVALID_HANDLE_VALUE then
                  begin
                     try
                        CloseHandle(hDrive);
                     except
                     end;
                     aDL[i].Number := -1;
                     SetLength(CBSecondDriveName, Length(CBSecondDriveName) - 1);
                     SetLength(CBSecondDriveSize, Length(CBSecondDriveSize) - 1);
                     SetLength(CBSecondDriveLetters, Length(CBSecondDriveLetters) - 1);
                     Continue;
                  end;
                  ws := GetStrBusType(aDL[i].BusType);
                  if ws <> '' then
                     ws := ws + '  ';
                  ws := ws + string(GetDriveVendorAndProductID(hDrive));
                  CBSecondDriveName[j] := ws;
                  sz := GetDriveSize(hDrive) / 1073741824;
                  try
                     CloseHandle(hDrive);
                  except
                  end;
                  if sz <= 0 then
                  begin
                     aDL[i].Number := -1;
                     SetLength(CBSecondDriveName, Length(CBSecondDriveName) - 1);
                     SetLength(CBSecondDriveSize, Length(CBSecondDriveSize) - 1);
                     SetLength(CBSecondDriveLetters, Length(CBSecondDriveLetters) - 1);
                     Continue;
                  end
                  else
                  begin
                     if sz < 1 then
                     begin
                        sz := sz * 1024;
                        mu := 'MB';
                     end
                     else if sz > 1000 then
                     begin
                        sz := sz / 1024;
                        mu := 'TB';
                     end
                     else
                        mu := 'GB';
                     Round3;
                     ws := ws + string(', ' + csz + ' ' + mu);
                     CBSecondDriveSize[j] := string(csz) + HalfSpaceCharCMB + string(mu);
                  end;
                  ws := ws + ',  [';
               end
               else
               begin
                  ws := wsAdd;
                  CBSecondDriveName[j] := vap;
                  CBSecondDriveSize[j] := ReplaceStr(Size, ' ', HalfSpaceCharCMB);
               end;
               CBSecondDriveLetters[j] := '[';
               if Length(aDL[i].VolPaths) > 0 then
               begin
                  k := 0;
                  while k < High(aDL[i].VolPaths) do
                  begin
                     ws := ws + aDL[i].VolPaths[k] + ', ';
                     CBSecondDriveLetters[j] := CBSecondDriveLetters[j] + aDL[i].VolPaths[k] + ', ';
                     Inc(k);
                  end;
                  ws := ws + aDL[i].VolPaths[k];
                  CBSecondDriveLetters[j] := CBSecondDriveLetters[j] + aDL[i].VolPaths[k];
               end
               else
               begin
                  ws := ws + ' ';
                  CBSecondDriveLetters[j] := CBSecondDriveLetters[j] + ' ';
               end;
               ws := ws + ']';
               CBSecondDriveLetters[j] := CBSecondDriveLetters[j] + ']';
               CBMaxLetSize := Max(CBMaxLetSize, cmbSecondDrive.Canvas.TextWidth(CBSecondDriveLetters[j] + '  '));
               tsl.Add(ws);
               Inc(j);
            end;
         end;
      end;
   end;
   SetErrorMode(ErrorMode);
   try
      if DriveToAdd > -1 then
      begin
         i := 1;
         while i < tsl.Count do
         begin
            if Pos(wsAdd, string(tsl[i]), 1) = 1 then
               Break;
            Inc(i);
         end;
         if i = tsl.Count then
            DriveToAdd := -1
         else
            DriveToAdd := i;
      end;
      if Sender = nil then
      begin
         if not cmbFirstDrive.Items.Equals(tsl) then
            cmbFirstDrive.Items.Assign(tsl);
         if AddSecondDrive then
            if not cmbSecondDrive.Items.Equals(tsl) then
               cmbSecondDrive.Items.Assign(tsl);
         if isEdit then
         begin
            with PData(frmMain.vstVMs.GetNodeData(frmMain.vstVMs.GetFirstSelected))^ do
            begin
               if FirstDriveName <> '' then
               begin
                  ws := GetStrBusType(FirstDriveBusType);
                  if ws <> '' then
                     ws := ws + '  '
                  else
                     ws := '';
                  ws := ws + string(FirstDriveName + ',  [');
                  i := 1;
                  while i < cmbFirstDrive.Items.Count do
                  begin
                     if Pos(ws, string(cmbFirstDrive.Items[i])) = 1 then
                     begin
                        cmbFirstDrive.ItemIndex := i;
                        Break;
                     end;
                     Inc(i);
                  end;
                  if i = cmbFirstDrive.Items.Count then
                     cmbFirstDrive.ItemIndex := 0;
               end
               else
                  cmbFirstDrive.ItemIndex := 0;
               if AddSecondDrive then
                  if SecondDriveName <> '' then
                  begin
                     ws := GetStrBusType(SecondDriveBusType);
                     if ws <> '' then
                        ws := ws + '  '
                     else
                        ws := '';
                     ws := ws + string(SecondDriveName + ',  [');
                     i := 1;
                     while i < cmbSecondDrive.Items.Count do
                     begin
                        if Pos(ws, string(cmbSecondDrive.Items[i])) = 1 then
                        begin
                           cmbSecondDrive.ItemIndex := i;
                           Break;
                        end;
                        Inc(i);
                     end;
                     if i = cmbSecondDrive.Items.Count then
                        cmbSecondDrive.ItemIndex := 0;
                  end
                  else
                     cmbSecondDrive.ItemIndex := 0;
            end;
         end
         else
         begin
            if DriveToAdd > -1 then
               cmbFirstDrive.ItemIndex := DriveToAdd
            else
               cmbFirstDrive.ItemIndex := 0;
            if AddSecondDrive then
               cmbSecondDrive.ItemIndex := 0;
         end;
      end
      else
      begin
         if not (Sender as TComboBox).Items.Equals(tsl) then
         begin
            i := (Sender as TComboBox).ItemIndex;
            (Sender as TComboBox).Items.Assign(tsl);
            if DriveToAdd = -1 then
               (Sender as TComboBox).ItemIndex := Min((Sender as TComboBox).Items.Count - 1, i)
            else
               (Sender as TComboBox).ItemIndex := Min((Sender as TComboBox).Items.Count - 1, DriveToAdd);
         end
         else if DriveToAdd > -1 then
            (Sender as TComboBox).ItemIndex := Min((Sender as TComboBox).Items.Count - 1, DriveToAdd);
      end;
   except
   end;
   DriveToAdd := -1;
   tsl.Free;
end;

procedure TfrmAddEdit.FormCreate(Sender: TObject);
var
   i, bflenfd, bflensd, l, indmin: Integer;
   prc, prevprc: Double;
begin
   ItemHeight := Round(32 * Screen.PixelsPerInch / 96);
   HMargin := Round(12 * Screen.PixelsPerInch / 96);
   lblToEditDiff := Round((2 * Screen.PixelsPerInch / 96 - 2) / 2 + 2);
   SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) and not WS_EX_TOOLWINDOW);
   bflenfd := lblFirstDrive.Width;
   bflensd := lblSecondDrive.Width;
   lblAudio.Caption := GetLangTextDef(idxAddEdit, ['Labels', 'Audio'], 'Audio');
   lblCDROM.Caption := GetLangTextDef(idxAddEdit, ['Labels', 'CDROM'], 'CD/DVD device:');
   lblEnableCPUVirtualization.Caption := GetLangTextDef(idxAddEdit, ['Labels', 'EnableCPUVirtualization'], 'Enable VT-x/AMD-V:');
   lblExeParams.Caption := GetLangTextDef(idxAddEdit, ['Labels', 'ExeParams'], 'Exe parameters:');
   lblFirstDrive.Caption := GetLangTextDef(idxAddEdit, ['Labels', 'FirstDrive'], 'First drive to add and boot:');
   lblHDD.Caption := GetLangTextDef(idxAddEdit, ['Labels', 'HDD'], 'Internal HDD:');
   lblMemory.Caption := GetLangTextDef(idxAddEdit, ['Labels', 'Memory'], 'Memory (MB):');
   lblMode.Caption := GetLangTextDef(idxAddEdit, ['Labels', 'Mode'], 'Mode to load the VM:');
   lblPriority.Caption := GetLangTextDef(idxAddEdit, ['Labels', 'Priority'], 'CPU priority:');
   lblRun.Caption := GetLangTextDef(idxAddEdit, ['Labels', 'Run'], 'Run:');
   lblSecondDrive.Caption := GetLangTextDef(idxAddEdit, ['Labels', 'SecondDrive'], 'Second drive to add (optional):');
   lblType.Caption := GetLangTextDef(idxAddEdit, ['Labels', 'Type'], 'Type:');
   lblVMName.Caption := GetLangTextDef(idxAddEdit, ['Labels', 'VMName'], 'VM name:');
   lblVMPath.Caption := GetLangTextDef(idxAddEdit, ['Labels', 'VMPath'], 'VM path:');
   lblCache.Caption := GetLangTextDef(idxAddEdit, ['Labels', 'UseHostCache'], 'Use host I/O cache:');
   odSearchVM.Title := GetLangTextDef(idxAddEdit, ['Dialogs', 'LoadVM', 'Title'], 'Load');
   odSearchVM.Filter := GetLangTextDef(idxAddEdit, ['Dialogs', 'LoadVM', 'Filter'], 'VirtualBox VM (*.vbox)|*.vbox|All files (*.*)|*.*');
   odSearchHDD.Title := GetLangTextDef(idxAddEdit, ['Dialogs', 'LoadHDDImage', 'Title'], 'Load');
   odSearchHDD.Filter := GetLangTextDef(idxAddEdit, ['Dialogs', 'LoadHDDImage', 'Filter'], 'QEMU disk images|*.img;*.qcow;*.qcow2;*.qed;*.qcow;*.cow;*.vdi;*.vmdk;*.vpc|All files|*.*');
   odOpenISO.Title := GetLangTextDef(idxAddEdit, ['Dialogs', 'LoadISO', 'Title'], 'Load');
   odOpenISO.Filter := GetLangTextDef(idxAddEdit, ['Dialogs', 'LoadISO', 'Filter'], 'ISO files|*.iso|All files|*.*');
   btnOK.Caption := ReplaceStr(GetLangTextDef(idxMessages, ['Buttons', 'OK'], 'OK'), '&', '');
   btnCancel.Caption := ReplaceStr(GetLangTextDef(idxMessages, ['Buttons', 'Cancel'], 'Cancel'), '&', '');
   cmbAudio.Items[0] := GetLangTextDef(idxAddEdit, ['Comboboxes', 'NoneText'], 'None');
   cmbAudio.ItemIndex := 1;
   cmbCDROM.Items[0] := GetLangTextDef(idxAddEdit, ['Comboboxes', 'NoneText'], 'None');
   cmbCDROM.ItemIndex := 0;
   cmbFirstDrive.Items[0] := GetLangTextDef(idxAddEdit, ['Comboboxes', 'NoneText'], 'None');
   cmbFirstDrive.ItemIndex := 0;
   cmbVMName.Items[0] := GetLangTextDef(idxAddEdit, ['Comboboxes', 'NoneText'], 'None');
   cmbVMName.Items[1] := GetLangTextDef(idxAddEdit, ['Comboboxes', 'CreateNewVM'], 'Create new VM');
   cmbVMName.ItemIndex := 0;
   cmbSecondDrive.Items[0] := GetLangTextDef(idxAddEdit, ['Comboboxes', 'NoneText'], 'None');
   cmbSecondDrive.ItemIndex := 0;
   cmbEnableCPUVirtualization.Items.Text := GetLangTextDef(idxAddEdit, ['Comboboxes', 'EnableCPUVirtualization'], 'Unchanged'#13#10'On'#13#10'Off'#13#10'Switch');
   cmbEnableCPUVirtualization.ItemIndex := 0;
   cmbCache.Items.BeginUpdate;
   cmbCache.Items.Text := GetLangTextDef(idxAddEdit, ['Comboboxes', 'EnableCPUVirtualization'], 'Unchanged'#13#10'On'#13#10'Off'#13#10'Switch');
   cmbCache.Items.Delete(0);
   cmbCache.Items.Delete(2);
   cmbCache.Items.Exchange(0, 1);
   cmbCache.ItemIndex := 0;
   cmbCache.Items.EndUpdate;
   cmbMode.Items.Text := GetLangTextDef(idxAddEdit, ['Comboboxes', 'Mode'], 'VM name'#13#10'VM path'#13#10'Exe parameters');
   cmbMode.ItemIndex := 0;
   cmbPriority.Items.Text := GetLangTextDef(idxAddEdit, ['Comboboxes', 'Priority'], 'BelowNormal'#13#10'Normal'#13#10'AboveNormal'#13#10'High');
   cmbPriority.ItemIndex := 1;
   cmbWS.Items.Text := GetLangTextDef(idxAddEdit, ['Comboboxes', 'WindowSize', 'VirtualBox'], 'Normal'#13#10'Minimized'#13#10'Maximized'#13#10'Fullscreen');
   cmbWS.ItemIndex := 0;
   btnBrowseForVM.Hint := GetLangTextDef(idxAddEdit, ['Hints', 'BrowseForVM'], 'click to browse for VM');
   btnBrowseForHDD.Hint := GetLangTextDef(idxAddEdit, ['Hints', 'BrowseForHdd'], 'click to browse for HDD image file');

   case SystemIconSize of
      -2147483647..18:
         begin
            sbVirtualBox.PngImage := frmMain.imlBtn16.PngImages[8].PngImage;
            sbQEMU.PngImage := frmMain.imlBtn16.PngImages[9].PngImage;
            btnOK.PngImage := frmMain.imlBtn16.PngImages[14].PngImage;
            btnCancel.PngImage := frmMain.imlBtn16.PngImages[15].PngImage;
         end;
      19..22:
         begin
            sbVirtualBox.PngImage := frmMain.imlBtn20.PngImages[8].PngImage;
            sbQEMU.PngImage := frmMain.imlBtn20.PngImages[9].PngImage;
            btnOK.PngImage := frmMain.imlBtn20.PngImages[14].PngImage;
            btnCancel.PngImage := frmMain.imlBtn20.PngImages[15].PngImage;
         end;
      23..2147483647:
         begin
            sbVirtualBox.PngImage := frmMain.imlBtn20.PngImages[8].PngImage;
            sbQEMU.PngImage := frmMain.imlBtn20.PngImages[9].PngImage;
            btnOK.PngImage := frmMain.imlBtn20.PngImages[14].PngImage;
            btnCancel.PngImage := frmMain.imlBtn20.PngImages[15].PngImage;
         end;
   end;

   cmbFirstDrive.Canvas.Font.Assign(cmbFirstDrive.Font);
   cmbFirstDrive.Canvas.Font.Assign(cmbFirstDrive.Font);
   btnOK.Glyph.Canvas.Font.Assign(btnOK.Font);
   btnOK.Width := Max(btnOK.Glyph.Canvas.TextWidth(btnOK.Caption), btnOK.Glyph.Canvas.TextWidth(btnCancel.Caption));
   btnOK.Margin := Round(sqrt(btnOK.Width)) + 5;
   btnOK.Width := 3 * btnOK.Margin + btnOK.PngImage.Width + btnOK.Width;
   btnOK.Spacing := Max(0, btnOK.Width - btnOK.Margin - btnOK.PngImage.Width - btnOK.Glyph.Canvas.TextWidth(btnOK.Caption)) div 2;
   btnCancel.Width := btnOK.Width;
   btnCancel.Margin := btnOK.Margin;
   btnCancel.Spacing := Max(0, btnCancel.Width - btnCancel.Margin - btnCancel.PngImage.Width - btnOK.Glyph.Canvas.TextWidth(btnCancel.Caption)) div 2;
   i := 8192;
   l := Canvas.TextWidth('  ') div 2;
   prevprc := 50;
   indmin := -1;
   while i <= 8202 do
   begin
      prc := 100.0 * (cmbFirstDrive.Canvas.TextWidth(Char(i) + Char(i)) - l) / l;
      if prc < 0 then
         prc := -0.75 * prc;
      if prc < prevprc then
      begin
         prevprc := prc;
         indmin := i;
      end;
      Inc(i);
   end;
   if indmin > -1 then
      HalfSpaceCharCMB := Char(indmin)
   else
      HalfSpaceCharCMB := ' ';
   bflenfd := lblFirstDrive.Width - bflenfd;
   bflensd := lblSecondDrive.Width - bflensd;

   for i := 0 to ComponentCount - 1 do
      if Components[i] is TComboBox then
         (Components[i] as TComboBox).ItemHeight := Round(1.0 * Screen.PixelsPerInch / 96 * (Components[i] as TComboBox).ItemHeight);

   if not AddSecondDrive then
   begin
      lblFirstDrive.Caption := GetLangTextDef(idxAddEdit, ['Labels', 'Drive'], 'Drive to add and boot:');
      Width := Width + lblFirstDrive.Width - lblSecondDrive.Width + bflenfd;
   end
   else if bflensd <> 0 then
      Width := Width + bflensd;
   btnOK.Top := ClientHeight - btnOK.Height - btnOK.Height div 3;
   btnCancel.Top := btnOK.Top;
   pnlAll.SetBounds(btnOK.Height div 3, btnOK.Height div 3, ClientWidth - 2 * (btnOK.Height div 3), btnOK.Top - 2 * (btnOK.Height div 3));
   for i := 0 to ComponentCount - 1 do
      if Components[i] is TLabel then
         (Components[i] as TLabel).Left := Round(0.5 * btnOK.Height)
      else if Components[i] is TComboBox then
         (Components[i] as TComboBox).Left := pnlAll.ClientWidth - btnOK.Height div 3 - (Components[i] as TComboBox).Width;
   btnBrowseForVM.Left := pnlAll.ClientWidth - btnOK.Height div 3 - btnBrowseForVM.Width;
   btnBrowseForHDD.Left := pnlAll.ClientWidth - btnOK.Height div 3 - btnBrowseForHDD.Width;
   edtHDD.Width := cmbMode.Width - btnBrowseForHDD.Width - btnOK.Height div 3;
   edtHDD.Left := cmbMode.Left;
   edtMemory.Width := cmbMode.Width;
   edtMemory.Left := cmbMode.Left;
   cmbFirstDrive.Width := cmbMode.Width;
   cmbFirstDrive.Left := cmbMOde.Left;
   cmbSecondDrive.Width := cmbMode.Width;
   cmbSecondDrive.Left := cmbMOde.Left;
   cmbWS.Width := cmbMode.Width;
   cmbWS.Left := cmbMOde.Left;
   cmbAudio.Width := cmbMode.Width;
   cmbAudio.Left := cmbMOde.Left;
   cmbCDROM.Width := cmbMode.Width;
   cmbCDROM.Left := cmbMOde.Left;
   cmbPriority.Width := cmbMode.Width;
   cmbPriority.Left := cmbMOde.Left;
   edtExeParams.Width := cmbMode.Width;
   edtExeParams.Left := cmbMode.Left;
   edtVMPath.Width := cmbMode.Width - btnBrowseForHDD.Width - btnOK.Height div 3;
   edtVMPath.Left := cmbMOde.Left;
   cmbEnableCPUVirtualization.Width := cmbMode.Width;
   cmbEnableCPUVirtualization.Left := cmbMOde.Left;
   pnlQEMU.Width := cmbMode.Width div 2 + 1;
   pnlQEMU.Left := cmbMode.Left + cmbMode.Width - pnlQEMU.Width;
   pnlVirtualBox.Width := cmbMode.Width div 2 + 1;
   pnlVirtualBox.Left := cmbMode.Left;
   lblEnableCPUVirtualization.Visible := True;
   cmbEnableCPUVirtualization.Visible := True;
   if AddSecondDrive then
   begin
      lblSecondDrive.Visible := True;
      cmbSecondDrive.Visible := True;
      ClientHeight := ClientHeight - pnlAll.Height + 2 * HMargin + ItemHeight * 8 + lblPriority.Height;
      lblSecondDrive.Top := HMargin + 4 * ItemHeight;
      cmbSecondDrive.Top := HMargin + 4 * ItemHeight - lblToEditDiff;
      lblCache.Top := HMargin + 5 * ItemHeight;
      cmbCache.Top := HMargin + 5 * ItemHeight - lblToEditDiff;
      lblEnableCPUVirtualization.Top := HMargin + 6 * ItemHeight;
      cmbEnableCPUVirtualization.Top := HMargin + 6 * ItemHeight - lblToEditDiff;
      lblRun.Top := HMargin + 7 * ItemHeight;
      cmbWS.Top := HMargin + 7 * ItemHeight - lblToEditDiff;
      lblPriority.Top := HMargin + 8 * ItemHeight;
      cmbPriority.Top := HMargin + 8 * ItemHeight - lblToEditDiff;
      lblHDD.Top := HMargin + 3 * ItemHeight;
      edtHDD.Top := HMargin + 3 * ItemHeight - lblToEditDiff;
      lblCDROM.Top := HMargin + 4 * ItemHeight;
      cmbCDROM.Top := HMargin + 4 * ItemHeight - lblToEditDiff;
      lblMemory.Top := HMargin + 5 * ItemHeight;
      edtMemory.Top := HMargin + 5 * ItemHeight - lblToEditDiff;
      lblAudio.Top := HMargin + 6 * ItemHeight;
      cmbAudio.Top := HMargin + 6 * ItemHeight - lblToEditDiff;
      btnBrowseForVM.Top := HMargin + 2 * ItemHeight - lblToEditDiff;
      btnBrowseForHDD.Top := HMargin + 2 * ItemHeight - lblToEditDiff;
   end
   else
   begin
      lblSecondDrive.Visible := False;
      cmbSecondDrive.Visible := False;
      ClientHeight := ClientHeight - pnlAll.Height + 2 * HMargin + ItemHeight * 7 + lblPriority.Height;
      lblCache.Top := HMargin + 4 * ItemHeight;
      cmbCache.Top := HMargin + 4 * ItemHeight - lblToEditDiff;
      lblEnableCPUVirtualization.Top := HMargin + 5 * ItemHeight;
      cmbEnableCPUVirtualization.Top := HMargin + 5 * ItemHeight - lblToEditDiff;
      lblRun.Top := HMargin + 6 * ItemHeight;
      cmbWS.Top := HMargin + 6 * ItemHeight - lblToEditDiff;
      lblPriority.Top := HMargin + 7 * ItemHeight;
      cmbPriority.Top := HMargin + 7 * ItemHeight - lblToEditDiff;
      lblHDD.Top := HMargin + ItemHeight;
      edtHDD.Top := HMargin + ItemHeight - lblToEditDiff;
      lblCDROM.Top := HMargin + 3 * ItemHeight;
      cmbCDROM.Top := HMargin + 3 * ItemHeight - lblToEditDiff;
      lblMemory.Top := HMargin + 4 * ItemHeight;
      edtMemory.Top := HMargin + 4 * ItemHeight - lblToEditDiff;
      lblAudio.Top := HMargin + 5 * ItemHeight;
      cmbAudio.Top := HMargin + 5 * ItemHeight - lblToEditDiff;
      btnBrowseForVM.Top := HMargin + 2 * ItemHeight - lblToEditDiff;
      btnBrowseForHDD.Top := HMargin + ItemHeight - lblToEditDiff;
   end;
   lblType.Top := HMargin;
   pnlVirtualBox.Top := HMargin - lblToEditDiff;
   pnlQEMU.Top := HMargin - lblToEditDiff;
   lblMode.Top := HMargin + ItemHeight;
   cmbMode.Top := HMargin + ItemHeight - lblToEditDiff;
   lblVMName.Top := HMargin + 2 * ItemHeight;
   cmbVMName.Top := HMargin + 2 * ItemHeight - lblToEditDiff;
   lblFirstDrive.Top := HMargin + 3 * ItemHeight;
   cmbFirstDrive.Top := HMargin + 3 * ItemHeight - lblToEditDiff;
   lblExeParams.Top := HMargin + 2 * ItemHeight;
   edtExeParams.Top := HMargin + 2 * ItemHeight - lblToEditDiff;
   lblVMPath.Top := HMargin + 2 * ItemHeight;
   edtVMPath.Top := HMargin + 2 * ItemHeight - lblToEditDiff;
   ShowedThisSession := False;
   originaledtHDDWindowProc := edtHDD.WindowProc;
   edtHDD.WindowProc := edtHDDWindowProc;
   originalcmbCDROMWindowProc := cmbCDROM.WindowProc;
   cmbCDROM.WindowProc := cmbCDROMWindowProc;
   originalcmbFirstDriveWindowProc := cmbFirstDrive.WindowProc;
   cmbFirstDrive.WindowProc := cmbFirstDriveWindowProc;
   originalcmbSecondDriveWindowProc := cmbSecondDrive.WindowProc;
   cmbSecondDrive.WindowProc := cmbSecondDriveWindowProc;
   DragAcceptFiles(edtHDD.Handle, True);
   DragAcceptFiles(cmbCDROM.Handle, True);
   DragAcceptFiles(cmbFirstDrive.Handle, True);
   DragAcceptFiles(cmbSecondDrive.Handle, True);
   CBClientWidth := Width;
   btnOK.Left := Round(0.4 * (ClientWidth - btnOK.Width - btnCancel.Width));
   btnCancel.Left := Round(0.6 * (ClientWidth - btnOK.Width - btnCancel.Width) + btnOK.Width);
end;

procedure TfrmAddEdit.FormDestroy(Sender: TObject);
begin
   DragAcceptFiles(edtHDD.Handle, False);
   DragAcceptFiles(cmbCDROM.Handle, False);
   DragAcceptFiles(cmbFirstDrive.Handle, False);
   DragAcceptFiles(cmbSecondDrive.Handle, False);
end;

procedure TfrmAddEdit.FormKeyPress(Sender: TObject; var Key: Char);
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

procedure TfrmAddEdit.AllKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
   if (Shift = []) and (Key = VK_F1) then
      frmMain.OpenInternetHelp(Self.Handle, DefSiteHelp);
end;

procedure TfrmAddEdit.btnBrowseForHDDClick(Sender: TObject);
var
   FolderName: string;
begin
   btnBrowseForHDD.Repaint;
   if odSearchHDD.FileName <> '' then
   begin
      FolderName := ExtractFilePath(odSearchHDD.FileName);
      odSearchHDD.FileName := '';
      odSearchHDD.InitialDir := FolderName;
   end;
   if odSearchHDD.Execute(Self.Handle) then
   begin
      edtHDD.Text := odSearchHDD.FileName;
      edtHDD.SetFocus;
      edtHDD.SelStart := Length(edtHDD.Text);
      edtHDD.SelLength := 0;
   end;
   SetFocus;
end;

procedure TfrmAddEdit.edtMemoryKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
   if (Shift = []) then
      case Key of
         VK_RETURN:
            begin
               Key := 0;
               btnOK.Click;
            end;
         VK_F1:
            frmMain.OpenInternetHelp(Self.Handle, DefSiteHelp);
         VK_ESCAPE:
            begin
               Key := 0;
               btnCancel.Click;
            end;
      end;
end;

procedure TfrmAddEdit.GetCDROMS;
var
   objWMIService: OLEVariant;
   colItems: OLEVariant;
   colItem: OLEVariant;
   oEnum: IEnumvariant;
   iValue: LongWord;
   s: AnsiString;
   i, l: Integer;
   Changed: Boolean;
   tCDROMInfo: CDROMInfo;

   function GetWMIObject(const objectName: AnsiString): IDispatch;
   var
      chEaten: Integer;
      BindCtx: IBindCtx;
      Moniker: IMoniker;
   begin
      OleCheck(CreateBindCtx(0, BindCtx));
      OleCheck(MkParseDisplayName(BindCtx, StringToOleStr(objectName), chEaten, Moniker));
      OleCheck(Moniker.BindToObject(BindCtx, nil, IDispatch, Result));
   end;

begin
   SetLength(aCDROMInfo, 0);
   // CoInitializeEx(nil, COINIT_MULTITHREADED);
   if Succeeded(CoInitialize(nil)) then
   try
      try
         objWMIService := GetWMIObject(AnsiString(Format('winmgmts:\\%s\%s', ['.', 'root\CIMV2'])));
         colItems := objWMIService.ExecQuery(Format('SELECT %s FROM %s', ['Drive', 'Win32_CDROMDrive']), 'WQL', 0);
         oEnum := IUnknown(colItems._NewEnum) as IEnumvariant;
         while oEnum.Next(1, colItem, iValue) = 0 do
         begin
            s := AnsiString(colItem.Properties_.Item('Drive', 0));
            SetLength(aCDROMInfo, Length(aCDROMInfo) + 1);
            if (Length(s) = 2) and (s[2] = ':') and (s[1] in ['A'..'Z']) then
               aCDROMInfo[High(aCDROMInfo)].Letter := s[1]
            else
               aCDROMInfo[High(aCDROMInfo)].Letter := '0';
         end;
         colItems := objWMIService.ExecQuery(Format('SELECT %s FROM %s', ['Caption', 'Win32_CDROMDrive']), 'WQL', 0);
         oEnum := IUnknown(colItems._NewEnum) as IEnumvariant;
         i := 0;
         while oEnum.Next(1, colItem, iValue) = 0 do
         begin
            if i > High(aCDROMInfo) then
               Break;
            aCDROMInfo[i].Name := AnsiString(colItem.Properties_.Item('Caption', 0));
            Inc(i);
         end;
      except
      end;
   finally
      CoUninitialize;
   end;
   l := Length(aCDROMInfo);
   if l > 1 then
      repeat
         Changed := False;
         for i := 0 to l - 2 do
            if aCDROMInfo[i].Letter > aCDROMInfo[i + 1].Letter then
            begin
               tCDROMInfo := aCDROMInfo[i];
               aCDROMInfo[i] := aCDROMInfo[i + 1];
               aCDROMInfo[i + 1] := tCDROMInfo;
               Changed := True;
            end;
      until not Changed;
   cmbCDROM.Items.BeginUpdate;
   cmbCDROM.Items.Clear;
   cmbCDROM.Items.Append(GetLangTextDef(idxAddEdit, ['Comboboxes', 'NoneText'], 'None'));
   nCDROMS := 0;
   for i := 0 to l - 1 do
   begin
      if aCDROMInfo[i].Letter = '0' then
         Break;
      cmbCDROM.Items.Append(string(aCDROMInfo[i].Name + ',   [' + UpCase(aCDROMInfo[i].Letter) + ':]'));
      Inc(nCDROMS);
   end;
   cmbCDROM.Items.Append(GetLangTextDef(idxAddEdit, ['Comboboxes', 'LoadISO'], 'Load ISO file...'));
   cmbCDROM.Items.EndUpdate;
   cmbCDROM.ItemIndex := 0;
   cmbCDROM.Tag := 0;
   CDDVDType := 0;
end;

procedure TfrmAddEdit.cmbCDROMChange(Sender: TObject);
var
   ws: string;
   Obj: TMyObj;
begin
   if cmbCDROM.ItemIndex = (nCDROMS + 1) then
   begin
      cmbCDROM.OnChange := nil;
      if odOpenISO.FileName <> '' then
      begin
         ws := odOpenISO.FileName;
         odOpenISO.FileName := '';
         odOpenISO.InitialDir := ExtractFilePath(ws);
      end;
      if odOpenISO.Execute(Self.Handle) then
      begin
         if cmbCDROM.ItemIndex < (cmbCDROM.Items.Count - 1) then
         begin
            if Assigned(cmbCDROM.Items.Objects[cmbCDROM.Items.Count - 1]) then
               TMyObj(cmbCDROM.Items.Objects[cmbCDROM.Items.Count - 1]).Free();
            cmbCDROM.Items.Delete(cmbCDROM.Items.Count - 1);
         end;
         Obj := TMyObj.Create();
         Obj.Text := odOpenISO.FileName;
         cmbCDROM.Items.AddObject(ExtractFileName(odOpenISO.FileName), Obj);
         cmbCDROM.ItemIndex := cmbCDROM.Items.Count - 1;
         cmbCDROM.Tag := cmbCDROM.ItemIndex;
         CDDVDType := 1;
      end
      else
         cmbCDROM.ItemIndex := cmbCDROM.Tag;
      SetFocus;
      cmbCDROM.OnChange := cmbCDROMChange;
   end
   else
   begin
      cmbCDROM.Tag := cmbCDROM.ItemIndex;
      if cmbCDROM.ItemIndex <= nCDROMS then
         CDDVDType := 0;
   end;
end;

procedure TfrmAddEdit.FormActivate(Sender: TObject);
var
   i: Integer;
   Obj: TMyObj;
   ws: string;
begin
   OnActivate := nil;
   if isEdit then
      if FocusFirstDrive then
         cmbFirstDrive.DroppedDown := True
      else if FocusSecDrive then
         cmbSecondDrive.DroppedDown := True;
   Refresh;
   GetDrives(nil);
   if sbQEMU.Down then
   begin
      GetCDROMS;
      if isEdit then
      begin
         with PData(frmMain.vstVMs.GetNodeData(frmMain.vstVMs.GetFirstSelected))^ do
            if CDROMName <> '' then
               if CDROMType = 0 then
               begin
                  ws := CDROMName + ',   [';
                  i := 1;
                  while i <= nCDROMS do
                  begin
                     if Pos(ws, string(cmbCDROM.Items[i])) = 1 then
                     begin
                        cmbCDROM.ItemIndex := i;
                        cmbCDROM.Tag := i;
                        Break;
                     end;
                     Inc(i);
                  end;
               end
               else
               begin
                  Obj := TMyObj.Create();
                  Obj.Text := CDROMName;
                  cmbCDROM.Items.AddObject(ExtractFileName(CDROMName), Obj);
                  cmbCDROM.ItemIndex := cmbCDROM.Items.Count - 1;
                  cmbCDROM.Tag := cmbCDROM.ItemIndex;
                  CDDVDType := 1;
                  ws := ExtractFilePath(CDROMName);
                  if DirectoryExists(ws) then
                     odOpenISO.InitialDir := ws;
               end;
      end;
   end;
end;

procedure TfrmAddEdit.edtHDDWindowProc(var Msg: TMessage);
var
   Buffer: array[0..MAX_PATH] of WideChar;
   wstrTemp: string;
begin
   if Msg.Msg = WM_DROPFILES then
   begin
      Application.BringToFront;
      frmMain.Repaint;
      Repaint;
      case DragQueryFileW(Msg.WPARAM, $FFFFFFFF, nil, 0) of
         1:
            begin
               DragQueryFileW(Msg.WPARAM, 0, @Buffer, SizeOf(Buffer));
               DragFinish(Msg.WPARAM);
               wstrTemp := string(Buffer);
               if FileExists(wstrTemp) then
               begin
                  odSearchHDD.FileName := wstrTemp;
                  edtHDD.Text := wstrTemp;
                  edtHDD.SetFocus;
                  edtHDD.SelStart := Length(edtHDD.Text);
                  edtHDD.SelLength := 0;
               end
               else
               begin
                  CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'NotAFile'], 'This is not a file !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
               end;
            end;
         else
            DragFinish(Msg.WPARAM);
            CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'JustOneItem'], 'Just one item at a time !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
      end;
   end
   else
      originaledtHDDWindowProc(Msg);
end;

procedure TfrmAddEdit.cmbCDROMWindowProc(var Msg: TMessage);
var
   Buffer: array[0..MAX_PATH] of WideChar;
   wstrTemp: string;
   ErrorMode: Word;
   p: Integer;
   Obj: TMyObj;
begin
   if Msg.Msg = WM_DROPFILES then
   begin
      Application.BringToFront;
      frmMain.Repaint;
      Repaint;
      case DragQueryFileW(Msg.WPARAM, $FFFFFFFF, nil, 0) of
         1:
            begin
               DragQueryFileW(Msg.WPARAM, 0, @Buffer, SizeOf(Buffer));
               DragFinish(Msg.WPARAM);
               wstrTemp := string(Buffer);
               if (Length(wstrTemp) = 3) and ((wstrTemp[1] >= 'A') and (wstrTemp[1] <= 'Z')) and (wstrTemp[2] = ':') and (wstrTemp[3] = '\') then
               begin
                  ErrorMode := SetErrorMode(SEM_FailCriticalErrors);
                  try
                     case GetDriveTypeW(PWideChar(wstrTemp)) of
                        DRIVE_CDROM:
                           begin
                              p := cmbCDROM.Items.IndexOf(string(FindCDROMFromLetter(AnsiChar(wstrTemp[1]))) + ',   [' + wstrTemp[1] + ':]');
                              if (p > -1) and (p <= nCDROMS) then
                              begin
                                 cmbCDROM.ItemIndex := p;
                                 cmbCDROM.SetFocus;
                              end;
                           end
                        else
                           CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'NotACD'], 'This is not a CD/DVD device !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
                           Exit;
                     end;
                  finally
                     SetErrorMode(ErrorMode);
                  end;
               end
               else if FileExists(wstrTemp) then
               begin
                  cmbCDROM.OnChange := nil;
                  if cmbCDROM.ItemIndex = (cmbCDROM.Items.Count - 1) then
                  begin
                     if Assigned(cmbCDROM.Items.Objects[cmbCDROM.Items.Count - 1]) then
                        TMyObj(cmbCDROM.Items.Objects[cmbCDROM.Items.Count - 1]).Free();
                     cmbCDROM.Items.Delete(cmbCDROM.Items.Count - 1);
                  end;
                  Obj := TMyObj.Create();
                  Obj.Text := wstrTemp;
                  cmbCDROM.Items.AddObject(ExtractFileName(wstrTemp), Obj);
                  cmbCDROM.ItemIndex := cmbCDROM.Items.Count - 1;
                  cmbCDROM.Tag := cmbCDROM.ItemIndex;
                  CDDVDType := 1;
                  cmbCDROM.SetFocus;
                  cmbCDROM.OnChange := cmbCDROMChange;
               end
               else
               begin
                  CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'NotACDOrIso'], 'Not a CD/DVD device or ISO file !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
               end;
            end;
         else
            DragFinish(Msg.WPARAM);
            CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'JustOneItem'], 'Just one item at a time !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
      end;
   end
   else
      originalcmbCDROMWindowProc(Msg);
end;

procedure TfrmAddEdit.cmbFirstDriveWindowProc(var Msg: TMessage);
var
   Buffer: array[0..MAX_PATH] of WideChar;
   strTemp: string;
   hVolume, hDrive: THandle;
   dwBytesReturned: dword;
   sdn: STORAGE_DEVICE_NUMBER;
   ErrorMode: Word;
begin
   if Msg.Msg = WM_DROPFILES then
   begin
      Application.BringToFront;
      frmMain.Repaint;
      Repaint;
      case DragQueryFile(Msg.WPARAM, $FFFFFFFF, nil, 0) of
         1:
            begin
               DragQueryFile(Msg.WPARAM, 0, @Buffer, SizeOf(Buffer));
               DragFinish(Msg.WPARAM);
               strTemp := string(Buffer);
               if (Length(strTemp) = 3) and CharInSet(strTemp[1], ['A'..'Z']) and (strTemp[2] = ':') and (strTemp[3] = '\') then
               begin
                  ErrorMode := SetErrorMode(SEM_FailCriticalErrors);
                  try
                     case GetDriveType(PWideChar(string(strTemp))) of
                        DRIVE_REMOVABLE, DRIVE_FIXED:
                           begin
                              try
                                 hVolume := CreateFile(PWideChar('\\.\' + strTemp[1] + ':'), 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
                              except
                                 hVolume := INVALID_HANDLE_VALUE;
                              end;
                              if hVolume <> INVALID_HANDLE_VALUE then
                              begin
                                 if ListOnlyUSBDrives and (GetBusType(hVolume) <> 7) then
                                 begin
                                    try
                                       CloseHandle(hVolume);
                                    except
                                    end;
                                    CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'NotUSB'], 'This is not a USB drive !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
                                    Exit;
                                 end;
                                 dwBytesReturned := 0;
                                 try
                                    if DeviceIoControl(hVolume, IOCTL_STORAGE_GET_DEVICE_NUMBER, nil, 0, @sdn, SizeOf(sdn), dwBytesReturned, nil) then
                                    begin
                                       if sdn.DeviceNumber <> OSDrive then
                                       begin
                                          try
                                             hDrive := CreateFile(PWideChar('\\.\PHYSICALDRIVE' + IntToStr(sdn.DeviceNumber)), 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
                                          except
                                             hDrive := INVALID_HANDLE_VALUE;
                                          end;
                                          if hDrive <> INVALID_HANDLE_VALUE then
                                          begin
                                             try
                                                CloseHandle(hDrive);
                                             except
                                             end;
                                             try
                                                DriveToAdd := sdn.DeviceNumber;
                                                GetDrives(cmbFirstDrive);
                                             finally
                                                DriveToAdd := -1;
                                             end;
                                          end
                                          else
                                          begin
                                             LastError := GetLastError;
                                             CustomMessageBox(Handle, (GetLangTextFormatDef(idxAddEdit, ['Messages', 'ErrorAccessDrive'], [SysErrorMessage(LastError)], 'Error accessing the drive !'#13#10#13#10'System message: %s')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
                                          end;
                                       end
                                       else
                                       begin
                                          CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'CantUseOSDrive'], 'This is the OS drive, can''t use !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
                                       end;
                                    end
                                    else
                                    begin
                                       LastError := GetLastError;
                                       CustomMessageBox(Handle, (GetLangTextFormatDef(idxAddEdit, ['Messages', 'ErrorDriveNumber'], [SysErrorMessage(LastError)], 'Error getting the drive number !'#13#10#13#10'System message: %s')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
                                    end;
                                 except
                                    LastError := GetLastError;
                                    CustomMessageBox(Handle, (GetLangTextFormatDef(idxAddEdit, ['Messages', 'ErrorAccessVolume'], [SysErrorMessage(LastError)], 'Error accessing the volume on drive !'#13#10'System message: %s')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
                                 end;
                                 try
                                    CloseHandle(hVolume);
                                 except
                                 end;
                              end
                              else
                              begin
                                 LastError := GetLastError;
                                 CustomMessageBox(Handle, (GetLangTextFormatDef(idxAddEdit, ['Messages', 'ErrorAccessVolume'], [SysErrorMessage(LastError)], 'Error accessing the volume on drive !'#13#10'System message: %s')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
                              end;
                           end
                        else
                           CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'NotADrive'], 'This is not a removable or fixed local drive !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
                           Exit;
                     end;
                  finally
                     SetErrorMode(ErrorMode);
                  end;
               end
               else
               begin
                  CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'NotAVolOrDrive'], 'Not a volume or drive !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
               end;
            end;
         else
            DragFinish(Msg.WPARAM);
            CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'JustOneItem'], 'Just one item at a time !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
      end;
   end
   else
      originalcmbFirstDriveWindowProc(Msg);
end;

procedure TfrmAddEdit.cmbSecondDriveWindowProc(var Msg: TMessage);
var
   Buffer: array[0..MAX_PATH] of AnsiChar;
   strTemp: AnsiString;
   hVolume, hDrive: THandle;
   dwBytesReturned: dword;
   sdn: STORAGE_DEVICE_NUMBER;
   ErrorMode: Word;
begin
   if Msg.Msg = WM_DROPFILES then
   begin
      Application.BringToFront;
      frmMain.Repaint;
      Repaint;
      case DragQueryFile(Msg.WPARAM, $FFFFFFFF, nil, 0) of
         1:
            begin
               DragQueryFile(Msg.WPARAM, 0, @Buffer, SizeOf(Buffer));
               DragFinish(Msg.WPARAM);
               strTemp := AnsiString(Buffer);
               if (Length(strTemp) = 3) and (strTemp[1] in ['A'..'Z']) and (strTemp[2] = ':') and (strTemp[3] = '\') then
               begin
                  ErrorMode := SetErrorMode(SEM_FailCriticalErrors);
                  try
                     case GetDriveType(PWideChar(string(strTemp))) of
                        DRIVE_REMOVABLE, DRIVE_FIXED:
                           begin
                              try
                                 hVolume := CreateFile(PWideChar('\\.\' + strTemp[1] + ':'), 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
                              except
                                 hVolume := INVALID_HANDLE_VALUE;
                              end;
                              if hVolume <> INVALID_HANDLE_VALUE then
                              begin
                                 if ListOnlyUSBDrives and (GetBusType(hVolume) <> 7) then
                                 begin
                                    try
                                       CloseHandle(hVolume);
                                    except
                                    end;
                                    CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'NotUSB'], 'This is not a USB drive !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
                                    Exit;
                                 end;
                                 dwBytesReturned := 0;
                                 try
                                    if DeviceIoControl(hVolume, IOCTL_STORAGE_GET_DEVICE_NUMBER, nil, 0, @sdn, SizeOf(sdn), dwBytesReturned, nil) then
                                    begin
                                       if sdn.DeviceNumber <> OSDrive then
                                       begin
                                          try
                                             hDrive := CreateFile(PWideChar('\\.\PHYSICALDRIVE' + IntToStr(sdn.DeviceNumber)), 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
                                          except
                                             hDrive := INVALID_HANDLE_VALUE;
                                          end;
                                          if hDrive <> INVALID_HANDLE_VALUE then
                                          begin
                                             try
                                                CloseHandle(hDrive);
                                             except
                                             end;
                                             try
                                                DriveToAdd := sdn.DeviceNumber;
                                                GetDrives(cmbSecondDrive);
                                             finally
                                                DriveToAdd := -1;
                                             end;
                                          end
                                          else
                                          begin
                                             LastError := GetLastError;
                                             CustomMessageBox(Handle, (GetLangTextFormatDef(idxAddEdit, ['Messages', 'ErrorAccessDrive'], [SysErrorMessage(LastError)], 'Error accessing the drive !'#13#10#13#10'System message: %s')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
                                          end;
                                       end
                                       else
                                       begin
                                          CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'CantUseOSDrive'], 'This is the OS drive, can''t use !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
                                       end;
                                    end
                                    else
                                    begin
                                       LastError := GetLastError;
                                       CustomMessageBox(Handle, (GetLangTextFormatDef(idxAddEdit, ['Messages', 'ErrorDriveNumber'], [SysErrorMessage(LastError)], 'Error getting the drive number !'#13#10#13#10'System message: %s')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
                                    end;
                                 except
                                    LastError := GetLastError;
                                    CustomMessageBox(Handle, (GetLangTextFormatDef(idxAddEdit, ['Messages', 'ErrorAccessVolume'], [SysErrorMessage(LastError)], 'Error accessing the volume on drive !'#13#10#13#10'System message: %s')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
                                 end;
                                 try
                                    CloseHandle(hVolume);
                                 except
                                 end;
                              end
                              else
                              begin
                                 LastError := GetLastError;
                                 CustomMessageBox(Handle, (GetLangTextFormatDef(idxAddEdit, ['Messages', 'ErrorAccessVolume'], [SysErrorMessage(LastError)], 'Error accessing the volume on drive !'#13#10#13#10'System message: %s')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
                              end;
                           end
                        else
                           CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'NotADrive'], 'This is not a removable or fixed local drive !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
                           Exit;
                     end;
                  finally
                     SetErrorMode(ErrorMode);
                  end;
               end
               else
               begin
                  CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'NotAVolOrDrive'], 'Not a volume or drive !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
               end;
            end;
         else
            DragFinish(Msg.WPARAM);
            CustomMessageBox(Handle, (GetLangTextDef(idxAddEdit, ['Messages', 'JustOneItem'], 'Just one item at a time !')), GetLangTextDef(idxMessages, ['Types', 'Warning'], 'Warning'), mtWarning, [mbOk], mbOk);
      end;
   end
   else
      originalcmbSecondDriveWindowProc(Msg);
end;

function TfrmAddEdit.FindCDROMFromLetter(const CDROMLetter: AnsiChar): AnsiString;
var
   objWMIService: OLEVariant;
   colItems: OLEVariant;
   colItem: OLEVariant;
   oEnum: IEnumvariant;
   iValue: LongWord;
   i, j: Integer;
   isFound: Boolean;
   strTemp: AnsiString;

   function GetWMIObject(const objectName: AnsiString): IDispatch;
   var
      chEaten: Integer;
      BindCtx: IBindCtx;
      Moniker: IMoniker;
   begin
      OleCheck(CreateBindCtx(0, BindCtx));
      OleCheck(MkParseDisplayName(BindCtx, StringToOleStr(objectName), chEaten, Moniker));
      OleCheck(Moniker.BindToObject(BindCtx, nil, IDispatch, Result));
   end;

begin
   Result := '';
   if Succeeded(CoInitialize(nil)) then
   try
      try
         objWMIService := GetWMIObject(AnsiString(Format('winmgmts:\\%s\%s', ['.', 'root\CIMV2'])));
         colItems := objWMIService.ExecQuery(Format('SELECT %s FROM %s', ['Drive', 'Win32_CDROMDrive']), 'WQL', 0);
         oEnum := IUnknown(colItems._NewEnum) as IEnumvariant;
         i := 0;
         isFound := False;
         while oEnum.Next(1, colItem, iValue) = 0 do
         begin
            strTemp := AnsiString(colItem.Properties_.Item('Drive', 0));
            if strTemp = AnsiString(CDROMLetter + ':') then
            begin
               isFound := True;
               Break;
            end;
            Inc(i);
         end;
         if not isFound then
            Exit;
         colItems := objWMIService.ExecQuery(Format('SELECT %s FROM %s', ['Caption', 'Win32_CDROMDrive']), 'WQL', 0);
         oEnum := IUnknown(colItems._NewEnum) as IEnumvariant;
         j := 0;
         while oEnum.Next(1, colItem, iValue) = 0 do
         begin
            if i = j then
            begin
               Result := AnsiString(colItem.Properties_.Item('Caption', 0));
               Break;
            end;
            Inc(j);
            if j > i then
               Break;
         end;
      except
      end;
   finally
      CoUninitialize;
   end;
end;

procedure TfrmAddEdit.cmbFirstDriveDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
begin
   with Control as TComboBox do
   begin
      CBClientWidth := Min(CBClientWidth, Rect.Right - Rect.Left - 1);
      Canvas.FillRect(Rect);
      if Index = 0 then
         Canvas.TextOut(Rect.Left + 2, Rect.Top, Items[Index])
      else
      begin
         try
            Canvas.TextOut(Rect.Left + 2, Rect.Top, CBFirstDriveName[Index - 1]);
            Canvas.TextOut(Rect.Left + CBClientWidth - Canvas.TextWidth(CBFirstDriveLetters[Index - 1]), Rect.Top, CBFirstDriveLetters[Index - 1]);
            Canvas.TextOut(Rect.Left + CBClientWidth - Canvas.TextWidth(CBFirstDriveSize[Index - 1] + ' ') - CBMaxLetSize, Rect.Top, ' ' + CBFirstDriveSize[Index - 1]);
         except
            Canvas.TextOut(Rect.Left + 2, Rect.Top, Items[Index]);
         end;
      end;
   end;
end;

procedure TfrmAddEdit.cmbSecondDriveDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
begin
   with Control as TComboBox do
   begin
      CBClientWidth := Min(CBClientWidth, Rect.Right - Rect.Left - 1);
      Canvas.FillRect(Rect);
      if Index = 0 then
         Canvas.TextOut(Rect.Left + 2, Rect.Top, Items[Index])
      else
      begin
         try
            Canvas.TextOut(Rect.Left + 2, Rect.Top, CBSecondDriveName[Index - 1]);
            Canvas.TextOut(Rect.Left + CBClientWidth - Canvas.TextWidth(CBSecondDriveLetters[Index - 1]), Rect.Top, CBSecondDriveLetters[Index - 1]);
            Canvas.TextOut(Rect.Left + CBClientWidth - Canvas.TextWidth(CBSecondDriveSize[Index - 1] + ' ') - CBMaxLetSize, Rect.Top, ' ' + CBSecondDriveSize[Index - 1]);
         except
            Canvas.TextOut(Rect.Left + 2, Rect.Top, Items[Index]);
         end;
      end;
   end;
end;

procedure TfrmAddEdit.cmbCDROMDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
begin
   with Control as TComboBox do
   begin
      CBClientWidth := Min(CBClientWidth, Rect.Right - Rect.Left - 1);
      Canvas.FillRect(Rect);
      if (Index = 0) or (Index > nCDROMS) then
         Canvas.TextOut(Rect.Left + 2, Rect.Top, Items[Index])
      else
      begin
         try
            Canvas.TextOut(Rect.Left + 2, Rect.Top, string(aCDROMInfo[Index - 1].Name));
            Canvas.TextOut(Rect.Left + CBClientWidth - Canvas.TextWidth(' []:' + aCDROMInfo[Index - 1].Letter), Rect.Top, ' [' + aCDROMInfo[Index - 1].Letter + ':]');
         except
            Canvas.TextOut(Rect.Left + 2, Rect.Top, Items[Index]);
         end;
      end;
   end;
end;

end.

