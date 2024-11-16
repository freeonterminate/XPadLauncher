(*
 * Windows XInput
 *
 * PLATFORMS
 *   Windows
 *
 * LICENSE
 *   Copyright (c) 2024 HOSOKAWA Jun
 *   Released under the MIT license
 *   http://opensource.org/licenses/mit-license.php
 *
 * HISTORY
 *   2024/11/03  Ver 1.0.0  Release
 *
 * Programmed by HOSOKAWA Jun (twitter: @pik)
 *)

unit Winapi.XInput;

interface

uses
  Winapi.Windows
  , System.SysUtils;

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
  PXInputCapabilities = ^TXInputCapabilities;

  TXInputCapabilitiesEx = packed record
    Capabilities: TXInputCapabilities;
    VendorId: Word;
    ProductId: Word;
    ProductVersion: Word;
    Reserved1: Word;
    Reserved2: DWORD;
  end;
  PXInputCapabilitiesEx = ^TXInputCapabilitiesEx;

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
  var State: TXInputState): HRESULT; stdcall;
  external XINPUT_DLL name 'XInputGetState';

function XInputSetState(
  dwUserIndex: DWORD;
  var pVibration: TXInputVibration): HRESULT; stdcall;
  external XINPUT_DLL name 'XInputSetState';

function XInputGetCapabilities(
  dwUserIndex: DWORD;
  dwFlags: DWORD;
  pCapabilitiesEx: PXInputCapabilities): HRESULT; stdcall;
  external XINPUT_DLL name 'XInputGetCapabilities';

{$WARNINGS OFF}
function XInputGetCapabilitiesEx(
  dwVersion: DWORD;
  dwUserIndex: DWORD;
  dwFlags: DWORD;
  pCapabilitiesEx: PXInputCapabilitiesEx): HRESULT; stdcall;
  external XINPUT_DLL index 108;
{$WARNINGS ON}

implementation

end.
