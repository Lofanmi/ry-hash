program ryHash;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  unitmain,
  unithash,
  unitprogressrecorder,
  unitthread,
  unithumanate,
  unittime;

  {$R *.res}

begin
  {$if declared(UseHeapTrace)}
  GlobalSkipIfNoLeaks := True; // supported as of debugger version 3.2.0
  {$endIf}
  RequireDerivedFormResource := True;
  Application.Title:='ryHash - 速度飞快的文件哈希工具 v1.0 - https:'
    +'//imlht.com';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
