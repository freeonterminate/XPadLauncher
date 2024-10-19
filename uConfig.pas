unit uConfig;

interface

uses
  System.SysUtils
  , PK.Device.GamePad.Types
  ;

type
  TJsonCommand = record
    name: String;
    path: String;
    sequences: TArray<Integer>
  end;

  TJsonCommands = record
    count: Integer;
    items: TArray<TJsonCommand>;
  end;

  TConfig = class
  private class var
    FInstance: TConfig;
  public
    class constructor CreateClass;
    class destructor DestroyClass;
    class function GetConfigFilePath: String;
  private var
    FItems: TArray<TJsonCommand>;
  private
    function GetCount: Integer;
    function GetItems(const AIndex: Integer): TJsonCommand;
  public
    function Add(
      const AName, APath: String;
      const ASequences: TArray<TGamePadButton>): TJsonCommand;
    procedure Remove(const AInfo: TJsonCommand);
    procedure Clear;
    procedure SaveToFile(const APath: String);
    procedure LoadFromFile(const APath: String);
    property Count: Integer read GetCount;
    property Items[const AIndex: Integer]: TJsonCommand read GetItems; default;
  end;

function Config: TConfig;

implementation

uses
  System.IOUtils
  , System.JSON.Serializers
  ;

function Config: TConfig;
begin
  Result := TConfig.FInstance;
end;

{ TConfig }

function TConfig.Add(
  const AName, APath: String;
  const ASequences: TArray<TGamePadButton>): TJsonCommand;
begin
  Result.name := AName;
  Result.path := APath;

  SetLength(Result.sequences, Length(ASequences));
  for var i := 0 to High(ASequences) do
    Result.sequences[i] := Ord(ASequences[i]);

  FItems := FItems + [Result];
end;

procedure TConfig.Clear;
begin
  SetLength(FItems, 0);
end;

class constructor TConfig.CreateClass;
begin
  FInstance := TConfig.Create;
  FInstance.LoadFromFile(GetConfigFilePath);
end;

class destructor TConfig.DestroyClass;
begin
  FInstance.SaveToFile(GetConfigFilePath);
  FInstance.Free;
end;

class function TConfig.GetConfigFilePath: String;
begin
  Result :=
    TPath.Combine(TPath.GetHomePath, 'piksware\XPadLauncher', 'config.json');
end;

function TConfig.GetCount: Integer;
begin
  Result := Length(FItems);
end;

function TConfig.GetItems(const AIndex: Integer): TJsonCommand;
begin
  if (AIndex > -1) and (AIndex < Length(FItems)) then
    Result := FItems[AIndex]
  else
  begin
    Result.name := '';
    Result.path := '';
    SetLength(Result.sequences, 0);
  end;
end;

procedure TConfig.LoadFromFile(const APath: String);
begin
  SetLength(FItems, 0);

  if not TFile.Exists(APath) then
    Exit;

  var Json := TFile.ReadAllText(APath, TEncoding.UTF8);
  if Json.IsEmpty then
    Exit;

  try
    var S := TJsonSerializer.Create;
    try
      var Commands := S.Deserialize<TJsonCommands>(Json);

      FItems := Commands.items;
    finally
      S.Free;
    end;
  except
  end;
end;

procedure TConfig.Remove(const AInfo: TJsonCommand);
begin
  for var i := 0 to High(FItems) do
    if FItems[i].path.ToUpper = AInfo.path.ToUpper then
    begin
      FItems := Copy(FItems, 0, i) + Copy(FItems, i + 1);
      Break;
    end;
end;

procedure TConfig.SaveToFile(const APath: String);
begin
  var Dir := ExtractFilePath(APath);
  if not TDirectory.Exists(Dir) then
    TDirectory.CreateDirectory(Dir);

  if not TDirectory.Exists(Dir) then
    Exit;

  var Commands: TJsonCommands;
  Commands.count := GetCount;
  SetLength(Commands.items, Commands.count);

  for var i := 0 to GetCount - 1 do
    Commands.items[i] := FItems[i];

  try
    var S := TJsonSerializer.Create;
    try
      var Json := S.Serialize<TJsonCommands>(Commands);

      TFile.WriteAllText(APath, Json);
    finally
      S.Free;
    end;
  except
  end;
end;

end.
