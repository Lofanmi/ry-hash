unit unitthread;

{$mode objfpc}{$H+}

interface

uses
  {$ifdef unix}
  cthreads,
  cmem, // the c memory manager is on some systems much faster for multi-threading
  {$endif}
  Classes, SysUtils,
  Generics.Collections,
  unithash, unittime;

type
  TThreadHashTask = record
    Config: HashAlgConfig;
    Filename: string;
    HashResult: HashResult;
    HashResultHander: procedure(const AHashResult: HashResult;
      const AHashConfig: HashAlgConfig) of object;
  end;
  PThreadHashTask = ^TThreadHashTask;

type
  TListThreadHashTask = specialize TList<TThreadHashTask>;

type
  TTaskQueue = class
  private
    FQueue: TListThreadHashTask;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const ATask: TThreadHashTask);
    function Get(var ATask: TThreadHashTask): boolean;
  end;

type
  { TThreadHash }
  TThreadHash = class(TThread)
  private
    FTaskQueue: TTaskQueue;
    FCurrentPThreadHashTask: PThreadHashTask;
    FCurrentFileHash: TFileHash;
    FCurrentGetTaskResult: boolean;
    procedure GetTask;
    procedure FreeTask;
    procedure HandleHashResult;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
    function Hash(const ATask: TThreadHashTask): boolean;
    function Percentage: integer;
    procedure FileHashStop;
    function CurrentGetTaskResult: boolean;
  end;

implementation

{ TTaskQueue }
constructor TTaskQueue.Create;
begin
  inherited Create;
  FQueue := TListThreadHashTask.Create;
end;

destructor TTaskQueue.Destroy;
begin
  FreeAndNil(FQueue);
  inherited Destroy;
end;

procedure TTaskQueue.Add(const ATask: TThreadHashTask);
begin
  FQueue.Add(ATask);
end;

function TTaskQueue.Get(var ATask: TThreadHashTask): boolean;
begin
  Result := False;
  if FQueue.Count > 0 then
  begin
    ATask := FQueue[0];
    FQueue.Delete(0);
    Result := True;
  end;
end;

{ TThreadHash }
constructor TThreadHash.Create;
begin
  FTaskQueue := TTaskQueue.Create;
  inherited Create(False);
end;

destructor TThreadHash.Destroy;
begin
  FreeAndNil(FTaskQueue);
  inherited Destroy;
end;

function TThreadHash.Hash(const ATask: TThreadHashTask): boolean;
begin
  FTaskQueue.Add(ATask);
  Result := True;
end;

procedure TThreadHash.GetTask;
var
  ATask: TThreadHashTask;
begin
  FCurrentGetTaskResult := FTaskQueue.Get(ATask);
  if FCurrentGetTaskResult then
  begin
    FCurrentPThreadHashTask := New(PThreadHashTask);
    FCurrentPThreadHashTask^.Config := ATask.Config;
    FCurrentPThreadHashTask^.Filename := ATask.Filename;
    FCurrentPThreadHashTask^.HashResultHander := ATask.HashResultHander;
    FCurrentFileHash := TFileHash.Create(ATask.Filename);
  end;
end;

procedure TThreadHash.FreeTask;
begin
  if Assigned(FCurrentPThreadHashTask) then
    Dispose(FCurrentPThreadHashTask);
  FCurrentPThreadHashTask := nil;
  FCurrentGetTaskResult := False;
  if Assigned(FCurrentFileHash) then
    FreeAndNil(FCurrentFileHash);
end;

procedure TThreadHash.HandleHashResult;
begin
  if Assigned(FCurrentPThreadHashTask) then
  begin
    FCurrentPThreadHashTask^.HashResultHander(FCurrentPThreadHashTask^.HashResult,
      FCurrentPThreadHashTask^.Config);
  end;
end;

function TThreadHash.Percentage: integer;
begin
  if Assigned(FCurrentPThreadHashTask) and Assigned(FCurrentFileHash) then
  begin
    Result := FCurrentFileHash.Percentage;
  end;
end;

procedure TThreadHash.FileHashStop;
begin
  if Assigned(FCurrentPThreadHashTask) and Assigned(FCurrentFileHash) then
  begin
    FCurrentFileHash.Stop;
  end;
end;

function TThreadHash.CurrentGetTaskResult: boolean;
begin
  Result := FCurrentGetTaskResult;
end;

procedure TThreadHash.Execute;
begin
  while not Terminated do
  begin
    Synchronize(@GetTask);
    try
      if FCurrentGetTaskResult then
      begin
        FCurrentFileHash.Hash(FCurrentPThreadHashTask^.Config,
          FCurrentPThreadHashTask^.HashResult);
        Synchronize(@HandleHashResult);
      end
      else
        Sleep(10);
    finally
      Synchronize(@FreeTask);
    end;
  end;
end;

end.
