unit uUnregisterThread;

interface

uses
   Classes, Windows, SysUtils, WinSvc, ShlWapi, Forms, Dialogs, uRegisterThread, uPrestartThread, SyncObjs;

type
   TUnregisterThread = class(TThread)
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

constructor TUnregisterThread.Create;
begin
   inherited Create(False);
   mEvent := TEvent.Create(nil, True, False, '');
   SetPriorityClass(GetCurrentProcess(), BELOW_NORMAL_PRIORITY_CLASS);
   Priority := tpHigher;
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
end; { TUnregisterThread.Create }

procedure TUnregisterThread.Execute;
var
   eStartupInfo: TStartupInfo;
   eProcessInfo: TProcessInformation;
   PexeVboxSvc, PexeVboxSvcPath, PexeRegSvr32, PexeRegSvr32Path, PexeRundll32Path, PexeRundll32, PexeSnetCfg, PexeSnetCfgPath{$IFDEF WIN32}, PexeDevCon, PexeDevConPath{$ENDIF}: PChar;
   exeVboxSvcPath, exeRegSvr32Path, exeVBPathAbs, exeRundll32Path, drvSysPath, dllPath{$IFDEF WIN32}, exeDevConPath{$ENDIF},
   strNetAdp, strNetBrdg1, strNetBrdg2, strNetBrdg3, curDir, exeSnetCfgPath, strTemp: string;
   Buffer: array[0..MAX_PATH] of Char;
   Path: array[0..MAX_PATH - 1] of Char;
   ExitCode, dwTID: DWORD;
   hProcessDup, RemoteProcHandle: Cardinal;
   bDup: BOOL;
   dwCode: DWORD;
   hrt: Cardinal;
   hKernel: HMODULE;
   FARPROC: Pointer;
   uExitCode: Cardinal;
   ssStatus: TServiceStatus;
   Result: Boolean;
   dt: Cardinal;
   i: Integer;
   hFind: THandle;
   wfa: ^WIN32_FIND_DATAW;
