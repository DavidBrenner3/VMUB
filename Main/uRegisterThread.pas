unit uRegisterThread;

interface

uses
   Classes, Windows, SysUtils, WinSvc, ShlWapi, Forms, Dialogs, uPrestartThread, ShellAPI, Messages, SyncObjs;

type
   TRegisterThread = class(TThread)
   private
      { Private declarations }
      mEvent: TEvent;
   protected
      procedure Execute; override;
   public
      constructor Create;
      procedure Terminate;
   end;

implementation

uses Mainform;

constructor TRegisterThread.Create;
begin
   inherited Create(False);
   mEvent := TEvent.Create(nil, True, False, '');
   strRegErrMsg := '';
   SetPriorityClass(GetCurrentProcess(), ABOVE_NORMAL_PRIORITY_CLASS);
   Priority := tpLower;
   with frmMain do
      if not (csDestroying in frmMain.ComponentState) then
         if (vstVMs.GetFirstSelected = nil) or ((vstVMs.GetFirstSelected <> nil) and (PData(vstVMs.GetNodeData(vstVMs.GetFirstSelected))^.Ptype = 0)) then
         begin
            imlBtn16.PngImages[0].PngImage := imlReg16.PngImages[2].PngImage;
            imlBtn16.PngImages[9].PngImage := imlReg16.PngImages[2].PngImage;
            imlBtn24.PngImages[0].PngImage := imlReg24.PngImages[2].PngImage;
            imlBtn24.PngImages[7].PngImage := imlReg24.PngImages[2].PngImage;
            if btnStart.PngImage.Width = 16 then
               btnStart.PngImage := imlReg16.PngImages[2].PngImage
            else
               btnStart.PngImage := imlReg24.PngImages[2].PngImage;
         end;
end; { TRegisterThread.Create }

procedure TRegisterThread.Execute;
type
   TRegFunc = function: HResult; stdcall;
var
   eStartupInfo: TStartupInfo;
   eProcessInfo: TProcessInformation;
   PexeVboxSvc, PexeVboxSvcPath, PexeRegSvr32, PexeRegSvr32Path, PexeRundll32Path, PexeRundll32{$IFDEF WIN32},
   PexeDevCon, PexeDevConPath{$ENDIF}, PexeSnetCfg, PexeSnetCfgPath: PChar;
   exeVboxSvcPath, exeRegSvr32Path, exeRundll32Path, exeVBPathAbs, dllPath, drvSysPath{$IFDEF WIN32}, exeDevConPath{$ENDIF},
   strDisplayName, strNetAdp, strNetBrdg1, strNetBrdg2, strNetBrdg3, curDir, exeSnetCfgPath, strTemp: string;
   Buffer: array[0..MAX_PATH] of Char;
   Path: array[0..MAX_PATH - 1] of Char;
   ExitCode, dwTID: DWORD;
   hProcessDup, RemoteProcHandle: Cardinal;
   i: Integer;
   bDup: BOOL;
   dwCode: DWORD;
   hrt: Cardinal;
   hKernel: HMODULE;
   FARPROC: Pointer;
   uExitCode: Cardinal;
   ssStatus: TServiceStatus;
   Result, resCP: Boolean;
   dt: Cardinal;
   InitFunc: TRegFunc;
   vLibHandle: THandle;
   hFind: THandle;
   wfa: ^WIN32_FIND_DATAW;
   fos: TSHFileOpStruct;
   //times: array[1..12] of Cardinal;
