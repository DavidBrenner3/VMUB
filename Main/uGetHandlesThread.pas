unit uGetHandlesThread;

interface

uses
   Classes, Windows, SysUtils, PSApi, Math, SyncObjs, ShellApi, Graphics, TLHelp32, Dialogs;

function ConvertPhysicalNameToVirtualPathName(const PhysicalName: string): string;
function GetHDDDevicesWithDOSPath: TStringList;
function GetFileFolderTypeNumber: Byte;

type
   TGetHandlesThread = class(TThread)
   private
      FVol: Char;
      { Private declarations }
   protected
      procedure Execute; override;
   public
      isJobDone: Boolean;
      constructor Create(const Vol: Char; const DoCleanup: Boolean = False);
      destructor Destroy; override;
   end;

const
   SystemHandleInformation = $10;
   FileNameInformation = 9;
   FileAccessInformation = 8;
   ObjectNameInformation = 1;
   DefaulBUFFERSIZE = $100000;

   STATUS_SUCCESS = $00000000;
   STATUS_TIMEOUT = $00000102;

var
   mEvent: TEvent;
   hTest: THandle;
   FnCPU, FhCPU: SmallInt;
   FprocessID: DWORD;
   FhProcess: THandle;

type
   TStrObj = class
      Value: string;
   end;

   SYSTEM_HANDLE = record
      uIdProcess: ULONG;
      ObjectType: Byte;
      Flags: Byte;
      Handle: USHORT;
      pObject: PVOID;
      GrantedAccess: ACCESS_MASK;
   end;

   SYSTEM_HANDLE_ARRAY = array[0..0] of SYSTEM_HANDLE;

   SYSTEM_HANDLE_INFORMATION = record
      uCount: ULONG;
      Handles: SYSTEM_HANDLE_ARRAY;
   end;
   PSYSTEM_HANDLE_INFORMATION = ^SYSTEM_HANDLE_INFORMATION;

   NT_STATUS = Cardinal;

   PFILE_NAME_INFORMATION = ^FILE_NAME_INFORMATION;
   FILE_NAME_INFORMATION = record
      FileNameLength: ULONG;
      FileName: array[0..MAX_PATH - 1] of WideChar;
   end;

   PUNICODE_STRING = ^TUNICODE_STRING;
   TUNICODE_STRING = record
      Length: WORD;
      MaximumLength: WORD;
      Buffer: array[0..MAX_PATH - 1] of WideChar;
   end;

   _OBJECT_NAME_INFORMATION = record
      Length: USHORT;
      MaximumLength: USHORT;
      Pad: DWORD;
      Name: array[0..MAX_PATH - 1] of Char;
   end;
   OBJECT_NAME_INFORMATION = _OBJECT_NAME_INFORMATION;
   POBJECT_NAME_INFORMATION = ^OBJECT_NAME_INFORMATION;

   PIO_STATUS_BLOCK = ^IO_STATUS_BLOCK;
   IO_STATUS_BLOCK = record
      Status: NT_STATUS;
      Information: DWORD;
   end;

   PGetFileNameThreadParam = ^TGetFileNameThreadParam;
   TGetFileNameThreadParam = record
      hFile: THandle;
      Result: NT_STATUS;
      FileName: array[0..MAX_PATH - 1] of WideChar;
   end;

   _FILE_ACCESS_INFORMATION = record
      GrantedAccess: ACCESS_MASK;
   end;
   FILE_ACCESS_INFORMATION = _FILE_ACCESS_INFORMATION;

implementation

uses MainForm;

function NtQueryInformationFile(FileHandle: THandle; IoStatusBlock: PIO_STATUS_BLOCK; FileInformation: Pointer; Length: DWORD; FileInformationClass: DWORD): NT_STATUS; stdcall; external 'ntdll.dll';

