unit PK.Device.GamePad.Types;

interface

uses
  System.SysUtils
  , System.Types
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
    A, B, X, Y,

    // エイリアス
    Menu = Start,
    View = Back,

    L1 = LeftShoulder,
    R1 = RightShoulder,
    L2 = LeftTrigger,
    R2 = RightTrigger,
    L3 = LeftThumb,
    R3 = RightThumb
  );
  TGamePadButtons = set of TGamePadButton;

  IGamePad = interface
  ['{80E4879F-7D6E-418A-A783-1FD39C519EFC}']
    procedure SetDeadZone(const ALeft, ARight: Integer);
    procedure SetControllerIndex(const AIndex: Integer);
    function GetControllerIndex: Integer;
    function Check: TGamePadButtons;
    function CheckStick(const AThumb: TGamePadButton): TPoint;
    function CheckTrigger(const AThumb: TGamePadButton): Integer;
    function IsClicked(const AButton: TGamePadButton): Boolean;
    function GetStatus: TGamePadButtons;

    property ControllerIndex: Integer
      read GetControllerIndex write SetControllerIndex;
    property Status: TGamePadButtons read GetStatus;
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
  protected
    procedure SetDeadZone(const ALeft, ARight: Integer); virtual; abstract;
    procedure SetControllerIndex(const AIndex: Integer); virtual; abstract;
    function GetControllerIndex: Integer; virtual; abstract;
  public
    function Check: TGamePadButtons; virtual; abstract;
    function CheckStick(const AThumb: TGamePadButton): TPoint;
      virtual; abstract;
    function CheckTrigger(const AThumb: TGamePadButton): Integer;
      virtual; abstract;
    function IsClicked(const AButton: TGamePadButton): Boolean;
      virtual; abstract;
    function GetStatus: TGamePadButtons; virtual; abstract;
  public
    function GetStatusAsArray(
      const AStatus: TGamePadButtons): TArray<TGamePadButton>;
    property
      StatusAsArray[const AStatus: TGamePadButtons]: TArray<TGamePadButton>
      read GetStatusAsArray;
  end;

implementation

uses
  System.Generics.Collections;

{ TGamePadIntf }

function TGamePadIntf.GetStatusAsArray(
  const AStatus: TGamePadButtons): TArray<TGamePadButton>;
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