begin
   Result := True;
   try
      ResetLastError;
      if PathIsRelative(PChar(ExeVBPath)) then
      begin
         PathCanonicalize(@Path[0], PChar(IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) + ExeVBPath));
         if string(Path) <> '' then
            exeVBPathAbs := Path
         else
            exeVBPathAbs := exeVBPath;
      end
      else
         exeVBPathAbs := exeVBPath;
      if TOSVersion.Major < 6 then
      begin
         strNetAdp := '';
         strNetBrdg1 := 'Flt';
         strNetBrdg2 := 'sun';
         strNetBrdg3 := 'M';
      end
      else
      begin
         strNetAdp := '6';
         strNetBrdg1 := 'Lwf';
         strNetBrdg2 := 'oracle';
         strNetBrdg3 := '';
      end;
      GetSystemDirectory(Buffer, MAX_PATH - 1);
      drvSysPath := IncludeTrailingPathDelimiter(string(Buffer)) + '\Drivers\';
      SetLength(exeRegsvr32Path, StrLen(Buffer));
      exeRegsvr32Path := Buffer;
      exeRegSvr32Path := IncludeTrailingPathDelimiter(exeRegSvr32Path) + 'regsvr32.exe';

      Result := Result and SetEnvVariable('VBOX_USER_HOME', VBOX_USER_HOME);

      if Terminated then
         Exit;

      if not Result then
      begin
         if LastError > 0 then
            strTemp := SysErrorMessage(LastError)
         else if LastExceptionStr <> '' then
            strTemp := LastExceptionStr;
         strRegErrMsg := strRegErrMsg + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemChangeEnv'], ['VBOX_USER_HOME'], 'problem changing the %s environment variable'#13#10#13#10'System message:') + ' ' + strTemp;
      end;

      if isVBInstalledToo and FileExists(exeVBPathToo) and useLoadedFromInstalled then
         Exit;

      if Terminated then
         Exit;

      FillChar(eStartupInfo, SizeOf(eStartupInfo), #0);
      eStartupInfo.dwFlags := STARTF_USESHOWWINDOW;
      eStartupInfo.cb := SizeOf(eStartupInfo);
      eStartupInfo.wShowWindow := SW_HIDE;

      {$IFDEF WIN32}
      if TOSversion.Architecture = arIntelX64 then
      begin
         if CheckInstalledInf('USB\VID_80EE&PID_CAFE') > 0 then
         begin
            exeDevConPath := ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs))) + 'data\tools\devcon_x64.exe';
            try
               strTemp := '"' + exeDevConPath + '" remove "USB\VID_80EE&PID_CAFE"';
               UniqueString(strTemp);
               PexeDevCon := PChar(strTemp);
               PexeDevConPath := PChar(ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs))) + 'data\tools\');
               ResetLastError;
               try
                  resCP := CreateProcess(nil, PexeDevCon, nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, PexeDevConPath, eStartupInfo, eProcessInfo);
                  LastError := GetLastError;
               except
                  on E: Exception do
                  begin
                     resCP := False;
                     LastExceptionStr := E.Message;
                  end;
               end;
               if Terminated then
                  Exit;
               if resCP then
               begin
                  dt := GetTickCount;
                  while (GetTickCount - dt) <= 5000 do
                  begin
                     if WaitForInputIdle(eProcessInfo.hProcess, 50) <> WAIT_TIMEOUT then
                        Break;
                     if Terminated then
                        Exit;
                  end;
                  dt := GetTickCount;
                  while (GetTickCount - dt) <= 8000 do
                  begin
                     if WaitForSingleObject(eProcessInfo.hProcess, 50) <> WAIT_TIMEOUT then
                        Break;
                     if Terminated then
                        Exit;
                  end;
                  try
                     GetExitCodeProcess(eProcessInfo.hProcess, ExitCode);
                     if ExitCode = Still_Active then
                     begin
                        uExitCode := 0;
                        RemoteProcHandle := GetProcessHandleFromID(eProcessInfo.dwProcessId);
                        bDup := DuplicateHandle(GetCurrentProcess(), RemoteProcHandle, GetCurrentProcess(), @hProcessDup, PROCESS_ALL_ACCESS, False, 0);
                        if GetExitCodeProcess(hProcessDup, dwCode) then
                        begin
                           hKernel := GetModuleHandle('Kernel32');
                           FARPROC := GetProcAddress(hKernel, 'ExitProcess');
                           hRT := CreateRemoteThread(hProcessDup, nil, 0, Pointer(FARPROC), @uExitCode, 0, dwTID);
                           if hrt = 0 then
                              TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), eProcessInfo.dwProcessId), 0)
                           else
                              CloseHandle(hRT);
                        end
                        else
                           TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), eProcessInfo.dwProcessId), 0);
                        if (bDup) then
                           CloseHandle(hProcessDup);
                        GetExitCodeProcess(eProcessInfo.hProcess, ExitCode);
                     end;
                     if (ExitCode <> Still_Active) and (ExitCode <> 0) then
                     begin
                        if LastError > 0 then
                           strTemp := SysErrorMessage(LastError)
                        else if LastExceptionStr <> '' then
                           strTemp := LastExceptionStr
                        else
                           strTemp := GetLangTextFormatDef(idxMain, ['Messages', 'ErrorCode'], [IntToStr(ExitCode), 'devcon'], '%s error code from %s');
                        strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemUninstalling'], ['VBoxUSB.inf'], 'problem uninstalling %s'#13#10#13#10'System message:') + ' ' + strTemp;
                        Result := Result and False;
                     end;
                     CloseHandle(eProcessInfo.hProcess);
                     CloseHandle(eProcessInfo.hThread);
                  except
                  end;
               end
               else
               begin
                  if not FileExists(exeDevConPath) then
                     strTemp := 'file not found'
                  else if LastError > 0 then
                     strTemp := SysErrorMessage(LastError)
                  else if LastExceptionStr <> '' then
                     strTemp := LastExceptionStr;
                  strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemStarting'], ['devcon'], 'problem starting %s'#13#10#13#10'System message:') + ' ' + strTemp;
                  Result := Result and False;
               end;
            finally
            end;
         end;
      end
      else
         UninstallInf('USB\VID_80EE&PID_CAFE');
      {$ENDIF}
      {$IFDEF WIN64}
      UninstallInf('USB\VID_80EE&PID_CAFE');
      {$ENDIF}

      ssStatus := ServiceStatus('VBoxUSB');
      if (ssStatus.dwCurrentState = SERVICE_RUNNING) or (ssStatus.dwCurrentState = SERVICE_STOPPED) then
      begin
         strDisplayName := ServiceDisplayName('VBoxUSB');
         if ((strDisplayName = 'VirtualBox USB') and isVBInstalledToo and FileExists(exeVBPathToo)) or (strDisplayName <> 'VirtualBox USB') then
         begin
            if ssStatus.dwCurrentState = SERVICE_RUNNING then
               ServiceStop('VBoxUSB');

            if Terminated then
               Exit;

            ssStatus := ServiceStatus('VBoxUSB');
            if (ssStatus.dwCurrentState = SERVICE_STOPPED) or (ssStatus.dwCurrentState = SERVICE_STOP_PENDING) then
               ServiceDelete('VBoxUSB');
         end;
      end;

      if Terminated then
         Exit;

      ssStatus := ServiceStatus('VBoxUSBMon');
      if (ssStatus.dwCurrentState = SERVICE_RUNNING) or (ssStatus.dwCurrentState = SERVICE_STOPPED) then
      begin
         strDisplayName := ServiceDisplayName('VBoxUSBMon');
         if ((strDisplayName = 'VirtualBox USB Monitor Driver') and isVBInstalledToo and FileExists(exeVBPathToo)) or ((strDisplayName <> 'VirtualBox USB Monitor Driver') and (strDisplayName <> 'PortableVBoxUSBMon')) then
         begin
            if ssStatus.dwCurrentState = SERVICE_RUNNING then
               ServiceStop('VBoxUSBMon');

            if Terminated then
               Exit;

            ssStatus := ServiceStatus('VBoxUSBMon');
            if (ssStatus.dwCurrentState = SERVICE_STOPPED) or (ssStatus.dwCurrentState = SERVICE_STOP_PENDING) then
               ServiceDelete('VBoxUSBMon');
         end;
      end;

      if Terminated then
         Exit;

      {$IFDEF WIN32}
      if TOSversion.Architecture = arIntelX64 then
      begin
         if CheckInstalledInf('sun_VBoxNetAdp') > 0 then
         begin
            exeDevConPath := ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs))) + 'data\tools\devcon_x64.exe';
            try
               strTemp := '"' + exeDevConPath + '" remove "sun_VBoxNetAdp"';
               UniqueString(strTemp);
               PexeDevCon := PChar(strTemp);
               PexeDevConPath := PChar(ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs))) + 'data\tools\');
               ResetLastError;
               try
                  resCP := CreateProcess(nil, PexeDevCon, nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, PexeDevConPath, eStartupInfo, eProcessInfo);
                  LastError := GetLastError;
               except
                  on E: Exception do
                  begin
                     resCP := False;
                     LastExceptionStr := E.Message;
                  end;
               end;
               if Terminated then
                  Exit;
               if resCP then
               begin
                  dt := GetTickCount;
                  while (GetTickCount - dt) <= 5000 do
                  begin
                     if WaitForInputIdle(eProcessInfo.hProcess, 50) <> WAIT_TIMEOUT then
                        Break;
                     if Terminated then
                        Exit;
                  end;
                  dt := GetTickCount;
                  while (GetTickCount - dt) <= 8000 do
                  begin
                     if WaitForSingleObject(eProcessInfo.hProcess, 50) <> WAIT_TIMEOUT then
                        Break;
                     if Terminated then
                        Exit;
                  end;
                  try
                     GetExitCodeProcess(eProcessInfo.hProcess, ExitCode);
                     if ExitCode = Still_Active then
                     begin
                        uExitCode := 0;
                        RemoteProcHandle := GetProcessHandleFromID(eProcessInfo.dwProcessId);
                        bDup := DuplicateHandle(GetCurrentProcess(), RemoteProcHandle, GetCurrentProcess(), @hProcessDup, PROCESS_ALL_ACCESS, False, 0);
                        if GetExitCodeProcess(hProcessDup, dwCode) then
                        begin
                           hKernel := GetModuleHandle('Kernel32');
                           FARPROC := GetProcAddress(hKernel, 'ExitProcess');
                           hRT := CreateRemoteThread(hProcessDup, nil, 0, Pointer(FARPROC), @uExitCode, 0, dwTID);
                           if hrt = 0 then
                              TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), eProcessInfo.dwProcessId), 0)
                           else
                              CloseHandle(hRT);
                        end
                        else
                           TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), eProcessInfo.dwProcessId), 0);
                        if (bDup) then
                           CloseHandle(hProcessDup);
                        GetExitCodeProcess(eProcessInfo.hProcess, ExitCode);
                     end;
                     CloseHandle(eProcessInfo.hProcess);
                     CloseHandle(eProcessInfo.hThread);
                  except
                  end;
               end;
            finally
            end;
         end;
      end
      else
         UninstallInf('sun_VBoxNetAdp');
      {$ENDIF}
      {$IFDEF WIN64}
      UninstallInf('sun_VBoxNetAdp');
      {$ENDIF}

      if Terminated then
         Exit;

      ssStatus := ServiceStatus('VBoxNetAdp');
      if ssStatus.dwCurrentState = SERVICE_RUNNING then
         ServiceStop('VBoxNetAdp');

      if Terminated then
         Exit;

      ssStatus := ServiceStatus('VBoxNetAdp');
      if (ssStatus.dwCurrentState = SERVICE_STOPPED) or (ssStatus.dwCurrentState = SERVICE_STOP_PENDING) then
         ServiceDelete('VBoxNetAdp');

      if Terminated then
         Exit;

      {$IFDEF WIN32}
      if TOSversion.Architecture = arIntelX64 then
         exeSnetCfgPath := ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs))) + 'data\tools\snetcfg_x64.exe'
      else
         exeSnetCfgPath := ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs))) + 'data\tools\snetcfg_x86.exe';
      {$ENDIF}
      {$IFDEF WIN64}
      exeSnetCfgPath := ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs))) + 'data\tools\snetcfg_x64.exe';
      {$ENDIF}
      ssStatus := ServiceStatus('VBoxNet' + strNetBrdg1);
    //  if (((TOSVersion.Major < 6) and (CheckInstalledInf(strNetBrdg2 + '_VBoxNet' + strNetBrdg1) > 0)) or ((TOSVersion.Major >= 6) and False)) or (ssStatus.dwCurrentState > 0) then
         try
            strTemp := '"' + exeSnetCfgPath + '" -u ' + strNetBrdg2 + '_VBoxNet' + strNetBrdg1;
            UniqueString(strTemp);
            PexeSnetCfg := PChar(strTemp);
            if ExtractFilePath(exeVBPathAbs) <> '' then
               PexeSnetCfgPath := PChar(ExtractFilePath(exeVBPathAbs))
            else
               PexeSnetCfgPath := nil;
            ResetLastError;
            try
               resCP := CreateProcess(nil, PexeSnetCfg, nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, PexeSnetCfgPath, eStartupInfo, eProcessInfo);
               LastError := GetLastError;
            except
               on E: Exception do
               begin
                  resCP := False;
                  LastExceptionStr := E.Message;
               end;
            end;
            if Terminated then
               Exit;
            if resCP then
            begin
               dt := GetTickCount;
               while (GetTickCount - dt) <= 5000 do
               begin
                  if WaitForInputIdle(eProcessInfo.hProcess, 50) <> WAIT_TIMEOUT then
                     Break;
                  if Terminated then
                     Exit;
               end;
               dt := GetTickCount;
               while (GetTickCount - dt) <= 10000 do
               begin
                  if WaitForSingleObject(eProcessInfo.hProcess, 50) <> WAIT_TIMEOUT then
                     Break;
                  if Terminated then
                     Exit;
               end;
               try
                  GetExitCodeProcess(eProcessInfo.hProcess, ExitCode);
                  if ExitCode = Still_Active then
                  begin
                     uExitCode := 0;
                     RemoteProcHandle := GetProcessHandleFromID(eProcessInfo.dwProcessId);
                     bDup := DuplicateHandle(GetCurrentProcess(), RemoteProcHandle, GetCurrentProcess(), @hProcessDup, PROCESS_ALL_ACCESS, False, 0);
                     if GetExitCodeProcess(hProcessDup, dwCode) then
                     begin
                        hKernel := GetModuleHandle('Kernel32');
                        FARPROC := GetProcAddress(hKernel, 'ExitProcess');
                        hRT := CreateRemoteThread(hProcessDup, nil, 0, Pointer(FARPROC), @uExitCode, 0, dwTID);
                        if hrt = 0 then
                           TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), eProcessInfo.dwProcessId), 0)
                        else
                           CloseHandle(hRT);
                     end
                     else
                        TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), eProcessInfo.dwProcessId), 0);
                     if (bDup) then
                        CloseHandle(hProcessDup);
                     GetExitCodeProcess(eProcessInfo.hProcess, ExitCode);
                  end;
                 { if (ExitCode <> Still_Active) and (ExitCode <> 0) then
                  begin
                     strTemp := GetLangTextFormatDef(idxMain, ['Messages', 'ErrorCode'], [IntToStr(ExitCode), 'snetcfg'], '%s error code from %s');
                     strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemUninstalling'], ['VBoxNet' + strNetBrdg1], 'problem uninstalling %s'#13#10#13#10'System message:') + strTemp;
                  end; }
                  CloseHandle(eProcessInfo.hProcess);
                  CloseHandle(eProcessInfo.hThread);
               except
               end;
            end
            else
            begin
             {  if not FileExists(exeSnetCfgPath) then
                  strTemp := 'file not found'
               else if LastError > 0 then
                  strTemp := SysErrorMessage(LastError)
               else if LastExceptionStr <> '' then
                  strTemp := LastExceptionStr;
               strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemStarting'], ['snetcfg'], 'problem starting %s'#13#10#13#10'System message:') + ' ' + strTemp;}
            end;
         finally
         end;

      if Terminated then
         Exit;

      if TOSVersion.Major < 6 then
         try
            if exeRegsvr32Path <> '' then
            begin
               strTemp := '"' + exeRegsvr32Path + '" /S /u "' + IncludeTrailingPathDelimiter(ExtractFilePath(exeRegSvr32Path)) + 'VBoxNetFltNobj.dll"';
               UniqueString(strTemp);
               PexeRegsvr32 := PChar(strTemp);
            end
            else
               PexeRegsvr32 := nil;
            if ExtractFilePath(exeRegsvr32Path) <> '' then
               PexeRegsvr32Path := PChar(ExtractFilePath(exeRegsvr32Path))
            else
               PexeRegsvr32Path := nil;
            ResetLastError;
            try
               resCP := CreateProcess(nil, PexeRegsvr32, nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, PexeRegsvr32Path, eStartupInfo, eProcessInfo);
               LastError := GetLastError;
            except
               on E: Exception do
               begin
                  resCP := False;
                  LastExceptionStr := E.Message;
               end;
            end;
            if Terminated then
               Exit;
            if resCP then
            begin
               dt := GetTickCount;
               while (GetTickCount - dt) <= 3000 do
               begin
                  if WaitForInputIdle(eProcessInfo.hProcess, 50) <> WAIT_TIMEOUT then
                     Break;
                  if Terminated then
                     Exit;
               end;
               dt := GetTickCount;
               while (GetTickCount - dt) <= 5000 do
               begin
                  if WaitForSingleObject(eProcessInfo.hProcess, 50) <> WAIT_TIMEOUT then
                     Break;
                  if Terminated then
                     Exit;
               end;
               try
                  GetExitCodeProcess(eProcessInfo.hProcess, ExitCode);
                  if ExitCode = Still_Active then
                  begin
                     uExitCode := 0;
                     RemoteProcHandle := GetProcessHandleFromID(eProcessInfo.dwProcessId);
                     bDup := DuplicateHandle(GetCurrentProcess(), RemoteProcHandle, GetCurrentProcess(), @hProcessDup, PROCESS_ALL_ACCESS, False, 0);
                     if GetExitCodeProcess(hProcessDup, dwCode) then
                     begin
                        hKernel := GetModuleHandle('Kernel32');
                        FARPROC := GetProcAddress(hKernel, 'ExitProcess');
                        hRT := CreateRemoteThread(hProcessDup, nil, 0, Pointer(FARPROC), @uExitCode, 0, dwTID);
                        if hrt = 0 then
                           TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), eProcessInfo.dwProcessId), 0)
                        else
                           CloseHandle(hRT);
                     end
                     else
                        TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), eProcessInfo.dwProcessId), 0);
                     if (bDup) then
                        CloseHandle(hProcessDup);
                     GetExitCodeProcess(eProcessInfo.hProcess, ExitCode);
                  end;
                  if (ExitCode <> Still_Active) and (ExitCode <> 0) then
                  begin
                     if not FileExists(IncludeTrailingPathDelimiter(ExtractFilePath(exeRegSvr32Path)) + 'VBoxNetFltNobj.dll') then
                        strTemp := 'file not found'
                     else
                        case ExitCode of
                           1: strTemp := GetLangTextDef(idxMain, ['Messages', 'InvArg'], 'Invalid argument');
                           2: strTemp := GetLangTextDef(idxMain, ['Messages', 'OleinitFld'], 'OleInitialize failed');
                           3: strTemp := GetLangTextDef(idxMain, ['Messages', 'LoadLibFld'], 'LoadLibrary failed');
                           4: strTemp := GetLangTextDef(idxMain, ['Messages', 'GetPrcAdFld'], 'GetProcAddress failed');
                           5: strTemp := GetLangTextDef(idxMain, ['Messages', 'DllRegUnregFld'], 'DllRegisterServer or DllUnregisterServer failed');
                        else
                           strTemp := '';
                        end;
                     strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemUnreg'], ['VBoxNetFltNobj.dll'], 'problem unregistering %s'#13#10#13#10'System message:') + ' ' + strTemp;
                  end;
                  CloseHandle(eProcessInfo.hProcess);
                  CloseHandle(eProcessInfo.hThread);
               except
               end;
            end
            else
            begin
               if not FileExists(exeRegSvr32Path) then
                  strTemp := 'file not found'
               else if LastError > 0 then
                  strTemp := SysErrorMessage(LastError)
               else if LastExceptionStr <> '' then
                  strTemp := LastExceptionStr;
               strRegErrMsg := strRegErrMsg + #13#10#13#10'problem starting regsvr32.exe'#13#10#13#10'System message: ' + strTemp;
            end;
         finally
         end;

      if Terminated then
         Exit;

      exeRegSvr32Path := ExtractFilePath(exeRegSvr32Path);
      if TOSVersion.Major < 6 then
      begin
         if FileExists(exeRegSvr32Path + 'VBoxNetFltNobj.dll') then
            RenameFile(exeRegSvr32Path + 'VBoxNetFltNobj.dll', exeRegSvr32Path + 'VBoxNetFltNobj.dll.ivbbak');
         CopyFile(PChar(IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathToo)) + 'drivers\network\netflt\VBoxNetFltNobj.dll'), PChar(exeRegSvr32Path + 'VBoxNetFltNobj.dll'), False);
      end;
      if FileExists(drvSysPath + 'VBoxNet' + strNetBrdg1 + '.sys') then
         RenameFile(drvSysPath + 'VBoxNet' + strNetBrdg1 + '.sys', drvSysPath + 'VBoxNet' + strNetBrdg1 + '.sys.ivbbak');
      CopyFile(PChar(IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathToo)) + 'drivers\network\net' + strNetBrdg1 + '\VBoxNet' + strNetBrdg1 + '.sys'), PChar(drvSysPath + 'VBoxNet' + strNetBrdg1 + '.sys'), False);

      if Terminated then
         Exit;

      ssStatus := ServiceStatus('VBoxNet' + strNetBrdg1);
      if ssStatus.dwCurrentState = SERVICE_RUNNING then
         ServiceStop('VBoxNet' + strNetBrdg1);

      if Terminated then
         Exit;

      ssStatus := ServiceStatus('VBoxNet' + strNetBrdg1);
      if (ssStatus.dwCurrentState = SERVICE_STOPPED) or (ssStatus.dwCurrentState = SERVICE_STOP_PENDING) then
         ServiceDelete('VBoxNet' + strNetBrdg1);

      if Terminated then
         Exit;

      ssStatus := ServiceStatus;
      if (ssStatus.dwCurrentState = SERVICE_RUNNING) or (ssStatus.dwCurrentState = SERVICE_STOPPED) then
      begin
         strDisplayName := ServiceDisplayName;
         if ((strDisplayName = 'VirtualBox Service') and isVBInstalledToo and FileExists(exeVBPathToo)) or ((strDisplayName <> 'VirtualBox Service') and (strDisplayName <> 'PortableVBoxDRV')) then
         begin
            if ssStatus.dwCurrentState = SERVICE_RUNNING then
               ServiceStop;

            if Terminated then
               Exit;

            ssStatus := ServiceStatus;
            if (ssStatus.dwCurrentState = SERVICE_STOPPED) or (ssStatus.dwCurrentState = SERVICE_STOP_PENDING) then
               ServiceDelete;
         end;
      end;

      if Terminated then
         Exit;

      dllPath := IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs));

      strRegErrMsg := '';
      Result := True;

      New(wfa);
      try
         hFind := FindFirstFile(PChar(dllPath + 'msvc*.dll'), wfa^);
         LastError := GetLastError;
      except
         on E: Exception do
         begin
            hFind := INVALID_HANDLE_VALUE;
            LastExceptionStr := E.Message;
         end;
      end;
      if hFind <> INVALID_HANDLE_VALUE then
      begin
         repeat
            if wfa.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY = 0 then
            begin
               if not FileExists(exeRegSvr32Path + wfa.cFileName) then
                  CopyFile(PChar(dllPath + wfa.cFileName), PChar(exeRegSvr32Path + wfa.cFileName), False)
               else
               begin
                  RenameFile(exeRegSvr32Path + wfa.cFileName, exeRegSvr32Path + wfa.cFileName + '.pvbbak');
                  CopyFile(PChar(dllPath + wfa.cFileName), PChar(exeRegSvr32Path + wfa.cFileName), False)
               end;
            end;
            if Terminated then
               Exit;
         until not Windows.FindNextFile(hFind, wfa^);
         Windows.FindClose(hFind);
      end;

      if Terminated then
         Exit;

      exeVboxSvcPath := IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + 'VBoxSvc.exe';

      try
         if exeVboxSvcPath <> '' then
         begin
            strTemp := '"' + exeVboxSvcPath + '" /reregserver';
            UniqueString(strTemp);
            PexeVboxSvc := PChar(strTemp);
         end
         else
            PexeVboxSvc := nil;
         if ExtractFilePath(exeVboxSvcPath) <> '' then
            PexeVboxSvcPath := PChar(ExtractFilePath(exeVboxSvcPath))
         else
            PexeVboxSvcPath := nil;
         resCP := True;
         try
            resCP := CreateProcess(nil, PexeVboxSvc, nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, PexeVboxSvcPath, eStartupInfo, eProcessInfo);
            LastError := GetLastError;
         except
            on E: Exception do
            begin
               resCP := False;
               LastExceptionStr := E.Message;
            end;
         end;
         if Terminated then
            Exit;
         if resCP then
         begin
            dt := GetTickCount;
            while (GetTickCount - dt) <= 3000 do
            begin
               if WaitForInputIdle(eProcessInfo.hProcess, 50) <> WAIT_TIMEOUT then
                  Break;
               if Terminated then
                  Exit;
            end;
            dt := GetTickCount;
            while (GetTickCount - dt) <= 5000 do
            begin
               if WaitForSingleObject(eProcessInfo.hProcess, 50) <> WAIT_TIMEOUT then
                  Break;
               if Terminated then
                  Exit;
            end;
            try
               GetExitCodeProcess(eProcessInfo.hProcess, ExitCode);
               if ExitCode = Still_Active then
               begin
                  uExitCode := 0;
                  RemoteProcHandle := GetProcessHandleFromID(eProcessInfo.dwProcessId);
                  bDup := DuplicateHandle(GetCurrentProcess(), RemoteProcHandle, GetCurrentProcess(), @hProcessDup, PROCESS_ALL_ACCESS, False, 0);
                  if GetExitCodeProcess(hProcessDup, dwCode) then
                  begin
                     hKernel := GetModuleHandle('Kernel32');
                     FARPROC := GetProcAddress(hKernel, 'ExitProcess');
                     hRT := CreateRemoteThread(hProcessDup, nil, 0, Pointer(FARPROC), @uExitCode, 0, dwTID);
                     if hrt = 0 then
                        TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), eProcessInfo.dwProcessId), 0)
                     else
                        CloseHandle(hRT);
                  end
                  else
                     TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), eProcessInfo.dwProcessId), 0);
                  if (bDup) then
                     CloseHandle(hProcessDup);
               end;
               CloseHandle(eProcessInfo.hProcess);
               CloseHandle(eProcessInfo.hThread);
            except
            end;
         end
         else
         begin
            if not FileExists(exeVboxSvcPath) then
               strTemp := 'file not found'
            else if LastError > 0 then
               strTemp := SysErrorMessage(LastError)
            else if LastExceptionStr <> '' then
               strTemp := LastExceptionStr;
            strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemReg'], ['VBoxSVC.exe'], 'problem registering %s'#13#10#13#10'System message:') + ' ' + strTemp;
            Result := Result and resCP;
         end;
      finally
      end;

      if Terminated then
         Exit;

      exeRegsvr32Path := exeRegsvr32Path + 'regsvr32.exe';

      try
         if exeRegsvr32Path <> '' then
         begin
            strTemp := '"' + exeRegsvr32Path + '" /S "' + IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + 'VBoxC.dll"';
            UniqueString(strTemp);
            PexeRegsvr32 := PChar(strTemp);
         end
         else
            PexeRegsvr32 := nil;
         if ExtractFilePath(exeRegsvr32Path) <> '' then
            PexeRegsvr32Path := PChar(ExtractFilePath(exeRegsvr32Path))
         else
            PexeRegsvr32Path := nil;
         ResetLastError;
         try
            resCP := CreateProcess(nil, PexeRegsvr32, nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, PexeRegsvr32Path, eStartupInfo, eProcessInfo);
            LastError := GetLastError;
         except
            on E: Exception do
            begin
               Result := Result and False;
               LastExceptionStr := E.Message;
            end;
         end;
         if Terminated then
            Exit;
         if resCP then
         begin
            dt := GetTickCount;
            while (GetTickCount - dt) <= 3000 do
            begin
               if WaitForInputIdle(eProcessInfo.hProcess, 50) <> WAIT_TIMEOUT then
                  Break;
               if Terminated then
                  Exit;
            end;
            dt := GetTickCount;
            while (GetTickCount - dt) <= 5000 do
            begin
               if WaitForSingleObject(eProcessInfo.hProcess, 50) <> WAIT_TIMEOUT then
                  Break;
               if Terminated then
                  Exit;
            end;
            try
               GetExitCodeProcess(eProcessInfo.hProcess, ExitCode);
               if ExitCode = Still_Active then
               begin
                  uExitCode := 0;
                  RemoteProcHandle := GetProcessHandleFromID(eProcessInfo.dwProcessId);
                  bDup := DuplicateHandle(GetCurrentProcess(), RemoteProcHandle, GetCurrentProcess(), @hProcessDup, PROCESS_ALL_ACCESS, False, 0);
                  if GetExitCodeProcess(hProcessDup, dwCode) then
                  begin
                     hKernel := GetModuleHandle('Kernel32');
                     FARPROC := GetProcAddress(hKernel, 'ExitProcess');
                     hRT := CreateRemoteThread(hProcessDup, nil, 0, Pointer(FARPROC), @uExitCode, 0, dwTID);
                     if hrt = 0 then
                        TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), eProcessInfo.dwProcessId), 0)
                     else
                        CloseHandle(hRT);
                  end
                  else
                     TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), eProcessInfo.dwProcessId), 0);
                  if (bDup) then
                     CloseHandle(hProcessDup);
                  GetExitCodeProcess(eProcessInfo.hProcess, ExitCode);
               end;
               if (ExitCode <> Still_Active) and (ExitCode <> 0) then
               begin
                  if not FileExists(IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + 'VBoxC.dll') then
                     strTemp := 'dll file not found'
                  else
                     case ExitCode of
                        1: strTemp := GetLangTextDef(idxMain, ['Messages', 'InvArg'], 'Invalid argument');
                        2: strTemp := GetLangTextDef(idxMain, ['Messages', 'OleinitFld'], 'OleInitialize failed');
                        3: strTemp := GetLangTextDef(idxMain, ['Messages', 'LoadLibFld'], 'LoadLibrary failed');
                        4: strTemp := GetLangTextDef(idxMain, ['Messages', 'GetPrcAdFld'], 'GetProcAddress failed');
                        5: strTemp := GetLangTextDef(idxMain, ['Messages', 'DllRegUnregFld'], 'DllRegisterServer or DllUnregisterServer failed');
                     else
                        strTemp := '';
                     end;
                  strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemReg'], ['VBoxC.dll'], 'problem registering %s'#13#10#13#10'System message:') + ' ' + strTemp;
                  Result := Result and False;
               end;
               CloseHandle(eProcessInfo.hProcess);
               CloseHandle(eProcessInfo.hThread);
            except
            end;
         end
         else
         begin
            if not FileExists(exeRegsvr32Path) then
               strTemp := 'file not found'
            else if LastError > 0 then
               strTemp := SysErrorMessage(LastError)
            else if LastExceptionStr <> '' then
               strTemp := LastExceptionStr;
            strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemStarting'], ['devcon'], 'problem starting %s'#13#10#13#10'System message:') + ' ' + strTemp;
            Result := Result and False;
         end;
      finally
      end;

      if Terminated then
         Exit;

      vLibHandle := LoadLibrary(PChar(IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + 'VBoxRT.dll'));
      resCP := True;
      if vLibHandle <> 0 then
      begin
         ResetLastError;
         @InitFunc := GetProcAddress(vLibHandle, 'RTR3InitDll');
         if @InitFunc = nil then
            @InitFunc := GetProcAddress(vLibHandle, 'RTR3Init');
         if @InitFunc <> nil then
            try
               InitFunc;
               LastError := GetLastError;
               resCP := LastError = 0;
            except
               on E: Exception do
               begin
                  resCP := False;
                  LastExceptionStr := E.Message;
               end;
            end;
         if not resCP then
         begin
            if LastError > 0 then
               strTemp := SysErrorMessage(LastError)
            else if LastExceptionStr <> '' then
               strTemp := LastExceptionStr
            else if @InitFunc = nil then
               strTemp := 'function not found';
            strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemFcntDll'], ['RTR3InitDll', 'VBoxRT.dll'], 'problem starting %s function from %s'#13#10#13#10'System message:') + ' ' + strTemp;
         end;
      end;

      if Terminated then
         Exit;

      if not resCp then
      begin
         SetLength(exeRundll32Path, StrLen(Buffer));
         exeRundll32Path := IncludeTrailingPathDelimiter(Buffer);
         exeRundll32Path := exeRundll32Path + 'rundll32.exe';
         try
            if exeRundll32Path <> '' then
            begin
               strTemp := '"' + exeRundll32Path + '" "' + IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + 'VBoxRT.dll,RTR3InitDll"';
               UniqueString(strTemp);
               PexeRundll32 := PChar(strTemp);
            end
            else
               PexeRundll32 := nil;
            if ExtractFilePath(exeRundll32Path) <> '' then
               PexeRundll32Path := PChar(ExtractFilePath(exeRundll32Path))
            else
               PexeRundll32Path := nil;
            ResetLastError;
            try
               resCP := CreateProcess(nil, PexeRundll32, nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, PexeRundll32Path, eStartupInfo, eProcessInfo);
               LastError := GetLastError;
            except
               on E: Exception do
               begin
                  Result := Result and False;
                  LastExceptionStr := E.Message;
               end;
            end;
            if Terminated then
               Exit;
            if resCP then
            begin
               dt := GetTickCount;
               while (GetTickCount - dt) <= 3000 do
               begin
                  if WaitForInputIdle(eProcessInfo.hProcess, 50) <> WAIT_TIMEOUT then
                     Break;
                  if Terminated then
                     Exit;
               end;
               dt := GetTickCount;
               while (GetTickCount - dt) <= 5000 do
               begin
                  if WaitForSingleObject(eProcessInfo.hProcess, 50) <> WAIT_TIMEOUT then
                     Break;
                  if Terminated then
                     Exit;
               end;
               try
                  GetExitCodeProcess(eProcessInfo.hProcess, ExitCode);
                  if ExitCode = Still_Active then
                  begin
                     uExitCode := 0;
                     RemoteProcHandle := GetProcessHandleFromID(eProcessInfo.dwProcessId);
                     bDup := DuplicateHandle(GetCurrentProcess(), RemoteProcHandle, GetCurrentProcess(), @hProcessDup, PROCESS_ALL_ACCESS, False, 0);
                     if GetExitCodeProcess(hProcessDup, dwCode) then
                     begin
                        hKernel := GetModuleHandle('Kernel32');
                        FARPROC := GetProcAddress(hKernel, 'ExitProcess');
                        hRT := CreateRemoteThread(hProcessDup, nil, 0, Pointer(FARPROC), @uExitCode, 0, dwTID);
                        if hrt = 0 then
                           TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), eProcessInfo.dwProcessId), 0)
                        else
                           CloseHandle(hRT);
                     end
                     else
                        TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), eProcessInfo.dwProcessId), 0);
                     if (bDup) then
                        CloseHandle(hProcessDup);
                     GetExitCodeProcess(eProcessInfo.hProcess, ExitCode);
                  end;
                  if (ExitCode <> Still_Active) and (ExitCode <> 0) then
                  begin
                     if not FileExists(IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + 'VBoxRT.dll') then
                        strTemp := 'file not found'
                     else
                        case ExitCode of
                           1: strTemp := GetLangTextDef(idxMain, ['Messages', 'InvArg'], 'Invalid argument');
                           2: strTemp := GetLangTextDef(idxMain, ['Messages', 'OleinitFld'], 'OleInitialize failed');
                           3: strTemp := GetLangTextDef(idxMain, ['Messages', 'LoadLibFld'], 'LoadLibrary failed');
                           4: strTemp := GetLangTextDef(idxMain, ['Messages', 'GetPrcAdFld'], 'GetProcAddress failed');
                           5: strTemp := GetLangTextDef(idxMain, ['Messages', 'DllRegUnregFld'], 'DllRegisterServer or DllUnregisterServer failed');
                        else
                           strTemp := '';
                        end;
                     strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemFcntDll'], ['RTR3InitDll', 'VBoxRT.dll'], 'problem starting %s function from %s'#13#10#13#10'System message:') + ' ' + strTemp;
                     Result := Result and False;
                  end;
                  CloseHandle(eProcessInfo.hProcess);
                  CloseHandle(eProcessInfo.hThread);
               except
               end;
            end
            else
            begin
               if not FileExists(exeRundll32Path) then
                  strTemp := 'file not found'
               else if LastError > 0 then
                  strTemp := SysErrorMessage(LastError)
               else if LastExceptionStr <> '' then
                  strTemp := LastExceptionStr;
               strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemStarting'], ['rundll32.exe'], 'problem starting %s'#13#10#13#10'System message:') + ' ' + strTemp;
               Result := Result and False;
            end;
         finally
         end;
      end;

      if Terminated then
         Exit;

      ssStatus := ServiceStatus;
      if ssStatus.dwCurrentState = 0 then
      begin
         if not ServiceCreate(IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + 'drivers\VBoxDrv\VBoxDrv.sys') then
         begin
            Result := Result and False;
            if LastError > 0 then
               strTemp := SysErrorMessage(LastError)
            else if LastExceptionStr <> '' then
               strTemp := LastExceptionStr;
            strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemCreateSrv'], ['VBoxDRV'], 'problem creating %s service'#13#10#13#10'System message:') + ' ' + strTemp;
         end;
      end;

      if Terminated then
         Exit;

      ssStatus := ServiceStatus;
      if (ssStatus.dwCurrentState = SERVICE_STOPPED) or (ssStatus.dwCurrentState = SERVICE_STOP_PENDING) then
      begin
         if not ServiceStart then
         begin
            Result := Result and False;
            if LastError > 0 then
               strTemp := SysErrorMessage(LastError)
            else if LastExceptionStr <> '' then
               strTemp := LastExceptionStr;
            strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemStartSrv'], ['VBoxDRV'], 'problem starting %s service'#13#10#13#10'System message:') + ' ' + strTemp;
         end;
      end;

      if Terminated then
         Exit;

      if LoadUSBPortable then
      begin
         ssStatus := ServiceStatus('VBoxUSBMon');
         if ssStatus.dwCurrentState = 0 then
         begin
            ResetLastError;
            if not ServiceCreate(IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + 'drivers\USB\filter\VBoxUSBMon.sys', 'VBoxUSBMon') then
            begin
               Result := Result and False;
               if LastError > 0 then
                  strTemp := SysErrorMessage(LastError)
               else if LastExceptionStr <> '' then
                  strTemp := LastExceptionStr;
               strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemCreateSrv'], ['VBoxUSBMon'], 'problem creating %s service'#13#10#13#10'System message:') + ' ' + strTemp;
            end;
         end;

         if Terminated then
            Exit;

         ssStatus := ServiceStatus('VBoxUSBMon');
         if (ssStatus.dwCurrentState = SERVICE_STOPPED) or (ssStatus.dwCurrentState = SERVICE_STOP_PENDING) then
         begin
            ResetLastError;
            if not ServiceStart('VBoxUSBMon') then
            begin
               Result := Result and False;
               if LastError > 0 then
                  strTemp := SysErrorMessage(LastError)
               else if LastExceptionStr <> '' then
                  strTemp := LastExceptionStr;
               strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemStartSrv'], ['VBoxUSBMon'], 'problem starting %s service'#13#10#13#10'System message:') + ' ' + strTemp;
            end;
         end;

         if Terminated then
            Exit;

         if CheckInstalledInf('USB\VID_80EE&PID_CAFE') < 1 then
         begin
            {$IFDEF WIN32}
            if TOSversion.Architecture = arIntelX64 then
            begin
               exeDevConPath := ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs))) + 'data\tools\devcon_x64.exe';
               try
                  strTemp := '"' + exeDevConPath + '" install "' + IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + 'drivers\USB\device\VBoxUSB.inf" "USB\VID_80EE&PID_CAFE"';
                  UniqueString(strTemp);
                  PexeDevCon := PChar(strTemp);
                  PexeDevConPath := PChar(ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs))) + 'data\tools\');
                  ResetLastError;
                  try
                     resCP := CreateProcess(nil, PexeDevCon, nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, PexeDevConPath, eStartupInfo, eProcessInfo);
                     LastError := GetLastError;
                  except
                     on E: Exception do
                     begin
                        Result := Result and False;
                        LastExceptionStr := E.Message;
                     end;
                  end;
                  if Terminated then
                     Exit;
                  if resCP then
                  begin
                     dt := GetTickCount;
                     while (GetTickCount - dt) <= 5000 do
                     begin
                        if WaitForInputIdle(eProcessInfo.hProcess, 50) <> WAIT_TIMEOUT then
                           Break;
                        if Terminated then
                           Exit;
                     end;
                     dt := GetTickCount;
                     while (GetTickCount - dt) <= 8000 do
                     begin
                        if WaitForSingleObject(eProcessInfo.hProcess, 50) <> WAIT_TIMEOUT then
                           Break;
                        if Terminated then
                           Exit;
                     end;
                     try
                        GetExitCodeProcess(eProcessInfo.hProcess, ExitCode);
                        if ExitCode = Still_Active then
                        begin
                           uExitCode := 0;
                           RemoteProcHandle := GetProcessHandleFromID(eProcessInfo.dwProcessId);
                           bDup := DuplicateHandle(GetCurrentProcess(), RemoteProcHandle, GetCurrentProcess(), @hProcessDup, PROCESS_ALL_ACCESS, False, 0);
                           if GetExitCodeProcess(hProcessDup, dwCode) then
                           begin
                              hKernel := GetModuleHandle('Kernel32');
                              FARPROC := GetProcAddress(hKernel, 'ExitProcess');
                              hRT := CreateRemoteThread(hProcessDup, nil, 0, Pointer(FARPROC), @uExitCode, 0, dwTID);
                              if hrt = 0 then
                                 TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), eProcessInfo.dwProcessId), 0)
                              else
                                 CloseHandle(hRT);
                           end
                           else
                              TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), eProcessInfo.dwProcessId), 0);
                           if (bDup) then
                              CloseHandle(hProcessDup);
                           GetExitCodeProcess(eProcessInfo.hProcess, ExitCode);
                        end;
                        if (ExitCode <> Still_Active) and (ExitCode <> 0) then
                        begin
                           if not FileExists(IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + 'drivers\USB\device\VBoxUSB.inf') then
                              strTemp := 'file not found'
                           else
                              strTemp := GetLangTextFormatDef(idxMain, ['Messages', 'ErrorCode'], [IntToStr(ExitCode), 'devcon'], '%s error code from %s');
                           strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemInstalling'], ['VBoxUSB.inf'], 'problem installing %s'#13#10#13#10'System message:') + ' ' + strTemp;
                           Result := Result and False;
                        end;
                        CloseHandle(eProcessInfo.hProcess);
                        CloseHandle(eProcessInfo.hThread);
                     except
                     end;
                  end
                  else
                  begin
                     if not FileExists(exeDevConPath) then
                        strTemp := 'file not found'
                     else if LastError > 0 then
                        strTemp := SysErrorMessage(LastError)
                     else if LastExceptionStr <> '' then
                        strTemp := LastExceptionStr;
                     strRegErrMsg := strRegErrMsg + #13#10#13#10'problem starting devcon'#13#10#13#10'System message: ' + strTemp;
                     Result := Result and False;
                  end;
               finally
               end;
            end
            else if InstallInf(IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + 'drivers\USB\device\VBoxUSB.inf', 'USB\VID_80EE&PID_CAFE') < 1 then
            begin
               Result := Result and False;
               if LastError > 0 then
                  strTemp := SysErrorMessage(LastError)
               else if LastExceptionStr <> '' then
                  strTemp := LastExceptionStr;
               strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemInstalling'], ['VBoxUSB.inf'], 'problem installing %s'#13#10#13#10'System message:') + ' ' + strTemp;
            end;
            {$ENDIF}
            {$IFDEF WIN64}
            if InstallInf(IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + 'drivers\USB\device\VBoxUSB.inf', 'USB\VID_80EE&PID_CAFE') < 1 then
            begin
               Result := Result and False;
               if LastError > 0 then
                  strTemp := SysErrorMessage(LastError)
               else if LastExceptionStr <> '' then
                  strTemp := LastExceptionStr;
               strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemInstalling'], ['VBoxUSB.inf'], 'problem installing %s'#13#10#13#10'System message:') + ' ' + strTemp;
            end;
            {$ENDIF}
         end;

         if Terminated then
            Exit;

         if DirectoryExists(drvSysPath) then
         begin
            if FileExists(drvSysPath + 'VBoxUSB.sys') then
               RenameFile(drvSysPath + 'VBoxUSB.sys', drvSysPath + 'VBoxUSB.sys.pvbbak');
            CopyFile(PChar(IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + 'drivers\USB\filter\VBoxUSBMon.sys'), PChar(drvSysPath + 'VBoxUSB.sys'), False);
         end;

         if Terminated then
            Exit;

         ssStatus := ServiceStatus('VBoxUSB');
         if (ssStatus.dwCurrentState = SERVICE_STOPPED) or (ssStatus.dwCurrentState = SERVICE_STOP_PENDING) then
         begin
            i := 0;
            while True do
            begin
               mEvent.WaitFor(500);
               resCP := ServiceStart('VBoxUSB');
               if Terminated then
                  Exit;
               if resCP then
                  Break;
               if (i >= 6) and (not resCP) then
               begin
                  if LastError > 0 then
                     strTemp := SysErrorMessage(LastError)
                  else if LastExceptionStr <> '' then
                     strTemp := LastExceptionStr;
                  strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemStartSrv'], ['VBoxUSB'], 'problem starting %s service'#13#10#13#10'System message:') + ' ' + strTemp;
                  Result := Result and False;
                  Break;
               end;
               Inc(i);
            end;
         end;

         if Terminated then
            Exit;
      end;

      if Terminated then
         Exit;

      if LoadNetPortable then
      begin
         drvSysPath := IncludeTrailingPathDelimiter(string(Buffer)) + '\Drivers\';
         if DirectoryExists(drvSysPath) then
         begin
            if FileExists(drvSysPath + 'VBoxNetAdp' + strNetAdp + '.sys') then
               RenameFile(drvSysPath + 'VBoxNetAdp' + strNetAdp + '.sys', drvSysPath + 'VBoxNetAdp' + strNetAdp + '.sys.pvbbak');
            CopyFile(PChar(IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + 'drivers\network\netadp' + strNetAdp + '\VBoxNetAdp' + strNetAdp + '.sys'), PChar(drvSysPath + 'VBoxNetAdp' + strNetAdp + '.sys'), False);
         end;

         if Terminated then
            Exit;

         if CheckInstalledInf('sun_VBoxNetAdp') < 1 then
         begin
            {$IFDEF WIN32}
            if TOSversion.Architecture = arIntelX64 then
            begin
               exeDevConPath := ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs))) + 'data\tools\devcon_x64.exe';
               try
                  strTemp := '"' + exeDevConPath + '" install "' + IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + 'drivers\network\netadp' + strNetAdp + '\VBoxNetAdp' + strNetAdp + '.inf" "sun_VBoxNetAdp"';
                  UniqueString(strTemp);
                  PexeDevCon := PChar(strTemp);
                  PexeDevConPath := PChar(ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs))) + 'data\tools\');
                  ResetLastError;
                  try
                     resCP := CreateProcess(nil, PexeDevCon, nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, PexeDevConPath, eStartupInfo, eProcessInfo);
                     LastError := GetLastError;
                  except
                     on E: Exception do
                     begin
                        Result := Result and False;
                        LastExceptionStr := E.Message;
                     end;
                  end;
                  if Terminated then
                     Exit;
                  if resCP then
                  begin
                     dt := GetTickCount;
                     while (GetTickCount - dt) <= 5000 do
                     begin
                        if WaitForInputIdle(eProcessInfo.hProcess, 50) <> WAIT_TIMEOUT then
                           Break;
                        if Terminated then
                           Exit;
                     end;
                     dt := GetTickCount;
                     while (GetTickCount - dt) <= 8000 do
                     begin
                        if WaitForSingleObject(eProcessInfo.hProcess, 50) <> WAIT_TIMEOUT then
                           Break;
                        if Terminated then
                           Exit;
                     end;
                     try
                        GetExitCodeProcess(eProcessInfo.hProcess, ExitCode);
                        if ExitCode = Still_Active then
                        begin
                           uExitCode := 0;
                           RemoteProcHandle := GetProcessHandleFromID(eProcessInfo.dwProcessId);
                           bDup := DuplicateHandle(GetCurrentProcess(), RemoteProcHandle, GetCurrentProcess(), @hProcessDup, PROCESS_ALL_ACCESS, False, 0);
                           if GetExitCodeProcess(hProcessDup, dwCode) then
                           begin
                              hKernel := GetModuleHandle('Kernel32');
                              FARPROC := GetProcAddress(hKernel, 'ExitProcess');
                              hRT := CreateRemoteThread(hProcessDup, nil, 0, Pointer(FARPROC), @uExitCode, 0, dwTID);
                              if hrt = 0 then
                                 TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), eProcessInfo.dwProcessId), 0)
                              else
                                 CloseHandle(hRT);
                           end
                           else
                              TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), eProcessInfo.dwProcessId), 0);
                           if (bDup) then
                              CloseHandle(hProcessDup);
                           GetExitCodeProcess(eProcessInfo.hProcess, ExitCode);
                        end;
                        if (ExitCode <> Still_Active) and (ExitCode <> 0) then
                        begin
                           if not FileExists(IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + 'drivers\network\netadp' + strNetAdp + '\VBoxNetAdp' + strNetAdp + '.inf') then
                              strTemp := 'file not found'
                           else
                              strTemp := GetLangTextFormatDef(idxMain, ['Messages', 'ErrorCode'], [IntToStr(ExitCode), 'devcon'], '%s error code from %s');
                           strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemInstalling'], ['VBoxNetAdp' + strNetAdp + '.inf'], 'problem installing %s'#13#10#13#10'System message:') + ' ' + strTemp;
                           Result := Result and False;
                        end;
                        CloseHandle(eProcessInfo.hProcess);
                        CloseHandle(eProcessInfo.hThread);
                     except
                     end;
                  end
                  else
                  begin
                     if not FileExists(exeDevConPath) then
                        strTemp := 'file not found'
                     else if LastError > 0 then
                        strTemp := SysErrorMessage(LastError)
                     else if LastExceptionStr <> '' then
                        strTemp := LastExceptionStr;
                     strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemStarting'], ['devcon'], 'problem starting %s'#13#10#13#10'System message:') + ' ' + strTemp;
                     Result := Result and False;
                  end;
               finally
               end;
            end
            else if InstallInf(IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + 'drivers\network\netadp' + strNetAdp + '\VBoxNetAdp' + strNetAdp + '.inf', 'sun_VBoxNetAdp') < 1 then
            begin
               Result := Result and False;
               if LastError > 0 then
                  strTemp := SysErrorMessage(LastError)
               else if LastExceptionStr <> '' then
                  strTemp := LastExceptionStr;
               strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemInstalling'], ['VBoxNetAdp' + strNetAdp], 'problem installing %s'#13#10#13#10'System message:') + ' ' + strTemp;
            end;
            {$ENDIF}
            {$IFDEF WIN64}
            if InstallInf(IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + 'drivers\network\netadp' + strNetAdp + '\VBoxNetAdp' + strNetAdp + '.inf', 'sun_VBoxNetAdp') < 1 then
            begin
               Result := Result and False;
               if LastError > 0 then
                  strTemp := SysErrorMessage(LastError)
               else if LastExceptionStr <> '' then
                  strTemp := LastExceptionStr;
               strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemInstalling'], ['VBoxNetAdp' + strNetAdp], 'problem installing %s'#13#10#13#10'System message:') + ' ' + strTemp;
            end;
            {$ENDIF}
         end;

         if Terminated then
            Exit;

         ssStatus := ServiceStatus('VBoxNetAdp');
         if (ssStatus.dwCurrentState = SERVICE_STOPPED) or (ssStatus.dwCurrentState = SERVICE_STOP_PENDING) then
         begin
            i := 0;
            while True do
            begin
               mEvent.WaitFor(500);
               resCP := ServiceStart('VBoxNetAdp');
               if resCP then
                  Break;
               if Terminated then
                  Exit;
               if (i >= 6) and (not resCP) then
               begin
                  if LastError > 0 then
                     strTemp := SysErrorMessage(LastError)
                  else if LastExceptionStr <> '' then
                     strTemp := LastExceptionStr;
                  strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemStartSrv'], ['VBoxNetAdp'], 'problem starting %s service'#13#10#13#10'System message:') + ' ' + strTemp;
                  Result := Result and False;
                  Break;
               end;
               Inc(i);
            end;
         end;

         if Terminated then
            Exit;

         curDir := GetCurrentDir();
         SetCurrentDir(ExtractFilePath(exeVBPathAbs));
         {$IFDEF WIN32}
         if TOSversion.Architecture = arIntelX64 then
            exeSnetCfgPath := ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs))) + 'data\tools\snetcfg_x64.exe'
         else
            exeSnetCfgPath := ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs))) + 'data\tools\snetcfg_x86.exe';
         {$ENDIF}
         {$IFDEF WIN64}
         exeSnetCfgPath := ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs))) + 'data\tools\snetcfg_x64.exe';
         {$ENDIF}
         ssStatus := ServiceStatus('VBoxNet' + strNetBrdg1);
         if (((TOSVersion.Major < 6) and (CheckInstalledInf(strNetBrdg2 + '_VBoxNet' + strNetBrdg1) < 1)) or ((TOSVersion.Major >= 6) and False)) or (ssStatus.dwCurrentState = 0) then
            try
               strTemp := '"' + exeSnetCfgPath + '" -v -l "drivers\network\net' + strNetBrdg1 + '\VBoxNet' + strNetBrdg1 + '.inf" -m "drivers\network\net' + strNetBrdg1 + '\VBoxNet' + strNetBrdg1 + strNetBrdg3 + '.inf" -c s -i ' + strNetBrdg2 + '_VBoxNet' + strNetBrdg1;
               UniqueString(strTemp);
               PexeSnetCfg := PChar(strTemp);
               if ExtractFilePath(exeVBPathAbs) <> '' then
                  PexeSnetCfgPath := PChar(ExtractFilePath(exeVBPathAbs))
               else
                  PexeSnetCfgPath := nil;
               ResetLastError;
               try
                  resCP := CreateProcess(nil, PexeSnetCfg, nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, PexeSnetCfgPath, eStartupInfo, eProcessInfo);
                  LastError := GetLastError;
               except
                  on E: Exception do
                  begin
                     Result := Result and False;
                     LastExceptionStr := E.Message;
                  end;
               end;
               if Terminated then
                  Exit;
               if resCP then
               begin
                  dt := GetTickCount;
                  while (GetTickCount - dt) <= 5000 do
                  begin
                     if WaitForInputIdle(eProcessInfo.hProcess, 50) <> WAIT_TIMEOUT then
                        Break;
                     if Terminated then
                        Exit;
                  end;
                  dt := GetTickCount;
                  while (GetTickCount - dt) <= 10000 do
                  begin
                     if WaitForSingleObject(eProcessInfo.hProcess, 50) <> WAIT_TIMEOUT then
                        Break;
                     if Terminated then
                        Exit;
                  end;
                  try
                     GetExitCodeProcess(eProcessInfo.hProcess, ExitCode);
                     if ExitCode = Still_Active then
                     begin
                        uExitCode := 0;
                        RemoteProcHandle := GetProcessHandleFromID(eProcessInfo.dwProcessId);
                        bDup := DuplicateHandle(GetCurrentProcess(), RemoteProcHandle, GetCurrentProcess(), @hProcessDup, PROCESS_ALL_ACCESS, False, 0);
                        if GetExitCodeProcess(hProcessDup, dwCode) then
                        begin
                           hKernel := GetModuleHandle('Kernel32');
                           FARPROC := GetProcAddress(hKernel, 'ExitProcess');
                           hRT := CreateRemoteThread(hProcessDup, nil, 0, Pointer(FARPROC), @uExitCode, 0, dwTID);
                           if hrt = 0 then
                              TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), eProcessInfo.dwProcessId), 0)
                           else
                              CloseHandle(hRT);
                        end
                        else
                           TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), eProcessInfo.dwProcessId), 0);
                        if (bDup) then
                           CloseHandle(hProcessDup);
                        GetExitCodeProcess(eProcessInfo.hProcess, ExitCode);
                     end;
                     if (ExitCode <> Still_Active) and (ExitCode <> 0) then
                     begin
                        if not FileExists('drivers\network\net' + strNetBrdg1 + '\VBoxNet' + strNetBrdg1 + '.inf') then
                           strTemp := 'VBoxNet' + strNetBrdg1 + '.inf not found'
                        else if not FileExists('drivers\network\net' + strNetBrdg1 + '\VBoxNet' + strNetBrdg1 + strNetBrdg3 + '.inf') then
                           strTemp := 'VBoxNet' + strNetBrdg1 + strNetBrdg3 + '.inf not found'
                        else
                           strTemp := GetLangTextFormatDef(idxMain, ['Messages', 'ErrorCode'], [IntToStr(ExitCode), 'snetcfg'], '%s error code from %s');;
                        strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemInstalling'], ['VBoxNet' + strNetBrdg1], 'problem installing %s'#13#10#13#10'System message:') + ' ' + strTemp;
                        Result := Result and False;
                     end;
                     CloseHandle(eProcessInfo.hProcess);
                     CloseHandle(eProcessInfo.hThread);
                  except
                  end;
               end
               else
               begin
                  if not FileExists(exeSnetCfgPath) then
                     strTemp := 'file not found'
                  else if LastError > 0 then
                     strTemp := SysErrorMessage(LastError)
                  else if LastExceptionStr <> '' then
                     strTemp := LastExceptionStr;
                  strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemStarting'], ['snetcfg'], 'problem starting %s'#13#10#13#10'System message:') + ' ' + strTemp;
                  Result := Result and False;
               end;
            finally
            end;

         if Terminated then
            Exit;

         SetCurrentDir(curDir);

         if (strNetBrdg1 = 'Flt') and (CheckInstalledInf(strNetBrdg2 + '_VBoxNet' + strNetBrdg1) < 1) then
         begin
            if LastError > 0 then
               strTemp := SysErrorMessage(LastError)
            else if LastExceptionStr <> '' then
               strTemp := LastExceptionStr;
            strRegErrMsg := strRegErrMsg + #13#10#13#10'problem installing VBoxNet' + strNetBrdg1 + #13#10#13#10'System message: ' + strTemp;
            Result := Result and False;
         end;

         if Terminated then
            Exit;

         if DirectoryExists(drvSysPath) then
         begin
            if FileExists(drvSysPath + 'VBoxNet' + strNetBrdg1 + '.sys') then
               RenameFile(drvSysPath + 'VBoxNet' + strNetBrdg1 + '.sys', drvSysPath + 'VBoxNet' + strNetBrdg1 + '.sys.pvbbak');
            CopyFile(PChar(IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + 'drivers\network\net' + strNetBrdg1 + '\VBoxNet' + strNetBrdg1 + '.sys'), PChar(drvSysPath + 'VBoxNet' + strNetBrdg1 + '.sys'), False);
         end;

         SetLength(exeRegsvr32Path, StrLen(Buffer));
         exeRegsvr32Path := Buffer;
         exeRegSvr32Path := IncludeTrailingPathDelimiter(exeRegSvr32Path);

         if Terminated then
            Exit;

         if FileExists(exeRegSvr32Path + 'VBoxNetFltNobj.dll') then
            RenameFile(exeRegSvr32Path + 'VBoxNetFltNobj.dll', exeRegSvr32Path + 'VBoxNetFltNobj.dll.pvbbak');
         CopyFile(PChar(IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + 'drivers\network\netflt\VBoxNetFltNobj.dll'), PChar(exeRegSvr32Path + 'VBoxNetFltNobj.dll'), False);
         exeRegsvr32Path := exeRegsvr32Path + 'regsvr32.exe';

         if Terminated then
            Exit;

         try
            if exeRegsvr32Path <> '' then
            begin
               strTemp := '"' + exeRegsvr32Path + '" /S "' + IncludeTrailingPathDelimiter(ExtractFilePath(exeRegSvr32Path)) + 'VBoxNetFltNobj.dll"';
               UniqueString(strTemp);
               PexeRegsvr32 := PChar(strTemp);
            end
            else
               PexeRegsvr32 := nil;
            if ExtractFilePath(exeRegsvr32Path) <> '' then
               PexeRegsvr32Path := PChar(ExtractFilePath(exeRegsvr32Path))
            else
               PexeRegsvr32Path := nil;
            ResetLastError;
            try
               resCP := CreateProcess(nil, PexeRegsvr32, nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, PexeRegsvr32Path, eStartupInfo, eProcessInfo);
               LastError := GetLastError;
            except
               on E: Exception do
               begin
                  Result := Result and False;
                  LastExceptionStr := E.Message;
               end;
            end;
            if Terminated then
               Exit;
            if resCP then
            begin
               dt := GetTickCount;
               while (GetTickCount - dt) <= 3000 do
               begin
                  if WaitForInputIdle(eProcessInfo.hProcess, 50) <> WAIT_TIMEOUT then
                     Break;
                  if Terminated then
                     Exit;
               end;
               dt := GetTickCount;
               while (GetTickCount - dt) <= 5000 do
               begin
                  if WaitForSingleObject(eProcessInfo.hProcess, 50) <> WAIT_TIMEOUT then
                     Break;
                  if Terminated then
                     Exit;
               end;
               try
                  GetExitCodeProcess(eProcessInfo.hProcess, ExitCode);
                  if ExitCode = Still_Active then
                  begin
                     uExitCode := 0;
                     RemoteProcHandle := GetProcessHandleFromID(eProcessInfo.dwProcessId);
                     bDup := DuplicateHandle(GetCurrentProcess(), RemoteProcHandle, GetCurrentProcess(), @hProcessDup, PROCESS_ALL_ACCESS, False, 0);
                     if GetExitCodeProcess(hProcessDup, dwCode) then
                     begin
                        hKernel := GetModuleHandle('Kernel32');
                        FARPROC := GetProcAddress(hKernel, 'ExitProcess');
                        hRT := CreateRemoteThread(hProcessDup, nil, 0, Pointer(FARPROC), @uExitCode, 0, dwTID);
                        if hrt = 0 then
                           TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), eProcessInfo.dwProcessId), 0)
                        else
                           CloseHandle(hRT);
                     end
                     else
                        TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), eProcessInfo.dwProcessId), 0);
                     if (bDup) then
                        CloseHandle(hProcessDup);
                     GetExitCodeProcess(eProcessInfo.hProcess, ExitCode);
                  end;
                  if (ExitCode <> Still_Active) and (ExitCode <> 0) then
                  begin
                     if not FileExists(IncludeTrailingPathDelimiter(ExtractFilePath(exeRegSvr32Path)) + 'VBoxNetFltNobj.dll') then
                        strTemp := 'dll file not found'
                     else
                        case ExitCode of
                           1: strTemp := 'Invalid argument';
                           2: strTemp := 'OleInitialize failed';
                           3: strTemp := 'LoadLibrary failed';
                           4: strTemp := 'GetProcAddress failed';
                           5: strTemp := 'DllRegisterServer or DllUnregisterServer failed';
                        end;
                     strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemReg'], ['VBoxNetFltNobj.dll'], 'problem registering %s'#13#10#13#10'System message:') + ' ' + strTemp;
                     Result := Result and False;
                  end;
                  CloseHandle(eProcessInfo.hProcess);
                  CloseHandle(eProcessInfo.hThread);
               except
               end;
            end
            else
            begin
               if not FileExists(exeRegSvr32Path) then
                  strTemp := 'file not found'
               else if LastError > 0 then
                  strTemp := SysErrorMessage(LastError)
               else if LastExceptionStr <> '' then
                  strTemp := LastExceptionStr;
               strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemStarting'], ['regsvr32.exe'], 'problem starting %s'#13#10#13#10'System message:') + ' ' + strTemp;
               Result := Result and False;
            end;
         finally
         end;

         ssStatus := ServiceStatus('VBoxNet' + strNetBrdg1);
         if (ssStatus.dwCurrentState = SERVICE_STOPPED) or (ssStatus.dwCurrentState = SERVICE_STOP_PENDING) then
         begin
            i := 0;
            while True do
            begin
               Sleep(500);
               resCP := ServiceStart('VBoxNet' + strNetBrdg1);
               if resCP then
                  Break;
               if Terminated then
                  Exit;
               if (i >= 6) and (not resCP) then
               begin
                  if LastError > 0 then
                     strTemp := SysErrorMessage(LastError)
                  else if LastExceptionStr <> '' then
                     strTemp := LastExceptionStr;
                  strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemStarting'], ['VBoxNet' + strNetBrdg1], 'problem starting %s'#13#10#13#10'System message:') + ' ' + strTemp;
                  Result := Result and False;
                  Break;
               end;
               Inc(i);
            end;
         end;

         if Terminated then
            Exit;

         ssStatus := ServiceStatus('VBoxNet' + strNetBrdg1);
         if ssStatus.dwCurrentState = 0 then
         begin
            if LastError > 0 then
               strTemp := SysErrorMessage(LastError)
            else if LastExceptionStr <> '' then
               strTemp := LastExceptionStr;
            strRegErrMsg := strRegErrMsg + #13#10#13#10 + GetLangTextFormatDef(idxMain, ['Messages', 'ProblemStarting'], ['VBoxNet' + strNetBrdg1], 'problem starting %s'#13#10#13#10'System message:') + ' ' + strTemp;
            Result := Result and False;
         end;
      end;

      if Terminated then
         Exit;

      strTemp := IncludeTrailingPathDelimiter(ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs))));
      if LowerCase(strTemp + 'app64') = Lowercase(ExcludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs))) then
      begin
         if DirectoryExists(strTemp + 'app32') then
            strTemp := strTemp + 'app32\'
         else
            strTemp := '';
      end
      else if LowerCase(strTemp + 'app32') = Lowercase(ExcludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs))) then
      begin
         if DirectoryExists(strTemp + 'app64') then
            strTemp := strTemp + 'app64\'
         else
            strTemp := '';
      end
      else
         strTemp := '';
      if strTemp <> '' then
      begin
         if not DirectoryExists(IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + 'ExtensionPacks') then
         begin
            if DirectoryExists(strTemp + 'ExtensionPacks') then
            begin
               ZeroMemory(@fos, SizeOf(fos));
               with fos do
               begin
                  wFunc := FO_MOVE;
                  fFlags := FOF_FILESONLY or FOF_SILENT or FOF_NOCONFIRMATION or FOF_NOERRORUI or FOF_NOCONFIRMMKDIR;
                  pFrom := PChar(strTemp + 'ExtensionPacks' + #0);
                  pTo := PChar(ExcludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + #0);
               end;
               ShFileOperation(fos);
            end;
         end;

         if Terminated then
            Exit;

         New(wfa);
         try
            hFind := FindFirstFile(PChar(strTemp + '*.iso'), wfa^);
            LastError := GetLastError;
         except
            on E: Exception do
            begin
               hFind := INVALID_HANDLE_VALUE;
               LastExceptionStr := E.Message;
            end;
         end;
         if hFind <> INVALID_HANDLE_VALUE then
         begin
            repeat
               if wfa.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY = 0 then
               begin
                  if not FileExists(IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + wfa.cFileName) then
                     MoveFile(PChar(strTemp + wfa.cFileName), PChar(IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + wfa.cFileName));
               end;
               if Terminated then
                  Exit;
            until not Windows.FindNextFile(hFind, wfa^);
            Windows.FindClose(hFind);
         end;
      end;
   finally
      FRegJobDone := True;
      if not Result then
         PostMessage(frmMain.Handle, WM_USER + 333, 3, 3);
      if not Terminated then
         Terminate;
   end;
end; { TRegisterThread.Execute }

procedure TRegisterThread.Terminate;
var
   dt: Cardinal;
begin
   TThread(Self).Terminate;
   dt := GetTickCount;
   while (not FRegJobDone) and ((GetTickCount - dt) <= 5000) do
      Sleep(1);
   mEvent.Free;
   if FPSJobDone and FPCJobDone and FRegJobDone and FUnregJobDone then
      SetPriorityClass(GetCurrentProcess(), NORMAL_PRIORITY_CLASS);
   if isVBPortable then
      if not (csDestroying in frmMain.ComponentState) then
         if (frmMain.vstVMs.GetFirstSelected = nil) or ((frmMain.vstVMs.GetFirstSelected <> nil) and (PData(frmMain.vstVMs.GetNodeData(frmMain.vstVMs.GetFirstSelected))^.Ptype = 0)) then
         begin
            frmMain.imlBtn16.PngImages[0].PngImage := frmMain.imlReg16.PngImages[0].PngImage;
            frmMain.imlBtn16.PngImages[9].PngImage := frmMain.imlReg16.PngImages[1].PngImage;
            frmMain.imlBtn24.PngImages[0].PngImage := frmMain.imlReg24.PngImages[0].PngImage;
            frmMain.imlBtn24.PngImages[7].PngImage := frmMain.imlReg24.PngImages[1].PngImage;
            if frmMain.btnStart.PngImage.Width = 16 then
               frmMain.btnStart.PngImage := frmMain.imlReg16.PngImages[0].PngImage
            else
               frmMain.btnStart.PngImage := frmMain.imlReg24.PngImages[0].PngImage;
         end;
   if StartSvcToo then
   begin
      StartSvcToo := False;
      FPSJobDone := False;
      FPSThread := TPrestartThread.Create;
   end;
end;

end.

