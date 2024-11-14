unit uButtonStatusForm;

interface

uses
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.ImgList,
  FMX.Objects, PK.Device.GamePad.Types, FMX.Ani, FMX.Effects;

type
  TfrmButtonStatus = class(TForm)
    glyphButton: TGlyph;
    timerClose: TTimer;
    rectBase: TRectangle;
    imgIcon: TImage;
    effectBlur: TBlurEffect;
    animBlur: TFloatAnimation;
    procedure FormCreate(Sender: TObject);
    procedure timerCloseTimer(Sender: TObject);
    procedure animBlurProcess(Sender: TObject);
    procedure animBlurFinish(Sender: TObject);
  private class var
    FSelf: TfrmButtonStatus;
  private
    class constructor CreateClass;
    class destructor DestroyClass;
  private const
    FORM_SIZE = 128;
  private var
    FGs: TArray<TGlyph>;
    FIconProc: TProc;
  private
    procedure ClearGlyphs;
    procedure ShowButtonStatusImpl(
      const AImageList: TCustomImageList;
      const AButtons: TGamePadButtonArray);
    procedure ShowIconImpl(const AIcon: TBitmap; const AProc: TProc);
  protected
    procedure Recreate; override;
  end;

procedure ShowButtonStatus(
  const AImageList: TCustomImageList;
  const AButtons: TGamePadButtonArray);

procedure ShowIcon(const AIcon: TBitmap; const AProc: TProc);

implementation

{$R *.fmx}

uses
  uCommandUtils
  {$IFDEF MSWINDOWS}
  , FMX.Platform.Win
  , FMX.Helpers.Win
  {$ENDIF}
  , PK.Utils.Log
  ;

procedure ShowIcon(const AIcon: TBitmap; const AProc: TProc);
begin
  TfrmButtonStatus.FSelf.ShowIconImpl(AIcon, AProc);
end;

procedure ShowButtonStatus(
  const AImageList: TCustomImageList;
  const AButtons: TGamePadButtonArray);
begin
  TfrmButtonStatus.FSelf.ShowButtonStatusImpl(AImageList, AButtons);
end;

{ TfrmButtonStatus }

procedure TfrmButtonStatus.animBlurFinish(Sender: TObject);
begin
  if Assigned(FIconProc) then
    FIconProc;

  Hide;
  imgIcon.Bitmap.Assign(nil);
end;

procedure TfrmButtonStatus.animBlurProcess(Sender: TObject);
const
  BY = 1.5;
  MAX = 2 * BY;
begin
  var F := (1 + effectBlur.Softness / animBlur.StopValue) * BY;
  imgIcon.Scale.Point := PointF(F, F);

  var W := imgIcon.Width * F;
  var H := imgIcon.Height * F;

  imgIcon.Opacity := MAX - F;

  imgIcon.SetBounds(
    (ClientWidth - W) / 2,
    (ClientHeight - H) / 2,
    imgIcon.Width,
    imgIcon.Height);
end;

procedure TfrmButtonStatus.ClearGlyphs;
begin
  for var i := 0 to High(FGs) do
    FGs[i].Free;
  SetLength(FGs, 0);
end;

class constructor TfrmButtonStatus.CreateClass;
begin
  TfrmButtonStatus.Create(nil);
end;

class destructor TfrmButtonStatus.DestroyClass;
begin
  TfrmButtonStatus.FSelf.Free;
end;

procedure TfrmButtonStatus.FormCreate(Sender: TObject);
begin
  FSelf := Self;
end;

procedure TfrmButtonStatus.Recreate;
begin
  inherited;

  {$IFDEF MSWINDOWS}
  var HWnd := FormToHWND(Self);

  var ExStyle := GetWindowLong(HWnd, GWL_EXSTYLE);
  ExStyle := ExStyle or WS_EX_LAYERED or WS_EX_TRANSPARENT or WS_EX_NOACTIVATE;
  SetWindowLong(HWnd, GWL_EXSTYLE, ExStyle);

  SetWindowPos(
    HWnd,
    HWND_TOPMOST,
    0,
    0,
    0,
    0,
    SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOSIZE);
  {$ENDIF}
end;

procedure TfrmButtonStatus.ShowButtonStatusImpl(
  const AImageList: TCustomImageList;
  const AButtons: TGamePadButtonArray);
const
  GS_MARGIN = 24;
  GS_SIZE = 64;
  FORM_GS_BY = GS_SIZE + GS_MARGIN;

  procedure SetFormWidth;
  begin
    with TfrmButtonStatus.FSelf, BoundsF do
      SetBoundsF(Left, Top, FORM_SIZE + Length(FGs) * FORM_GS_BY, FORM_SIZE);
  end;

begin
  imgIcon.Visible := False;

  glyphButton.Images := AImageList;

  timerClose.Enabled := False;
  timerClose.Enabled := True;

  ClearGlyphs;

  var Len := Length(AButtons);
  if Len < 1 then
  begin
    glyphButton.ImageIndex := -1;
    SetFormWidth;
  end
  else
  begin
    BeginUpdate;
    try
      rectBase.Visible := True;

      glyphButton.ImageIndex := StatusToImageIndex([AButtons[0]]);

      var W := glyphButton.BoundsRect.Width + GS_MARGIN;
      var X := glyphButton.Position.X + W;

      for var i := 1 to High(AButtons) do
      begin
        var G := TGlyph.Create(nil);
        FGs := FGs + [G];

        G.Images := glyphButton.Images;
        G.ImageIndex := StatusToImageIndex([AButtons[i]]);
        G.SetBounds(X, glyphButton.BoundsRect.Top, GS_SIZE, GS_SIZE);
        G.Parent := glyphButton.Parent;

        X := X + W;
      end;

      SetFormWidth;
    finally
      EndUpdate;
    end;
  end;

  var R := Screen.DisplayFromForm(TfrmButtonStatus.FSelf).Workarea;
  with BoundsF do
    SetBoundsF(
      (R.Width - Width) / 2,
      (R.Height - FORM_SIZE) / 2,
      Width,
      FORM_SIZE
    );

  Show;
end;

procedure TfrmButtonStatus.ShowIconImpl(
  const AIcon: TBitmap;
  const AProc: TProc);
begin
  ShowButtonStatus(glyphButton.Images, []);
  timerClose.Enabled := False;

  FIconProc := AProc;

  rectBase.Visible := False;

  imgIcon.Bitmap.Assign(AIcon);
  imgIcon.Opacity := 1;
  imgIcon.Visible := True;

  animBlur.Start;
end;

procedure TfrmButtonStatus.timerCloseTimer(Sender: TObject);
begin
  timerClose.Enabled := False;
  Hide;
end;

end.
