unit uEjectThread;

interface

uses
   Classes, Windows, SysUtils, SyncObjs, Dialogs;

type
   TEjectThread = class(TThread)
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

constructor TEjectThread.Create;
begin
   inherited Create(False);
   mEvent := TEvent.Create(nil, True, False, '');
end; { TEjectThread.Create }

procedure TEjectThread.Execute;
var
   resCM: Integer;
   VetoType: PNP_VETO_TYPE;
   VetoName: array[0..MAX_PATH - 1] of CHAR;
   StartTime: Cardinal;
begin
   try
      StartTime := GetTickCount;
      repeat
         begin
            FillChar(VetoName[0], SizeOf(VetoName), 0);
            try
               resCM := CM_Request_Device_Eject(FDevInstParent, @VetoType, @VetoName[0], Length(VetoName), 0);
               LastError := GetLastError;
            except
               resCM := -1;
            end;
            EjectResult := (resCM = CR_SUCCESS) and (VetoType = PNP_VetoTypeUnknown);
            if EjectResult then
               Break;
            if (GetTickCount - StartTime) >= 5000 then
               Break;
            mEvent.WaitFor(500);
            if (GetTickCount - StartTime) >= 5000 then
               Break;
         end;
      until Terminated;
   finally
      FEjectJobDone := True;
   end;
end; { TEjectThread.Execute }

procedure TEjectThread.Terminate;
begin
   TThread(Self).Terminate;
   mEvent.SetEvent;
   while not FEjectJobDone do
      Sleep(1);
   mEvent.Free;
end;

end.

