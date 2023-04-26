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
    CheckBoxCRC32: TCheckBox;
    CheckBoxMD5: TCheckBox;
    CheckBoxSHA1: TCheckBox;
    CheckBoxSHA256: TCheckBox;
    CheckBoxSHA512: TCheckBox;
    LabelFinish: TLabel;
    LabelCurrent: TLabel;
    LabelLogger: TLabel;
    MemoLogger: TMemo;
    ProgressBarFinish: TProgressBar;
    ProgressBarCurrent: TProgressBar;
  private

  public

  end;

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

end.

