(*
 * XPad Launcher
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
 *   2024/11/23  Ver 1.0.0  Release
 *
 * Programmed by HOSOKAWA Jun (twitter: @pik)
 *)

unit uConfig;

interface

uses
  System.SysUtils
  , System.Classes
  , System.JSON.Serializers
  , FMX.Graphics
  , PK.AutoRun
  , PK.Device.GamePad.Types
  ;

type
  TSequence = TArray<TGamePadButtonArray>;
  TSequenceArray = TArray<TSequence>;

  TJsonCommand = record
    name: String;
    path: String;
    image: String;
    sequence: TSequence;
    [JsonIgnore] procedure GetImage(const AImage: TBitmap);
    [JsonIgnore] procedure SetImage(const AImage: TBitmap);
  end;

  TJsonCommands = record
    controllerId: String;
    count: Integer;
    items: TArray<TJsonCommand>;
  end;

  TConfig = class
  private class var
    FInstance: TConfig;
    FAutoRun: TAutoRun;
  public
    class constructor CreateClass;
    class destructor DestroyClass;
    class function GetConfigFilePath: String;
  private var
    FItems: TArray<TJsonCommand>;
    FSeqs: TSequenceArray;
    FSortedSeqs: TSequenceArray;
    FControllerId: String;
    FIsFirstRun: Boolean;
  private
    procedure CreateSortedSeqs;
    function GetCount: Integer;
    function GetItems(const AIndex: Integer): TJsonCommand;
    function GetSequence(const AIndex: Integer): TSequence;
    function GetSortedSequence(const AIndex: Integer): TSequence;
  public
    function Add(
      const AName, APath: String;
      const AImage: TBitmap;
      const ASequence: TSequence): TJsonCommand;
    procedure Remove(const AInfo: TJsonCommand);
    procedure Clear;
    function ExistsConfigJson: Boolean;
    procedure Save;
    procedure Load;
    function SortedIndexToIndex(const ASortedIndex: Integer): Integer;
    property Count: Integer read GetCount;
    property Items[const AIndex: Integer]: TJsonCommand read GetItems; default;
    property Sequence[const AIndex: Integer]: TSequence read GetSequence;
    property SortedSequence[const AIndex: Integer]: TSequence
      read GetSortedSequence;
    property ControllerId: String read FControllerId write FControllerId;
    property IsFirstRun: Boolean read FIsFirstRun;
    class property AutoRun: TAutoRun read FAutoRun;
  end;

function Config: TConfig;

implementation

uses
  System.IOUtils
  , System.Generics.Collections
  , System.Generics.Defaults
  , System.NetEncoding
  , System.JSON.Types
  {$IFDEF MSWINDOWS}
  , PK.Graphic.IconConverter.Win
  , PK.Graphic.IconUtils.Win
  {$ENDIF}
  , PK.Utils.Log
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
  const ASequence: TSequence): TJsonCommand;
begin
  Result.name := AName;
  Result.path := APath;

  if (AImage = nil) then
    Result.image := ''
  else
    Result.SetImage(AImage);

  SetLength(Result.sequence, Length(ASequence));
  for var i := 0 to High(ASequence) do
  begin
    for var j := 0 to High(ASequence[i]) do
      Result.sequence[i] := Result.sequence[i] + [ASequence[i][j]];
  end;

  FItems := FItems + [Result];
  FSeqs := FSeqs + [ASequence];
  CreateSortedSeqs;
end;

procedure TConfig.Clear;
begin
  SetLength(FItems, 0);
  SetLength(FSeqs, 0);
  SetLength(FSortedSeqs, 0);
end;

class constructor TConfig.CreateClass;
begin
  FInstance := TConfig.Create;
  FInstance.FIsFirstRun := not FInstance.ExistsConfigJson;
  FInstance.Load;
  FAutoRun := TAutoRun.Create('XPadLauncher');
end;

procedure TConfig.CreateSortedSeqs;
begin
  SetLength(FSortedSeqs, 0);

  var Len := Length(FSeqs);
  SetLength(FSortedSeqs, Len);
  for var i := 0 to High(FSeqs) do
    FSortedSeqs[i] := FSeqs[i];

  TArray.Sort<TSequence>(
    FSortedSeqs,
    TComparer<TSequence>.Construct(
      function(const L, R: TSequence): Integer
      begin
        Result := Length(R) - Length(L);
      end
    )
  );
end;

class destructor TConfig.DestroyClass;
begin
  FAutoRun.Free;
  FInstance.Save;
  FInstance.Free;
end;

function TConfig.ExistsConfigJson: Boolean;
begin
  Result := TFile.Exists(GetConfigFilePath);
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
    SetLength(Result.sequence, 0);
  end;
end;

function TConfig.GetSequence(const AIndex: Integer): TSequence;
begin
  if (AIndex > -1) and (AIndex < Length(FSeqs)) then
    Result := FSeqs[AIndex]
  else
    FillChar(Result, SizeOf(Result), 0);
end;

function TConfig.GetSortedSequence(const AIndex: Integer): TSequence;
begin
  if (AIndex > -1) and (AIndex < Length(FSeqs)) then
    Result := FSortedSeqs[AIndex]
  else
    FillChar(Result, SizeOf(Result), 0);
end;

procedure TConfig.Load;
begin
  SetLength(FItems, 0);

  if not ExistsConfigJson then
    Exit;

  var Path := GetConfigFilePath;
  var Json := TFile.ReadAllText(Path, TEncoding.UTF8);
  if Json.IsEmpty then
    Exit;

  try
    var S := TJsonSerializer.Create;
    try
      var Commands := S.Deserialize<TJsonCommands>(Json);

      SetLength(FItems, Length(Commands.items));
      for var i := 0 to High(Commands.items) do
        FItems[i] := Commands.items[i];

      FControllerId := Commands.controllerId;
    finally
      S.Free;
    end;
  except
  end;

  SetLength(FSeqs, Length(FItems));
  for var i := 0 to High(FItems) do
  begin
    var Seq := FItems[i].sequence;
    SetLength(FSeqs[i], Length(Seq));

    for var j := 0 to High(Seq) do
    begin
      SetLength(FSeqs[i][j], Length(Seq[j]));

      for var k := 0 to High(Seq[j]) do
        FSeqs[i][j][k] := TGamePadButton(Seq[j][k]);
    end;
  end;

  CreateSortedSeqs;

  // 確認
  {
  var SB := TStringBuilder.Create;
  try
    SB.Append(sLineBreak);
    for var i := 0 to High(FSeqs) do
    begin
      SB.Append('i:');
      SB.Append(i);
      var Seqs := FSeqs[i];
      for var j := 0 to High(Seqs) do
      begin
        SB.Append(' j:');
        SB.Append(j);
        var Seq := Seqs[j];

        for var k := 0 to High(Seq) do
        begin
          SB.Append(' ');
          SB.Append(Seq[k].ToString);
        end;
      end;

      SB.Append(sLineBreak);
    end;
  finally
    SB.Free;
  end;
  // }
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

  Commands.controllerId := FControllerId;
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

function TConfig.SortedIndexToIndex(const ASortedIndex: Integer): Integer;
begin
  Result := -1;
  for var i := 0 to High(FSeqs) do
    if FSortedSeqs[ASortedIndex] = FSeqs[i] then
    begin
      Result := i;
      Break;
    end;
end;

end.
