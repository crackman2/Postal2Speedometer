unit CPlayer;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Windows,

  { custom }

  CustomTypes, CProcMem;

type

  { TPlayer }

  TPlayer = class
  public
    InitSuccess: boolean;

    pos: RVec3;
    vel: RVec3;
    cam: RVec2;
    camalt: RVec2;
    camflip: boolean;

    onground: byte;



    constructor Create(ProcMem: TProcMem);
    procedure GetPosition();
    procedure GetVelocity();
    procedure GetOnGround();
    procedure GetAngles();

    procedure PointVelocityInCameraDirection();

    procedure SetVelocity(dir: byte);
    procedure SetOnGround();
    procedure GetAll();


    procedure InitLocalPlayerAddresses();

  private
    ProcMem: TProcMem;

    EngineDLLBase: DWORD;
    FPSGameDLLBase: DWORD;

    LocalPlayerBase: DWORD;

    camx: word;
    FirstTimeInit: boolean;



  const
    { --- offsets to find the player --- }
    offset_Engine: DWORD = $4CFF28;
    offset_LocalPlayer: array [0..5] of DWORD = ($2C, $58, $10, $144, $8C, $0);

    { ---- offsets from player base ---- }
    offset_posx: DWORD = $E0;
    offset_posy: DWORD = $E4;
    offset_posz: DWORD = $E8;

    offset_velx: DWORD = $F8;
    offset_vely: DWORD = $FC;
    offset_velz: DWORD = $100;

    offset_camx: DWORD = $450;

    offset_onground: DWORD = $3C;

    { --------- code injection --------- }
    // FPSGame.DLL+AB8A - 66 0FD6 16            - movq [esi],xmm2       Spack
    // FPSGame.DLL+B036 - F3 0F11 06            - movss [esi],xmm0      Spack 2
    // FPSGame.DLL+AB8A - 66 0FD6 16            - movq [esi],xmm2       low risk
    offset_Spack1: DWORD = $AB8A;
    originalSpack1: array [0..3] of byte = ($66, $0F, $D6, $16);
    offset_Spack2: DWORD = $B036;
    originalSpack2: array [0..3] of byte = ($F3, $0F, $11, $06);

    // Engine.dll.text+229BD0 - F3 0F10 83 C8020000   - movss xmm0,[ebx+000002C8] //max speed
    bytesmaxspeed: array [0..1] of array of DWORD = (
      ($22ABD0, $F3, $0F, $10, $83, $C8, $02, $00, $00), //original
      ($22ABD0, $F3, $0F, $10, $83, $D8, $02, $00, $00)  //modified
      );


    { --------- constant value --------- }
    maxspeed: single = 2000;


  end;




implementation

constructor TPlayer.Create(ProcMem: TProcMem);
begin
  Self.ProcMem := ProcMem;

  Self.pos := RVec3_Create(0, 0, 0);
  Self.vel := RVec3_Create(0, 0, 0);
  Self.cam := RVec2_Create(0, 0);

  FirstTimeInit := True;

  InitLocalPlayerAddresses();
end;

procedure TPlayer.GetPosition;
begin
  pos.x := ProcMem.rpmf(LocalPlayerBase + offset_posx);
  pos.y := ProcMem.rpmf(LocalPlayerBase + offset_posy);
  pos.z := ProcMem.rpmf(LocalPlayerBase + offset_posz);
end;

procedure TPlayer.GetVelocity;
begin
  vel.x := ProcMem.rpmf(LocalPlayerBase + offset_velx);
  vel.y := ProcMem.rpmf(LocalPlayerBase + offset_vely);
  vel.z := ProcMem.rpmf(LocalPlayerBase + offset_velz);
end;

procedure TPlayer.GetOnGround;
begin
  onground := ProcMem.rpmb(LocalPlayerBase + offset_onground);
end;

procedure TPlayer.GetAngles;
begin
  camx := ProcMem.rpmw(LocalPlayerBase + offset_camx);
  cam.x := camx / 182.04444444444;
  cam.x := cam.x * (3.1415926535 / 180);  //convert to radians
