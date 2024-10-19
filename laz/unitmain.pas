unit unitmain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  Generics.Collections, HlpHashFactory, Clipbrd, ExtCtrls,
  unitthread, unithash, unittime, unithumanate;

type
  TDictionaryStringProgressBar = specialize TDictionary<string, TProgressBar>;

type
  TDictionaryStringCheckBox = specialize TDictionary<string, TCheckBox>;

type
  TDictionaryStringThreadHash = specialize TDictionary<string, TThreadHash>;

type
  TDictionaryStringTFileHash = specialize TDictionary<string, TFileHash>;

type
  TDictionaryStringString = specialize TDictionary<string, string>;

type
  { TFormMain }
  TFormMain = class(TForm)
    ButtonBrowse: TButton;
    ButtonClear: TButton;
    ButtonCopy: TButton;
    ButtonSave: TButton;
    ButtonStop: TButton;
    ButtonAbout: TButton;
    MemoLogger: TMemo;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    TimerUpdatePosition: TTimer;
    procedure ButtonAboutClick(Sender: TObject);
    procedure ButtonBrowseClick(Sender: TObject);
    procedure ButtonClearClick(Sender: TObject);
    procedure ButtonCopyClick(Sender: TObject);
    procedure ButtonSaveClick(Sender: TObject);
    procedure ButtonStopClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
    procedure TimerUpdatePositionTimer(Sender: TObject);
  private
    MapProgressBar: TDictionaryStringProgressBar;
    MapCheckBox: TDictionaryStringCheckBox;
    MapThreadHash: TDictionaryStringThreadHash;
    MapHashStringRes: TDictionaryStringString;
    ProgressBarFinish: TProgressBar;
    LabelFinish: TLabel;
    Stopped: boolean;
    procedure InitHashAlgConfigList;
    procedure InitComponents;
    function HashAlgList: TArrayHashAlg;
    procedure ResetProgressBar;
    procedure HashFileList(const AFileList: array of string);
    procedure HashFile(const AFilename: string; const AHashAlgList: TArrayHashAlg);
    procedure HashResultHander(const AHashResult: HashResult;
      const AHashConfig: HashAlgConfig);
    procedure ShowResult(const AFilename: string; const t2: TTimeSpec;
      const Res: TDictionaryStringString);
  public

  end;

var
  FormMain: TFormMain;
  HashAlgConfigList: array of HashAlgConfig;

implementation

{$R *.lfm}

{ TFormMain }
procedure TFormMain.InitHashAlgConfigList;
begin
  SetLength(HashAlgConfigList, 11);

  HashAlgConfigList[0].Name := 'crc32';
  HashAlgConfigList[0].Hash := THashFactory.TChecksum.TCRC.CreateCRC32_PKZIP();
  HashAlgConfigList[0].Enabled := True;

  HashAlgConfigList[1].Name := 'md5';
  HashAlgConfigList[1].Hash := THashFactory.TCrypto.CreateMD5;
  HashAlgConfigList[1].Enabled := True;

  HashAlgConfigList[2].Name := 'sha1';
  HashAlgConfigList[2].Hash := THashFactory.TCrypto.CreateSHA1;
  HashAlgConfigList[2].Enabled := True;

  HashAlgConfigList[3].Name := 'sha256';
  HashAlgConfigList[3].Hash := THashFactory.TCrypto.CreateSHA2_256;
  HashAlgConfigList[3].Enabled := True;

  HashAlgConfigList[4].Name := 'sha512';
  HashAlgConfigList[4].Hash := THashFactory.TCrypto.CreateSHA2_512;
  HashAlgConfigList[4].Enabled := False;

  HashAlgConfigList[5].Name := 'fnv1/32';
  HashAlgConfigList[5].Hash := TFNV32offset32.Create;
  HashAlgConfigList[5].Enabled := False;

  HashAlgConfigList[6].Name := 'fnv1a/32';
  HashAlgConfigList[6].Hash := THashFactory.THash32.CreateFNV1a;
  HashAlgConfigList[6].Enabled := False;

  HashAlgConfigList[7].Name := 'fnv1/64';
  HashAlgConfigList[7].Hash := TFNV64offset64.Create;
  HashAlgConfigList[7].Enabled := False;

  HashAlgConfigList[8].Name := 'fnv1a/64';
  HashAlgConfigList[8].Hash := THashFactory.THash64.CreateFNV1a;
  HashAlgConfigList[8].Enabled := False;

  HashAlgConfigList[9].Name := 'fnv1/128';
  HashAlgConfigList[9].Hash := THashFactory.THash64.CreateFNV;
  HashAlgConfigList[9].Enabled := False;

  HashAlgConfigList[10].Name := 'fnv1a/128';
  HashAlgConfigList[10].Hash := THashFactory.THash64.CreateFNV1a;
  HashAlgConfigList[10].Enabled := False;
