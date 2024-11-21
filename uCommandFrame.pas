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
 *   2024/11/18  Ver 1.0.0  Release
 *
 * Programmed by HOSOKAWA Jun (twitter: @pik)
 *)

unit uCommandFrame;

interface

uses
  System.SysUtils
  , System.Types
  , System.Classes
  , System.Generics.Collections
  , FMX.Types
  , FMX.Graphics
  , FMX.Controls
  , FMX.Controls.Presentation
  , FMX.Forms
  , FMX.StdCtrls
  , FMX.Objects
  , FMX.Layouts
  , FMX.ImgList
  , FMX.ListBox
  , PK.Device.GamePad
  , PK.Device.GamePad.Types
  , uConfig
  ;

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
    rectGrouping: TRectangle;
    procedure btnSeqAddClick(Sender: TObject);
    procedure laySeqInfoNameClick(Sender: TObject);
    procedure btnCommandRemoveClick(Sender: TObject);
    procedure btnSeqDelClick(Sender: TObject);
  private type
    TGlyphs = TList<TGlyph>;
  private var
    FParent: TCommandFrames;
    FPad: TGamePad;
    FImageList: TImageList;
    FCommands: TList<TGlyphs>;
    FItem: TListBoxItem;
    FHasImage: Boolean;
    FOrgGrouping: TRectangle;
    FGroupingRects: TList<TRectangle>;
  private
    procedure AdjustSeqWidth;
    procedure GlyphClickHandler(Sender: TObject);
    procedure SetInfo(const ACommand: TJsonCommand);
    procedure AddCommand(const AButtons: TGamePadButtons);
    procedure CreateGroupingRect;
    procedure ClearGroupingRect;
    procedure DeleteGlyphs(const AIndex: Integer);
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
  uCommandUtils
  , uCommandInputForm
  ;

procedure TframeCommand.AddCommand(const AButtons: TGamePadButtons);
begin
  if AButtons = [] then
    Exit;

  var H := laySeq.Height;
  var W := H + 8;

  var Buttons := FPad.StatusAsArray[AButtons];

  if Length(Buttons) > 0 then
  begin
    var Gs := TGlyphs.Create;
    FCommands.Add(Gs);

    var C := FCommands.Count;

    for var i := 0 to High(Buttons) do
    begin
      var B := Buttons[i];

      var G := TGlyph.Create(laySeq);
      Gs.Add(G);

      G.Images := FImageList;
      G.ImageIndex := StatusToImageIndex([B]);
      G.Align := TAlignLayout.Left;
      G.HitTest := True;
      G.OnClick := GlyphClickHandler;

      G.Margins.Right := 8;

      var X := C * W;
      G.SetBounds(X, 0, H, H);

      G.Parent := laySeq;
      GlyphClickHandler(G);

      Inc(C);
    end;
  end;

  AdjustSeqWidth;
  CreateGroupingRect;
end;

procedure TframeCommand.AdjustSeqWidth;
begin
  var Gs := FCommands[FCommands.Count - 1];
  laySeq.Width :=
    Gs[Gs.Count - 1].BoundsRect.Right + rectSelector.Stroke.Thickness + 4;
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
      This.FItem.Free;
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

  var Glyph := TGlyph(rectSelector.TagObject);
  if Glyph <> nil then
  begin
    var Index := -1;

    for var i := 0 to FCommands.Count - 1 do
    begin
      var tmpIndex := FCommands[i].IndexOf(Glyph);
      if tmpIndex > -1 then
      begin
        Index := i;
        Break;
      end;
    end;

    Glyph.Free;
    FCommands[Index].Remove(Glyph);

    var Next: TGlyph := nil;
    if FCommands[Index].Count > 0 then
    begin
      Next := FCommands[Index][FCommands[Index].Count - 1];
    end
    else
    begin
      DeleteGlyphs(Index);

      var C := FCommands.Count;

      if Index > 0 then
        Dec(Index);

      if Index < C then
        for var i := Index to C - 1 do
        begin
          var GC := FCommands[i].Count;
          if GC > 0 then
          begin
            Next := FCommands[i][GC - 1];
            Break;
          end;
        end;
    end;

    if Next = nil then
    begin
      rectSelector.TagObject := nil;
      rectSelector.Visible := False;
    end
    else
    begin
      rectSelector.TagObject := Next;
      GlyphClickHandler(Next);
      rectSelector.Parent := Next;

      AdjustSeqWidth;
    end;
  end;

  CreateGroupingRect;
