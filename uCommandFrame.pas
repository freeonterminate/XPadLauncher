unit uCommandFrame;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Generics.Collections,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Layouts, FMX.Controls.Presentation, FMX.ImgList, FMX.ListBox,
  PK.Device.GamePad, PK.Device.GamePad.Types, uConfig;

type
  TCommandFrames = class;

  TframeCommand = class(TFrame)
    pnlSeqeunce: TPanel;
    laySeqMain: TLayout;
    laySeqInfo: TLayout;
    laySeqInfoName: TLayout;
    lblSeqName: TLabel;
    lblSeqPath: TLabel;
    laySeqDelete: TLayout;
    btnCommandRemove: TButton;
    pathSeqDelete: TPath;
    laySeqAppImageBase: TLayout;
    imgSeqAppIcon: TImage;
    lblSeqMessage: TLabel;
    laySeqBase: TLayout;
    laySeqOpBase: TLayout;
    btnSeqAdd: TButton;
    pathSeqAdd: TPath;
    btnSeqDel: TButton;
    pathSeqDel: TPath;
    pnlSeqBaseFrame: TPanel;
    scSeqBase: THorzScrollBox;
    laySeq: TLayout;
    rectSelector: TRectangle;
    procedure btnSeqAddClick(Sender: TObject);
    procedure laySeqInfoNameClick(Sender: TObject);
    procedure btnCommandRemoveClick(Sender: TObject);
    procedure btnSeqDelClick(Sender: TObject);
  private var
    FParent: TCommandFrames;
    FPad: TGamePad;
    FImageList: TImageList;
    FCommands: TList<TGlyph>;
    FItem: TListBoxItem;
  private
    procedure GlyphClickHandler(Sender: TObject);
    procedure SetInfo(const ACommand: TJsonCommand);
    procedure AddCommand(const AButtons: TGamePadButtons);
  public
    constructor CreateCommandFrame(
      const AParent: TListBox;
      const APad: TGamePad;
      const AImageList: TImageList);
    destructor Destroy; override;
  end;

  TCommandFrames = class
  private var
    FPad: TGamePad;
    FImageList: TImageList;
    FListBox: TListBox;
    FItems: TList<TframeCommand>;
  public
    constructor Create(
      const APad: TGamePad;
      const AImageList: TImageList;
      const AListBox: TListBox);
    destructor Destroy; override;
    procedure Clear;
    function Add: TframeCommand;
    procedure Load;
    procedure Save;
  end;


implementation

{$R *.fmx}

uses
  uButtonIndexes
  , uCommandInputForm
  ;

procedure TframeCommand.AddCommand(const AButtons: TGamePadButtons);
begin
  if AButtons = [] then
    Exit;

  var G := TGlyph.Create(laySeq);
  FCommands.Add(G);

  G.Images := FImageList;
  G.ImageIndex := StatusToImageIndex(AButtons);
  G.Align := TAlignLayout.Left;
  G.HitTest := True;
  G.OnClick := GlyphClickHandler;

  G.Margins.Right := 8;
  var H := laySeq.Height;
  var W := H + 8;
  var X := FCommands.Count * W;
  G.SetBounds(X, 0, H, H);

  G.Parent := laySeq;
  GlyphClickHandler(G);

  laySeq.Width := X;
end;

procedure TframeCommand.btnCommandRemoveClick(Sender: TObject);
begin
  var This := Self;
  TThread.ForceQueue(
    nil,
    procedure
    begin
      FParent.FItems.Remove(This);
      This.Free;
    end
  );
end;

procedure TframeCommand.btnSeqAddClick(Sender: TObject);
begin
  var Buttons := FPad.Status;
  if Buttons <> [] then
    AddCommand(FPad.Status);
end;

