unit PK.Device.GamePad.Win;

interface

uses
  Winapi.Windows
  , System.SysUtils
  , System.Types
  , PK.Device.GamePad.Types
  ;

type
  TWinGamePad = class(TGamePadIntf)
  private var
    FControllerIndex: Integer;
    FStatus: TGamePadButtons;
    FPrevStatus: TGamePadButtons;
    FDeadZoneLeft: Integer;
    FDeadZoneRight: Integer;
  public
    constructor Create; reintroduce;
    procedure SetDeadZone(const ALeft, ARight: Integer); override;
    procedure SetControllerIndex(const AIndex: Integer); override;
    function GetControllerIndex: Integer; override;
    function Check: TGamePadButtons; override;
    function CheckStick(const AThumb: TGamePadButton): TPoint; override;
    function CheckTrigger(const AThumb: TGamePadButton): Integer; override;
    function IsClicked(const AButton: TGamePadButton): Boolean; override;
    function GetStatus: TGamePadButtons; override;
  end;

  TWinGamePadFactory = class(TGamePadFactory)
  public
    function CreateGamePad: IGamePad; override;
  end;

implementation

uses
  System.Math
  , FMX.Platform
  , PK.Utils.Log
  ;

type
  // XINPUT_GAMEPAD Structure
  TXInpuTWinGamePad = packed record
    wButtons: Word;
    bLeftTrigger: Byte;
    bRightTrigger: Byte;
    sThumbLX: SmallInt;
    sThumbLY: SmallInt;
    sThumbRX: SmallInt;
    sThumbRY: SmallInt;
  end;

  // XINPUT_STATE Structure
  TXInputState = packed record
    dwPacketNumber: DWORD;
    Gamepad: TXInpuTWinGamePad;
  end;

const
  XINPUT_GAMEPAD_DPAD_UP        = $0001;
  XINPUT_GAMEPAD_DPAD_DOWN      = $0002;
  XINPUT_GAMEPAD_DPAD_LEFT      = $0004;
  XINPUT_GAMEPAD_DPAD_RIGHT     = $0008;
  XINPUT_GAMEPAD_START          = $0010;
  XINPUT_GAMEPAD_BACK           = $0020;
  XINPUT_GAMEPAD_LEFT_THUMB     = $0040;
  XINPUT_GAMEPAD_RIGHT_THUMB    = $0080;
  XINPUT_GAMEPAD_LEFT_SHOULDER  = $0100;
  XINPUT_GAMEPAD_RIGHT_SHOULDER = $0200;
  XINPUT_GAMEPAD_A              = $1000;
  XINPUT_GAMEPAD_B              = $2000;
  XINPUT_GAMEPAD_X              = $4000;
  XINPUT_GAMEPAD_Y              = $8000;

  // Dead zone
  XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE  = 7849;
  XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE = 8689;

// Import XInputGetState
const
  XINPUT_DLL = 'xinput1_4.dll';

function XInputGetState(
  dwUserIndex: DWORD;
  var State: TXInputState): DWORD; stdcall;
  external XINPUT_DLL name 'XInputGetState';

procedure RegisterGamePadWin;
begin
  TPlatformServices.Current.AddPlatformService(
    IGamePadFactory,
    TWinGamePadFactory.Create);
end;

{ TWinGamePadFactory }

function TWinGamePadFactory.CreateGamePad: IGamePad;
begin
  Result := TWinGamePad.Create;
end;

{ TWinGamePad }