end;

procedure TFormMain.InitComponents;
var
  topProgressBar, topCheckBox, step: integer;
  pb: TProgressBar;
  cb: TCheckBox;
  config: HashAlgConfig;
  ratio: integer;
begin
  ratio := trunc(DesignTimePPI / 96);
  Constraints.MinHeight := 0;
  Constraints.MaxHeight := 0;
  MapProgressBar := TDictionaryStringProgressBar.Create;
  MapCheckBox := TDictionaryStringCheckBox.Create;
  MapThreadHash := TDictionaryStringThreadHash.Create;
  MapHashStringRes := TDictionaryStringString.Create;
  topProgressBar := ratio * 212;
  topCheckBox := ratio * 205;
  step := ratio * 20;
  for config in HashAlgConfigList do
  begin
    pb := TProgressBar.Create(self);
    pb.Parent := self;
    pb.Min := 0;
    pb.Max := 100;
    pb.Height := ratio * 8;
    pb.Width := ratio * 395;
    pb.Left := ratio * 12;
    pb.Top := topProgressBar;
    topProgressBar := topProgressBar + step;

    cb := TCheckBox.Create(self);
    cb.Parent := self;
    cb.Caption := config.Name;
    cb.Left := ratio * 416;
    cb.Checked := config.Enabled;
    cb.Top := topCheckBox;
    topCheckBox := topCheckBox + step;

    MapProgressBar.Add(config.Name, pb);
    MapCheckBox.Add(config.Name, cb);
    MapThreadHash.Add(config.Name, TThreadHash.Create);
  end;
  // ProgressBarFinish
  ProgressBarFinish := TProgressBar.Create(self);
  ProgressBarFinish.Parent := self;
  ProgressBarFinish.Min := 0;
  ProgressBarFinish.Max := 100;
  ProgressBarFinish.Height := ratio * 8;
  ProgressBarFinish.Width := ratio * 395;
  ProgressBarFinish.Left := ratio * 12;
  ProgressBarFinish.Top := topProgressBar;
  // LabelFinish
  LabelFinish := TLabel.Create(self);
  LabelFinish.Parent := self;
  LabelFinish.Caption := '就绪';
  LabelFinish.Left := ratio * 416;
  LabelFinish.Top := topCheckBox;
  Height := Height + step * (1 + Length(hashAlgConfigList));
  Constraints.MinHeight := Height;
  Constraints.MaxHeight := Height;
end;

function TFormMain.HashAlgList: TArrayHashAlg;
var
  temp: TArrayHashAlg;
  config: HashAlgConfig;
  ok: boolean;
  cb: TCheckBox;
  alg: HashAlg;
begin
  Result := nil;
  temp := nil;
  for config in HashAlgConfigList do
  begin
    ok := MapCheckBox.TryGetValue(config.Name, cb);
    if ok and cb.Checked then
    begin
      alg.Name := config.Name;
      alg.Hash := config.Hash;
      SetLength(temp, Length(Result) + 1);
      if Length(Result) > 0 then
        Move(Result[Low(Result)], temp[Low(temp)], Length(Result) * SizeOf(integer));
      temp[High(temp)] := alg;
      Result := temp;
    end;
  end;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  InitHashAlgConfigList;
  InitComponents;
  ButtonStop.Enabled := False;
end;