function NtQueryObject(ObjectHandle: THandle; ObjectInformationClass: DWORD; ObjectInformation: Pointer; ObjectInformationLength: ULONG; ReturnLength: PDWORD): NT_STATUS; stdcall; external 'ntdll.dll';

function NtQuerySystemInformation(SystemInformationClass: DWORD; SystemInformation: Pointer; SystemInformationLength: ULONG; ReturnLength: PULONG): NT_STATUS; stdcall; external 'ntdll.dll' name 'NtQuerySystemInformation';

function GetProcessImageFileName(hProcess: THandle; lpImageFileName: LPCWSTR; nSize: DWORD): DWORD; stdcall; external 'PSAPI.dll' name 'GetProcessImageFileNameW';

function PrivateExtractIcons(lpszFile: PChar; nIconIndex, cxIcon, cyIcon: integer; phicon: PHANDLE; piconid: PDWORD; nicon, flags: DWORD): DWORD; stdcall; external 'user32.dll' name 'PrivateExtractIconsW';

function GetFileNameHandleThr(Data: Pointer): DWORD; stdcall;
var
   dwReturn: DWORD;
   FileNameInfo: FILE_NAME_INFORMATION;
   ObjectNameInfo: OBJECT_NAME_INFORMATION;
   IoStatusBlock: IO_STATUS_BLOCK;
   pThreadParam: TGetFileNameThreadParam;
begin
   ZeroMemory(@FileNameInfo, SizeOf(FILE_NAME_INFORMATION));
   try
      pThreadParam := PGetFileNameThreadParam(Data)^;
      Result := STATUS_SUCCESS;
   except
      Result := STATUS_TIMEOUT;
   end;
   if Result = STATUS_SUCCESS then
   try
      Result := NtQueryInformationFile(pThreadParam.hFile, @IoStatusBlock, @FileNameInfo, MAX_PATH * 2, FileNameInformation);
   except
      Result := STATUS_TIMEOUT;
   end;
   if Result = STATUS_SUCCESS then
   begin
      try
         Result := NtQueryObject(pThreadParam.hFile, ObjectNameInformation, @ObjectNameInfo, MAX_PATH * 2, @dwReturn);
      except
         Result := STATUS_TIMEOUT;
      end;
      if Result = STATUS_SUCCESS then
      begin
         pThreadParam.Result := Result;
         {$IFDEF WIN32}
         Move(ObjectNameInfo.Name[0], pThreadParam.FileName[0], Min(ObjectNameInfo.Length, MAX_PATH) * SizeOf(WideChar));
         {$ENDIF}
         {$IFDEF WIN64}
         Move(ObjectNameInfo.Name[(ObjectNameInfo.MaximumLength - ObjectNameInfo.Length) * SizeOf(WideChar)], pThreadParam.FileName[0], Min(ObjectNameInfo.Length, MAX_PATH) * SizeOf(WideChar));
         {$ENDIF}
      end
      else
      begin
         pThreadParam.Result := STATUS_SUCCESS;
         Result := STATUS_SUCCESS;
         Move(FileNameInfo.FileName[0], pThreadParam.FileName[0], Min(IoStatusBlock.Information, MAX_PATH) * SizeOf(WideChar));
      end;
   end;
   if Result = STATUS_SUCCESS then
   try
      PGetFileNameThreadParam(Data)^ := pThreadParam;
      Result := STATUS_SUCCESS;
   except
      Result := STATUS_TIMEOUT;
   end;
   ExitThread(Result);
end;

type
   aTHandle = array of THandle;
   aString = array of string;
   aDWORD = array of DWORD;

function GetFileNameHandle(hFiles: aTHandle): aString;
var
   i: Integer;
   lpExitCode: DWORD;
   pThreadParams: array of TGetFileNameThreadParam;
   hThreads: array of THandle;
