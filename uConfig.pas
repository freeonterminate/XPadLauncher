unit uConfig;

interface

uses
  System.SysUtils
  , System.Classes
  , System.JSON.Serializers
  , FMX.Graphics
  , PK.Device.GamePad.Types
  ;

type
  TJsonCommand = record
    name: String;
    path: String;
    image: String;
    sequences: TArray<TArray<Integer>>;
    [JsonIgnore] procedure GetImage(const AImage: TBitmap);
    [JsonIgnore] procedure SetImage(const AImage: TBitmap);
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
      const AImage: TBitmap;
      const ASequences: TArray<TArray<TGamePadButton>>): TJsonCommand;
    procedure Remove(const AInfo: TJsonCommand);
    procedure Clear;
    procedure Save;
    procedure Load;
    property Count: Integer read GetCount;
    property Items[const AIndex: Integer]: TJsonCommand read GetItems; default;
  end;

function Config: TConfig;

implementation

uses
  System.IOUtils
  , System.NetEncoding
  , System.JSON.Types
  {$IFDEF MSWINDOWS}
  , PK.Graphic.IconConverter.Win
  , PK.Graphic.IconUtils.Win
  {$ENDIF}
  ;

function Config: TConfig;
begin
  Result := TConfig.FInstance;
end;

{ TJsonCommand }

procedure TJsonCommand.GetImage(const AImage: TBitmap);
begin
  if AImage = nil then
    Exit;

  if image.IsEmpty then
  begin
    AImage.Assign(nil);

    {$IFDEF MSWINDOWS}
    if TFile.Exists(path) then
    begin
      var Icon := TIconUtils.GetAppIcon(path, 0);
      try
        TIconConverter.IconToBitmap(Icon, AImage);
      finally
        TIconUtils.FreeIcon(Icon);
      end;
    end;
    {$ENDIF}

    Exit;
  end;

  var B64: TBase64Encoding := nil;
  var Base64Data: TStringStream := nil;
  var ImageData: TMemoryStream := nil;
  try
    B64 := TBase64Encoding.Create;
    Base64Data := TStringStream.Create(image);
    ImageData := TMemoryStream.Create;

    B64.Decode(Base64Data, ImageData);
    ImageData.Position := 0;

    AImage.LoadFromStream(ImageData);
  finally
    B64.Free;
    Base64Data.Free;
    ImageData.Free;
  end;
end;

procedure TJsonCommand.SetImage(const AImage: TBitmap);
begin
  image := '';

  if (AImage = nil) or (AImage.IsEmpty) then
    Exit;

  var B64: TBase64Encoding := nil;
  var Base64Data: TStringStream := nil;
  var ImageData: TMemoryStream := nil;
  try
    B64 := TBase64Encoding.Create;
    Base64Data := TStringStream.Create(image);
    ImageData := TMemoryStream.Create;

    AImage.SaveToStream(ImageData);
    ImageData.Position := 0;

    B64.Encode(ImageData, Base64Data);
    Base64Data.Position := 0;

    image := Base64Data.DataString;
  finally
    B64.Free;
    Base64Data.Free;
    ImageData.Free;
  end;
end;

{ TConfig }

function TConfig.Add(
  const AName, APath: String;
  const AImage: TBitmap;
  const ASequences: TArray<TArray<TGamePadButton>>): TJsonCommand;
begin
  Result.name := AName;
  Result.path := APath;

  if (AImage = nil) then
    Result.image := ''
  else
    Result.SetImage(AImage);

  SetLength(Result.sequences, Length(ASequences));
  for var i := 0 to High(ASequences) do
  begin
    for var j := 0 to High(ASequences[i]) do
      Result.sequences[i] := Result.sequences[i] + [Ord(ASequences[i][j])];
  end;

  FItems := FItems + [Result];
end;

procedure TConfig.Clear;
begin
  SetLength(FItems, 0);
end;

class constructor TConfig.CreateClass;
begin
  FInstance := TConfig.Create;
  FInstance.Load;
end;

class destructor TConfig.DestroyClass;
begin
  FInstance.Save;
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

procedure TConfig.Load;
begin
  var Path := GetConfigFilePath;

  SetLength(FItems, 0);

  if not TFile.Exists(Path) then
    Exit;

  var Json := TFile.ReadAllText(Path, TEncoding.UTF8);
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

procedure TConfig.Save;
begin
  var Path := GetConfigFilePath;

  var Dir := ExtractFilePath(Path);
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
      S.Formatting := TJsonFormatting.Indented;

      var Json := S.Serialize<TJsonCommands>(Commands);

      TFile.WriteAllText(Path, Json);
    finally
      S.Free;
    end;
  except
  end;
end;

end.
