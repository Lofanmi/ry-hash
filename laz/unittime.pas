unit unittime;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, Windows;

type
  TTimeSpec = record
    Sec: int64;
    Nsec: int64;
  end;

  TTimeUnit = record
    Name: string;
    Factor: int64;
  end;

function GetHighPrecisionTimestamp: TTimeSpec;
function TimeSince(start: TTimeSpec): TTimeSpec;
function FormatTimeSpan(const TimeSpan: TTimeSpec): string;

implementation

// 目前只支持 Windows，其他平台还没实现。
function GetHighPrecisionTimestamp: TTimeSpec;
var
  Freq, Counter: int64;
begin
  if QueryPerformanceFrequency(Freq) then
  begin
    if QueryPerformanceCounter(Counter) then
    begin
      Result.Sec := Counter div Freq;
      Result.Nsec := (Counter mod Freq) * 1000000000 div Freq;
    end
    else
    begin
      Result.Sec := -1;
      Result.Nsec := -1;
    end;
  end
  else
  begin
    Result.Sec := -1;
    Result.Nsec := -1;
  end;
end;

function TimeSince(start: TTimeSpec): TTimeSpec;
var
  EndTime: TTimeSpec;
begin
  EndTime := GetHighPrecisionTimestamp;

  Result.Sec := EndTime.Sec - start.Sec;
  Result.Nsec := EndTime.Nsec - start.Nsec;

  if Result.Nsec < 0 then
  begin
    Dec(Result.Sec);
    Inc(Result.Nsec, 1000000000);
  end;
end;

var
  Units: array[0..5] of TTimeUnit;

procedure InitializeUnits;
begin
  Units[0].Name := 'ns';
  Units[0].Factor := 1;
  Units[1].Name := 'µs';
  Units[1].Factor := 1000;
  Units[2].Name := 'ms';
  Units[2].Factor := 1000000;
  Units[3].Name := 's';
  Units[3].Factor := 1000000000;
  Units[4].Name := 'm';
  Units[4].Factor := 60000000000;
  Units[5].Name := 'h';
  Units[5].Factor := 3600000000000;
end;

function FormatTimeSpan(const TimeSpan: TTimeSpec): string;
var
  TotalNsec: int64;
  i: integer;
  Value: double;
  UnitName: string;
begin
  TotalNsec := TimeSpan.Sec * 1000000000 + TimeSpan.Nsec;

  for i := High(Units) downto Low(Units) do
  begin
    if TotalNsec >= Units[i].Factor then
    begin
      Value := TotalNsec / Units[i].Factor;
      UnitName := Units[i].Name;
      Break;
    end;
  end;

  if i = Low(Units) then
    Result := Format('%.0f %s', [Value, UnitName])
  else
    Result := Format('%.2f %s', [Value, UnitName]);
end;

initialization
  InitializeUnits;

end.
