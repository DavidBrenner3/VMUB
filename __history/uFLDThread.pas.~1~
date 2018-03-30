unit uFLDThread;

interface

uses
   Classes, Windows, SysUtils, SyncObjs;

type
   TFLDThread = class(TThread)
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

constructor TFLDThread.Create;
begin
   inherited Create(False);
   mEvent := TEvent.Create(nil, True, False, '');
end; { TFLDThread.Create }

procedure TFLDThread.Execute;
var
   dwBytesReturned: Cardinal;
   i: Integer;
   StartTime: Cardinal;
   FLDResult: Boolean;
begin
   try
      for i := FLDIndStart to High(VolumesInfo) do
      begin
         if VolumesInfo[i].FirstDrv <> DoFDThread then
            Continue;
         FLDAreaProblem := -1;
         if FDLSkipTo < 0 then
         begin
            FLDAreaProblem := 0;
            try
               VolumesInfo[i].Handle := CreateFile(VolumesInfo[i].Name, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
               LastError := GetLastError;
            except
               VolumesInfo[i].Handle := INVALID_HANDLE_VALUE;
            end;
            if VolumesInfo[i].Handle = INVALID_HANDLE_VALUE then
            begin
               FLDFailedInd := i;
               Break;
            end;
            try
               FlushFileBuffers(VolumesInfo[i].Handle);
            except
            end;
            if FlushWaitTime > 0 then
               mEvent.WaitFor(FlushWaitTime);
         end;
         if Terminated then
            Break;
         if FDLSkipTo < 1 then
         begin
            if LockVolumes and (not DisableLockAndDismount) then
            begin
               FLDAreaProblem := 1;
               StartTime := GetTickCount;
               repeat
                  begin
                     try
                        FLDResult := DeviceIoControl(VolumesInfo[i].Handle, FSCTL_LOCK_VOLUME, nil, 0, nil, 0, dwBytesReturned, nil);
                        LastError := GetLastError;
                     except
                        FLDResult := False;
                     end;
                     if FLDResult then
                        Break;
                     if (GetTickCount - StartTime) >= 10000 then
                        Break;
                     mEvent.WaitFor(50);
                     if (GetTickCount - StartTime) >= 10000 then
                        Break;
                  end;
               until Terminated;
               if not FLDResult then
               begin
                  FLDFailedInd := i;
                  Break;
               end;
            end;
         end;
         if not DisableLockAndDismount then
         begin
            FLDAreaProblem := 2;
            StartTime := GetTickCount;
            repeat
               begin
                  try
                     FLDResult := DeviceIoControl(VolumesInfo[i].Handle, FSCTL_DISMOUNT_VOLUME, nil, 0, nil, 0, dwBytesReturned, nil);
                     LastError := GetLastError;
                  except
                     FLDResult := False;
                  end;
                  if FLDResult then
                     Break;
                  if (GetTickCount - StartTime) >= 5000 then
                     Break;
                  mEvent.WaitFor(50);
                  if (GetTickCount - StartTime) >= 5000 then
                     Break;
               end;
            until Terminated;
            if not FLDResult then
            begin
               FLDFailedInd := i;
               Break;
            end;
         end;
         FDLSkipTo := -1;
      end;
   finally
      FLDJobDone := True;
   end;
end; { TFLDThread.Execute }

procedure TFLDThread.Terminate;
begin
   TThread(Self).Terminate;
   mEvent.SetEvent;
   while not FLDJobDone do
      Sleep(1);
   mEvent.Free;
end;

end.

