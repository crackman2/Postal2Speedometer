unit CustomTypes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

{ ------------------------------ Custom Types ------------------------------ }
{ -> commonly used types should get their own unit                           }


type
  RVec3 = record
    x: single;
    y: single;
    z: single;
  end;



  PRVec3 = ^RVec3;

  RVec2i = record
    x: integer;
    y: integer;
  end;
  MVPmatrix = array[0..15] of single;

  RVec4 = record
    x: single;
    y: single;
    z: single;
    w: single;
  end;

  RVec2 = record
    x: single;
    y: single;
  end;

  RDoubleVec3 = record
    Base: RVec3;
    Tip: RVec3;
  end;

operator -(const a, b: RVec3): RVec3;
operator +(const a, b: RVec3): RVec3;
function RVec3_Create(x, y, z: single): RVec3;
function RVec2_Create(x, y: single): RVec2;
function RVec4_Create(x, y, z, w: single): RVec4;
function RVec2i_Create(x, y: integer): RVec2i;
function RDoubleVec3_Create(Base, Tip: RVec3): RDoubleVec3;
function RVec2_Dist(vec1:RVec2; vec2:RVec2): Single;


implementation

operator -(const a, b: RVec3): RVec3;
begin
  Result.x := a.x - b.x;
  Result.y := a.y - b.y;
  Result.z := a.z - b.z;
end;

operator +(const a, b: RVec3): RVec3;
begin
  Result.x := a.x + b.x;
  Result.y := a.y + b.y;
  Result.z := a.z + b.z;
end;


function RVec3_Create(x, y, z: single): RVec3;
begin
  Result.x := x;
  Result.y := y;
  Result.z := z;
end;

function RVec2_Create(x, y: single): RVec2;
begin
  Result.x := x;
  Result.y := y;
end;

function RVec4_Create(x, y, z, w: single): RVec4;
begin
  Result.x := x;
  Result.y := y;
  Result.z := z;
  Result.w := w;
end;

function RVec2i_Create(x, y: integer): RVec2i;
begin
  Result.x := x;
  Result.y := y;
end;

function RDoubleVec3_Create(Base, Tip: RVec3): RDoubleVec3;
begin
  Result.Base := Base;
  Result.Tip := Tip;
end;

function RVec2_Dist(vec1: RVec2; vec2: RVec2): Single;
begin
  Result:=Sqrt(
               Sqr(vec1.x - vec2.x)  +
               Sqr(vec1.y - vec2.y)
  );
end;



end.

