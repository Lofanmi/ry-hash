unit unithumanate;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Math, DateUtils;

function IBytes(s: uint64): string;

implementation

function LogN(n, b: double): double;
begin
  Result := Ln(n) / Ln(b);
end;

function HumanateBytes(s: uint64; base: double; sizes: array of string): string;
var
  e: integer;
  suffix: string;
  val: double;
  f: string;
begin
  if s < 10 then
    Exit(Format('%d B', [s]));

  e := Floor(LogN(s, base));
  if (e < 0) or (e >= Length(sizes)) then
    Exit('Invalid size');

  suffix := sizes[e];
  val := Floor((double(s) / Power(base,double(e)) * 10 + 0.5)) / 10;

  if val < 10 then
    f := '%.1f %s'
  else
    f := '%.0f %s';

  Result := Format(f, [val, suffix]);
end;

function IBytes(s: uint64): string;
const
  Sizes: array[0..6] of string = ('B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB');
begin
  Result := HumanateBytes(s, 1024, Sizes);
end;

end.