procedure TFormMain.FormDropFiles(Sender: TObject; const FileNames: array of string);
begin
  HashFileList(FileNames);
end;

procedure TFormMain.ButtonBrowseClick(Sender: TObject);
begin
  if OpenDialog.Execute then
  begin
    HashFileList(OpenDialog.Files.ToStringArray);
  end;
end;

procedure TFormMain.ButtonAboutClick(Sender: TObject);
var
  s: string;
begin
  s := 'ryHash - 速度飞快的文件哈希工具 v1.0' + #13#10 +
    '作者博客: https://imlht.com' + #13#10 +
    '项目主页: https://github.com/Lofanmi/ry-hash' + #13#10 +
    '开发语言: Object Pascal' + #13#10 +
    '开发环境: 基于 Lazarus IDE v3.6 + FPC 3.2.2 编译';
  MessageDlg('关于', s, mtInformation, [mbOK], 0);
end;

procedure TFormMain.ButtonClearClick(Sender: TObject);
begin
  MemoLogger.Clear;
  ResetProgressBar;
end;

procedure TFormMain.ButtonCopyClick(Sender: TObject);
var
  t: string;
begin
  t := MemoLogger.Lines.Text;
  if t = '' then
  begin
    Exit;
  end;
  Clipboard.AsText := t;
  if Clipboard.AsText = t then
  begin
    MessageDlg('成功', '成功复制到剪切板！', mtInformation, [mbOK], 0);
    MemoLogger.SetFocus;
    MemoLogger.SelectAll;
  end;
end;

procedure TFormMain.ButtonSaveClick(Sender: TObject);
var
  Filename: string;
  FileStream: TFileStream;
  SaveResult: boolean;
  Message: string;
  t: string;
  L: longint;
