unit PK.Device.GamePad.Win;

interface

uses
  Winapi.Windows
  , Winapi.DirectInput
  , Winapi.ActiveX
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
      constructor Create(const AInfo: PDIDeviceInstance);
    end;
    TDeviceInfos = TList<TDeviceInfo>;

  private class var
    FDeviceInfos: TDeviceInfos;
  private
    class constructor CreateClass;
    class destructor DestroyClass;
    class function CallbackFunc(
      lpddi: PDIDEVICEINSTANCE;
      pvRef: Pointer): BOOL; static; stdcall;
  private var
    FControllerIndex: Integer;
    FStatus: TGamePadButtons;
    FPrevStatus: TGamePadButtons;
    FDeadZoneLeft: Integer;
    FDeadZoneRight: Integer;
  public
    constructor Create; reintroduce;
    function GetControllerIndex: Integer; override;
    function Check: TGamePadButtons; override;
    function CheckStick(const AThumb: TGamePadButton): TPoint; override;
    function CheckTrigger(const AThumb: TGamePadButton): Integer; override;
    function IsClicked(const AButton: TGamePadButton): Boolean; override;
    procedure Vibrate(
      const ALeftMotor, ARightMotor: Word;
      const ADuration: Integer); override;

    procedure SetDeadZone(const ALeft, ARight: Integer); override;
    procedure SetControllerIndex(const AIndex: Integer); override;
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

type
  // XINPUT_GAMEPAD Structure
  TXInputGamePad = packed record
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
    Gamepad: TXInputGamePad;
  end;

  // XINPUT_VIBRATION 構造体
  TXInputVibration = packed record
    wLeftMotorSpeed: Word;  // 左モーターの振動強度 (0-65535)
    wRightMotorSpeed: Word; // 右モーターの振動強度 (0-65535)
  end;

  TXInputCapabilities = packed record
    &Type: Byte;
    SubType: Byte;
    Flags: Word;
    Gamepad: TXInputGamePad;
    Vibration: TXInputVibration;
  end;

  TXInputCapabilitiesEx = packed record
    Capabilities: TXInputCapabilities;
    VendorId: Word;
    ProductId: Word;
    ProductVersion: Word;
    Reserved1: Word;
    Reserved2: DWORD;
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
  XINPUT_DLL = 'xinput1_4.dll';

function XInputGetState(
  dwUserIndex: DWORD;
  var State: TXInputState): DWORD; stdcall;
  external XINPUT_DLL name 'XInputGetState';

function XInputSetState(
  dwUserIndex: DWORD;
  var pVibration: TXInputVibration): DWORD; stdcall;
  external XINPUT_DLL name 'XInputSetState';

{$WARNINGS OFF}
function XInputGetCapabilitiesEx(
  dwVerion: DWORD;
  dwUserIndex: DWORD;
  dwFlags: DWORD;
  var pCapabilitiesEx: TXInputCapabilitiesEx): DWORD; stdcall;
  external XINPUT_DLL index 108;
{$WARNINGS ON}

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

