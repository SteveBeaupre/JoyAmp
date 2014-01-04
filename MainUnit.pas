unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, TrayIcon, ExtCtrls, MMSystem, Joystick;

type
  TMainForm = class(TForm)
    TrayIcon: TTrayIcon;
    PopupMenu: TPopupMenu;
    ExitMenu: TMenuItem;
    ConfigMenu: TMenuItem;
    Joystick: TJoystick;
    DevicesMenu: TMenuItem;
    RepeatTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure ExitMenuClick(Sender: TObject);
    procedure JoystickButtonEvent(Sender: TObject; Button: Integer;
      Pressed: Boolean);
    procedure JoystickPOVEvent(Sender: TObject; Angle: Integer;
      Centered: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure JoystickAxisEvent(Sender: TObject; Axis: Char;
      Value: Integer);
    procedure ConfigMenuClick(Sender: TObject);
    procedure RepeatTimerTimer(Sender: TObject);
  private
    { Private declarations }
    POVBackup: Integer;
    RepeatCode:  DWORD;
    RepeatCount: DWORD;
    DevicesMenuEntry: Array [0..15] of TMenuItem;
    procedure OnDevicesSubMenusClick(Sender: TObject);
    procedure DoAction(i: Integer; Pressed: Boolean);
    procedure StartRepeatTimer(K: DWORD);
    procedure StopRepeatTimer;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses ConfigUnit;

{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////

procedure TMainForm.FormCreate(Sender: TObject);
var
 i: Integer;
 HaveDevices: Boolean;
begin
POVBackup   := -1;
RepeatCode  := 0;
RepeatCount := 0;

if not Joystick.NumDevSupported > 0 then begin
  ShowMessage('Joystick Drivers Unavailable.');
  Application.ProcessMessages;
end;

HaveDevices := False;
for i := 0 to 15 do begin
  DevicesMenuEntry[i] := TMenuItem.Create(Self);
  if(Joystick.IsJoystickConnected(i)) then begin
    DevicesMenuEntry[i].Caption := Joystick.GetJoystickProductName(i);
    DevicesMenuEntry[i].Tag := i;
    DevicesMenu.Add(DevicesMenuEntry[i]);
    DevicesMenuEntry[i].OnClick := OnDevicesSubMenusClick;
    HaveDevices := True;
  end;
end;

if(HaveDevices) then begin
  DevicesMenu.Items[0].Click;
end else begin
  ShowMessage('No Devices Found!');
  PostQuitMessage(0);
end;
end;

////////////////////////////////////////////////////////////////////////////////////////////////

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
var
 i: Integer;
begin
RepeatTimer.Enabled := False;
for i := 15 downto 0 do
  DevicesMenuEntry[i].Free;
end;

////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////

procedure TMainForm.ExitMenuClick(Sender: TObject);
begin
Self.Close;
end;

////////////////////////////////////////////////////////////////////////////////////////////////

procedure TMainForm.OnDevicesSubMenusClick(Sender: TObject);
var
 i: Integer;
begin
Joystick.StopPolling;
Joystick.JoyID := TMenuItem(Sender).Tag;

for i := 0 to 15 do
  DevicesMenuEntry[i].Checked := False;

TMenuItem(Sender).Checked := not TMenuItem(Sender).Checked;
Joystick.StartPolling;
end;

////////////////////////////////////////////////////////////////////////////////////////////////

procedure TMainForm.ConfigMenuClick(Sender: TObject);
begin
Joystick.StopPolling;

ConfigForm.LoadSettingsFromFile;
ConfigForm.SaveSettings;
ConfigForm.ResetEditsColor;

ConfigForm.Joystick.JoyID := Joystick.JoyID;
ConfigForm.Joystick.StartPolling;

if(ConfigForm.ShowModal = mrOk) then begin
  ConfigForm.SaveSettingsToFile;
end else begin
  ConfigForm.RestoreSettings;
end;

ConfigForm.Joystick.StopPolling;
Joystick.StartPolling;
end;

////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////

procedure TMainForm.JoystickButtonEvent(Sender: TObject; Button: Integer; Pressed: Boolean);
var
 i: Integer;
begin
with(ConfigForm) do begin
  for i := 0 to 8 do begin
    if(LabeledEdits[i].Text = 'Button ' + IntToStr(Button)) then begin
      DoAction(i, Pressed);
      break;
    end;
  end;
end;
end;

////////////////////////////////////////////////////////////////////////////////////////////////

procedure TMainForm.JoystickPOVEvent(Sender: TObject; Angle: Integer; Centered: Boolean);
var
 i: Integer;
begin
if(Centered) then begin
  Angle := POVBackup;
end;

with(ConfigForm) do begin
  for i := 0 to 8 do begin
    if((Angle = 0) and (LabeledEdits[i].Text = 'POV_UP')) then begin
      POVBackup := Angle;
      DoAction(i, not Centered);
      break;
    end else if(((Angle div 100) = 90) and (LabeledEdits[i].Text = 'POV_RIGHT')) then begin
      POVBackup := Angle;
      DoAction(i, not Centered);
      break;
    end else if(((Angle div 100) = 180) and (LabeledEdits[i].Text = 'POV_DOWN')) then begin
      POVBackup := Angle;
      DoAction(i, not Centered);
      break;
    end else if(((Angle div 100) = 270) and (LabeledEdits[i].Text = 'POV_LEFT')) then begin
      POVBackup := Angle;
      DoAction(i, not Centered);
      break;
    end;
  end;
end;

if(Centered) then begin
  POVBackup := -1;
end;
end;

////////////////////////////////////////////////////////////////////////////////////////////////

procedure TMainForm.JoystickAxisEvent(Sender: TObject; Axis: Char; Value: Integer);
{var
 i: Integer;}
begin
{with(ConfigForm) do begin
  for i := 0 to 8 do begin
    if((Value < $2000) and (LabeledEdits[i].Text = '-' + Axis + ' Axis')) then begin

      break;
    end else if((Value >= $E000) and (LabeledEdits[i].Text = '+' + Axis + ' Axis')) then begin

      break;
    end;
  end;
end;}
end;

////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////

procedure TMainForm.RepeatTimerTimer(Sender: TObject);
var
 h: HWND;
begin
// Get the winamp windows handle
h := FindWindow('Winamp v1.x', nil);

// Make sure we've found it
if(h <> 0) then begin
  // Skip the first shot, we just change the timer interval
  if(RepeatCount = 0) then begin
    RepeatTimer.Interval := 100;
  end else begin

    // Send more messages to simulate key repetition
    if(RepeatCode < 256) then begin
      PostMessage(h, WM_KEYDOWN, RepeatCode, $00000001);
    end else begin
      PostMessage(h, WM_MOUSEWHEEL, RepeatCode, 0);
    end;
  end;
  // keep track of how many repetition we've done yet
  Inc(RepeatCount);
end;
end;

////////////////////////////////////////////////////////////////////////////////////////////////

procedure TMainForm.StartRepeatTimer(K: DWORD);
begin
// Set the key repetition timer related variables
RepeatCode  := K;
RepeatCount := 0;

// Enable the key repetition timer
RepeatTimer.Enabled := true;
end;

////////////////////////////////////////////////////////////////////////////////////////////////

procedure TMainForm.StopRepeatTimer;
begin
// Disable and reset the key repetition timer and related variables
RepeatTimer.Enabled := false;
RepeatTimer.Interval := 250;
RepeatCode  := 0;
RepeatCount := 0;
end;

////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////

procedure TMainForm.DoAction(i: Integer; Pressed: Boolean);
var
 h: HWND;
 d: Integer;
 m,k,p: DWORD;
begin
h := FindWindow('Winamp v1.x', nil);
if(h <> 0) then begin

  k := 0; m := 0; p := 0;

  if(i <= 6) then begin
    case i of
      0: k := Ord('X');
      1: k := Ord('V');
      2: k := Ord('C');
      3: k := Ord('Z');
      4: k := Ord('B');
      5: k := VK_NUMPAD7;
      6: k := VK_NUMPAD9;
    end;

    case Pressed of
      True:  begin m := WM_KEYDOWN; p := $00000001; end;
      False: begin m := WM_KEYUP;   p := $C0000001; end;
    end;

    PostMessage(h, m, k, p);

    case Pressed of
      True:  StartRepeatTimer(k);
      False: StopRepeatTimer;
    end;

  end else begin
    if(Pressed) then begin
      d := WHEEL_DELTA shl 16;
      if(i = 7) then
        d := -d;

      PostMessage(h, WM_MOUSEWHEEL, d, 0);
      StartRepeatTimer(d);
    end else begin
      StopRepeatTimer;
    end;
  end;
end;
end;

end.
