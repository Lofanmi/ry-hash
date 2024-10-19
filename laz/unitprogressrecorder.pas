unit unitprogressrecorder;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Math, SyncObjs;

type
  IProgressRecorder = interface(IInterface)
    ['{71E911B1-FD68-5A9A-87FD-AD122870D261}']
    procedure Reset;
    procedure Inc(step: integer);
    function Percentage: integer;
  end;

  TProgressRecorder = class(TInterfacedObject, IProgressRecorder)
  private
    FTotal: int64;
    FCurrent: int64;
    FCriticalSection: TCriticalSection;
  public
    constructor Create(ATotal: int64);
    destructor Destroy; override;
    procedure Reset;
    procedure Inc(step: integer);
    function Percentage: integer;
  end;

implementation

constructor TProgressRecorder.Create(ATotal: int64);
begin
  FTotal := ATotal;
  FCurrent := 0;
  FCriticalSection := TCriticalSection.Create;
  inherited Create;
end;

destructor TProgressRecorder.Destroy;
begin
  FreeAndNil(FCriticalSection);
  inherited Destroy;
end;

procedure TProgressRecorder.Reset;
begin
  FCriticalSection.Enter;
  try
    FCurrent := 0;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TProgressRecorder.Inc(step: integer);
begin
  FCriticalSection.Enter;
  try
    FCurrent := FCurrent + step;
  finally
    FCriticalSection.Leave;
  end;
end;

function TProgressRecorder.Percentage: integer;
var
  Pct: double;
begin
  FCriticalSection.Enter;
  try
    if FTotal = 0 then
      Pct := 0.0
    else
      Pct := (FCurrent / FTotal) * 100.0;
    Result := Round(Pct);
  finally
    FCriticalSection.Leave;
  end;
end;

end.