constructor TWinGamePad.TDeviceInfo.Create(const AInfo: PDIDeviceInstance);
begin
  var VIdPId := AInfo^.guidProduct.D1;
  FPadInfo.VendorId := LoWord(VIdPId);
  FPadInfo.ProductId := HiWord(VIdPId);

  FPadInfo.Id := AInfo.guidInstance.ToString;

  FPadInfo.Caption := AInfo.tszInstanceName;

  var Target :=
    Format('VID_%.4x&PID_%.4x', [FPadInfo.VendorId, FPadInfo.ProductId]);
  var Target2 :=
    Format('%.4x_PID&%.4x', [FPadInfo.VendorId, FPadInfo.ProductId]);
  var DeviceCaption := '';

  {
  Log.d(Target);
  Log.d(Target2);
  Log.d('');
  //}

  TWMI.GetPropertyEx(
    'Win32_PnPEntity',
    ['Caption', 'DeviceID', 'PNPClass'],
    procedure(const iProps: TWMI.TWbemPropDic)

      function GetProps(const AName: String): String;
      begin
        try
          if iProps[AName] <> Null then
            Result := iProps[AName]
          else
            Result := '';
        except
          Result := '';
        end;
      end;

    begin
      var Caption := GetProps('Caption');
      var DeviceID := GetProps('DeviceID');
      var PNPClass := GetProps('PNPClass');

      //Log.d(DeviceID + '  ' + PNPClass);

      if
        (
          (PNPClass = 'USB') or
          (PNPClass = 'HIDClass') or
          (PNPClass = 'XboxComposite')
        ) and
        (
          (DeviceID.Contains(Target) and not DeviceID.Contains('HID\')) or
          DeviceID.Contains(Target2)
        )
      then
      begin
        //Log.d(DeviceId);

        if DeviceID.StartsWith('BTHENUM') then
        begin
          var Index := DeviceID.IndexOf(Target2);
          if Index > -1 then
          begin
            Inc(Index, Target2.Length);
            var Path1 := DeviceID.Substring(Index, 13);
            var Path2 := DeviceID.Substring(Index + 13, 12);

            var BTarget :=
              Format(
                'BTHENUM\DEV_%s%sBLUETOOTHDEVICE_%s',
                [Path2, Path1, Path2]
              );

            TWMI.GetPropertyEx(
              'Win32_PnPEntity',
              ['Caption', 'DeviceID'],
              procedure(const iProps: TWMI.TWbemPropDic)
              begin
                try
                  var DeviceID := iProps['DeviceID'];
                  if DeviceID = BTarget then
                    Caption := iProps['Caption'];
                except
                end;
              end
            );
          end;
        end;

        var Ist := False;
        for var Info in FDeviceInfos do
          if Info.FPadInfo.Caption = Caption then
          begin
            Ist := True;
          end;

        if not Ist then
          DeviceCaption := Caption;
      end;
    end
  );

  if
    (not DeviceCaption.IsEmpty) and
    (not DeviceCaption.Contains('USB')) and
    (not DeviceCaption.Contains('Bluetooth'))
  then
    FPadInfo.Caption := DeviceCaption;

  //Log.d(DeviceCaption + ': ' + FPadInfo.Caption + ': ');
end;

{ TWinGamePad }

class function TWinGamePad.CallbackFunc(
  lpddi: PDIDEVICEINSTANCE;
  pvRef: Pointer): BOOL;
begin
  //Writeln('Called');
  FDeviceInfos.Add(TDeviceInfo.Create(lpddi));

  // XInput 認識デバイス数を超えていたら中止
  if FDeviceInfos.Count < PUInt32(pvRef)^ then
    Result := DIENUM_CONTINUE
  else
    Result := DIENUM_STOP;
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

class constructor TWinGamePad.CreateClass;
begin
  FDeviceInfos := TDeviceInfos.Create;

  // XInput の数を調べる
  var Count: UInt32 := 0;
  for var i := 0 to 15 do // GameInput 実装環境では 16 まで拡張される
  begin
    var State: TXInputState;
    if XInputGetState(i, State) <> ERROR_SUCCESS then
    begin
      Count := i;
      Break;
    end;
  end;

  // COMライブラリの初期化
  if Succeeded(CoInitialize(nil)) then
    try
      var DirectInput: IDirectInput8 := nil;

      // DirectInput8オブジェクトの作成
      if
        Failed(
          DirectInput8Create(
            GetModuleHandle(nil),
            DIRECTINPUT_VERSION,
            IID_IDirectInput8,
            DirectInput,
            nil
          )
        )
      then
      begin
        Exit;
      end;

      // デバイスの列挙
      DirectInput.EnumDevices(
        DI8DEVCLASS_GAMECTRL,
        @CallbackFunc,
        @Count,
        DIEDFL_ALLDEVICES
      )
    finally
      // COMのクリーンアップ
      CoUninitialize;
    end;
end;

class destructor TWinGamePad.DestroyClass;
begin
  FDeviceInfos.Free;
end;

function TWinGamePad.GetControllerIndex: Integer;
begin
  Result := FControllerIndex;
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

procedure TWinGamePad.SetControllerIndex(const AIndex: Integer);
begin
  FControllerIndex := AIndex;
end;

procedure TWinGamePad.SetDeadZone(const ALeft, ARight: Integer);
begin
  FDeadZoneLeft := ALeft;
  FDeadZoneRight := ARight;
end;

procedure TWinGamePad.Vibrate(
  const ALeftMotor, ARightMotor: Word;
  const ADuration: Integer);
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      var Vibration: TXInputVibration;

      Vibration.wLeftMotorSpeed := ALeftMotor;
      Vibration.wRightMotorSpeed := ARightMotor;
      XInputSetState(FControllerIndex, Vibration);

      Sleep(ADuration);

      Vibration.wLeftMotorSpeed := 0;
      Vibration.wRightMotorSpeed := 0;
      XInputSetState(FControllerIndex, Vibration);
    end
  ).Start;
end;

initialization
  RegisterGamePadWin;

end.