begin
   SetLength(hThreads, FnCPU);
   SetLength(pThreadParams, FnCPU);
   SetLength(Result, FnCPU);
   for i := 0 to FnCPU - 1 do
   begin
      Result[i] := '';
      ZeroMemory(@pThreadParams[i], SizeOf(TGetFileNameThreadParam));
      pThreadParams[i].hFile := hFiles[i];
      try
         hThreads[i] := CreateThread(nil, 0, @GetFileNameHandleThr, @pThreadParams[i], 0, PDWORD(nil)^);
      except
         hThreads[i] := 0;
      end;
   end;
   for i := 0 to FnCPU - 1 do
      if hThreads[i] <> 0 then
      try
         SetThreadPriority(hThreads[i], THREAD_PRIORITY_HIGHEST);
         case WaitForSingleObject(hThreads[i], 100) of
            WAIT_OBJECT_0:
               begin
                  GetExitCodeThread(hThreads[i], lpExitCode);
                  if lpExitCode = STATUS_SUCCESS then
                     Result[i] := pThreadParams[i].FileName;
               end;
            WAIT_TIMEOUT:
               TerminateThread(hThreads[i], 0);
         end;
      finally
         CloseHandle(hThreads[i]);
      end;
end;

function GetHDDDevicesWithDOSPath: TStringList;
var
   i: integer;
   Root: string;
   Device: string;
   Buffer: string;
   strObj: TStrObj;
begin
   SetLength(Buffer, 1000);
   Result := TStringList.Create;
   Result.CaseSensitive := False;
   Result.Sorted := False;
   Result.Duplicates := dupIgnore;
   Result.BeginUpdate;
   for i := Ord('a') to Ord('z') do
   begin
      Root := Char(i - 32) + ':';
      if (QueryDosDevice(PChar(Root), PChar(Buffer), 1000) <> 0) then
      begin
         Device := PChar(Buffer);
         strObj := TStrObj.Create;
         strObj.Value := Root;
         Result.AddObject(Device, strObj);
      end;
   end;
   Result.EndUpdate;
end;

function ConvertPhysicalNameToVirtualPathName(const PhysicalName: string): string;
var
   i, Index: Integer;
   Device: string;
begin
   i := Length(PhysicalName);
   while i > 1 do
   begin
      if PhysicalName[i] = '\' then
      begin
         Device := Copy(PhysicalName, 1, i - 1);
         Index := DevPathNameMap.IndexOf(Device);
         if Index > -1 then
         begin
            Result := TStrObj(DevPathNameMap.Objects[Index]).Value + Copy(PhysicalName, i, Length(PhysicalName) - i + 1);
            Exit;
         end;
      end;
      Dec(i);
   end;
   Result := PhysicalName;
end;

{function GetParentProcessId(ProcessID: DWORD): DWORD;
var
   Snapshot: THandle;
   Entry: TProcessEntry32;
   B: Boolean;
begin
   Result := 0; // 0 means not found
   Snapshot := CreateToolHelp32Snapshot(TH32CS_SNAPPROCESS, 0);
   if Snapshot <> 0 then
   begin
      FillChar(Entry, SizeOf(Entry), 0);
      Entry.dwSize := SizeOf(Entry);
      B := Process32First(Snapshot, Entry);
      while B do
      begin
         if Entry.th32ProcessID = ProcessID then
         begin
            Result := Entry.th32ParentProcessID;
            Break;
         end;
         B := Process32Next(Snapshot, Entry);
      end;
      CloseHandle(Snapshot);
   end;
end;}

function GetEXEVersionProductName(const FileName: string): string;
type
   PLandCodepage = ^TLandCodepage;
   TLandCodepage = record
      wLanguage,
         wCodePage: word;
   end;
var
   dummy,
      len: cardinal;
   buf, pntr: pointer;
   lang: string;
