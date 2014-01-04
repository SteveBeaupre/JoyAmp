unit ConfigUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Joystick;

type
  PLabeledEdit = ^TLabeledEdit;

  TConfigForm = class(TForm)
    Button1: TButton;
    Button2: TButton;
    GroupBox1: TGroupBox;
    LabeledEditPlay: TLabeledEdit;
    LabeledEditStop: TLabeledEdit;
    LabeledEditPause: TLabeledEdit;
    LabeledEditPrevious: TLabeledEdit;
    LabeledEditNext: TLabeledEdit;
    LabeledEditBack: TLabeledEdit;
    LabeledEditFoward: TLabeledEdit;
    LabeledEditVolumeUp: TLabeledEdit;
    LabeledEditVolumeDown: TLabeledEdit;
    Joystick: TJoystick;
    procedure LabeledEditPlayDblClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure JoystickButtonEvent(Sender: TObject; Button: Integer;
      Pressed: Boolean);
    procedure JoystickPOVEvent(Sender: TObject; Angle: Integer;
      Centered: Boolean);
    procedure JoystickAxisEvent(Sender: TObject; Axis: Char;
      Value: Integer);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    { Private declarations }
    SettingsBackup: Array [0..8] of String;
    SelEdit: Integer;
  public
    { Public declarations }
    LabeledEdits: Array [0..8] of PLabeledEdit;

    procedure ResetEditsColor;
    procedure SaveSettings;
    procedure RestoreSettings;
    procedure SaveSettingsToFile;
    procedure LoadSettingsFromFile;
  end;

var
  ConfigForm: TConfigForm;

const
  SettingsFileName = 'Settings.txt';

implementation

{$R *.dfm}

procedure TConfigForm.FormCreate(Sender: TObject);
begin
SelEdit := -1;
LabeledEdits[0] := @LabeledEditPlay;
LabeledEdits[1] := @LabeledEditStop;
LabeledEdits[2] := @LabeledEditPause;
LabeledEdits[3] := @LabeledEditPrevious;
LabeledEdits[4] := @LabeledEditNext;
LabeledEdits[5] := @LabeledEditBack;
LabeledEdits[6] := @LabeledEditFoward;
LabeledEdits[7] := @LabeledEditVolumeDown;
LabeledEdits[8] := @LabeledEditVolumeUp;
LoadSettingsFromFile;
end;

procedure TConfigForm.SaveSettings;
var
 i: Integer;
begin
for i := 0 to 8 do
  SettingsBackup[i] := LabeledEdits[i].Text;
end;

procedure TConfigForm.RestoreSettings;
var
 i: Integer;
begin
for i := 0 to 8 do
  LabeledEdits[i].Text := SettingsBackup[i];
end;

procedure TConfigForm.SaveSettingsToFile;
const
 EditNames: Array [0..8] of String = (
        'Play:    ',
        'Stop:    ',
        'Pause:   ',
        'Prev:    ',
        'Next:    ',
        'Back:    ',
        'Foward:  ',
        'VolDown: ',
        'VolUp:   '
 );
var
 i: Integer;
 Lst: TStringList;
begin
Lst := TStringList.Create;
for i := 0 to 8 do begin
  if(LabeledEdits[i].Text <> '') then begin
    Lst.Add(EditNames[i] + LabeledEdits[i].Text);
  end else begin
    Lst.Add(EditNames[i] + '<Undefined>');
  end;
end;
Lst.SaveToFile(SettingsFileName);
Lst.Free;
end;

procedure TConfigForm.LoadSettingsFromFile;
var
 i: Integer;
 s: String;
 Lst: TStringList;
begin
if(FileExists(SettingsFileName)) then begin
  Lst := TStringList.Create;
  Lst.LoadFromFile(SettingsFileName);
  for i := 0 to 8 do begin
    s := Lst.Strings[i];
    Delete(s, 1, 9);
    if(s <> '<Undefined>') then begin
      LabeledEdits[i].Text := s;
    end else begin
     LabeledEdits[i].Text := '';
    end;
  end;
  Lst.Free;
end;
end;

procedure TConfigForm.ResetEditsColor;
var
 i: Integer;
begin
SelEdit := -1;
for i := 0 to 8 do
  LabeledEdits[i].Color := clWhite;
end;

procedure TConfigForm.LabeledEditPlayDblClick(Sender: TObject);
begin
ResetEditsColor;
TLabeledEdit(Sender).Color := clBlue;
SelEdit := TLabeledEdit(Sender).Tag;
TLabeledEdit(Sender).SelLength := 0;
end;

procedure TConfigForm.JoystickButtonEvent(Sender: TObject; Button: Integer; Pressed: Boolean);
begin
if((SelEdit > -1) and (Pressed = True)) then begin
  LabeledEdits[SelEdit].Text := 'Button ' + IntToStr(Button);
  ResetEditsColor;
end;
end;

procedure TConfigForm.JoystickPOVEvent(Sender: TObject; Angle: Integer; Centered: Boolean);
begin
if((SelEdit > -1) and (Centered = False)) then begin
  case (Angle div 100) of
    0:   begin LabeledEdits[SelEdit].Text := 'POV_UP';    ResetEditsColor; end;
    90:  begin LabeledEdits[SelEdit].Text := 'POV_RIGHT'; ResetEditsColor; end;
    180: begin LabeledEdits[SelEdit].Text := 'POV_DOWN';  ResetEditsColor; end;
    270: begin LabeledEdits[SelEdit].Text := 'POV_LEFT';  ResetEditsColor; end;
  end;
end;
end;

procedure TConfigForm.JoystickAxisEvent(Sender: TObject; Axis: Char; Value: Integer);
begin
{if(SelEdit > -1) then begin
  if(Value < $2000) then begin
    LabeledEdits[SelEdit].Text := '-' + Axis + ' Axis';
    ResetEditsColor;
  end else if(Value >= $E000) then begin
    LabeledEdits[SelEdit].Text := '+' + Axis + ' Axis';
    ResetEditsColor;
  end;
end;}
end;

procedure TConfigForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
if(Key = VK_BACK) then
  LabeledEdits[SelEdit].Text := '';
if((Key = VK_BACK) or (Key = VK_ESCAPE)) then
  ResetEditsColor;
end;

end.