begin
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

      FillChar(eStartupInfo, SizeOf(eStartupInfo), #0);
      eStartupInfo.dwFlags := STARTF_USESHOWWINDOW;
      eStartupInfo.cb := SizeOf(eStartupInfo);
      eStartupInfo.wShowWindow := SW_HIDE;

      GetSystemDirectory(Buffer, MAX_PATH - 1);

      if Terminated then
         Exit;

      SetEnvVariable('VBOX_USER_HOME', '');

      if isVBInstalledToo and FileExists(exeVBPathToo) and useLoadedFromInstalled then
         Exit;

      exeVboxSvcPath := IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + 'VBoxSvc.exe';

      try
         if exeVboxSvcPath <> '' then
         begin
            strTemp := '"' + exeVboxSvcPath + '" /unregserver';
            UniqueString(strTemp);
            PexeVboxSvc := PChar(strTemp);
         end
         else
            PexeVboxSvc := nil;
         if ExtractFilePath(exeVboxSvcPath) <> '' then
            PexeVboxSvcPath := PChar(ExtractFilePath(exeVboxSvcPath))
         else
            PexeVboxSvcPath := nil;
         try
            Result := CreateProcess(nil, PexeVboxSvc, nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, PexeVboxSvcPath, eStartupInfo, eProcessInfo);
            LastError := GetLastError;
         except
            on E: Exception do
            begin
               Result := False;
               LastExceptionStr := E.Message;
            end;
         end;
         if Terminated then
            Exit;
         if Result then
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
         end;
      finally
      end;

      if Terminated then
         Exit;

      SetLength(exeRegsvr32Path, StrLen(Buffer));
      exeRegsvr32Path := IncludeTrailingPathDelimiter(Buffer);
      exeRegsvr32Path := exeRegsvr32Path + 'regsvr32.exe';

      try
         if exeRegsvr32Path <> '' then
         begin
            strTemp := '"' + exeRegsvr32Path + '" /s /u "' + IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs)) + 'VBoxC.dll"';
            UniqueString(strTemp);
            PexeRegsvr32 := PChar(strTemp);
         end
         else
            PexeRegsvr32 := nil;
         if ExtractFilePath(exeRegsvr32Path) <> '' then
            PexeRegsvr32Path := PChar(ExtractFilePath(exeRegsvr32Path))
         else
            PexeRegsvr32Path := nil;
         try
            Result := CreateProcess(nil, PexeRegsvr32, nil, nil, False, CREATE_NO_WINDOW or NORMAL_PRIORITY_CLASS, nil, PexeRegsvr32Path, eStartupInfo, eProcessInfo);
            LastError := GetLastError;
         except
            on E: Exception do
            begin
               Result := False;
               LastExceptionStr := E.Message;
            end;
         end;
         if Terminated then
            Exit;
         if Result then
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
         end;
      finally
      end;

      if Terminated then
         Exit;

      if LoadUSBPortable then
      begin
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
                     Result := CreateProcess(nil, PexeDevCon, nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, PexeDevConPath, eStartupInfo, eProcessInfo);
                     LastError := GetLastError;
                  except
                     on E: Exception do
                     begin
                        Result := False;
                        LastExceptionStr := E.Message;
                     end;
                  end;
                  if Terminated then
                     Exit;
                  if Result then
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
                           strRegErrMsg := 'problem uninstalling VBox USB driver'#13#10#13#10'System message: ' + IntToStr(ExitCode) + ' error code from devcon';
                        CloseHandle(eProcessInfo.hProcess);
                        CloseHandle(eProcessInfo.hThread);
                     except
                     end;
                  end
                  else
                  begin
                     if not FileExists(exeDevConPath) then
                        strRegErrMsg := 'file not found'
                     else if LastError > 0 then
                        strRegErrMsg := SysErrorMessage(LastError)
                     else if LastExceptionStr <> '' then
                        strRegErrMsg := LastExceptionStr;
                     strRegErrMsg := 'problem starting devcon'#13#10#13#10'System message: ' + strRegErrMsg;
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

         if Terminated then
            Exit;

         drvSysPath := IncludeTrailingPathDelimiter(string(Buffer)) + '\Drivers\';
         if DirectoryExists(drvSysPath) then
         begin
            DeleteFile(drvSysPath + 'VBoxUSB.sys');
            if FileExists(drvSysPath + 'VBoxUSB.sys.pvbbak') then
               RenameFile(drvSysPath + 'VBoxUSB.sys.pvbbak', drvSysPath + 'VBoxUSB.sys');
         end;

         if Terminated then
            Exit;

         ssStatus := ServiceStatus('VBoxUSB');
         if ssStatus.dwCurrentState = SERVICE_RUNNING then
            ServiceStop('VBoxUSB');

         if Terminated then
            Exit;

         ssStatus := ServiceStatus('VBoxUSB');
         if (ssStatus.dwCurrentState = SERVICE_STOPPED) or (ssStatus.dwCurrentState = SERVICE_STOP_PENDING) then
            ServiceDelete('VBoxUSB');

         if Terminated then
            Exit;

         ssStatus := ServiceStatus('VBoxUSBMon');
         if (ssStatus.dwCurrentState = 0) or (ServiceDisplayName('VBoxUSBMon') = 'PortableVBoxUSBMon') then
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

      if LoadNetPortable then
      begin

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
                     Result := CreateProcess(nil, PexeDevCon, nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, PexeDevConPath, eStartupInfo, eProcessInfo);
                     LastError := GetLastError;
                  except
                     on E: Exception do
                     begin
                        Result := False;
                        LastExceptionStr := E.Message;
                     end;
                  end;
                  if Terminated then
                     Exit;
                  if Result then
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
                           strRegErrMsg := 'problem uninstalling VBoxNetadp' + strNetAdp + '.inf'#13#10#13#10'System message: ' + IntToStr(ExitCode) + ' error code from devcon';
                        CloseHandle(eProcessInfo.hProcess);
                        CloseHandle(eProcessInfo.hThread);
                     except
                     end;
                  end
                  else
                  begin
                     if not FileExists(exeDevConPath) then
                        strRegErrMsg := 'devcon not found'
                     else if LastError > 0 then
                        strRegErrMsg := SysErrorMessage(LastError)
                     else if LastExceptionStr <> '' then
                        strRegErrMsg := LastExceptionStr;
                     strRegErrMsg := 'problem starting devcon'#13#10#13#10'System message: ' + strRegErrMsg;
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

         if DirectoryExists(drvSysPath) then
         begin
            DeleteFile(drvSysPath + 'VBoxNetAdp' + strNetAdp + '.sys');
            if FileExists(drvSysPath + 'VBoxNetAdp' + strNetAdp + '.sys.pvbbak') then
               RenameFile(drvSysPath + 'VBoxNetAdp' + strNetAdp + '.sys.pvbbak', drvSysPath + 'VBoxNetAdp' + strNetAdp + '.sys');
         end;

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
         if (((TOSVersion.Major < 6) and (CheckInstalledInf(strNetBrdg2 + '_VBoxNet' + strNetBrdg1) > 0)) or ((TOSVersion.Major >= 6) and False)) or (ssStatus.dwCurrentState > 0) then
            try
               exeSnetCfgPath := '"' + exeSnetCfgPath + '" -v -u ' + strNetBrdg2 + '_VBoxNet' + strNetBrdg1;
               UniqueString(exeSnetCfgPath);
               PexeSnetCfg := PChar(exeSnetCfgPath);
               if ExtractFilePath(exeVBPathAbs) <> '' then
                  PexeSnetCfgPath := PChar(ExtractFilePath(exeVBPathAbs))
               else
                  PexeSnetCfgPath := nil;
               ResetLastError;
               try
                  Result := CreateProcess(nil, PexeSnetCfg, nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, PexeSnetCfgPath, eStartupInfo, eProcessInfo);
                  LastError := GetLastError;
               except
                  on E: Exception do
                  begin
                     Result := False;
                     LastExceptionStr := E.Message;
                  end;
               end;
               if Terminated then
                  Exit;
               if Result then
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
                        strRegErrMsg := IntToStr(ExitCode) + ' error code from snetcfg';
                        strRegErrMsg := 'problem uninstalling VBoxNet' + strNetBrdg1 + #13#10#13#10'System message: ' + strRegErrMsg;
                     end;
                     CloseHandle(eProcessInfo.hProcess);
                     CloseHandle(eProcessInfo.hThread);
                  except
                  end;
               end
               else
               begin
                  if not FileExists(exeSnetCfgPath) then
                     strRegErrMsg := 'file not found'
                  else if LastError > 0 then
                     strRegErrMsg := SysErrorMessage(LastError)
                  else if LastExceptionStr <> '' then
                     strRegErrMsg := LastExceptionStr;
                  strRegErrMsg := 'problem starting snetcfg'#13#10#13#10'System message: ' + strRegErrMsg;
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
                  Result := CreateProcess(nil, PexeRegsvr32, nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, PexeRegsvr32Path, eStartupInfo, eProcessInfo);
                  LastError := GetLastError;
               except
                  on E: Exception do
                  begin
                     Result := False;
                     LastExceptionStr := E.Message;
                  end;
               end;
               if Terminated then
                  Exit;
               if Result then
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
                           strRegErrMsg := 'dll file not found'
                        else
                           case ExitCode of
                              1: strRegErrMsg := 'Invalid argument';
                              2: strRegErrMsg := 'OleInitialize failed';
                              3: strRegErrMsg := 'LoadLibrary failed';
                              4: strRegErrMsg := 'GetProcAddress failed';
                              5: strRegErrMsg := 'DllRegisterServer or DllUnregisterServer failed';
                           end;
                        strRegErrMsg := 'problem registering VBoxNetFltNobj.dll'#13#10#13#10'System message: ' + strRegErrMsg;
                     end;
                     CloseHandle(eProcessInfo.hProcess);
                     CloseHandle(eProcessInfo.hThread);
                  except
                  end;
               end
               else
               begin
                  if not FileExists(exeRegSvr32Path) then
                     strRegErrMsg := 'file not found'
                  else if LastError > 0 then
                     strRegErrMsg := SysErrorMessage(LastError)
                  else if LastExceptionStr <> '' then
                     strRegErrMsg := LastExceptionStr;
                  strRegErrMsg := 'problem starting regsvr32.exe'#13#10#13#10'System message: ' + strRegErrMsg;
               end;
            finally
            end;

         if Terminated then
            Exit;

         exeRegSvr32Path := ExtractFilePath(exeRegSvr32Path);
         if TOSVersion.Major < 6 then
         begin
            DeleteFile(exeRegSvr32Path + 'VBoxNetFltNobj.dll');
            if FileExists(exeRegSvr32Path + 'VBoxNetFltNobj.dll.pvbbak') then
               RenameFile(exeRegSvr32Path + 'VBoxNetFltNobj.dll.pvbbak', exeRegSvr32Path + 'VBoxNetFltNobj.dll');
         end;

         if Terminated then
            Exit;

         DeleteFile(exeRegSvr32Path + 'drivers\VBoxNet' + strNetBrdg1 + '.sys');
         if FileExists(exeRegSvr32Path + 'drivers\VBoxNet' + strNetBrdg1 + '.sys.pvbbak') then
            RenameFile(exeRegSvr32Path + 'drivers\VBoxNet' + strNetBrdg1 + '.sys.pvbbak', exeRegSvr32Path + 'drivers\VBoxNet' + strNetBrdg1 + '.sys');

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
      end;

      if Terminated then
         Exit;

      ssStatus := ServiceStatus;
      if ServiceDisplayName = 'PortableVBoxDRV' then
      begin
         if ssStatus.dwCurrentState = SERVICE_RUNNING then
            ServiceStop;

         if Terminated then
            Exit;

         ssStatus := ServiceStatus;
         if (ssStatus.dwCurrentState = SERVICE_STOPPED) or (ssStatus.dwCurrentState = SERVICE_STOP_PENDING) then
            ServiceDelete;
      end;

      if Terminated then
         Exit;

      dllPath := IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathAbs));

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
               if FileExists(exeRegSvr32Path + wfa.cFileName + '.pvbbak') then
               begin
                  DeleteFile(exeRegSvr32Path + wfa.cFileName);
                  RenameFile(exeRegSvr32Path + wfa.cFileName + '.pvbbak', exeRegSvr32Path + wfa.cFileName);
               end;
            end;
            if Terminated then
               Exit;
         until not Windows.FindNextFile(hFind, wfa^);
         Windows.FindClose(hFind);
      end;

      if Terminated then
         Exit;

      if (not isVBinstalledToo) or (not FileExists(exeVBPathToo)) then
         Exit;

      exeVboxSvcPath := IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathToo)) + 'VBoxSvc.exe';

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
         try
            Result := CreateProcess(nil, PexeVboxSvc, nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, PexeVboxSvcPath, eStartupInfo, eProcessInfo);
            LastError := GetLastError;
         except
            on E: Exception do
            begin
               Result := False;
               LastExceptionStr := E.Message;
            end;
         end;
         if Terminated then
            Exit;
         if Result then
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
         end;
      finally
      end;

      if Terminated then
         Exit;

      SetLength(exeRegsvr32Path, StrLen(Buffer));
      exeRegsvr32Path := IncludeTrailingPathDelimiter(Buffer);
      exeRegsvr32Path := exeRegsvr32Path + 'regsvr32.exe';

      try
         if exeRegsvr32Path <> '' then
         begin
            strTemp := '"' + exeRegsvr32Path + '" /s "' + IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathToo)) + 'VBoxC.dll"';
            UniqueString(strTemp);
            PexeRegsvr32 := PChar(strTemp);
         end
         else
            PexeRegsvr32 := nil;
         if ExtractFilePath(exeVBPathToo) <> '' then
            PexeRegsvr32Path := PChar(ExtractFilePath(exeVBPathToo))
         else
            PexeRegsvr32Path := nil;
         try
            Result := CreateProcess(nil, PexeRegsvr32, nil, nil, False, CREATE_NO_WINDOW or NORMAL_PRIORITY_CLASS, nil, PexeRegsvr32Path, eStartupInfo, eProcessInfo);
            LastError := GetLastError;
         except
            on E: Exception do
            begin
               Result := False;
               LastExceptionStr := E.Message;
            end;
         end;
         if Terminated then
            Exit;
         if Result then
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
         end;
      finally
      end;

      if Terminated then
         Exit;

      SetLength(exeRundll32Path, StrLen(Buffer));
      exeRundll32Path := Buffer;
      exeRundll32Path := exeRundll32Path + '\rundll32.exe';

      try
         if exeRundll32Path <> '' then
         begin
            strTemp := '"' + exeRundll32Path + '" "' + IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathToo)) + 'VBoxRT.dll,RTR3InitDll"';
            UniqueString(strTemp);
            PexeRundll32 := PChar(strTemp);
         end
         else
            PexeRundll32 := nil;
         if ExtractFilePath(exeVBPathToo) <> '' then
            PexeRundll32Path := PChar(ExtractFilePath(exeVBPathToo))
         else
            PexeRundll32Path := nil;
         try
            Result := CreateProcess(nil, PexeRundll32, nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, PexeRundll32Path, eStartupInfo, eProcessInfo);
            LastError := GetLastError;
         except
            on E: Exception do
            begin
               Result := False;
               LastExceptionStr := E.Message;
            end;
         end;
         if Terminated then
            Exit;
         if Result then
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
         end;
      finally
      end;

      if Terminated then
         Exit;

      ssStatus := ServiceStatus;
      if ssStatus.dwCurrentState = 0 then
         ServiceCreate(IncludeTrailingPathDelimiter(ExtractFilePath(exeVBPathToo)) + 'drivers\VBoxDrv\VBoxDrv.sys', 'VboxDRV', 'VirtualBox Service');

      if Terminated then
         Exit;

      ssStatus := ServiceStatus;
      if (ssStatus.dwCurrentState = SERVICE_STOPPED) or (ssStatus.dwCurrentState = SERVICE_STOP_PENDING) then
         ServiceStart;

      if Terminated then
         Exit;

      ssStatus := ServiceStatus('VBoxUSBMon');
      if ssStatus.dwCurrentState = 0 then
         ServiceCreate(IncludeTrailingPathDelimiter(ExtractFilePath(ExeVBPathToo)) + 'drivers\USB\filter\VBoxUSBMon.sys', 'VBoxUSBMon', 'VirtualBox USB Monitor Driver');

      if Terminated then
         Exit;

      ssStatus := ServiceStatus('VBoxUSBMon');
      if (ssStatus.dwCurrentState = SERVICE_STOPPED) or (ssStatus.dwCurrentState = SERVICE_STOP_PENDING) then
         ServiceStart('VBoxUSBMon');

      if Terminated then
         Exit;

      if CheckInstalledInf('USB\VID_80EE&PID_CAFE') < 1 then
      begin
         {$IFDEF WIN32}
         if TOSversion.Architecture = arIntelX64 then
         begin
            exeDevConPath := ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(ExeVBPathAbs))) + 'data\tools\devcon_x64.exe';
            try
               strTemp := '"' + exeDevConPath + '" install "' + IncludeTrailingPathDelimiter(ExtractFilePath(ExeVBPathToo)) + 'drivers\USB\device\VBoxUSB.inf" "USB\VID_80EE&PID_CAFE"';
               UniqueString(strTemp);
               PexeDevCon := PChar(strTemp);
               PexeDevConPath := PChar(ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(ExeVBPathAbs))) + 'data\tools\');
               ResetLastError;
               try
                  Result := CreateProcess(nil, PexeDevCon, nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, PexeDevConPath, eStartupInfo, eProcessInfo);
                  LastError := GetLastError;
               except
                  on E: Exception do
                  begin
                     Result := False;
                     LastExceptionStr := E.Message;
                  end;
               end;
               if Terminated then
                  Exit;
               if Result then
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
         end
         else
            InstallInf(IncludeTrailingPathDelimiter(ExtractFilePath(ExeVBPathToo)) + 'drivers\USB\device\VBoxUSB.inf', 'USB\VID_80EE&PID_CAFE');
         {$ENDIF}
         {$IFDEF WIN64}
         InstallInf(IncludeTrailingPathDelimiter(ExtractFilePath(ExeVBPathToo)) + 'drivers\USB\device\VBoxUSB.inf', 'USB\VID_80EE&PID_CAFE');
         {$ENDIF}
      end;

      if Terminated then
         Exit;

      if DirectoryExists(drvSysPath) then
      begin
         if FileExists(drvSysPath + 'VBoxUSB.sys') then
            RenameFile(drvSysPath + 'VBoxUSB.sys', drvSysPath + 'VBoxUSB.sys.ivbbak');
         CopyFile(PChar(IncludeTrailingPathDelimiter(ExtractFilePath(ExeVBPathToo)) + 'drivers\USB\filter\VBoxUSBMon.sys'), PChar(drvSysPath + 'VBoxUSB.sys'), False);
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
            Result := ServiceStart('VBoxUSB');
            if Result then
               Break;
            if (i >= 6) and (not Result) then
               Break;
            Inc(i);
         end;
      end;

      if Terminated then
         Exit;

      if DirectoryExists(drvSysPath) then
      begin
         if FileExists(drvSysPath + 'VBoxNetAdp' + strNetAdp + '.sys') then
            RenameFile(drvSysPath + 'VBoxNetAdp' + strNetAdp + '.sys', drvSysPath + 'VBoxNetAdp' + strNetAdp + '.sys.ivbbak');
         CopyFile(PChar(IncludeTrailingPathDelimiter(ExtractFilePath(ExeVBPathToo)) + 'drivers\network\netadp' + strNetAdp + '\VBoxNetAdp' + strNetAdp + '.sys'), PChar(drvSysPath + 'VBoxNetAdp' + strNetAdp + '.sys'), False);
      end;

      if Terminated then
         Exit;

      if CheckInstalledInf('sun_VBoxNetAdp') < 1 then
      begin
         {$IFDEF WIN32}
         if TOSversion.Architecture = arIntelX64 then
         begin
            exeDevConPath := ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(ExeVBPathAbs))) + 'data\tools\devcon_x64.exe';
            try
               strTemp := '"' + exeDevConPath + '" install "' + IncludeTrailingPathDelimiter(ExtractFilePath(ExeVBPathToo)) + 'drivers\network\netadp' + strNetAdp + '\VBoxNetAdp' + strNetAdp + '.inf" "sun_VBoxNetAdp"';
               UniqueString(strTemp);
               PexeDevCon := PChar(strTemp);
               PexeDevConPath := PChar(ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(ExeVBPathAbs))) + 'data\tools\');
               ResetLastError;
               try
                  Result := CreateProcess(nil, PexeDevCon, nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, PexeDevConPath, eStartupInfo, eProcessInfo);
                  LastError := GetLastError;
               except
                  on E: Exception do
                  begin
                     Result := False;
                     LastExceptionStr := E.Message;
                  end;
               end;
               if Terminated then
                  Exit;
               if Result then
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
         end
         else
            InstallInf(IncludeTrailingPathDelimiter(ExtractFilePath(ExeVBPathToo)) + 'drivers\network\netadp' + strNetAdp + '\VBoxNetAdp' + strNetAdp + '.inf', 'sun_VBoxNetAdp');
         {$ENDIF}
         {$IFDEF WIN64}
         InstallInf(IncludeTrailingPathDelimiter(ExtractFilePath(ExeVBPathToo)) + 'drivers\network\netadp' + strNetAdp + '\VBoxNetAdp' + strNetAdp + '.inf', 'sun_VBoxNetAdp');
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
            Result := ServiceStart('VBoxNetAdp');
            if Result then
               Break;
            if (i >= 6) and (not Result) then
               Break;
            Inc(i);
         end;
      end;

      if Terminated then
         Exit;

      curDir := GetCurrentDir();
      SetCurrentDir(ExtractFilePath(exeVBPathToo));
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
               Result := CreateProcess(nil, PexeSnetCfg, nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, PexeSnetCfgPath, eStartupInfo, eProcessInfo);
               LastError := GetLastError;
            except
               on E: Exception do
               begin
                  Result := False;
                  LastExceptionStr := E.Message;
               end;
            end;
            if Terminated then
               Exit;
            if Result then
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
                        strRegErrMsg := 'VBoxNet' + strNetBrdg1 + '.inf not found'
                     else if not FileExists('drivers\network\net' + strNetBrdg1 + '\VBoxNet' + strNetBrdg1 + strNetBrdg3 + '.inf') then
                        strRegErrMsg := 'VBoxNet' + strNetBrdg1 + strNetBrdg3 + '.inf not found'
                     else
                        strRegErrMsg := IntToStr(ExitCode) + ' error code from snetcfg';
                     strRegErrMsg := 'problem installing VBoxNet' + strNetBrdg1 + '.inf'#13#10#13#10'System message: ' + strRegErrMsg;
                  end;
                  CloseHandle(eProcessInfo.hProcess);
                  CloseHandle(eProcessInfo.hThread);
               except
               end;
            end
            else
            begin
               if not FileExists(exeSnetCfgPath) then
                  strRegErrMsg := 'file not found'
               else if LastError > 0 then
                  strRegErrMsg := SysErrorMessage(LastError)
               else if LastExceptionStr <> '' then
                  strRegErrMsg := LastExceptionStr;
               strRegErrMsg := 'problem starting snetcfg'#13#10#13#10'System message: ' + strRegErrMsg;
               Exit;
            end;
         finally
         end;

      SetCurrentDir(curDir);

      if Terminated then
         Exit;

      DeleteFile(exeRegSvr32Path + 'drivers\VBoxNet' + strNetBrdg1 + '.sys');
      if FileExists(exeRegSvr32Path + 'drivers\VBoxNet' + strNetBrdg1 + '.sys.ivbbak') then
         RenameFile(exeRegSvr32Path + 'drivers\VBoxNet' + strNetBrdg1 + '.sys.ivbbak', exeRegSvr32Path + 'drivers\VBoxNet' + strNetBrdg1 + '.sys');

      if Terminated then
         Exit;

      if TOSVersion.Major < 6 then
      begin
         SetLength(exeRegsvr32Path, StrLen(Buffer));
         exeRegsvr32Path := Buffer;
         exeRegSvr32Path := IncludeTrailingPathDelimiter(exeRegSvr32Path);

         DeleteFile(exeRegSvr32Path + 'VBoxNetFltNobj.dll');
         if FileExists(exeRegSvr32Path + 'VBoxNetFltNobj.dll.ivbbak') then
            RenameFile(exeRegSvr32Path + 'VBoxNetFltNobj.dll.ivbbak', exeRegSvr32Path + 'VBoxNetFltNobj.dll');

         exeRegsvr32Path := exeRegsvr32Path + 'regsvr32.exe';

         try
            if exeRegsvr32Path <> '' then
            begin
               strTEmp := '"' + exeRegsvr32Path + '" /S "' + IncludeTrailingPathDelimiter(ExtractFilePath(exeRegSvr32Path)) + 'VBoxNetFltNobj.dll"';
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
               Result := CreateProcess(nil, PexeRegsvr32, nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, PexeRegsvr32Path, eStartupInfo, eProcessInfo);
               LastError := GetLastError;
            except
               on E: Exception do
               begin
                  Result := False;
                  LastExceptionStr := E.Message;
               end;
            end;
            if Terminated then
               Exit;
            if Result then
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
                        strRegErrMsg := 'dll file not found'
                     else
                        case ExitCode of
                           1: strRegErrMsg := 'Invalid argument';
                           2: strRegErrMsg := 'OleInitialize failed';
                           3: strRegErrMsg := 'LoadLibrary failed';
                           4: strRegErrMsg := 'GetProcAddress failed';
                           5: strRegErrMsg := 'DllRegisterServer or DllUnregisterServer failed';
                        end;
                     strRegErrMsg := 'problem registering VBoxNetFltNobj.dll'#13#10#13#10'System message: ' + strRegErrMsg;
                  end;
                  CloseHandle(eProcessInfo.hProcess);
                  CloseHandle(eProcessInfo.hThread);
               except
               end;
            end
            else
            begin
               if not FileExists(exeRegSvr32Path) then
                  strRegErrMsg := 'file not found'
               else if LastError > 0 then
                  strRegErrMsg := SysErrorMessage(LastError)
               else if LastExceptionStr <> '' then
                  strRegErrMsg := LastExceptionStr;
               strRegErrMsg := 'problem starting regsvr32.exe'#13#10#13#10'System message: ' + strRegErrMsg;
            end;
         finally
         end;
      end;

      ssStatus := ServiceStatus('VBoxNet' + strNetBrdg1);
      if (ssStatus.dwCurrentState = SERVICE_STOPPED) or (ssStatus.dwCurrentState = SERVICE_STOP_PENDING) then
      begin
         i := 0;
         while True do
         begin
            Sleep(500);
            Result := ServiceStart('VBoxNet' + strNetBrdg1);
            if Result then
               Break;
            if Terminated then
               Exit;
            if (i >= 6) and (not Result) then
            begin
               if LastError > 0 then
                  strRegErrMsg := SysErrorMessage(LastError)
               else if LastExceptionStr <> '' then
                  strRegErrMsg := LastExceptionStr;
               strRegErrMsg := 'problem starting VBoxNet' + strNetBrdg1 + ' service'#13#10#13#10'System message: ' + strRegErrMsg;
               Break;
            end;
            Inc(i);
         end;
      end;

   finally
      FUnregJobDone := True;
      if not Terminated then
         Terminate;
   end;
end; { TUnregisterThread.Execute }

procedure TUnregisterThread.Terminate;
var
   dt: Cardinal;
begin
   if ChangeFromTempToReal then
   begin
      ChangeFromTempToReal := False;
      ExeVBPath := ExeVBPathTemp;
      LoadNetPortable := LoadNetPortableTemp;
      LoadUSBPortable := LoadUSBPortableTemp;
      useLoadedFromInstalled := useLoadedFromInstalledTemp;
   end;
   TThread(Self).Terminate;
   dt := GetTickCount;
   while (not FUnregJobDone) and ((GetTickCount - dt) <= 5000) do
      Sleep(1);
   mEvent.Free;
   if FPSJobDone and FPCJobDone and FRegJobDone and FUnregJobDone then
      SetPriorityClass(GetCurrentProcess(), NORMAL_PRIORITY_CLASS);
   if StartSvcToo and (not StartRegToo) then
   begin
      StartSvcToo := False;
      FPSJobDone := False;
      FPSThread := TPrestartThread.Create;
   end;
   if StartRegToo then
   begin
      StartRegToo := False;
      FRegJobDone := False;
      FRegThread := TRegisterThread.Create;
      Exit;
   end;
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
end;

end.

