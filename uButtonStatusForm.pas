unit uButtonStatusForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.ImgList,
  FMX.Objects, PK.Device.GamePad.Types;

type
  TfrmButtonStatus = class(TForm)
    glyphButton: TGlyph;
    timerClose: TTimer;
    Rectangle1: TRectangle;
    procedure FormCreate(Sender: TObject);
    procedure timerCloseTimer(Sender: TObject);
  private class var
    FSelf: TfrmButtonStatus;
  private
    class constructor CreateClass;
    class destructor DestroyClass;
  public
  end;

procedure ShowButtonStatus(
  const AImageList: TImageList;
  const AButtons: TGamePadButtonArray);

implementation

{$R *.fmx}

uses
  uCommandUtils
  {$IFDEF MSWINDOWS}
  , Winapi.Windows
  , FMX.Platform.Win
  {$ENDIF}
  ;

procedure ShowButtonStatus(
  const AImageList: TImageList;
  const AButtons: TGamePadButtonArray);
begin
  with TfrmButtonStatus.FSelf do
  begin
    glyphButton.Images := AImageList;
    Show;

    timerClose.Enabled := False;
    timerClose.Enabled := True;

    if Length(AButtons) > 0 then
      glyphButton.ImageIndex := StatusToImageIndex([AButtons[0]])
    else
      glyphButton.ImageIndex := -1;
  end;
end;

{ TfrmButtonStatus }

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

  {$IFDEF MSWINDOWS}
  var HWnd := FormToHWND(Self);

  var ExStyle := GetWindowLong(HWnd, GWL_EXSTYLE);
  ExStyle := ExStyle or WS_EX_LAYERED or WS_EX_TRANSPARENT or WS_EX_NOACTIVATE;
  SetWindowLong(HWnd, GWL_EXSTYLE, ExStyle);

  SetLayeredWindowAttributes(HWnd, 0, $c0, LWA_ALPHA);

  // Window を最前面に
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

procedure TfrmButtonStatus.timerCloseTimer(Sender: TObject);
begin
  timerClose.Enabled := False;
  Hide;
end;

end.