end;

procedure TframeCommand.ClearGroupingRect;
begin
  for var R in FGroupingRects do
    R.Free;
  FGroupingRects.Clear;
end;

constructor TframeCommand.CreateCommandFrame(
  const AParent: TListBox;
  const APad: TGamePad;
  const AImageList: TImageList);
begin
  inherited Create(nil);

  FCommands := TList<TGlyphs>.Create;

  FPad := APad;
  FImageList := AImageList;

  FItem := TListBoxItem.Create(nil);
  FItem.Height := pnlSeqeunce.Height + 12;
  FItem.Margins.Bottom := 16;

  FGroupingRects := TList<TRectangle>.Create;

  FOrgGrouping := rectGrouping;
  FOrgGrouping.Visible := False;

  Parent := FItem;

  AParent.InsertObject(
    AParent.Items.Count - 1,
    FItem
  );

  rectSelector.Visible := False;
end;

procedure TframeCommand.CreateGroupingRect;
begin
  ClearGroupingRect;

  var H := laySeq.Height;

  for var Gs in FCommands do
  begin
    var Min: Single := MaxInt;
    var Max: Single := -MaxInt;

    if Gs.Count > 1 then
    begin
      for var G in Gs do
      begin
        var Left := G.BoundsRect.Left;
        var Right := G.BoundsRect.Right;

        if Max < Right then
          Max := Right;

        if Min > Left then
          Min := Left;
      end;

      var R := TRectangle(FOrgGrouping.Clone(laySeq));
      FGroupingRects.Add(R);

      R.SetBounds(Min, 0, Max - Min, H);
      R.Parent := laySeq;
      R.Visible := True;
      R.SendToBack;
    end;
  end;
end;

procedure TframeCommand.DeleteGlyphs(const AIndex: Integer);
begin
  for var G in FCommands[AIndex] do
    G.Free;
  FCommands[AIndex].Free;
  FCommands.Delete(AIndex);
end;

destructor TframeCommand.Destroy;
begin
  ClearGroupingRect;

  for var i := 0 to FCommands.Count - 1 do
    DeleteGlyphs(0);

  FGroupingRects.Free;
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

  if FHasImage then
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

  FHasImage := not ACommand.image.IsEmpty;

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

    for var Ss in Item.sequence do
    begin
      var Buttons: TGamePadButtons := [];
      for var S in Ss do
        Include(Buttons, TGamePadButton(S));

      P.AddCommand(Buttons);
    end;
  end;
end;

procedure TCommandFrames.Save;
begin
  Config.Clear;

  for var i := 0 to FItems.Count - 1 do
  begin
    var F := FItems[i];

    var Seq: TArray<TArray<TGamePadButton>>;
    SetLength(Seq, F.FCommands.Count);

    for var j := 0 to F.FCommands.Count - 1 do
    begin
      for var G in F.FCommands[j] do
        Seq[j] := Seq[j] + [ImageIndexToPadButton(G.ImageIndex)];
    end;

    var Bmp: TBitmap := nil;
    if F.FHasImage then
      Bmp := F.imgSeqAppIcon.Bitmap;

    Config.Add(F.lblSeqName.Text, F.lblSeqPath.Text, Bmp, Seq);
  end;

  Config.Save;
end;

end.
