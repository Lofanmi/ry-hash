unit unitMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls;

type

  { TFormMain }

  TFormMain = class(TForm)
    ButtonBrowse: TButton;
    ButtonClear: TButton;
    ButtonCopy: TButton;
    ButtonSave: TButton;
    ButtonStop: TButton;
    ButtonPerformance: TButton;
    MemoLogger: TMemo;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    procedure ButtonBrowseClick(Sender: TObject);
    procedure ButtonClearClick(Sender: TObject);
    procedure ButtonCopyClick(Sender: TObject);
    procedure ButtonSaveClick(Sender: TObject);
    procedure ButtonStopClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
  private

  public

  end;

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

{ TFormMain }

procedure TFormMain.FormCreate(Sender: TObject);
begin

end;

procedure TFormMain.FormDropFiles(Sender: TObject;
  const FileNames: array of string);
begin

end;

procedure TFormMain.ButtonBrowseClick(Sender: TObject);
begin

end;

procedure TFormMain.ButtonClearClick(Sender: TObject);
begin

end;

procedure TFormMain.ButtonCopyClick(Sender: TObject);
begin

end;

procedure TFormMain.ButtonSaveClick(Sender: TObject);
begin

end;

procedure TFormMain.ButtonStopClick(Sender: TObject);
begin

end;


end.

