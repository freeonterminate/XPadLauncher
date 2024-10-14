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

    Start, Back,
    LeftThumb, RightThumb,
    LeftShoulder, RightShoulder,
    LeftTrigger, RightTrigger,
    A, B, X, Y,

    LStickL, RStickL,
    LStickR, RStickR,
    LStickU, RStickU,
    LStickD, RStickD,

    LStickLU, RStickLU,
    LStickRU, RStickRU,
    LStickLD, RStickLD,
    LStickRD, RStickRD,

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
  end;

implementation

end.