function TWinGamePad.Check: TGamePadButtons;
  // Stick
  const R = 0.0;
  const U = 1.5;
  const L1 = 3.0;
  const L2 = -3.0;
  const D = -1.5;

  const RU = 0.75;
  const LU = 2.25;
  const LD = -2.25;
  const RD = -0.75;

  const Delta = 0.5;

  var Theta: Single;

  function InMin(const AValue: Single): Boolean;
  begin
    Result := Theta > (AValue - Delta);
  end;

  function InMax(const AValue: Single): Boolean;
  begin
    Result := Theta < (AValue + Delta);
  end;

  function InMinMax(const AValue: Single): Boolean;
  begin
    Result := InMin(AValue) and InMax(AValue);
  end;

  function IsL: Boolean;
  begin
    Result := (InMinMax(L1) or InMinMax(L2)) and (Theta <> 0);;
  end;

  function IsR: Boolean;
  begin
    Result := InMinMax(R) and (Theta <> 0);
  end;

  function IsU: Boolean;
  begin
    Result := InMinMax(U);
  end;

  function IsD: Boolean;
  begin
    Result := InMinMax(D);
  end;

  function IsLU: Boolean;
  begin
    Result := InMinMax(LU);
  end;

  function IsLD: Boolean;
  begin
    Result := InMinMax(LD);
  end;

  function IsRU: Boolean;
  begin
    Result := InMinMax(RU);
  end;

  function IsRD: Boolean;
  begin
    Result := InMinMax(RD);
  end;

begin
  Result := [];

  var State: TXInputState;
  if XInputGetState(FControllerIndex, State) <> ERROR_SUCCESS then
    Exit;

  FPrevStatus := FStatus;

  // Cross Key
  if (State.Gamepad.wButtons and XINPUT_GAMEPAD_DPAD_UP) <> 0 then
    Include(Result, TGamePadButton.Up);

  if (State.Gamepad.wButtons and XINPUT_GAMEPAD_DPAD_DOWN) <> 0 then
    Include(Result, TGamePadButton.Down);

  if (State.Gamepad.wButtons and XINPUT_GAMEPAD_DPAD_LEFT) <> 0 then
    Include(Result, TGamePadButton.Left);

  if (State.Gamepad.wButtons and XINPUT_GAMEPAD_DPAD_RIGHT) <> 0 then
    Include(Result, TGamePadButton.Right);

  if TGamePadButton.Left in Result then
  begin
    if TGamePadButton.Up in Result then
      Include(Result, TGamePadButton.LeftUp);

    if TGamePadButton.Down in Result then
      Include(Result, TGamePadButton.LeftDown);
  end;

  if TGamePadButton.Right in Result then
  begin
    if TGamePadButton.Up in Result then
      Include(Result, TGamePadButton.RightUp);

    if TGamePadButton.Down in Result then
      Include(Result, TGamePadButton.RightDown);
  end;

  // Button
  if (State.Gamepad.wButtons and XINPUT_GAMEPAD_A) <> 0 then
    Include(Result, TGamePadButton.A);

  if (State.Gamepad.wButtons and XINPUT_GAMEPAD_B) <> 0 then
    Include(Result, TGamePadButton.B);

  if (State.Gamepad.wButtons and XINPUT_GAMEPAD_X) <> 0 then
    Include(Result, TGamePadButton.X);

  if (State.Gamepad.wButtons and XINPUT_GAMEPAD_Y) <> 0 then
    Include(Result, TGamePadButton.Y);

  // Start / Back
  if (State.Gamepad.wButtons and XINPUT_GAMEPAD_START) <> 0 then
    Include(Result, TGamePadButton.Start);

  if (State.Gamepad.wButtons and XINPUT_GAMEPAD_BACK) <> 0 then
    Include(Result, TGamePadButton.Back);

  // Shoulder (L1, R1)
  if (State.Gamepad.wButtons and XINPUT_GAMEPAD_LEFT_SHOULDER) <> 0 then
    Include(Result, TGamePadButton.LeftShoulder);

  if (State.Gamepad.wButtons and XINPUT_GAMEPAD_RIGHT_SHOULDER) <> 0 then
    Include(Result, TGamePadButton.RightShoulder);

  // Trigger (L2, R2)
  if (State.Gamepad.bLeftTrigger > 0) then
    Include(Result, TGamePadButton.LeftTrigger);

  if (State.Gamepad.bRightTrigger > 0) then
    Include(Result, TGamePadButton.RightTrigger);

  // Stick Button (L3, R3)
  if (State.Gamepad.wButtons and XINPUT_GAMEPAD_LEFT_THUMB) <> 0 then
    Include(Result, TGamePadButton.LeftThumb);

  if (State.Gamepad.wButtons and XINPUT_GAMEPAD_RIGHT_THUMB) <> 0 then
    Include(Result, TGamePadButton.RightThumb);

  // L Stick
  var LS := CheckStick(TGamePadButton.LeftThumb);
  Theta := ArcTan2(LS.Y, LS.X);

  if IsLU then
    Include(Result, TGamePadButton.LStickLU)
  else if IsLD then
    Include(Result, TGamePadButton.LStickLD)
  else if IsRU then
    Include(Result, TGamePadButton.LStickRU)
  else if IsRD then
    Include(Result, TGamePadButton.LStickRD)
  else if IsL then
    Include(Result, TGamePadButton.LStickL)
  else if IsR then
    Include(Result, TGamePadButton.LStickR)
  else if IsU then
    Include(Result, TGamePadButton.LStickU)
  else if IsD then
    Include(Result, TGamePadButton.LStickD);

  // R Stick
  var RS := CheckStick(TGamePadButton.RightThumb);
  Theta := ArcTan2(RS.Y, RS.X);

  if IsLU then
    Include(Result, TGamePadButton.RStickLU)
  else if IsLD then
    Include(Result, TGamePadButton.RStickLD)
  else if IsRU then
    Include(Result, TGamePadButton.RStickRU)
  else if IsRD then
    Include(Result, TGamePadButton.RStickRD)
  else if IsL then
    Include(Result, TGamePadButton.RStickL)
  else if IsR then
    Include(Result, TGamePadButton.RStickR)
  else if IsU then
    Include(Result, TGamePadButton.RStickU)
  else if IsD then
    Include(Result, TGamePadButton.RStickD);

  FStatus := Result;
