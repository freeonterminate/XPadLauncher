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
    procedure SetControllerId(const AId: String); override;
    function GetControllerId: String; override;
    function GetPrevStatus: TGamePadButtons; override;
    function GetStatus: TGamePadButtons; override;
    function GetGamePadInfoCount: Integer; override;
    function GetGamePadInfos(const AIndex: Integer): TGamePadInfo; override;
  public
    constructor Create; reintroduce;

    function Check: TGamePadButtons; override;
    function CheckStick(const AThumb: TGamePadButton): TPointF;
      override;
    function CheckTrigger(const AThumb: TGamePadButton): Single;
      override;
    function IsClicked(const AButton: TGamePadButton): Boolean;
      override;
    procedure Vibrate(
      const ALeftMotor, ARightMotor: Single;
      const ADuration: Integer); override;

    procedure SetDeadZone(const ALeft, ARight: Single); override;

    procedure UpdateGamePadInfo; override;

    function CheckController: Boolean; override;
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

function TGamePad.CheckController: Boolean;
begin
  Result := False;
  if FIntf <> nil then
    Result := FIntf.CheckController;
end;

function TGamePad.CheckStick(const AThumb: TGamePadButton): TPointF;
begin
  if FIntf = nil then
    Result := Point(0, 0)
  else
    Result := FIntf.CheckStick(AThumb);
end;

function TGamePad.CheckTrigger(const AThumb: TGamePadButton): Single;
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

function TGamePad.GetControllerId: String;
begin
  if FIntf = nil then
    Result := ''
  else
    Result := FIntf.GetControllerId;
end;

function TGamePad.GetGamePadInfoCount: Integer;
begin
  if FIntf = nil then
    Result := 0
  else
    Result := FIntf.GetGamePadInfoCount;
end;

function TGamePad.GetGamePadInfos(const AIndex: Integer): TGamePadInfo;
begin
  Result := GAMEPADINFO_NONE;
  if FIntf <> nil then
    Result := FIntf.GetGamePadInfos(AIndex)
end;

function TGamePad.GetPrevStatus: TGamePadButtons;
begin
  if FIntf = nil then
    Result := []
  else
    Result := FIntf.GetPrevStatus;
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

procedure TGamePad.SetControllerId(const AId: String);
begin
  if FIntf <> nil then
    FIntf.SetControllerId(AId);
end;

procedure TGamePad.SetDeadZone(const ALeft, ARight: Single);
begin
  if FIntf <> nil then
    FIntf.SetDeadZone(ALeft, ARight);
end;

procedure TGamePad.UpdateGamePadInfo;
begin
  if FIntf <> nil then
    FIntf.UpdateGamePadInfo;
end;

procedure TGamePad.Vibrate(
  const ALeftMotor, ARightMotor: Single;
  const ADuration: Integer);
begin
  if (FIntf <> nil) and (ADuration > 0) then
    FIntf.Vibrate(ALeftMotor, ARightMotor, ADuration);
end;

end.
