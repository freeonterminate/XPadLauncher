﻿unit uCommandPanel;

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
  , PK.Device.GamePad.Types
  , PK.Device.GamePad
  ;

type
  TCommandPanels = class;

  TCommandPanel = class
  private var
    FParent: TCommandPanels;
    FItem: TListBoxItem;
    FPanel: TPanel;
    FPalette: TLayout;
    FSelector: TRectangle;
    FCommands: TList<TGlyph>;
  private
    procedure RemoveBtnClickHandler(Sender: TObject);
    procedure AddBtnClickHandler(Sender: TObject);
    procedure DelBtnClickHandler(Sender: TObject);
    procedure GlyphClickHandler(Sender: TObject);
    function GetCount: Integer;
    function GetCommands(const AIndex: Integer): TGamePadButton;
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
    FItems: TList<TCommandPanel>;
  public
    constructor Create(
      const APad: TGamePad;
      const AImageList: TImageList;
      const AListBox: TListBox;
      const APanel: TPanel);
    destructor Destroy; override;
    function Add: TCommandPanel;
  end;

implementation

uses
  System.DateUtils
  , FMX.Types
  , uButtonIndexes
  ;

{ TCommandPanel }

procedure TCommandPanel.AddBtnClickHandler(Sender: TObject);
begin
  if FParent.FPad.Status = [] then
    Exit;

  var G := TGlyph.Create(FPalette);
  FCommands.Add(G);

  G.Images := FParent.FImageList;
  G.ImageIndex := GetImageIndex(FParent.FPad.Status);
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
  FPalette := TLayout(FPanel.FindComponent('laySeq'));
  FSelector := TRectangle(FPanel.FindComponent('rectSelector'));
  FSelector.Visible := False;

  RemoveBtn.OnClick := RemoveBtnClickHandler;
  AddBtn.OnClick := AddBtnClickHandler;
  DelBtn.OnClick := DelBtnClickHandler;

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
  Result := GetGamePadButton(FCommands[AIndex].ImageIndex);
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

{ TCommandPanels }

function TCommandPanels.Add: TCommandPanel;
begin
  Result := TCommandPanel.Create(Self);
  FItems.Add(Result);
end;

constructor TCommandPanels.Create(
  const APad: TGamePad;
  const AImageList: TImageList;
  const AListBox: TListBox;
  const APanel: TPanel);
begin
  inherited Create;

  FPad := APad;
  FImageList := AImageList;
  FListBox := AListBox;

  FOriginalPanel := TMemoryStream.Create;
  FOriginalPanel.WriteComponent(APanel);
  FOrignalHeight := APanel.Height;
  APanel.Visible := False;

  FItems := TList<TCommandPanel>.Create;
end;

destructor TCommandPanels.Destroy;
begin
  FOriginalPanel.Free;

  for var Item in FItems do
    Item.Free;

  FItems.Free;

  inherited;
end;

end.