procedure TframeCommand.btnSeqDelClick(Sender: TObject);
begin
  if not rectSelector.Visible then
    Exit;

  rectSelector.Parent := nil;

  var G := TGlyph(rectSelector.TagObject);
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
      rectSelector.TagObject := G;
      GlyphClickHandler(G);

      rectSelector.Parent := G;

      laySeq.Width := FCommands[C - 1].BoundsRect.Width;
    end
    else
    begin
      rectSelector.TagObject := nil;
      rectSelector.Visible := False;
    end;
  end;
end;

constructor TframeCommand.CreateCommandFrame(
  const AParent: TListBox;
  const APad: TGamePad;
  const AImageList: TImageList);
begin
  inherited Create(nil);

  FCommands := TList<TGlyph>.Create;

  FPad := APad;
  FImageList := AImageList;

  FItem := TListBoxItem.Create(nil);
  FItem.Height := pnlSeqeunce.Height + 12;
  FItem.Margins.Bottom := 16;

  Parent := FItem;

  AParent.InsertObject(
    AParent.Items.Count - 1,
    FItem
  );

  rectSelector.Visible := False;
end;

destructor TframeCommand.Destroy;
begin
  FCommands.Free;
  inherited;
end;

procedure TframeCommand.GlyphClickHandler(Sender: TObject);
var
  G: TGlyph absolute Sender;
begin
  rectSelector.Visible := True;
  rectSelector.TagObject := G;

  var M := rectSelector.Stroke.Thickness;
  rectSelector.SetBounds(-M, -M, rectSelector.Width, rectSelector.Height);

  rectSelector.Parent := G;
end;

procedure TframeCommand.laySeqInfoNameClick(Sender: TObject);
begin
  var Command: TJsonCommand;
  Command.name := lblSeqName.Text;
  Command.path := lblSeqPath.Text;
  Command.SetImage(imgSeqAppIcon.Bitmap);

  ShowInputCommand(
    Screen.ActiveForm,
    Command,
    procedure(const ASuccess: Boolean; const ACommand: TJsonCommand)
    begin
      if ASuccess then
        SetInfo(ACommand);
    end
  );
end;

procedure TframeCommand.SetInfo(const ACommand: TJsonCommand);
begin
  lblSeqName.Text := ACommand.name;
  lblSeqPath.Text := ACommand.path;
  ACommand.GetImage(imgSeqAppIcon.Bitmap);

  lblSeqMessage.Visible := False;
end;

{ TCommandFrames }

function TCommandFrames.Add: TframeCommand;
begin
  Result := TframeCommand.CreateCommandFrame(FListBox, FPad, FImageList);
  Result.FParent := Self;
  FItems.Add(Result);
end;

procedure TCommandFrames.Clear;
begin
  for var Item in FItems do
    Item.Free;

  FItems.Clear;
end;

constructor TCommandFrames.Create(
  const APad: TGamePad;
  const AImageList: TImageList;
  const AListBox: TListBox);
begin
  inherited Create;

  FPad := APad;
  FImageList := AImageList;
  FListBox := AListBox;

  FItems := TList<TframeCommand>.Create;

  Load;
end;

destructor TCommandFrames.Destroy;
begin
  Clear;
  FItems.Free;

  inherited;
end;

procedure TCommandFrames.Load;
begin
  Clear;

  for var i := 0 to Config.Count - 1 do
  begin
    var Item := Config[i];

    var P := Add;
    P.SetInfo(Item);

    for var C in Item.sequences do
      P.AddCommand([TGamePadButton(C)]);
  end;
end;

procedure TCommandFrames.Save;
begin
  Config.Clear;

  for var i := 0 to FItems.Count - 1 do
  begin
    var F := FItems[i];

    var Seq: TArray<TGamePadButton>;
    for var j := 0 to F.FCommands.Count - 1 do
      Seq := Seq + [ImageIndexToPadButton(F.FCommands[j].ImageIndex)];

    Config.Add(
      F.lblSeqName.Text,
      F.lblSeqPath.Text,
      F.imgSeqAppIcon.Bitmap,
      Seq
    );
  end;

  Config.Save;
end;

end.
