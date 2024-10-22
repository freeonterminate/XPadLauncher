unit uCommandPanel;

interface

uses
  System.SysUtils
  , System.Classes
  , System.Types
  , System.Generics.Collections
  , FMX.ListBox
  , FMX.Layouts
  , FMX.StdCtrls
  , FMX.Objects
  , FMX.ImgList
  , FMX.Controls
  , PK.Device.GamePad.Types
  , PK.Device.GamePad
  , uConfig
  ;

type
  TCommandPanels = class;

  TCommandPanel = class
  private var
    FParent: TCommandPanels;
    FItem: TListBoxItem;
    FPanel: TPanel;
    FPalette: TLayout;
    FInfo: TLayout;
    FInfoName: TLabel;
    FInfoPath: TLabel;
    FInfoImage: TImage;
    FSelector: TRectangle;
    FCommands: TList<TGlyph>;
  private
    procedure RemoveBtnClickHandler(Sender: TObject);
    procedure AddBtnClickHandler(Sender: TObject);
    procedure DelBtnClickHandler(Sender: TObject);
    procedure GlyphClickHandler(Sender: TObject);
    procedure InfoClickHandler(Sender: TObject);
    function GetCount: Integer;
    function GetCommands(const AIndex: Integer): TGamePadButton;
    procedure AddCommand(const AButtons: TGamePadButtons);
    procedure SetNameAndPath(const ACommand: TJsonCommand);
  public
    constructor Create(const AParent: TCommandPanels);
    destructor Destroy; override;
    property Items[const AIndex: Integer]: TGamePadButton read GetCommands;
    property Count: Integer read GetCount;
    property ListItem: TListBoxItem read FItem;
    property Panel: TPanel read FPanel;
  end;

  TCommandPanels = class
  private var
    FOriginalPanel: TMemoryStream;
    FOrignalHeight: Single;
    FPad: TGamePad;
    FImageList: TImageList;
    FListBox: TListBox;
    FStyleBook: TStyleBook;
    FItems: TList<TCommandPanel>;
  private
    procedure Load;
    procedure Save;
  public
    constructor Create(
      const APad: TGamePad;
      const AImageList: TImageList;
      const AListBox: TListBox;
      const APanel: TPanel;
      const AStyleBook: TStyleBook);
    destructor Destroy; override;
    procedure Clear;
    function Add: TCommandPanel;
  end;

implementation

uses
  System.DateUtils
  , System.JSON.Serializers
  , System.IOUtils
  , FMX.Types
  , FMX.Forms
  , uButtonIndexes
  , uCommandInputForm
  {$IFDEF MSWINDOWS}
  , PK.Graphic.IconConverter.Win
  , PK.Graphic.IconUtils.Win
  {$ENDIF}
  ;

{ TCommandPanel }

procedure TCommandPanel.AddBtnClickHandler(Sender: TObject);
begin
  AddCommand(FParent.FPad.Status);
end;

procedure TCommandPanel.AddCommand(const AButtons: TGamePadButtons);
begin
  if AButtons = [] then
    Exit;

  var G := TGlyph.Create(FPalette);
  FCommands.Add(G);

  G.Images := FParent.FImageList;
  G.ImageIndex := StatusToImageIndex(AButtons);
  G.Align := TAlignLayout.Left;
  G.HitTest := True;
  G.OnClick := GlyphClickHandler;

  G.Margins.Right := 8;
  var H := FPalette.Height;
  var W := H + 8;
  var X := FCommands.Count * W;
  G.SetBounds(X, 0, H, H);

  G.Parent := FPalette;
  GlyphClickHandler(G);

  FPalette.Width := X;
end;

constructor TCommandPanel.Create(const AParent: TCommandPanels);
begin
  inherited Create;

  FParent := AParent;

  FItem := TListBoxItem.Create(nil);
  FItem.Height := FParent.FOrignalHeight + 12;
  FItem.Margins.Bottom := 8;

  FParent.FOriginalPanel.Position := 0;
  FPanel := TPanel(FParent.FOriginalPanel.ReadComponent(nil));
  FPanel.Margins.Rect := Rect(4, 4, 4, 4);
  FPanel.Align := TAlignLayout.Contents;
  FPanel.Name := 'Panel' + DateTimeToMilliseconds(Now).ToString;

  var RemoveBtn := TButton(FPanel.FindComponent('btnCommandRemove'));
  var AddBtn := TButton(FPanel.FindComponent('btnSeqAdd'));
  var DelBtn := TButton(FPanel.FindComponent('btnSeqDel'));
  RemoveBtn.OnClick := RemoveBtnClickHandler;
  AddBtn.OnClick := AddBtnClickHandler;
  DelBtn.OnClick := DelBtnClickHandler;

  FPalette := TLayout(FPanel.FindComponent('laySeq'));
  FSelector := TRectangle(FPanel.FindComponent('rectSelector'));
  FSelector.Visible := False;

  FInfo := TLayout(FPanel.FindComponent('laySeqInfoName'));
  FInfoName := TLabel(FPanel.FindComponent('lblSeqName'));
  FInfoPath := TLabel(FPanel.FindComponent('lblSeqPath'));
  FInfoImage := TImage(FPanel.FindComponent('imgSeqAppIcon'));
  FInfo.OnClick := InfoClickHandler;
  FInfoName.Text := '';
  FInfoPath.Text := '';

  FPanel.Parent := FItem;

  FParent.FListBox.InsertObject(
    FParent.FListBox.Items.Count - 1,
    FItem
  );

  FCommands := TList<TGlyph>.Create;
