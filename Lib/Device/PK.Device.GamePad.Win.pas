unit PK.Device.GamePad.Win;

interface

{$DEFINE USE_XINPUT}

//{$DEFINE USE_GAMEINPUT}
// Can't use GameInput API
// BUG: Game controllers (Xbox One, Xbox 360, Sony PS5)
//      - GetGamepadState always returns empty state
// https://github.com/microsoft/GDK/issues/70

uses
  Winapi.Windows
  , Winapi.GameInput
  , Winapi.XInput
  , System.Classes
  , System.SysUtils
  , System.Types
  , System.Generics.Collections
  , PK.Device.GamePad.Types
  ;

type
  TWinGamePad = class(TGamePadIntf)
  private type

    TDeviceInfo = record
    private
      FPadInfo: TGamePadInfo;
    public
      constructor Create(const ADevice: PIGameInputDevice);
    end;
    TDeviceInfos = TList<TDeviceInfo>;

  private class var
    FGameInput: PIGameInput;
    FDevices: TList<PIGameInputDevice>;
    FDeviceInfos: TDeviceInfos;
  private
    class constructor CreateClass;
    class destructor DestroyClass;
    class procedure UpdateDeviceList;
    class procedure CallbackFunc(
      callbackToken: GameInputCallbackToken;
      context: Pointer;
      device: PIGameInputDevice;
      timestamp: UInt64;
      currentStatus: GameInputDeviceStatus;
      previousStatus: GameInputDeviceStatus); static; stdcall;
  private var
    FControllerId: String;
    FTarget: PIGameInputDevice;
    FTargetIndex: Integer;
    FStatus: TGamePadButtons;
    FPrevStatus: TGamePadButtons;
    FDeadZoneLeft: Single;
    FDeadZoneRight: Single;
    FGPadState: GameInputGamepadState;
  public
    constructor Create; reintroduce;
    function Check: TGamePadButtons; override;
    function CheckStick(const AThumb: TGamePadButton): TPointF; override;
    function CheckTrigger(const AThumb: TGamePadButton): Single; override;

    function IsClicked(const AButton: TGamePadButton): Boolean; override;
    procedure Vibrate(
      const ALeftMotor, ARightMotor: Single;
      const ADuration: Integer); override;

    function GetControllerId: String; override;
    procedure SetControllerId(const AId: String); override;
    procedure UpdateGamePadInfo; override;

    procedure SetDeadZone(const ALeft, ARight: Single); override;
    function GetStatus: TGamePadButtons; override;

    function GetGamePadInfoCount: Integer; override;
    function GetGamePadInfos(const AIndex: Integer): TGamePadInfo; override;
  end;

  TWinGamePadFactory = class(TGamePadFactory)
  public
    function CreateGamePad: IGamePad; override;
  end;

implementation

uses
  System.Math
  , System.Variants
  , FMX.Platform
  , PK.HardInfo.WMI.Win
  , PK.Utils.Log
  ;

const
  // Dead zone
  {$IFDEF USE_XINPUT}
  GAMEPAD_LEFT_THUMB_DEADZONE  = 7849;
  GAMEPAD_RIGHT_THUMB_DEADZONE = 8689;
  {$ENDIF}

  {$IFDEF USE_GAMEINPUT}
  GAMEPAD_LEFT_THUMB_DEADZONE  = 0.2;
  GAMEPAD_RIGHT_THUMB_DEADZONE = 0.2;
  {$ENDIF}

function AppLocalDeviceIDToString(const AID: APP_LOCAL_DEVICE_ID): String;
begin
  Result := '';
  for var i := 0 to High(AID.value) do
    Result := Result + AID.value[i].ToHexString(2);
end;

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

{ TWinGamePad.TDeviceInfo }

constructor TWinGamePad.TDeviceInfo.Create(const ADevice: PIGameInputDevice);
type
  TPnPInfo = record
    FCaption: String;
    FDeviceID: String;
    FPNPClass: String;
  end;
