﻿(*
 * GamePad
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
 *   2024/11/18  Ver 1.0.0  Release
 *
 * Programmed by HOSOKAWA Jun (twitter: @pik)
 *)

unit PK.Device.GamePad.Types;

interface

uses
  System.SysUtils
  , System.Types
  , System.Generics.Collections
  ;

type
  TGamePadButton = (
    None,

    Up, Down, Left, Right,
    LeftUp, LeftDown, RightUp, RightDown, // 斜め方向の簡単化

    LStickL, RStickL,
    LStickR, RStickR,
    LStickU, RStickU,
    LStickD, RStickD,

    LStickLU, RStickLU,
    LStickRU, RStickRU,
    LStickLD, RStickLD,
    LStickRD, RStickRD,

    Start, Back,
    LeftThumb, RightThumb,
    LeftShoulder, RightShoulder,
    LeftTrigger, RightTrigger,
    A, B, X, Y
  );
  TGamePadButtons = set of TGamePadButton;

  TGamePadButtonArray = TArray<TGamePadButton>;

  TGamPadButtonHelper = record helper for TGamePadButton
  public
    function ToString: String;
  end;

  TGamePadInfo = record
  private var
    FId: String;
    FIndex: Integer;
    FCaption: String;
    FVendorId: Word;
    FProductId: Word;
  private
    function GetValid: Boolean;
  public
    constructor Create(
      const AId: String;
      const AIndex: Integer;
      const ACaption: String;
      const AVendorId, AProductId: Word);
    property Valid: Boolean read GetValid;
    property Id: String read FId write FId;
    property Index: Integer read FIndex write FIndex;
    property Caption: String read FCaption write FCaption;
    property VendorId: Word read FVendorId write FVendorId;
    property ProductId: Word read FProductId write FProductId;
  end;

  IGamePad = interface
  ['{80E4879F-7D6E-418A-A783-1FD39C519EFC}']
    // ゲームパッドの入力を得る
    function Check: TGamePadButtons;

    // ゲームパッドのスティックの値を得る
    function CheckStick(const AThumb: TGamePadButton): TPointF;

    // ゲームパッドのトリガーの値を得る
    function CheckTrigger(const AThumb: TGamePadButton): Single;

    // ボタンがクリック（押して離されたか）を判定
    function IsClicked(const AButton: TGamePadButton): Boolean;

    // 振動させる
    procedure Vibrate(
      const ALeftMotor, ARightMotor: Single;
      const ADuration: Integer;
      const AOnComplete: TProc);

    // デッドゾーンを設定する
    procedure SetDeadZone(const ALeft, ARight: Single);

    // １つ前のボタンの状態を返す
    function GetPrevStatus: TGamePadButtons;

    // Check を呼んだ時の入力を返す
    function GetStatus: TGamePadButtons;

    // ゲームパッドの固有値をセットする
    procedure SetControllerId(const AId: String);

    // ゲームパッドの固有値を返す
    function GetControllerId: String;

    // ゲームパッドの数を返す
    function GetGamePadInfoCount: Integer;

    // ゲームパッドの情報を返す
    function GetGamePadInfos(const AIndex: Integer): TGamePadInfo;

    // ゲームパッドの情報を更新する
    procedure UpdateGamePadInfo;

    // ゲームパッドの挿抜を確認する（挿抜されていたら UpdateGamePadInfo を呼ぶ）
    function CheckController: Boolean;

    // 有効なゲームパッドが選択されているかを返す
    function Available: Boolean;

    // プロパティ
    property PrevStatus: TGamePadButtons read GetPrevStatus;
    property Status: TGamePadButtons read GetStatus;
    property ControllerId: String read GetControllerId write SetControllerId;

    property GamePadInfoCount: Integer read GetGamePadInfoCount;
    property GamePadInfos[const AIndex: Integer]: TGamePadInfo
      read GetGamePadInfos;
  end;

  IGamePadFactory = interface
  ['{A543159F-4FE5-485D-8D0C-8025FDEA2B48}']
    function CreateGamePad: IGamePad;
  end;

  TGamePadFactory = class(TInterfacedObject, IGamePadFactory)
  public
    function CreateGamePad: IGamePad; virtual; abstract;
  end;

  TGamePadIntf = class abstract(TInterfacedObject, IGamePad)
  private
    function GetStatusAsArray(
      const AStatus: TGamePadButtons): TGamePadButtonArray;
    function GetNewlyPressedButtons: TGamePadButtonArray;
  protected
    procedure SetControllerId(const AId: String); virtual; abstract;
    function GetControllerId: String; virtual; abstract;
    function GetPrevStatus: TGamePadButtons; virtual; abstract;
    function GetStatus: TGamePadButtons; virtual; abstract;
    function GetGamePadInfoCount: Integer; virtual; abstract;
    function GetGamePadInfos(
      const AIndex: Integer): TGamePadInfo; virtual; abstract;
    procedure UpdateGamePadInfo; virtual; abstract;
  public
    function Check: TGamePadButtons; virtual; abstract;
    function CheckStick(const AThumb: TGamePadButton): TPointF;
      virtual; abstract;
    function CheckTrigger(const AThumb: TGamePadButton): Single;
      virtual; abstract;
    function IsClicked(const AButton: TGamePadButton): Boolean;
      virtual; abstract;
    procedure Vibrate(
      const ALeftMotor, ARightMotor: Single;
      const ADuration: Integer;
      const AOnComplete: TProc); virtual; abstract;
    procedure SetDeadZone(const ALeft, ARight: Single); virtual; abstract;
    function CheckController: Boolean; virtual; abstract;
    function Available: Boolean; virtual; abstract;
  public
    property Status: TGamePadButtons read GetStatus;
    property ControllerId: String read GetControllerId write SetControllerId;

    property GamePadInfoCount: Integer read GetGamePadInfoCount;
    property GamePadInfos[const AIndex: Integer]: TGamePadInfo
      read GetGamePadInfos;

    // ボタンの押下値を配列で返す
    property
      StatusAsArray[const AStatus: TGamePadButtons]: TGamePadButtonArray
      read GetStatusAsArray;

    // 新たに押されたボタンを配列で返す
    property NewlyPressedButtons: TGamePadButtonArray
      read GetNewlyPressedButtons;
  end;

