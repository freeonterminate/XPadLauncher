unit uConfigForm;

interface

uses
  System.SysUtils
  , System.Classes
  , System.ImageList
  , System.Types
  , System.UITypes
  , FMX.Controls
  , FMX.Controls.Presentation
  , FMX.Dialogs
  , FMX.Effects
  , FMX.Forms
  , FMX.Graphics
  , FMX.ImgList
  , FMX.Layouts
  , FMX.ListBox
  , FMX.Objects
  , FMX.Types
  , FMX.StdCtrls
  , PK.Device.GamePad
  , uCommandPanel
  ;

type
  TfrmConfig = class(TForm)
    timerUpdate: TTimer;
    glpA: TGlyph;
    styleAir: TStyleBook;
    glpB: TGlyph;
    glpX: TGlyph;
    glpY: TGlyph;
    glpBack: TGlyph;
    glpStart: TGlyph;
    glpCR: TGlyph;
    glpLB: TGlyph;
    glpRB: TGlyph;
    glpLT: TGlyph;
    glpRT: TGlyph;
    glpLS: TGlyph;
    glpRS: TGlyph;
    glpLStick: TGlyph;
    glpRStick: TGlyph;
    pnlButtonSide: TPanel;
    pnlFront: TPanel;
    lblTitle: TLabel;
    layRoot: TLayout;
    layButtons: TLayout;
    laySequenceBase: TLayout;
    lstbxSequences: TListBox;
    btnClose: TButton;
    pnlSeqeunce: TPanel;
    imgSeqAppIcon: TImage;
    scSeqBase: THorzScrollBox;
    laySeq: TLayout;
    laySeqInfo: TLayout;
    btnCommandRemove: TButton;
    laySeqInfoName: TLayout;
    lblSeqName: TLabel;
    laySeqDelete: TLayout;
    laySeqMain: TLayout;
    laySeqOpBase: TLayout;
    laySeqBase: TLayout;
    lblSeqPath: TLabel;
    btnSeqAdd: TButton;
    btnSeqDel: TButton;
    pathSeqAdd: TPath;
    pathSeqDel: TPath;
    pathSeqDelete: TPath;
    pnlSeqBaseFrame: TPanel;
    itemSeqAdd: TListBoxItem;
    rectSeqAddButton: TRectangle;
    pathSeqAddButton: TPath;
    rectSelector: TRectangle;
    effectTitleGlow: TGlowEffect;
    layTitle: TLayout;
    Image1: TImage;
    dlgOpen: TOpenDialog;
    laySeqAppImageBase: TLayout;
    lblSeqMessage: TLabel;
    procedure FormDestroy(Sender: TObject);
    procedure timerUpdateTimer(Sender: TObject);
    procedure rectSeqAddButtonMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure btnCloseClick(Sender: TObject);
  private var
    FPad: TGamePad;
    FImageList: TImageList;
    FCommandPanels: TCommandPanels;
  private
    procedure Init(const APad: TGamePad; const AImageList: TImageList);
  public
  end;

procedure ShowConfig(const APad: TGamePad; const AImageList: TImageList);

implementation

{$R *.fmx}

uses
  System.DateUtils
  , PK.Device.GamePad.Types
  , uButtonIndexes
  ;

procedure ShowConfig(const APad: TGamePad; const AImageList: TImageList);
begin
  var Form := TfrmConfig.Create(nil);
  try
    Form.Init(APad, AImageList);
    Form.ShowModal;
  finally
    Form.ReleaseForm;
  end;
end;

{ TfrmConfig }

procedure TfrmConfig.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmConfig.FormDestroy(Sender: TObject);
begin
  FCommandPanels.Free;
end;

procedure TfrmConfig.Init(const APad: TGamePad; const AImageList: TImageList);
begin
  FPad := APad;
  FImageList := AImageList;

  glpA.Images := FImageList;
  glpB.Images := FImageList;
  glpX.Images := FImageList;
  glpY.Images := FImageList;

  glpBack.Images := FImageList;
  glpStart.Images := FImageList;

  glpCR.Images := FImageList;
  glpLStick.Images := FImageList;
  glpRStick.Images := FImageList;

  glpLB.Images := FImageList;
  glpLS.Images := FImageList;
  glpLT.Images := FImageList;
  glpRB.Images := FImageList;
  glpRS.Images := FImageList;
  glpRT.Images := FImageList;

  FCommandPanels :=
    TCommandPanels.Create(
      FPad,
      FImageList,
      lstbxSequences,
      pnlSeqeunce,
      dlgOpen);

  timerUpdate.Enabled := True;
