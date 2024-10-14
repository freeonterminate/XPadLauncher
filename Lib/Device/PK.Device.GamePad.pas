unit PK.Device.GamePad;

interface

uses
  System.SysUtils
  , System.Types
  , PK.Device.GamePad.Types
  ;

type
  TGamePad = class(TGamePadIntf)
  private var
    FIntf: IGamePad;
  protected
    procedure SetDeadZone(const ALeft, ARight: Integer); override;
    procedure SetControllerIndex(const AIndex: Integer); override;
    function GetControllerIndex: Integer; override;
  public
    constructor Create; reintroduce;

    function Check: TGamePadButtons; override;
    function CheckStick(const AThumb: TGamePadButton): TPoint;
      override;
    function CheckTrigger(const AThumb: TGamePadButton): Integer;
      override;
    function IsClicked(const AButton: TGamePadButton): Boolean;
      override;
    function GetStatus: TGamePadButtons; override;

    property ControllerIndex: Integer
      read GetControllerIndex write SetControllerIndex;
    property Status: TGamePadButtons read GetStatus;
  end;

implementation

uses
  FMX.Platform
  {$IFDEF MSWINDOWS}
  , PK.Device.GamePad.Win
  {$ENDIF}
  ;

{ TGamePad }

function TGamePad.Check: TGamePadButtons;
begin
  if FIntf = nil then
    Result := []
  else
    Result := FIntf.Check;
end;

function TGamePad.CheckStick(const AThumb: TGamePadButton): TPoint;
begin
  if FIntf = nil then
    Result := Point(0, 0)
  else
    Result := FIntf.CheckStick(AThumb);
end;

function TGamePad.CheckTrigger(const AThumb: TGamePadButton): Integer;
begin
  if FIntf = nil then
    Result := 0
  else
    Result := FIntf.CheckTrigger(AThumb);
end;

constructor TGamePad.Create;
begin
  inherited;

  var Factory: IGamePadFactory;
  if
    TPlatformServices.Current.SupportsPlatformService(
      IGamePadFactory,
      Factory
    )
  then
    FIntf := Factory.CreateGamePad
  else
    FIntf := nil;
end;

function TGamePad.GetControllerIndex: Integer;
begin
  if FIntf = nil then
    Result := -1
  else
    Result := FIntf.GetControllerIndex;
end;

function TGamePad.GetStatus: TGamePadButtons;
begin
  if FIntf = nil then
    Result := []
  else
    Result := FIntf.GetStatus;
end;

function TGamePad.IsClicked(const AButton: TGamePadButton): Boolean;
begin
  if FIntf = nil then
    Result := False
  else
    Result := FIntf.IsClicked(AButton);
end;

procedure TGamePad.SetControllerIndex(const AIndex: Integer);
begin
  if FIntf <> nil then
    FIntf.SetControllerIndex(AIndex);
end;

procedure TGamePad.SetDeadZone(const ALeft, ARight: Integer);
begin
  if FIntf <> nil then
    FIntf.SetDeadZone(ALeft, ARight);
end;

end.