end;

procedure TCommandPanel.DelBtnClickHandler(Sender: TObject);
begin
  if not FSelector.Visible then
    Exit;

  FSelector.Parent := nil;

  var G := TGlyph(FSelector.TagObject);
  if G <> nil then
  begin
    var Index := FCommands.IndexOf(G);

    G.Free;
    FCommands.Remove(G);

    if FCommands.Count > 0 then
    begin
      var C := FCommands.Count;
      if Index >= C then
        Index := C - 1;

      G := FCommands[Index];
      FSelector.TagObject := G;
      GlyphClickHandler(G);

      FSelector.Parent := G;

      FPalette.Width := FCommands[C - 1].BoundsRect.Width;
    end
    else
    begin
      FSelector.TagObject := nil;
      FSelector.Visible := False;
    end;
  end;
end;

destructor TCommandPanel.Destroy;
begin
  for var G in FCommands do
    G.Free;

  FItem.Free;

  FCommands.Free;
  inherited;
end;

function TCommandPanel.GetCommands(const AIndex: Integer): TGamePadButton;
begin
  Result := ImageIndexToPadButton(FCommands[AIndex].ImageIndex);
end;

function TCommandPanel.GetCount: Integer;
begin
  Result := FCommands.Count;
end;

procedure TCommandPanel.GlyphClickHandler(Sender: TObject);
var
  G: TGlyph absolute Sender;
begin
  FSelector.Visible := True;
  FSelector.TagObject := G;

  var M := FSelector.Stroke.Thickness;
  FSelector.SetBounds(-M, -M, FSelector.Width, FSelector.Height);

  FSelector.Parent := G;
end;

procedure TCommandPanel.InfoClickHandler(Sender: TObject);
begin
  var Command: TJsonCommand;
  Command.name := FInfoName.Text;
  Command.path := FInfoPath.Text;
  Command.SetImage(FInfoImage.Bitmap);

  ShowInputCommand(
    Screen.ActiveForm,
    Command,
    procedure(const ASuccess: Boolean; const ACommand: TJsonCommand)
    begin
      if ASuccess then
        SetNameAndPath(ACommand);
    end
  );
end;

procedure TCommandPanel.RemoveBtnClickHandler(Sender: TObject);
begin
  var This := Self;
  TThread.ForceQueue(
    nil,
    procedure
    begin
      This.Free;
      FParent.FItems.Remove(This);
    end
  );
end;

procedure TCommandPanel.SetNameAndPath(const ACommand: TJsonCommand);
begin
    FInfoName.Text := ACommand.name;
    FInfoPath.Text := ACommand.path;
    ACommand.GetImage(FInfoImage.Bitmap);

    TLabel(FPanel.FindComponent('lblSeqMessage')).Visible := False;
end;

{ TCommandPanels }

function TCommandPanels.Add: TCommandPanel;
begin
  Result := TCommandPanel.Create(Self);
  FItems.Add(Result);
end;

procedure TCommandPanels.Clear;
begin
  for var Item in FItems do
    Item.Free;

  FItems.Clear;
end;

constructor TCommandPanels.Create(
  const APad: TGamePad;
  const AImageList: TImageList;
  const AListBox: TListBox;
  const APanel: TPanel;
  const AStyleBook: TStyleBook);
begin
  inherited Create;

  FPad := APad;
  FImageList := AImageList;
  FListBox := AListBox;
  FStyleBook := AStyleBook;

  FOriginalPanel := TMemoryStream.Create;
  FOriginalPanel.WriteComponent(APanel);
  FOrignalHeight := APanel.Height;
  APanel.Visible := False;

  FItems := TList<TCommandPanel>.Create;

  Load;
end;

destructor TCommandPanels.Destroy;
begin
  Save;

  FOriginalPanel.Free;

  for var Item in FItems do
    Item.Free;

  FItems.Free;

  inherited;
end;

procedure TCommandPanels.Load;
begin
  Clear;

  for var i := 0 to Config.Count - 1 do
  begin
    var Item := Config[i];

    var P := Add;
    P.SetNameAndPath(Item);

    for var C in Item.sequences do
      P.AddCommand([TGamePadButton(C)]);
  end;
end;

procedure TCommandPanels.Save;
begin
  Config.Clear;

  for var i := 0 to FItems.Count - 1 do
  begin
    var P := FItems[i];

    var Seq: TArray<TGamePadButton>;
    for var j := 0 to P.FCommands.Count - 1 do
      Seq := Seq + [ImageIndexToPadButton(P.FCommands[j].ImageIndex)];

    Config.Add(P.FInfoName.Text, P.FInfoPath.Text, Seq);
  end;
end;

end.