end;

procedure TPlayer.PointVelocityInCameraDirection;
var
  velocityMagnitude: single = 0;
  normalizedVX: single = 0;
  normalizedVY: single = 0;
  dotProduct: single = 0;
  dirAngleX: single = 0;
  dirAngleY: single = 0;
begin
  dirAngleX := cos(cam.x);
  dirAngleY := sin(cam.x);



  velocityMagnitude := Sqrt((vel.x * vel.x) + (vel.y * vel.y));

  if velocityMagnitude <> 0 then
  begin
    normalizedVX := vel.x / velocityMagnitude;
    normalizedVY := vel.y / velocityMagnitude;

    dotProduct := dirAngleX * normalizedVX + dirAngleY * normalizedVY;

    vel.x := dotProduct * dirAngleX * velocityMagnitude;
    vel.y := dotProduct * dirAngleY * velocityMagnitude;


    velocityMagnitude := Sqrt((vel.x * vel.x) + (vel.y * vel.y));

    if velocityMagnitude > maxspeed then
    begin
      vel.x := normalizedVX * maxspeed;
      vel.y := normalizedVY * maxspeed;

      velocityMagnitude := Sqrt((vel.x * vel.x) + (vel.y * vel.y));

    end;
  end;
end;

procedure TPlayer.SetVelocity(dir: byte);
var
  mask_X: byte = $01;
  mask_Y: byte = $02;
  mask_Z: byte = $04;
begin
  if (dir and mask_X) <> 0 then ProcMem.wpmf(LocalPlayerBase + offset_velx, vel.x);
  if (dir and mask_Y) <> 0 then ProcMem.wpmf(LocalPlayerBase + offset_vely, vel.y);
  if (dir and mask_Z) <> 0 then ProcMem.wpmf(LocalPlayerBase + offset_velz, vel.z);
end;

procedure TPlayer.SetOnGround;
begin
  ProcMem.wpmb(LocalPlayerBase + offset_onground, onground);
end;

procedure TPlayer.GetAll;
begin
  GetPosition();
  GetVelocity();
  GetOnGround();
  GetAngles();
end;

procedure TPlayer.InitLocalPlayerAddresses();
var
  i: cardinal;
  old: DWORD = 0;
begin
  try
    if FirstTimeInit then
    begin
      EngineDllBase := 0;
      EngineDLLBase := DWORD(ProcMem.GetModuleBaseAddress('Engine.dll'));
      //EngineDLLBase := DWORD(GetModuleHandle('Engine.dll'));

      { --- for code injection --- }
      FPSGameDLLBase := DWORD(ProcMem.GetModuleBaseAddress('FPSGame.DLL'));
      VirtualProtect(Pointer(FPSGameDLLBase + offset_Spack1), 4, PAGE_EXECUTE_READWRITE, old);
      VirtualProtect(Pointer(FPSGameDLLBase + offset_Spack2), 4, PAGE_EXECUTE_READWRITE, old);
      VirtualProtect(Pointer(EngineDLLBase + bytesmaxspeed[0, 0]), 12,
        PAGE_EXECUTE_READWRITE, old);

      FirstTimeInit := False;
    end;

    if (EngineDLLBase <> 0) and Assigned(Pointer(EngineDLLBase)) then
    begin
      LocalPlayerBase := EngineDLLBase + offset_Engine;
      for i := 0 to High(offset_LocalPlayer) do
      begin
        if Assigned(Pointer(ProcMem.rpmd(LocalPlayerBase))) then
        begin
          LocalPlayerBase := ProcMem.rpmd(LocalPlayerBase);
          LocalPlayerBase += offset_LocalPlayer[i];
        end
        else
          break;
      end;
      //WriteLn('LocalPlayerBase: ' + IntToHex(LocalPlayerBase,8));
    end
    else
    begin
      FirstTimeInit := True;
    end;
  finally

  end;
end;


end.
