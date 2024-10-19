unit unithash;

{$mode objfpc}{$H+}

{$OVERFLOWCHECKS OFF}
{$RANGECHECKS OFF}

interface

uses
  Classes, SysUtils, HlpIHash, HlpIHashResult, HlpHashLibTypes, HlpHash,
  HlpIHashInfo, HlpHashResult,
  unitprogressrecorder, unittime, unithumanate;

type
  TFNV32offset32 = class sealed(THash, IHash32, ITransformBlock)
  strict private
  var
    FHash: uint32;
  public
    constructor Create();
    procedure Initialize(); override;
    procedure TransformBytes(const AData: THashLibByteArray;
      AIndex, ALength: int32); override;
    function TransformFinal(): IHashResult; override;
    function Clone(): IHash; override;
  end;

  TFNV64offset64 = class sealed(THash, IHash64, ITransformBlock)
  strict private
  var
    FHash: uint64;
  public
    constructor Create();
    procedure Initialize(); override;
    procedure TransformBytes(const AData: THashLibByteArray;
      AIndex, ALength: int32); override;
    function TransformFinal(): IHashResult; override;
    function Clone(): IHash; override;
  end;

type
  HashAlg = record
    Name: string;
    Hash: IHash;
  end;

  TArrayHashAlg = specialize TArray<HashAlg>;

  HashAlgConfig = record
    Name: string;
    Hash: IHash;
    Enabled: boolean;
  end;

  HashResult = record
    FileName: string;
    HumanizeFileSize: string;
    FileSize: int64;
    ModTime: string;
    HashName: string;
    HumanizeDuration: string;
    HumanizeSpeed: string;
    Hash: string;
  end;

type
  TFileHash = class
  private
    FFilename: string;
    FFile: TFileStream;
    FFileInfo: TSearchRec;
    FProgressRecorder: TProgressRecorder;
    FStopped: boolean;
    procedure SetStopped(Value: boolean);
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;
    procedure Stop;
    function Percentage: integer;
    procedure Hash(const AHashConfig: HashAlgConfig; var res: HashResult);
    property Stopped: boolean read FStopped write SetStopped;
  end;

implementation

const
  offset32 = 2166136261;
  offset64 = 14695981039346656037;

{ TFNV32offset32 }
function TFNV32offset32.Clone(): IHash;
var
  LHashInstance: TFNV32offset32;
begin
  LHashInstance := TFNV32offset32.Create();
  LHashInstance.FHash := FHash;
  Result := LHashInstance as IHash;
  Result.BufferSize := BufferSize;
end;

constructor TFNV32offset32.Create;
begin
  inherited Create(4, 1);
end;

procedure TFNV32offset32.Initialize;
begin
  FHash := offset32;
end;

procedure TFNV32offset32.TransformBytes(const AData: THashLibByteArray;
  AIndex, ALength: int32);
var
  LIdx: int32;
begin
  {$IFDEF DEBUG}
    System.Assert(AIndex >= 0);
    System.Assert(ALength >= 0);
    System.Assert(AIndex + ALength <= System.Length(AData));
  {$ENDIF DEBUG}
  LIdx := AIndex;
  while ALength > 0 do
  begin
    FHash := (FHash * 16777619) xor AData[LIdx];
    System.Inc(LIdx);
    System.Dec(ALength);
  end;
end;

function TFNV32offset32.TransformFinal: IHashResult;
begin
  Result := THashResult.Create(FHash);
  Initialize();
end;

{ TFNV64offset64 }
function TFNV64offset64.Clone(): IHash;
var
  LHashInstance: TFNV64offset64;
begin
  LHashInstance := TFNV64offset64.Create();
  LHashInstance.FHash := FHash;
  Result := LHashInstance as IHash;
  Result.BufferSize := BufferSize;
end;

constructor TFNV64offset64.Create;
begin
  inherited Create(8, 1);
end;

procedure TFNV64offset64.Initialize;
begin
  FHash := offset64;
end;

procedure TFNV64offset64.TransformBytes(const AData: THashLibByteArray;
  AIndex, ALength: int32);
var
  LIdx: int32;
begin
  {$IFDEF DEBUG}
  System.Assert(AIndex >= 0);
  System.Assert(ALength >= 0);
  System.Assert(AIndex + ALength <= System.Length(AData));
  {$ENDIF DEBUG}
  LIdx := AIndex;
  while ALength > 0 do
  begin
    FHash := uint64(FHash * uint64(1099511628211)) xor AData[LIdx];
    System.Inc(LIdx);
    System.Dec(ALength);
  end;
end;

function TFNV64offset64.TransformFinal: IHashResult;
begin
  Result := THashResult.Create(FHash);
  Initialize();
end;

{ TFileHash }
constructor TFileHash.Create(const AFileName: string);
var
  SearchCode: integer;
begin
  inherited Create;
  FFilename := AFileName;
  SearchCode := FindFirst(AFileName, faAnyFile, FFileInfo);
  if SearchCode <> 0 then
    raise Exception.CreateFmt('文件不存在: %s', [AFileName]);
  FFile := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  FProgressRecorder := TProgressRecorder.Create(FFileInfo.Size);
end;

destructor TFileHash.Destroy;
begin
  FreeAndNil(FFile);
  FreeAndNil(FProgressRecorder);
  inherited Destroy;
end;

procedure TFileHash.SetStopped(Value: boolean);
begin
  FStopped := Value; // 需要改原子操作，但是包好像没有这个函数。
end;

procedure TFileHash.Stop;
begin
  SetStopped(True);
end;

function TFileHash.Percentage: integer;
begin
  Result := FProgressRecorder.Percentage;
end;

procedure TFileHash.Hash(const AHashConfig: HashAlgConfig; var res: HashResult);
var
  Buffer: TBytes;
  BytesRead: integer;
  t, t2: TTimeSpec;
begin
  res.FileName := FFilename;
  res.HumanizeFileSize := IBytes(uint64(FFileInfo.Size));
  res.FileSize := FFileInfo.Size;
  res.ModTime := FormatDateTime('yyyy-mm-dd hh:nn:ss', FFileInfo.TimeStamp);
  res.HashName := AHashConfig.Name;

  Buffer := nil;
  SetLength(Buffer, 1 * 1024 * 1024); // 1MB buffer
  FFile.Seek(0, soBeginning);
  AHashConfig.Hash.Initialize;
  FProgressRecorder.Reset;

  t := GetHighPrecisionTimestamp;
  while not FStopped and (FFile.Position < FFile.Size) do
  begin
    BytesRead := FFile.Read(Buffer[0], Length(Buffer));
    AHashConfig.Hash.TransformBytes(Buffer, 0, BytesRead);
    FProgressRecorder.Inc(BytesRead);
  end;
  t2 := TimeSince(t);

  res.HumanizeDuration := FormatTimeSpan(t2);
  res.HumanizeSpeed := IBytes(uint64(Trunc(double(FFileInfo.Size) /
    double(t2.Sec + t2.Nsec / 1000000000))));

  if FStopped then
    res.Hash := '(用户中止计算)'
  else
    res.Hash := LowerCase(AHashConfig.Hash.TransformFinal.ToString);
end;

end.