end;

function TWinGamePad.CheckStick(const AThumb: TGamePadButton): TPoint;

  procedure GetStickValue(const AThumbX, AThumbY, ADeadZone: Integer);
  begin
    Result.X := AThumbX;
    Result.Y := AThumbY;

    if (Abs(Result.X) < ADeadZone) and (Abs(Result.Y) < ADeadZone) then
    begin
      Result.X := 0;
      Result.Y := 0;
    end;
  end;

begin
  Result.X := 0;
  Result.Y := 0;

  var State: TXInputState;
  if XInputGetState(FControllerIndex, State) <> ERROR_SUCCESS then
    Exit;

  // 左右スティックの X, Y 軸の値
  case AThumb  of
    TGamePadButton.LeftThumb:
      GetStickValue(
        State.Gamepad.sThumbLX,
        State.Gamepad.sThumbLY,
        FDeadZoneLeft);

    TGamePadButton.RightThumb:
      GetStickValue(
        State.Gamepad.sThumbRX,
        State.Gamepad.sThumbRY,
        FDeadZoneRight);
  end;
end;

function TWinGamePad.CheckTrigger(const AThumb: TGamePadButton): Integer;
begin
  Result := 0;

  var State: TXInputState;
  if XInputGetState(FControllerIndex, State) <> ERROR_SUCCESS then
    Exit;

  // 左右 Trigger (L2, R2) の値
  case AThumb  of
    TGamePadButton.LeftTrigger:
      Result := State.Gamepad.bLeftTrigger;

    TGamePadButton.RightTrigger:
      Result := State.Gamepad.bRightTrigger;
  end;
end;

constructor TWinGamePad.Create;
begin
  inherited;

  FControllerIndex := 0;
  FDeadZoneLeft := XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE;
  FDeadZoneRight := XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE;
end;

function TWinGamePad.GetControllerIndex: Integer;
begin
  Result := FControllerIndex;
end;

function TWinGamePad.GetStatus: TGamePadButtons;
begin
  Result := FStatus;
end;

function TWinGamePad.IsClicked(const AButton: TGamePadButton): Boolean;
begin
  Result := (AButton in FPrevStatus) and not (AButton in FStatus);
end;

procedure TWinGamePad.SetControllerIndex(const AIndex: Integer);
begin
  FControllerIndex := AIndex;
end;

procedure TWinGamePad.SetDeadZone(const ALeft, ARight: Integer);
begin
  FDeadZoneLeft := ALeft;
  FDeadZoneRight := ARight;
end;

initialization
  RegisterGamePadWin;

end.