begin
  var GPadInfo := ADevice^.lpVtbl^.GetDeviceInfo(ADevice);

  FPadInfo.Id := AppLocalDeviceIDToString(GPadInfo.deviceId);
  FPadInfo.VendorId := GPadInfo.vendorId;
  FPadInfo.ProductId := GPadInfo.productId;

  {
  Log.d(
    Format(
      '%s (%.4x:%.4x)',
      [FPadInfo.Id, FPadInfo.VendorId, FPadInfo.ProductId]
    )
  );
  }

  var VIdPId := MakeLong(FPadInfo.VendorId, FPadInfo.ProductId);

  if GPadInfo.displayName <> nil then
  begin
    var Name: String;
    SetLength(Name, GPadInfo.displayName.sizeInBytes);
    Move(
      GPadInfo^.displayName^.data,
      PChar(Name)^,
      GPadInfo.displayName.sizeInBytes);
  end;

  var Target :=
    Format('VID_%.4x&PID_%.4x', [FPadInfo.VendorId, FPadInfo.ProductId]);
  var Target2 :=
    Format('%.4x_PID&%.4x', [FPadInfo.VendorId, FPadInfo.ProductId]);
  var DeviceCaption := '';

  {
  Log.d('');
  Log.d(Target);
  Log.d(Target2);
  //}

  var PnPInfos: TArray<TPnPInfo>;

  TWMI.GetProperty(
    'Win32_PnPEntity',
    ['Caption', 'DeviceID', 'PNPClass'],
    procedure(const AProps: TWMI.TWbemPropDic)

      function GetProps(const AName: String): String;
      begin
        try
          if AProps[AName] <> Null then
            Result := AProps[AName]
          else
            Result := '';
        except
          Result := '';
        end;
      end;

    begin
      var Len := Length(PnPInfos);
      SetLength(PnPInfos, Len + 1);

      PnPInfos[Len].FCaption := GetProps('Caption');
      PnPInfos[Len].FDeviceID := GetProps('DeviceID');
      PnPInfos[Len].FPNPClass := GetProps('PNPClass');
    end
  );

  for var i := 0 to High(PnPInfos) do
  begin
    var Info := PnPInfos[i];

    if
      (
        (Info.FPNPClass = 'USB') or
        (Info.FPNPClass = 'HIDClass') or
        (Info.FPNPClass = 'XboxComposite') or
        (Info.FPNPClass = 'XnaComposite')
      ) and
      (
        (
          Info.FDeviceID.Contains(Target) and
          not Info.FDeviceID.Contains('HID\')
        ) or
        Info.FDeviceID.Contains(Target2)
      )
    then
    begin
      //Log.d(Info.FDeviceId);

      if Info.FDeviceID.StartsWith('BTHENUM') then
      begin
        var Index := Info.FDeviceID.IndexOf(Target2);
        if Index > -1 then
        begin
          Inc(Index, Target2.Length);
          var Path1 := Info.FDeviceID.Substring(Index, 13);
          var Path2 := Info.FDeviceID.Substring(Index + 13, 12);

          var BTarget :=
            Format(
              'BTHENUM\DEV_%s%sBLUETOOTHDEVICE_%s',
              [Path2, Path1, Path2]
            );

          for var j := 0 to High(PnPInfos) do
          begin
            var Info2 := PnPInfos[j];
            if Info2.FDeviceID = BTarget then
            begin
              Info.FCaption := Info2.FCaption;
              Break;
            end;
          end;
        end;
      end;

      var Ist := False;
      for var DevInfo in FDeviceInfos do
        if DevInfo.FPadInfo.Caption = Info.FCaption then
        begin
          Ist := True;
          Break;
        end;

      if
        (not Ist) and
        (not DeviceCaption.Contains(Info.FCaption)) and
        (not Info.FCaption.StartsWith('USB'))
      then
        DeviceCaption := DeviceCaption + ' or ' + Info.FCaption;
    end;
  end;

  if not DeviceCaption.IsEmpty then
    FPadInfo.Caption := DeviceCaption.Substring(4);

  Log.d(DeviceCaption + ': ' + FPadInfo.Caption + ': ');
end;

{ TWinGamePad }

class procedure TWinGamePad.CallbackFunc(
  callbackToken: GameInputCallbackToken;
  context: Pointer;
  device: PIGameInputDevice;
  timestamp: UInt64;
  currentStatus: GameInputDeviceStatus;
  previousStatus: GameInputDeviceStatus);
begin
  Log.d(
    Format(
      'Device: %d / %d',
      [FDeviceInfos.Count, Ord(device^.lpVtbl.GetDeviceStatus(device))]
    )
  );

  FDevices.Insert(0, device);
  FDeviceInfos.Insert(0, TDeviceInfo.Create(device));
end;

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
  {$IFDEF USE_XINPUT}
  Result := [];

  var State: TXInputState;
  if XInputGetState(FTargetIndex, State) <> ERROR_SUCCESS then
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
    begin
      Exclude(Result, TGamePadButton.Left);
      Exclude(Result, TGamePadButton.Up);
      Include(Result, TGamePadButton.LeftUp);
    end;

    if TGamePadButton.Down in Result then
    begin
      Exclude(Result, TGamePadButton.Left);
      Exclude(Result, TGamePadButton.Down);
      Include(Result, TGamePadButton.LeftDown);
    end;
  end;

  if TGamePadButton.Right in Result then
  begin
    if TGamePadButton.Up in Result then
    begin
      Exclude(Result, TGamePadButton.Right);
      Exclude(Result, TGamePadButton.Up);
      Include(Result, TGamePadButton.RightUp);
    end;

    if TGamePadButton.Down in Result then
    begin
      Exclude(Result, TGamePadButton.Right);
      Exclude(Result, TGamePadButton.Down);
      Include(Result, TGamePadButton.RightDown);
    end;
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
  {$ENDIF}

  {$IFDEF USE_GAMEINPUT}
  Result := [];

  var State: GameInputGamepadState;
  var Reading: PIGameInputReading := nil;

  if
    Failed(
      FGameInput^.lpVtbl^.GetCurrentReading(
        FGameInput,
        GameInputKind.GameInputKindGamepad,
        nil,
        @Reading
      )
    )
  then
    Exit;

  try
    FillChar(State, SizeOf(State), 0);
    if not Reading^.lpVtbl^.GetGamepadState(Reading, @State) then
      Exit;
  finally
    Reading^.lpVtbl^.Release(Reading);
  end;

  if
    (UInt32(State.buttons) = 0) and
    (State.leftTrigger = 0) and
    (State.rightTrigger = 0) and
    (State.leftThumbstickX = 0) and
    (State.leftThumbstickY = 0) and
    (State.rightThumbstickX = 0) and
    (State.rightThumbstickY = 0)
  then
    Exit;

  FPrevStatus := FStatus;

  FGPadState := State;
  var Buttons := UInt32(FGPadState.buttons);
  Log.d(Buttons.ToHexString(8));

  // Cross Key
  if (Buttons and Ord(GameInputGamepadDPadUp)) <> 0 then
    Include(Result, TGamePadButton.Up);

  if (Buttons and Ord(GameInputGamepadDPadDown)) <> 0 then
    Include(Result, TGamePadButton.Down);

  if (Buttons and Ord(GameInputGamepadDPadLeft)) <> 0 then
    Include(Result, TGamePadButton.Left);

  if (Buttons and Ord(GameInputGamepadDPadRight)) <> 0 then
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
  if (Buttons and Ord(GameInputGamepadA)) <> 0 then
    Include(Result, TGamePadButton.A);

  if (Buttons and Ord(GameInputGamepadB)) <> 0 then
    Include(Result, TGamePadButton.B);

  if (Buttons and Ord(GameInputGamepadX)) <> 0 then
    Include(Result, TGamePadButton.X);

  if (Buttons and Ord(GameInputGamepadY)) <> 0 then
    Include(Result, TGamePadButton.Y);

  // Start / Back
  if (Buttons and Ord(GameInputGamepadMenu)) <> 0 then
    Include(Result, TGamePadButton.Start);

  if (Buttons and Ord(GameInputGamepadView)) <> 0 then
    Include(Result, TGamePadButton.Back);

  // Shoulder (L1, R1)
  if (Buttons and Ord(GameInputGamepadLeftShoulder)) <> 0 then
    Include(Result, TGamePadButton.LeftShoulder);

  if (Buttons and Ord(GameInputGamepadRightShoulder)) <> 0 then
    Include(Result, TGamePadButton.RightShoulder);

  // Trigger (L2, R2)
  if (FGPadState.leftTrigger > 0) then
    Include(Result, TGamePadButton.LeftTrigger);

  if (FGPadState.rightTrigger > 0) then
    Include(Result, TGamePadButton.RightTrigger);

  // Stick Button (L3, R3)
  if (Buttons and Ord(GameInputGamepadLeftThumbstick)) <> 0 then
    Include(Result, TGamePadButton.LeftThumb);

  if (Buttons and Ord(GameInputGamepadRightThumbstick)) <> 0 then
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
  {$ENDIF}
end;

function TWinGamePad.CheckStick(const AThumb: TGamePadButton): TPointF;

  procedure GetStickValue(const AThumbX, AThumbY, ADeadZone: Single);
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

  // 左右スティックの X, Y 軸の値
  {$IFDEF USE_XINPUT}
  var State: TXInputState;
  if XInputGetState(FTargetIndex, State) <> ERROR_SUCCESS then
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
  {$ENDIF}

  {$IFDEF USE_GAMEINPUT}
  case AThumb  of
    TGamePadButton.LeftThumb:
      GetStickValue(
        FGPadState.leftThumbstickX,
        FGPadState.leftThumbstickY,
        FDeadZoneLeft);

    TGamePadButton.RightThumb:
      GetStickValue(
        FGPadState.rightThumbstickX,
        FGPadState.rightThumbstickY,
        FDeadZoneRight);
  end;
  {$ENDIF}
end;

function TWinGamePad.CheckTrigger(const AThumb: TGamePadButton): Single;
begin
  Result := 0;

  // 左右 Trigger (L2, R2) の値
  {$IFDEF USE_XINPUT}
  var State: TXInputState;
  if XInputGetState(FTargetIndex, State) <> ERROR_SUCCESS then
    Exit;

  // 左右 Trigger (L2, R2) の値
  case AThumb  of
    TGamePadButton.LeftTrigger:
      Result := State.Gamepad.bLeftTrigger;

    TGamePadButton.RightTrigger:
      Result := State.Gamepad.bRightTrigger;
  end;
  {$ENDIF}

  {$IFDEF USE_GAMEINPUT}
  case AThumb  of
    TGamePadButton.LeftTrigger:
      Result := FGPadState.leftTrigger;

    TGamePadButton.RightTrigger:
      Result := FGPadState.rightTrigger;
  end;
  {$ENDIF}
end;

constructor TWinGamePad.Create;
begin
  inherited;

  FControllerId := '';
  FTarget := nil;

  FDeadZoneLeft := GAMEPAD_LEFT_THUMB_DEADZONE;
  FDeadZoneRight := GAMEPAD_RIGHT_THUMB_DEADZONE;
end;

class constructor TWinGamePad.CreateClass;
begin
  FDeviceInfos := TDeviceInfos.Create;
  FDevices := TList<PIGameInputDevice>.Create;

  UpdateDeviceList;
end;

class destructor TWinGamePad.DestroyClass;
begin
  FDeviceInfos.Free;
  FDevices.Free;
  FGameInput^.lpVtbl^.Release(FGameInput);
end;

function TWinGamePad.GetControllerId: String;
begin
  Result := FControllerId;
end;

function TWinGamePad.GetGamePadInfoCount: Integer;
begin
  Result := FDeviceInfos.Count;
end;

function TWinGamePad.GetGamePadInfos(const AIndex: Integer): TGamePadInfo;
begin
  if (AIndex < 0) or (AIndex >= FDeviceInfos.Count) then
    Exit(GAMEPADINFO_NONE);

  var Info := FDeviceInfos[AIndex];

  Result := Info.FPadInfo;
end;

function TWinGamePad.GetStatus: TGamePadButtons;
begin
  Result := FStatus;
end;

function TWinGamePad.IsClicked(const AButton: TGamePadButton): Boolean;
begin
  Result := (AButton in FPrevStatus) and not (AButton in FStatus);
end;

procedure TWinGamePad.SetControllerId(const AId: String);
begin
  FControllerId := AId;
  FTarget := nil;

  for var i := 0 to FDevices.Count - 1 do
  begin
    var Device := FDevices[i];
    var Info := Device^.lpVtbl^.GetDeviceInfo(Device);

    if
      (Info <> nil) and
      (AppLocalDeviceIDToString(Info.deviceId) = FControllerId)
    then
    begin
      FTarget := Device;
      FTargetIndex := i;
      Break;
    end;
  end;
end;

procedure TWinGamePad.SetDeadZone(const ALeft, ARight: Single);
begin
  FDeadZoneLeft := ALeft;
  FDeadZoneRight := ARight;
end;

class procedure TWinGamePad.UpdateDeviceList;
begin
  FDevices.Clear;
  FDeviceInfos.Clear;

  if FGameInput <> nil then
    FGameInput^.lpVtbl^.Release(FGameInput);

  if Failed(GameInputCreate(@FGameInput)) then
    Exit;

  var Token: GameInputCallbackToken;

  var Res := FGameInput^.lpVtbl^.RegisterDeviceCallback(
    FGameInput,
    nil,
    GameInputKind.GameInputKindGamepad,
    GameInputDeviceStatus.GameInputDeviceAnyStatus,
    GameInputEnumerationKind.GameInputBlockingEnumeration,
    nil,
    @CallbackFunc,
    @Token
  );

  if Succeeded(Res) then
    FGameInput^.lpVtbl^.UnregisterCallback(FGameInput, Token, 5000)
  else
    Log.d('Failed: ' + UInt32(Res).ToHexString(8));
end;

procedure TWinGamePad.UpdateGamePadInfo;
begin
  UpdateDeviceList;
end;

procedure TWinGamePad.Vibrate(
  const ALeftMotor, ARightMotor: Single;
  const ADuration: Integer);
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      if FTarget <> nil then
      begin
        {$IFDEF USE_XINPUT}
        var Params: TXInputVibration;
        FillChar(Params, SizeOf(Params), 0);

        Params.wLeftMotorSpeed := Trunc(ALeftMotor * $ffff);
        Params.wRightMotorSpeed := Trunc(ARightMotor * $ffff);

        XInputSetState(FTargetIndex, Params);

        Sleep(ADuration);

        FillChar(Params, SizeOf(Params), 0);
        XInputSetState(FTargetIndex, Params);
        {$ENDIF}

        {$IFDEF USE_GAMEINPUT}
        var Params: GameInputRumbleParams;
        FillChar(Params, SizeOf(Params), 0);

        Params.leftTrigger := ALeftMotor;
        Params.rightTrigger := ARightMotor;

        FTarget^.lpVtbl^.SetRumbleState(FTarget, @Params);
        Sleep(ADuration);

        FillChar(Params, SizeOf(Params), 0);
        FTarget^.lpVtbl^.SetRumbleState(FTarget, @Params);
        {$ENDIF}
      end;
    end
  ).Start;
end;

initialization
  RegisterGamePadWin;

end.