const
  GAMEPADINFO_NONE: TGamePadInfo =
  (
    FId: '';
    FIndex: -1;
    FCaption: '';
    FVendorId: 0;
    FProductId: 0
  );

implementation

uses
  System.TypInfo;

{ TGamPadButtonHelper }

function TGamPadButtonHelper.ToString: String;
begin
  Result := GetEnumName(TypeInfo(TGamePadButton), Ord(Self));
end;

{ TGamePadInfo }

constructor TGamePadInfo.Create(
  const AId: String;
  const AIndex: Integer;
  const ACaption: String;
  const AVendorId, AProductId: Word);
begin
  FId := AId;
  FIndex := AIndex;
  FCaption := ACaption;
  FVendorId := AVendorId;
  FProductId := AProductId;
end;

function TGamePadInfo.GetValid: Boolean;
begin
  Result := FIndex > -1;
end;

{ TGamePadIntf }

function TGamePadIntf.GetNewlyPressedButtons: TGamePadButtonArray;
begin
  Result := GetStatusAsArray(GetStatus - GetPrevStatus);
end;

function TGamePadIntf.GetStatusAsArray(
  const AStatus: TGamePadButtons): TGamePadButtonArray;
begin
  Result := [];

  // LStick
  if TGamePadButton.LStickL in AStatus then
    Result := Result + [TGamePadButton.LStickL];

  if TGamePadButton.LStickR in AStatus then
    Result := Result + [TGamePadButton.LStickR];

  if TGamePadButton.LStickU in AStatus then
    Result := Result + [TGamePadButton.LStickU];

  if TGamePadButton.LStickD in AStatus then
    Result := Result + [TGamePadButton.LStickD];

  if TGamePadButton.LStickLU in AStatus then
    Result := Result + [TGamePadButton.LStickLU];

  if TGamePadButton.LStickLD in AStatus then
    Result := Result + [TGamePadButton.LStickLD];

  if TGamePadButton.LStickRU in AStatus then
    Result := Result + [TGamePadButton.LStickRU];

  if TGamePadButton.LStickRD in AStatus then
    Result := Result + [TGamePadButton.LStickRD];

  // RStick
  if TGamePadButton.RStickL in AStatus then
    Result := Result + [TGamePadButton.RStickL];

  if TGamePadButton.RStickR in AStatus then
    Result := Result + [TGamePadButton.RStickR];

  if TGamePadButton.RStickU in AStatus then
    Result := Result + [TGamePadButton.RStickU];

  if TGamePadButton.RStickD in AStatus then
    Result := Result + [TGamePadButton.RStickD];

  if TGamePadButton.RStickLU in AStatus then
    Result := Result + [TGamePadButton.RStickLU];

  if TGamePadButton.RStickLD in AStatus then
    Result := Result + [TGamePadButton.RStickLD];

  if TGamePadButton.RStickRU in AStatus then
    Result := Result + [TGamePadButton.RStickRU];

  if TGamePadButton.RStickRD in AStatus then
    Result := Result + [TGamePadButton.RStickRD];

  // Cross
  if TGamePadButton.Up in AStatus then
    Result := Result + [TGamePadButton.Up];

  if TGamePadButton.Down in AStatus then
    Result := Result + [TGamePadButton.Down];

  if TGamePadButton.Left in AStatus then
    Result := Result + [TGamePadButton.Left];

  if TGamePadButton.Right in AStatus then
    Result := Result + [TGamePadButton.Right];

  if TGamePadButton.LeftUp in AStatus then
    Result := Result + [TGamePadButton.LeftUp];

  if TGamePadButton.LeftDown in AStatus then
    Result := Result + [TGamePadButton.LeftDown];

  if TGamePadButton.RightUp in AStatus then
    Result := Result + [TGamePadButton.RightUp];

  if TGamePadButton.RightDown in AStatus then
    Result := Result + [TGamePadButton.RightDown];

  // L Buttons
  if TGamePadButton.LeftShoulder in AStatus then
    Result := Result + [TGamePadButton.LeftShoulder];

  if TGamePadButton.LeftTrigger in AStatus then
    Result := Result + [TGamePadButton.LeftTrigger];

  if TGamePadButton.LeftThumb in AStatus then
    Result := Result + [TGamePadButton.LeftThumb];

  // R Buttons
  if TGamePadButton.RightShoulder in AStatus then
    Result := Result + [TGamePadButton.RightShoulder];

  if TGamePadButton.RightTrigger in AStatus then
    Result := Result + [TGamePadButton.RightTrigger];

  if TGamePadButton.RightThumb in AStatus then
    Result := Result + [TGamePadButton.RightThumb];

  // Start Back
  if TGamePadButton.Start in AStatus then
    Result := Result + [TGamePadButton.Start];

  if TGamePadButton.Back in AStatus then
    Result := Result + [TGamePadButton.Back];

  // A B X Y
  if TGamePadButton.A in AStatus then
    Result := Result + [TGamePadButton.A];

  if TGamePadButton.B in AStatus then
    Result := Result + [TGamePadButton.B];

  if TGamePadButton.X in AStatus then
    Result := Result + [TGamePadButton.X];

  if TGamePadButton.Y in AStatus then
    Result := Result + [TGamePadButton.Y];
end;

end.