begin
   try
      len := GetFileVersionInfoSize(PChar(FileName), dummy);
   except
      len := 0;
   end;
   if len = 0 then
      Exit;
   GetMem(buf, len);
   try
      try
         if not GetFileVersionInfo(PChar(FileName), 0, len, buf) then
            Exit;

         if not VerQueryValue(buf, '\VarFileInfo\Translation\', pntr, len) then
            Exit;

         lang := Format('%.4x%.4x', [PLandCodepage(pntr)^.wLanguage, PLandCodepage(pntr)^.wCodePage]);

         if VerQueryValue(buf, PChar('\StringFileInfo\' + lang + '\ProductName'), pntr, len) { and (@len <> nil)} then
            result := string(PChar(pntr));
      except
      end;
   finally
      FreeMem(buf);
   end;
end;

function SetDebugPrivilege: Boolean;
var
   TokenHandle: THandle;
   TokenPrivileges: TTokenPrivileges;
   isOpened: Boolean;
begin
   Result := false;
   try
      isOpened := OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, TokenHandle);
   except;
      isOpened := False;
   end;
   if isOpened then
   begin
      if LookupPrivilegeValue(nil, PChar('SeDebugPrivilege'), TokenPrivileges.Privileges[0].Luid) then
      begin
         TokenPrivileges.PrivilegeCount := 1;
         TokenPrivileges.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
         try
            Result := AdjustTokenPrivileges(TokenHandle, False,
               TokenPrivileges, 0, PTokenPrivileges(nil)^, PDWord(nil)^);
         except
            Result := False;
         end;
      end;
   end;
end;

procedure EnumerateOpenDevicesOnVolume(const v: Char);
var
   Root, Device, Buffer: string;
   FileNames: aString;
   hProcesses: aTHandle;
   hFiles, hOrgFiles: aTHandle;
   ProcessIDs, aAccess: aDWORD;
   ResultLength, aBufferSize: DWORD;
   aIndex, ld, ldc, le, nAddPos, pCPU: Integer;
   pHandleInfo: PSYSTEM_HANDLE_INFORMATION;
   hInfoHandles: NT_STATUS;
   lpszProcess: PWideChar;
   idDuplicated: Boolean;
   hIcon: THandle;
   nIconId: DWORD;
   iconFound: Boolean;
   bIsFolder: Boolean;

   procedure AddToFound;
   var
      j: Integer;
   begin
      for j := 0 to FhCPU do
         if Length(FileNames[j]) > ld then
            if CompareMem(@Filenames[j][1], @Device[1], ldc) then
            begin
               FileNames[j] := UpperCase(v) + ':' + Copy(FileNames[j], ld + 1, Length(FileNames[j]) - ld + 1);
               if DirectoryExists(FileNames[j]) then
                  bIsFolder := True
               else if FileExists(FileNames[j]) then
                  bIsFolder := False
               else
                  Continue;

               nAddPos := 0;
               while nAddPos <= High(OpenHandlesInfo) do
               begin
                  if OpenHandlesInfo[nAddPos].ProcessID = ProcessIDs[j] then
                     Break;
                  Inc(nAddPos);
               end;

               lpszProcess := AllocMem(MAX_PATH);
               if nAddPos > High(OpenHandlesInfo) then
               begin
                  iconFound := False;
                  SetLength(OpenHandlesInfo, Length(OpenHandlesInfo) + 1);
                  try
                     if GetProcessImageFileName(hProcesses[j], lpszProcess, 2 * MAX_PATH) <> 0 then
                     begin
                        OpenHandlesInfo[High(OpenHandlesInfo)].Process := ExtractFileName(lpszProcess);
                        le := Length(ExtractFileExt(OpenHandlesInfo[High(OpenHandlesInfo)].Process));
                        OpenHandlesInfo[High(OpenHandlesInfo)].Process := Copy(OpenHandlesInfo[High(OpenHandlesInfo)].Process,
                           1, Length(OpenHandlesInfo[High(OpenHandlesInfo)].Process) - le);
                        OpenHandlesInfo[High(OpenHandlesInfo)].ProcessFullPath := ConvertPhysicalNameToVirtualPathName(string(lpszProcess));
                        OpenHandlesInfo[High(OpenHandlesInfo)].ProcessID := ProcessIDs[j];
                        OpenHandlesInfo[High(OpenHandlesInfo)].ProductName := GetEXEVersionProductName(OpenHandlesInfo[High(OpenHandlesInfo)].ProcessFullPath);
                        if OpenHandlesInfo[High(OpenHandlesInfo)].ProductName = '' then
                           OpenHandlesInfo[High(OpenHandlesInfo)].ProductName := OpenHandlesInfo[High(OpenHandlesInfo)].Process;
                        OpenHandlesInfo[High(OpenHandlesInfo)].ProcessIcon := TIcon.Create;
                        iconFound := False;
                        case SystemIconSize of
                           -2147483647..18:
                              begin
                                 if PrivateExtractIcons(PWideChar(OpenHandlesInfo[High(OpenHandlesInfo)].ProcessFullPath), 0, 16, 16,
                                    @hIcon, @nIconId, 1, LR_LOADFROMFILE) <> 0 then
                                 begin
                                    OpenHandlesInfo[High(OpenHandlesInfo)].ProcessIcon.Handle := hIcon;
                                    iconFound := True;
                                 end;
                              end;
                           19..22:
                              begin
                                 if PrivateExtractIcons(PWideChar(OpenHandlesInfo[High(OpenHandlesInfo)].ProcessFullPath), 0, 20, 20,
                                    @hIcon, @nIconId, 1, LR_LOADFROMFILE) <> 0 then
                                 begin
                                    OpenHandlesInfo[High(OpenHandlesInfo)].ProcessIcon.Handle := hIcon;
                                    iconFound := True;
                                 end;
                              end;
                           23..2147483647:
                              begin
                                 if PrivateExtractIcons(PWideChar(OpenHandlesInfo[High(OpenHandlesInfo)].ProcessFullPath), 0, 24, 24,
                                    @hIcon, @nIconId, 1, LR_LOADFROMFILE) <> 0 then
                                 begin
                                    OpenHandlesInfo[High(OpenHandlesInfo)].ProcessIcon.Handle := hIcon;
                                    iconFound := True;
                                 end;
                              end;
                        end;
                        if not iconFound then
                        begin
                           OpenHandlesInfo[High(OpenHandlesInfo)].ProcessIcon.Free;
                           OpenHandlesInfo[High(OpenHandlesInfo)].ProcessIcon := nil;
                        end;
                     end
                     else
                     begin
                        OpenHandlesInfo[High(OpenHandlesInfo)].Process := 'System';
                        OpenHandlesInfo[High(OpenHandlesInfo)].ProcessFullPath := '';
                        OpenHandlesInfo[High(OpenHandlesInfo)].ProductName := 'System';
                     end;
                  except
                     OpenHandlesInfo[High(OpenHandlesInfo)].Process := 'System';
                     OpenHandlesInfo[High(OpenHandlesInfo)].ProcessFullPath := '';
                     OpenHandlesInfo[High(OpenHandlesInfo)].ProductName := 'System';
                  end;
                  SetLength(OpenHandlesInfo[High(OpenHandlesInfo)].FilesData, 0);
               end;

               SetLength(OpenHandlesInfo[High(OpenHandlesInfo)].FilesData, Length(OpenHandlesInfo[High(OpenHandlesInfo)].FilesData) + 1);

               OpenHandlesInfo[High(OpenHandlesInfo)].FilesData[High(OpenHandlesInfo[High(OpenHandlesInfo)].FilesData)].FileName := FileNames[j];
               OpenHandlesInfo[High(OpenHandlesInfo)].FilesData[High(OpenHandlesInfo[High(OpenHandlesInfo)].FilesData)].FileHandle := hOrgFiles[j];
               OpenHandlesInfo[High(OpenHandlesInfo)].FilesData[High(OpenHandlesInfo[High(OpenHandlesInfo)].FilesData)].AccessType := aAccess[j];
               OpenHandlesInfo[High(OpenHandlesInfo)].FilesData[High(OpenHandlesInfo[High(OpenHandlesInfo)].FilesData)].isFolder := bIsFolder;
               OpenHandlesInfo[High(OpenHandlesInfo)].Delete := False;

               FreeMem(lpszProcess);
            end;
   end;

var
   j: Integer;
   CurProcessID: DWORD;
   hCurProcess: THandle;
   //dt: Cardinal;
begin
   //dt := Gettickcount;
   SetLength(OpenHandlesInfo, 0);
   SetDebugPrivilege;

   SetLength(Buffer, 1000);
   Root := v + ':';
   if (QueryDosDevice(PChar(Root), PChar(Buffer), 1000) <> 0) then
      Device := PChar(Buffer)
   else
      Exit;
   ld := Length(Device);
   ldc := 2 * ld;
   AbufferSize := DefaulBUFFERSIZE;
   pHandleInfo := AllocMem(AbufferSize);
   try
      hInfoHandles := NTQuerySystemInformation(DWORD(SystemHandleInformation), pHandleInfo, AbufferSize, @ResultLength);
   except
      hInfoHandles := STATUS_TIMEOUT;
   end;

   if hInfoHandles = STATUS_SUCCESS then
   begin
      if (FprocessID <> 0) and (FhProcess <> 0) then
      begin
         for aIndex := 0 to pHandleInfo^.uCount - 1 do
            if pHandleInfo.Handles[aIndex].ObjectType = nObjectType then //Files and folders
               if pHandleInfo.Handles[aIndex].uIdProcess = FprocessID then
               begin
                  try
                     DuplicateHandle(FhProcess, pHandleInfo.Handles[aIndex].Handle, 0, nil, 0, False, DUPLICATE_CLOSE_SOURCE);
                  except
                  end;
               end;
         try
            TerminateProcess(FhProcess, 0);
         except
         end;
         FreeMem(pHandleInfo);
         Exit;
      end;
      //Aligned parts
      pCPU := 0;
      SetLength(FileNames, FnCPU);
      SetLength(hFiles, FnCPU);
      SetLength(hOrgFiles, FnCPU);
      SetLength(hProcesses, FnCPU);
      SetLength(ProcessIDs, FnCPU);
      SetLength(aAccess, FnCPU);
      CurProcessID := GetCurrentProcessID;
      hCurProcess := GetCurrentProcess();
      for aIndex := 0 to pHandleInfo^.uCount - 1 do
         if pHandleInfo.Handles[aIndex].ObjectType = nObjectType then //Files and folders
            if pHandleInfo.Handles[aIndex].uIdProcess <> CurProcessID then
            begin
               ProcessIDs[pCPU] := pHandleInfo.Handles[aIndex].uIdProcess;
               hOrgFiles[pCPU] := pHandleInfo.Handles[aIndex].Handle;
               aAccess[pCPU] := pHandleInfo.Handles[aIndex].GrantedAccess;
               try
                  hProcesses[pCPU] := OpenProcess(PROCESS_DUP_HANDLE or PROCESS_QUERY_INFORMATION, FALSE, pHandleInfo.Handles[aIndex].uIdProcess);
               except
                  hProcesses[pCPU] := 0;
               end;
               if hProcesses[pCPU] <> 0 then
               begin
                  hFiles[pCPU] := 0;
                  LastError := 0;
                  try
                     idDuplicated := DuplicateHandle(hProcesses[pCPU], pHandleInfo.Handles[aIndex].Handle, hCurProcess, @hFiles[pCPU], 0, False, DUPLICATE_SAME_ACCESS);
                     LastError := GetLastError;
                  except
                     idDuplicated := False;
                  end;
                  if idDuplicated then
                  begin
                     if pCPU = FhCPU then
                     begin
                        FileNames := GetFileNameHandle(hFiles);
                        for j := 0 to FhCPU do
                        begin
                           AddToFound;
                           CloseHandle(hProcesses[j]);
                           CloseHandle(hFiles[j]);
                        end;
                        pCPU := 0;
                     end
                     else
                        Inc(pCPU);
                  end
                  else
                     CloseHandle(hProcesses[pCPU]);
               end;
            end;
      if pCPU > 0 then
      begin
         //Unaligned part
         FnCPU := pCPU;
         Dec(pCPU);
         FhCPU := pCPU;
         SetLength(FileNames, FnCPU);
         SetLength(hFiles, FnCPU);
         SetLength(hOrgFiles, FnCPU);
         SetLength(hProcesses, FnCPU);
         SetLength(ProcessIDs, FnCPU);
         SetLength(aAccess, FnCPU);
         FileNames := GetFileNameHandle(hFiles);
         for j := 0 to FhCPU do
         begin
            AddToFound;
            CloseHandle(hProcesses[j]);
            CloseHandle(hFiles[j]);
         end;
      end;
   end;
   FreeMem(pHandleInfo);
   //dt := Gettickcount - dt;
   //messagebox(0, pchar(inttostr(dt)), '', mb_ok);
end;

function GetFileFolderTypeNumber: Byte;
var
   hGetType: THandle;
   pHandleInfo: PSYSTEM_HANDLE_INFORMATION;
   resInfoHandles: NT_STATUS;
   CurProcessID, ResultLength, aBufferSize: DWORD;
   aIndex: Integer;
begin
   Result := 0;
   try
      hGetType := CreateFile(PChar('Nul'), GENERIC_READ, 0, nil, CREATE_NEW, 0, 0);
   except
      hGetType := INVALID_HANDLE_VALUE;
   end;
   if hGetType <> INVALID_HANDLE_VALUE then
   try
      AbufferSize := DefaulBUFFERSIZE;
      pHandleInfo := AllocMem(AbufferSize);
      try
         resInfoHandles := NTQuerySystemInformation(DWORD(SystemHandleInformation), pHandleInfo, AbufferSize, @ResultLength);
      except
         resInfoHandles := STATUS_TIMEOUT;
      end;

      if resInfoHandles = STATUS_SUCCESS then
      begin
         CurProcessID := GetCurrentProcessID;
         for aIndex := 0 to pHandleInfo^.uCount - 1 do
         begin
            if pHandleInfo.Handles[aIndex].uIdProcess = CurProcessID then
               if pHandleInfo.Handles[aIndex].Handle = hGetType then
               begin
                  Result := pHandleInfo.Handles[aIndex].ObjectType;
                  Break;
               end;
         end;
      end;
      FreeMem(pHandleInfo);
   finally
      CloseHandle(hGetType);
   end;
   if Result = 0 then
      case TOSVersion.Major of
         5: if TOSVersion.Minor = 0 then
               Result := 26 //2000
            else
               Result := 28; //XP
         6: case TOSVersion.Minor of
               0: Result := 25; //Vista
               1: Result := 28; //7
               2: Result := 31; //8
               3: Result := 30; //8.1
            end;
         10: Result := 35; //10
      end;
end;

constructor TGetHandlesThread.Create(const Vol: Char; const DoCleanup: Boolean = False);
begin
   if not DoCleanup then
   begin
      FprocessID := 0;
      FhProcess := 0;
   end;
   inherited Create(False);
   FnCPU := NumberOfProcessors;
   FhCPU := NumberOfProcessors - 1;
   mEvent := TEvent.Create(nil, True, False, '');
   FVol := Vol;
   isJobDone := False;
   Priority := tpHighest;
end; { TGetHandlesThread.Create }

destructor TGetHandlesThread.Destroy;
begin
   mEvent.Free;
end;

procedure TGetHandlesThread.Execute;
begin
   try
      EnumerateOpenDevicesOnVolume(FVol);
   finally
      isJobDone := True;
   end;
end; { TGetHandlesThread.Execute }

end.

