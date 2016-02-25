unit uPrecacheThread;

interface

uses
   Classes, Windows, SysUtils, Dialogs;

const
   BufferSize = 10485760;
   ExtFilesNotToCache: array[1..3] of string = ('.rtf', '.iso', '.chm');

type
   TPrecacheThread = class(TThread)
   private
      //  ts: TTime;
      Buffer: array of AnsiChar;
      { Private declarations }
   protected
      procedure Execute; override;
   public
      constructor Create;
      procedure Terminate;
      procedure CacheFile(const FileName: string);
   end;

implementation

uses Mainform;

constructor TPrecacheThread.Create;
begin
   inherited Create(False);
   SetPriorityClass(GetCurrentProcess(), ABOVE_NORMAL_PRIORITY_CLASS);
   Priority := tpLower;
end; { TPrecacheThread.Create }

procedure TPrecacheThread.CacheFile(const FileName: string);
var
   hFile: THandle;
   BytesRead: Cardinal;
begin
   try
      hFile := CreateFile(PChar(Filename), GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, 0);
      if hFile = INVALID_HANDLE_VALUE then
         Exit;
      repeat
         if Terminated then
            Break;
         if not ReadFile(hFile, Buffer, BufferSize, BytesRead, nil) then
            Break;
      until BytesRead <> BufferSize;
      CloseHandle(hFile);
   except
   end;
end;

procedure TPrecacheThread.Execute;
var
   VBPath: string;
   hFind: THandle;
   wfa: ^WIN32_FIND_DATAW;
   i: Integer;
begin
   // ts := Now;
   try
      if not FileExists(ExeVBPath) then
         Exit;
      if Terminated then
         Exit;
      VBPath := ExtractFilePath(ExeVBPath);
      New(wfa);
      hFind := FindFirstFile(PChar(VBPath + '*.*'), wfa^);
      if hFind = INVALID_HANDLE_VALUE then
         Exit;
      SetLength(Buffer, BufferSize + 1);
      repeat
         if wfa.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY = 0 then
         begin
            i := Low(ExtFilesNotToCache);
            while i <= High(ExtFilesNotToCache) do
            begin
               if ExtractFileExt(wfa.cFileName) = ExtFilesNotToCache[i] then
                  Break;
               Inc(i);
            end;
            if i <= High(ExtFilesNotToCache) then
               Continue;
            Cachefile(VBPath + wfa.cFileName);
         end;
         if Terminated then
            Exit;
      until not Windows.FindNextFile(hFind, wfa^);
      Windows.FindClose(hFind);
      VBPath := VBPath + 'ExtensionPacks\Oracle_VM_VirtualBox_Extension_Pack\';
      if not DirectoryExists(VBPath) then
         Exit;
      if FileExists(VBPath + 'ExtPack.xml') then
         CacheFile(VBPath + 'ExtPack.xml')
      else
         Exit;
      if TOSversion.Architecture = arIntelX86 then
         VBPath := VBPath + 'win.x86\'
      else if TOSversion.Architecture = arIntelX64 then
         VBPath := VBPath + 'win.amd64\';
      New(wfa);
      hFind := FindFirstFile(PChar(VBPath + '*.*'), wfa^);
      if hFind = INVALID_HANDLE_VALUE then
         Exit;
      repeat
         if wfa.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY = 0 then
            Cachefile(VBPath + wfa.cFileName);
         if Terminated then
            Exit;
      until not Windows.FindNextFile(hFind, wfa^);
      Windows.FindClose(hFind);
   finally
      FPCJobDone := True;
      SetLength(Buffer, 0);
      if not Terminated then
         Terminate;
   end;
end; { TPrecacheThread.Execute }

procedure TPrecacheThread.Terminate;
var
   dt: Cardinal;
begin
   TThread(Self).Terminate;
   dt := GetTickCount;
   while (not FPCJobDone) and ((GetTickCount - dt) <= 5000) do
      Sleep(1);
   if FPSJobDone and FPCJobDone and FRegJobDone and FUnregJobDone then
      SetPriorityClass(GetCurrentProcess(), NORMAL_PRIORITY_CLASS);
end;

end.

