unit uCommandInputForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Edit,
  FMX.StdCtrls, FMX.Objects, FMX.Controls.Presentation, FMX.Layouts,
  uConfig;

type
  TInputCommandDoneProc =
    reference to procedure (
      const ASuccess: Boolean;
      const ACommand: TJsonCommand);

  TfrmInputCommand = class(TForm)
    layRoot: TLayout;
    layCommandBase: TLayout;
    layButtonBase: TLayout;
    btnCancel: TButton;
    btnOK: TButton;
    imgIcon: TImage;
    layCommandInfoBase: TLayout;
    layCommandTitleBase: TLayout;
    lblCommandName: TLabel;
    lblCommandExe: TLabel;
    layCommandLinesBase: TLayout;
    edtCommandName: TEdit;
    edtCommand: TEdit;
    layCommandCommandBase: TLayout;
    btnCommandRef: TButton;
    pathCommandRefIcon: TPath;
    dlgOpen: TOpenDialog;
    dlgOpenImage: TOpenDialog;
    procedure imgIconClick(Sender: TObject);
    procedure btnCommandRefClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private var
    FHasImage: Boolean;
    FParent: TCommonCustomForm;
    FCommand: TJsonCommand;
    FDoneProc: TInputCommandDoneProc;
    FOK: Boolean;
  public
    constructor CreateWithParam(
      const AParent: TCommonCustomForm;
      const ACommand: TJsonCommand;
      const ADoneProc: TInputCommandDoneProc);
  end;

procedure ShowInputCommand(
  const AParent: TCommonCustomFOrm;
  var ACommand: TJsonCommand;
  const ADoneProc: TInputCommandDoneProc);

implementation

{$R *.fmx}

uses
  System.IOUtils
  , PK.Graphic.BitmapCodecManagerHelper
  , PK.Utils.ScreenHelper
  , uMisc
  ;

procedure ShowInputCommand(
  const AParent: TCommonCustomFOrm;
  var ACommand: TJsonCommand;
  const ADoneProc: TInputCommandDoneProc);
begin
  var F := TfrmInputCommand.CreateWithParam(AParent, ACommand, ADoneProc);
  F.ShowModal;
end;

procedure TfrmInputCommand.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmInputCommand.btnCommandRefClick(Sender: TObject);
begin
  if dlgOpen.Execute then
  begin
    var F := dlgOpen.FileName;

    if edtCommandName.Text.IsEmpty then
      edtCommandName.Text := ChangeFileExt(ExtractFileName(F), '');

    edtCommand.Text := F;
    GetAppIconImage(F, imgIcon.Bitmap);
  end;
end;

procedure TfrmInputCommand.btnOKClick(Sender: TObject);
begin
  FOK := True;
  Close;
end;

constructor TfrmInputCommand.CreateWithParam(
  const AParent: TCommonCustomForm;
  const ACommand: TJsonCommand;
  const ADoneProc: TInputCommandDoneProc);
begin
  inherited Create(nil);

  FParent := AParent;

  StyleBook := AParent.StyleBook;
  FCommand := ACommand;
  FDoneProc := ADoneProc;

  var B := AParent.BoundsF;
  var X := B.Left + (B.Width - Width) / 2;
  var Y := B.Top + (B.Height - Height) / 2;

  BoundsF := RectF(X, Y, X + Width, Y + Height);

  edtCommandName.Text := FCommand.name;
  edtCommand.Text := FCommand.path;
  FCommand.GetImage(imgIcon.Bitmap);
  FHasImage := not FCommand.image.IsEmpty;
end;

procedure TfrmInputCommand.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TfrmInputCommand.FormDestroy(Sender: TObject);
begin
  FCommand.name := edtCommandName.Text;
  FCommand.path := edtCommand.Text;

  if FCommand.name.IsEmpty then
  begin
    var Name := FCommand.path;
    if TFile.Exists(Name) then
      Name := ChangeFileExt(ExtractFileName(Name), '');

    FCommand.name := Name;
  end;

  if FHasImage then
    FCommand.SetImage(imgIcon.Bitmap);

  if Assigned(FDoneProc) then
    FDoneProc(FOK, FCommand);
end;

procedure TfrmInputCommand.imgIconClick(Sender: TObject);
begin
  dlgOpenImage.Filter := TBitmapCodecManager.GetFilterString;
  if dlgOpenImage.Execute then
  begin
    imgIcon.Bitmap.LoadFromFile(dlgOpenImage.FileName);
    FHasImage := True;
  end;
end;

end.