end;

procedure TfrmConfig.rectSeqAddButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FCommandPanels.Add;
  lstbxSequences.ScrollBy(0, -MaxInt);
end;

procedure TfrmConfig.timerUpdateTimer(Sender: TObject);
begin
  var S := FPad.Check;

  layButtons.BeginUpdate;
  try
    // A B X Y
    glpA.ImageIndex := B_As[TGamePadButton.A in S];
    glpB.ImageIndex := B_Bs[TGamePadButton.B in S];
    glpX.ImageIndex := B_Xs[TGamePadButton.X in S];
    glpY.ImageIndex := B_Ys[TGamePadButton.Y in S];

    // Back Start
    glpBack.ImageIndex := B_BACKs[TGamePadButton.Back in S];
    glpStart.ImageIndex := B_STARTs[TGamePadButton.Start in S];

    // LB LS LT
    glpLB.ImageIndex := B_LBs[TGamePadButton.LeftShoulder in S];
    glpLS.ImageIndex := B_LSs[TGamePadButton.LeftThumb in S];
    glpLT.ImageIndex := B_LTs[TGamePadButton.LeftTrigger in S];

    // RB RS RT
    glpRB.ImageIndex := B_RBs[TGamePadButton.RightShoulder in S];
    glpRS.ImageIndex := B_RSs[TGamePadButton.RightThumb in S];
    glpRT.ImageIndex := B_RTs[TGamePadButton.RightTrigger in S];

    // CROSS
    glpCR.ImageIndex :=
      B_CROSS
      + Ord(TGamePadButton.Down in S) * 1
      + Ord(TGamePadButton.Left in S) * 2
      + Ord(TGamePadButton.Right in S) * 3
      + Ord(TGamePadButton.Up in S) * 4;

    if TGamePadButton.LeftUp in S then
      glpCR.ImageIndex := B_CROSS_LU;

    if TGamePadButton.LeftDown in S then
      glpCR.ImageIndex := B_CROSS_LD;

    if TGamePadButton.RightUp in S then
      glpCR.ImageIndex := B_CROSS_RU;

    if TGamePadButton.RightDown in S then
      glpCR.ImageIndex := B_CROSS_RD;

    // Left Stick
    glpLStick.ImageIndex :=
      ST_L
      + Ord(TGamePadButton.LStickD in S) * 1
      + Ord(TGamePadButton.LStickL in S) * 2
      + Ord(TGamePadButton.LStickR in S) * 3
      + Ord(TGamePadButton.LStickU in S) * 4;

    if TGamePadButton.LStickLU in S then
      glpLStick.ImageIndex := ST_L_LU;

    if TGamePadButton.LStickLD in S then
      glpLStick.ImageIndex := ST_L_LD;

    if TGamePadButton.LStickRU in S then
      glpLStick.ImageIndex := ST_L_RU;

    if TGamePadButton.LStickRD in S then
      glpLStick.ImageIndex := ST_L_RD;

    // RStick
    glpRStick.ImageIndex :=
      ST_R
      + Ord(TGamePadButton.RStickD in S) * 1
      + Ord(TGamePadButton.RStickL in S) * 2
      + Ord(TGamePadButton.RStickR in S) * 3
      + Ord(TGamePadButton.RStickU in S) * 4;

    if TGamePadButton.RStickLU in S then
      glpRStick.ImageIndex := ST_R_LU;

    if TGamePadButton.RStickLD in S then
      glpRStick.ImageIndex := ST_R_LD;

    if TGamePadButton.RStickRU in S then
      glpRStick.ImageIndex := ST_R_RU;

    if TGamePadButton.RStickRD in S then
      glpRStick.ImageIndex := ST_R_RD;
  finally
    layButtons.EndUpdate;
  end;
end;

end.
