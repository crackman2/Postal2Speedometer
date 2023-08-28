unit CProcMem;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Windows, JwaTlHelp32;

type

  { TProcMem }

  TProcMem = class
  public
    InitSuccess: boolean;

    ProcId: DWORD;
    ProcH: HANDLE;


    constructor Create(WinTitle: string);
    destructor Destroy();

    function rpmf(Address: DWORD): single;
    function rpmd(Address: DWORD): DWORD;
    function rpmw(Address: DWORD): word;
    function rpmb(Address: DWORD): byte;

    function wpmf(Address: DWORD; Value: single): boolean;
    function wpmb(Address: DWORD; Value: byte): boolean;

    function GetModuleBaseAddress(lpModName: PChar): Pointer;
  end;


implementation

constructor TProcMem.Create(WinTitle: string);
var
  winhandle: HWND = 0;
begin
  Self.ProcId := 0;
  Self.ProcH := 0;

  if WinTitle <> '' then
  begin
    winhandle := FindWindow(nil, PChar(WinTitle));
    if winhandle <> 0 then
    begin
      GetWindowThreadProcessId(winhandle, Self.ProcId);
      if Self.ProcId <> 0 then
      begin
        Self.ProcH := OpenProcess(PROCESS_ALL_ACCESS, False, Self.ProcId);
        if Self.ProcH <> 0 then
        begin
          //writeln('ProcMem: ' + WinTitle + ' was opened successfully');
          InitSuccess := True;
        end
        else
        begin
          //writeln('ProcMem Err: proch is null');
          InitSuccess := False;
        end;
      end
      else
      begin
        //WriteLn('ProcMem Err: procid is null');
        InitSuccess := False;
      end;
    end
    else
    begin
      //writeln('ProcMem Err: window handle not found');
      InitSuccess := False;
    end;
  end
  else
  begin
    //WriteLn('ProcMem Err: WinTitle empty?');
    InitSuccess := False;
  end;
end;

destructor TProcMem.Destroy;
begin
  CloseHandle(Self.ProcH);
end;


function TProcMem.rpmf(Address: DWORD): single;
var
  trash: longword = 0;
begin
  Result := 0;
  if Self.ProcH <> 0 then
  begin
    ReadProcessMemory(Self.ProcH, Pointer(Address), @Result, SizeOf(Result), trash);
  end;
end;

function TProcMem.rpmd(Address: DWORD): DWORD;
var
  trash: longword = 0;
begin
  Result := 0;
  if Self.ProcH <> 0 then
  begin
    ReadProcessMemory(Self.ProcH, Pointer(Address), @Result, SizeOf(Result), trash);
  end;
end;

function TProcMem.rpmw(Address: DWORD): word;
var
  trash: longword = 0;
begin
  Result := 0;
  if Self.ProcH <> 0 then
  begin
    ReadProcessMemory(Self.ProcH, Pointer(Address), @Result, SizeOf(Result), trash);
  end;
end;

function TProcMem.rpmb(Address: DWORD): byte;
var
  trash: longword = 0;
begin
  Result := 0;
  if Self.ProcH <> 0 then
  begin
    ReadProcessMemory(Self.ProcH, Pointer(Address), @Result, SizeOf(Result), trash);
  end;
end;

function TProcMem.wpmf(Address: DWORD; Value: single): boolean;
var
  trash: longword = 0;
begin
  Result := False;
  if Self.ProcH <> 0 then
  begin
    Result := WriteProcessMemory(Self.ProcH, Pointer(Address), @Value, SizeOf(Value), trash);
  end;
end;

function TProcMem.wpmb(Address: DWORD; Value: byte): boolean;
var
  trash: longword = 0;
begin
  Result := False;
  if Self.ProcH <> 0 then
  begin
    Result := WriteProcessMemory(Self.ProcH, Pointer(Address), @Value, SizeOf(Value), trash);
  end;
end;

function TProcMem.GetModuleBaseAddress(lpModName: PChar): Pointer;
var
  hSnap: cardinal;
  tm: TModuleEntry32;
begin
  Result := Pointer(0);
  hSnap := CreateToolHelp32Snapshot(TH32CS_SNAPMODULE, Self.ProcId);
  if hSnap <> 0 then
  begin
    tm.dwSize := sizeof(TModuleEntry32);
    if Module32First(hSnap, tm) = True then
    begin
      while Module32Next(hSnap, tm) = True do
      begin
        if lstrcmpi(tm.szModule, lpModName) = 0 then
        begin
          Result := Pointer(tm.modBaseAddr);
          break;
        end;
      end;
    end;
    CloseHandle(hSnap);
  end;
end;

end.
