unit uXPadCommand;

interface

uses
  System.SysUtils
  , System.Generics.Collections
  , FMX.Types
  , PK.Device.GamePad.Types
  , PK.Device.GamePad
  ;

type
  TCommandBuffer = class
  private const
    BUFFER_LEN = 12;
  private type
    TSequence = TArray<TGamePadButton>;
    TSequences = TList<TSequence>;
  private var
    FPad: TGamePad;
    FBuff: TSequence;
    FIndex: Integer;
    FSequences: TSequences;
  private
  public
    constructor Create(const AGamePad: TGamePad);
    destructor Destroy; override;
    function CommandIndexOf(const ASequence: TSequence): Integer;
    procedure RegisterCommand(const ASequence: TSequence);
    procedure UnregisterCommand(const ASequence: TSequence);
    procedure Update;
  end;

implementation

{ TCommandBuffer }

function TCommandBuffer.CommandIndexOf(const ASequence: TSequence): Integer;
begin
  Result := -1;

  var C := FSequences.Count;
  for var i := 0 to C - 1 do
  begin
    var S := FSequences[i];

    if Length(S) <> Length(ASequence) then
      Continue;

    var IsEqual := True;
    for var j := 0 to High(S) do
    begin
      if S[j] <> ASequence[j] then
      begin
        IsEqual := False;
        Break;
      end;
    end;

    if IsEqual then
    begin
      Result := i;
      Break;
    end;
  end;
end;

constructor TCommandBuffer.Create(const AGamePad: TGamePad);
begin
  inherited Create;

  FPad := AGamePad;
  FSequences := TSequences.Create;
  SetLength(FBuff, BUFFER_LEN);
end;

destructor TCommandBuffer.Destroy;
begin
  FSequences.Free;

  inherited;
end;

procedure TCommandBuffer.RegisterCommand(const ASequence:TSequence);
begin
  if CommandIndexOf(ASequence) < 0 then
    FSequences.Add(ASequence);
end;

procedure TCommandBuffer.UnregisterCommand(const ASequence: TSequence);
begin
  var Index := CommandIndexOf(ASequence);
  if (Index > -1) and (Index < FSequences.Count) then
    FSequences.Delete(Index);
end;

procedure TCommandBuffer.Update;
begin
  var B := FPad.Check;
end;

end.
