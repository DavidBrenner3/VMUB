unit uPrestartThread;

interface

uses
   Classes, Windows, SysUtils;

type
   TPrestartThread = class(TThread)
   private
      { Private declarations }
   protected
      procedure Execute; override;
   public
      constructor Create;
      procedure Terminate;
   end;

implementation

uses Mainform;

constructor TPrestartThread.Create;
begin
   inherited Create(False);
   SetPriorityClass(GetCurrentProcess(), ABOVE_NORMAL_PRIORITY_CLASS);
   Priority := tpLower;
end; { TPrestartThread.Create }

procedure TPrestartThread.Execute;
var
   exeVBSvcPath: string;
   PexeVBSvcPath, PVBSvcPath: PChar;
   svcThrStartupInfo: TStartupInfo;
begin
   try
      exeVBSvcPath := ExtractFilePath(ExeVBPath) + 'VBoxSvc.exe';
      if not FileExists(ExeVBSvcPath) then
         Exit;
      FillChar(svcThrStartupInfo, SizeOf(svcThrStartupInfo), #0);
      svcThrStartupInfo.dwFlags := STARTF_USESHOWWINDOW;
      svcThrStartupInfo.cb := SizeOf(svcThrStartupInfo);
      svcThrStartupInfo.wShowWindow := SW_SHOWNORMAL;
      if ExeVBPath <> '' then
         PexeVBSvcPath := PChar(ExeVBSvcPath)
      else
         PexeVBSvcPath := nil;
      if ExtractFilePath(ExeVBPath) <> '' then
      begin
         UniqueString(ExeVBSvcPath);
         PVBSvcPath := PChar(ExtractFilePath(ExeVBSvcPath));
      end
      else
         PVBSvcPath := nil;
      CreateProcess(nil, PExeVBSvcPath, nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, PVBSvcPath, svcThrStartupInfo, svcThrProcessInfo);
   finally
      FPSJobDone := True;
   end;
end; { TPrestartThread.Execute }

procedure TPrestartThread.Terminate;
var
   dt: Cardinal;
begin
   TThread(Self).Terminate;
   dt := GetTickCount;
   while (not FPSJobDone) and ((GetTickCount - dt) <= 5000)  do
     Sleep(1);
   if FPSJobDone and FPCJobDone and FRegJobDone and FUnregJobDone then
      SetPriorityClass(GetCurrentProcess(), NORMAL_PRIORITY_CLASS);
end;

end.