begin
  t := MemoLogger.Lines.Text;
  if t = '' then
  begin
    Exit;
  end;
  if SaveDialog.Execute then
  begin
    Filename := SaveDialog.FileName;

    FileStream := TFileStream.Create(Filename, fmCreate);
    try
      L := Length(t);
      FileStream.WriteBuffer(Pointer(t)^, L);
      SaveResult := True;
    except
      on E: Exception do
      begin
        SaveResult := False;
        Message := Format('保存文件失败 [%s]！错误：%s',
          [Filename, E.Message]);
      end;
    end;
    FileStream.Free;
    if SaveResult then
    begin
      Message := Format('成功保存到文件 [%s]！', [Filename]);
      MessageDlg('成功', Message, mtInformation, [mbOK], 0);
    end
    else
    begin
      MessageDlg('失败', Message, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TFormMain.ButtonStopClick(Sender: TObject);
var
  kv: specialize TPair<string, TThreadHash>;
begin
  for kv in MapThreadHash do
  begin
    if kv.Value.CurrentGetTaskResult then
      kv.Value.FileHashStop;
  end;
end;

procedure TFormMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var
  kv: specialize TPair<string, TThreadHash>;
begin
  for kv in MapThreadHash do
  begin
    kv.Value.Terminate;
    kv.Value.Free;
  end;
  FreeAndNil(MapProgressBar);
  FreeAndNil(MapCheckBox);
  FreeAndNil(MapThreadHash);
  FreeAndNil(MapHashStringRes);
end;

procedure TFormMain.ResetProgressBar;
var
  bar: TProgressBar;
begin
  for bar in MapProgressBar.Values.ToArray do
  begin
    bar.Position := 0;
  end;
  ProgressBarFinish.Position := 0;
end;

procedure TFormMain.HashFileList(const AFileList: array of string);
var
  n, i, j: integer;
  step: double;
  hashAlgArray: TArrayHashAlg;
  t, t2: TTimeSpec;
begin
  ButtonStop.Enabled := True;
  Stopped := False;

  hashAlgArray := HashAlgList();
  n := Length(AFileList);

  step := double(100.0) / double(n);

  ResetProgressBar;

  TimerUpdatePosition.Enabled := True;
  j := 0;
  for i := High(AFileList) downto Low(AFileList) do
  begin
    MapHashStringRes.Clear;
    LabelFinish.Caption := Format('%d / %d', [j, n]);
    t := GetHighPrecisionTimestamp;
    HashFile(AFileList[i], hashAlgArray);
    while MapHashStringRes.Count < Length(hashAlgArray) do
    begin
      Application.ProcessMessages;
    end;
    t2 := TimeSince(t);
    ShowResult(AFileList[i], t2, MapHashStringRes);
    ProgressBarFinish.Position := ProgressBarFinish.Position + Trunc(step);
    j := j + 1;
  end;

  ProgressBarFinish.Position := ProgressBarFinish.Max;
  ButtonStop.Enabled := False;
  LabelFinish.Caption := '就绪';
  TimerUpdatePosition.Enabled := False;
  MapHashStringRes.Clear;
end;

procedure TFormMain.HashFile(const AFilename: string;
  const AHashAlgList: TArrayHashAlg);
var
  fileInfo: TSearchRec;
  find: integer;
  alg: HashAlg;
  task: TThreadHashTask;
begin
  find := FindFirst(AFileName, faAnyFile, fileInfo);
  if find <> 0 then
  begin
    ShowMessage('文件不存在: ' + AFileName);
    Exit;
  end;
  for alg in AHashAlgList do
  begin
    task.Config.Name := alg.Name;
    task.Config.Hash := alg.Hash;
    task.Filename := AFilename;
    task.HashResultHander := @HashResultHander;
    MapThreadHash.Items[alg.Name].Hash(task);
  end;
end;

procedure TFormMain.HashResultHander(const AHashResult: HashResult;
  const AHashConfig: HashAlgConfig);
var
  info: string;
begin
  info := Format('%s [elapsed=%s] [speed=%s/s]', [AHashResult.Hash,
    AHashResult.HumanizeDuration, AHashResult.HumanizeSpeed]);
  MapHashStringRes.Add(AHashConfig.Name, info);
  MapProgressBar.Items[AHashConfig.Name].Position :=
    MapProgressBar.Items[AHashConfig.Name].Max;
end;

procedure TFormMain.ShowResult(const AFilename: string; const t2: TTimeSpec;
  const Res: TDictionaryStringString);
var
  info, Value: string;
  FFileInfo: TSearchRec;
  hashAlgArray: TArrayHashAlg;
  alg: HashAlg;
begin
  FindFirst(AFileName, faAnyFile, FFileInfo);
  info := '';
  info := info + Format('文件: %s' + #13#10, [AFilename]);
  info := info + Format('大小: %s (%d 字节)' + #13#10,
    [IBytes(uint64(FFileInfo.Size)), FFileInfo.Size]);
  info := info + Format('修改时间: %s' + #13#10,
    [FormatDateTime('yyyy-mm-dd hh:nn:ss', FFileInfo.TimeStamp)]);
  hashAlgArray := HashAlgList;
  for alg in hashAlgArray do
  begin
    if Res.TryGetValue(alg.Name, Value) then
    begin
      info := info + Format('%s: %s' + #13#10, [alg.Name, Value]);
    end;
  end;
  info := info + Format('耗时: %s' + #13#10, [FormatTimeSpan(t2)]);
  info := info + Format('速度: %s/s' + #13#10,
    [IBytes(uint64(Trunc(double(FFileInfo.Size) /
    double(t2.Sec + t2.Nsec / 1000000000))))]);
  MemoLogger.Lines.Add(info);
end;

procedure TFormMain.TimerUpdatePositionTimer(Sender: TObject);
var
  kv: specialize TPair<string, TThreadHash>;
  p: integer;
  finish: integer;
  cb: TCheckBox;
begin
  finish := 0;
  for kv in MapThreadHash do
  begin
    if MapCheckBox.TryGetValue(kv.Key, cb) and cb.Checked and
      kv.Value.CurrentGetTaskResult then
    begin
      p := kv.Value.Percentage;
      MapProgressBar.Items[kv.Key].Position := p;
      if p = MapProgressBar.Items[kv.Key].Max then
      begin
        finish := finish + 1;
      end;
    end;
  end;
end;

end.
