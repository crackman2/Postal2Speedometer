unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, Windows,

  { custom }
  CProcMem, CPlayer, CustomTypes;

type

  { TFormOverlay }

  TFormOverlay = class(TForm)
    LabelCounter: TLabel;
    TimerUpdateObjects: TTimer;
    TimerUpdatePointers: TTimer;
    TimerUpdateSpeed: TTimer;

    procedure FormCreate(Sender: TObject);
    procedure TimerUpdateObjectsTimer(Sender: TObject);
    procedure TimerUpdateSpeedTimer(Sender: TObject);
    procedure TimerUpdatePointersTimer(Sender: TObject);
    procedure InitHandles();
  private
    ProcMem: TProcMem;
    Player: TPlayer;
  public

  end;

var
  FormOverlay: TFormOverlay;
  FirstTimeSetUp: boolean = True;

implementation

{$R *.lfm}

{ TFormOverlay }

procedure TFormOverlay.TimerUpdateSpeedTimer(Sender: TObject);
var
  TotalVelocity: single = 0;
  hWin: HWND = 0;
begin
  hWin := FindWindow(nil, 'POSTAL 2');
  if (hWin <> 0) and (GetForegroundWindow() = hWin) then
  begin
    if Assigned(Player) then
    begin
      Player.GetVelocity();
      TotalVelocity := Sqrt(Sqr(Player.vel.x) + Sqr(Player.vel.y));
      if TotalVelocity <> 0 then TotalVelocity := Round(TotalVelocity);

      //digit is 25px wide
      LabelCounter.Caption := FloatToStr(TotalVelocity);

      LabelCounter.Left := (Self.Width div 2) -
        ((25 div 2) * (Length(FloatToStr(TotalVelocity))));

      LabelCounter.Alignment := taCenter;
      LabelCounter.Layout := tlCenter;
    end
    else
    begin
      LabelCounter.Caption := '';
      TimerUpdateSpeed.Enabled := False;
      InitHandles();
    end;
  end
  else
  begin
    LabelCounter.Caption := '';
    TimerUpdateSpeed.Enabled := False;
    InitHandles();
  end;
end;

procedure TFormOverlay.TimerUpdatePointersTimer(Sender: TObject);
var
  rect: TRect;
  hwin: HWND = 0;
begin
  hwin := FindWindow(nil, 'POSTAL 2');

  if hwin <> 0 then
  begin
    if Assigned(Player) then Player.InitLocalPlayerAddresses()
    else
    begin
      TimerUpdateSpeed.Enabled := False;
      InitHandles();
    end;

    GetWindowRect(hwin, rect);
    Self.Top := rect.Top;
    Self.Left := rect.Left;
    Self.Width := rect.Right - rect.Left;
    Self.Height := rect.Bottom - rect.Top;


    LabelCounter.Top := Self.Height - (longint(Self.Height) div 2);
    LabelCounter.Left := Self.Width div 2;
  end
  else
  begin
    LabelCounter.Caption := '';
    TimerUpdateSpeed.Enabled := False;
    InitHandles();
  end;
end;

procedure TFormOverlay.InitHandles;
begin
  if not FirstTimeSetUp then
  begin
    ProcMem.Free;
    ProcMem := nil;
    Player.Free;
    Player := nil;
  end
  else
    FirstTimeSetUp := False;

  ProcMem := TProcMem.Create('POSTAL 2');

  if Assigned(ProcMem) and ProcMem.InitSuccess then
    Player := TPlayer.Create(ProcMem);

  if Assigned(Player) then TimerUpdateSpeed.Enabled := True;

end;


procedure TFormOverlay.FormCreate(Sender: TObject);
var
  style: longint;
begin
  { --------------------------- Set Window Style --------------------------- }
  { -> must be transparent, use color key                                    }
  SetLayeredWindowAttributes(Handle, clSilver, 0, ULW_COLORKEY);
  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or
    SWP_NOSIZE or SWP_NOACTIVATE);
  style := GetWindowLong(Handle, GWL_EXSTYLE);
  style := style or WS_EX_TOPMOST or WS_EX_NOACTIVATE or WS_EX_TRANSPARENT;
  SetWindowLong(Handle, GWL_EXSTYLE, style);


  InitHandles();
end;

procedure TFormOverlay.TimerUpdateObjectsTimer(Sender: TObject);
begin
  if FindWindow(nil, 'POSTAL 2') = 0 then
  begin
    LabelCounter.Caption := '';
    TimerUpdateSpeed.Enabled := False;
    InitHandles();
  end;
end;



end.
