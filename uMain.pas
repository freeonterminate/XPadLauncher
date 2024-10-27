unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, PK.TrayIcon, FMX.Menus,
  System.ImageList, FMX.ImgList, FMX.Objects,
  PK.Device.GamePad, PK.Device.GamePad.Types;

type
  TfrmMain = class(TForm)
    popupMain: TPopupMenu;
    menuEnabled: TMenuItem;
    menuSep1: TMenuItem;
    menuConfig: TMenuItem;
    menuVersion: TMenuItem;
    menuSep2: TMenuItem;
    menuExit: TMenuItem;
    imglstButtons: TImageList;
    imgLogo: TImage;
    timerUpdate: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure menuExitClick(Sender: TObject);
    procedure menuConfigClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure timerUpdateTimer(Sender: TObject);
    procedure menuEnabledClick(Sender: TObject);
  private
    FTrayIcon: TTrayIcon;
    FPad: TGamePad;
    FCommands: TArray<TGamePadButton>;
    FCommandIndex: Integer;
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

uses
  uConfig
  , uConfigForm
  , PK.Utils.ImageListHelper
  {$IFDEF MSWINDOWS}
  , PK.GUI.DarkMode.Win
  {$ENDIF}
  ;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  SetLength(FCommands, 32);
  FCommandIndex := 0;

  FPad := TGamePad.Create;
  FPad.ControllerIndex := 1;

  FTrayIcon := TTrayIcon.Create;
  FTrayIcon.AssignPopupMenu(popupMain);
  FTrayIcon.LButtonPopup := True;
  FTrayIcon.RegisterIcon('Icon', imgLogo.Bitmap);
  FTrayIcon.ChangeIcon('Icon', 'XPad Launcher');
  FTrayIcon.Apply('{A4523C1E-210C-48AE-9A3F-00E0E04DB0BB}');

  {$IFDEF RELEASE}
  SetBounds(-MaxInt, -MaxInt, 1, 1);
  {$ENDIF}

  timerUpdate.Enabled := True;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FTrayIcon.Free;
  FPad.Free;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  {$IFDEF DEBUG}
  ShowConfig(FPad, imglstButtons);
  Close;
  {$ENDIF}

  {$IFDEF RELEASE}
  FTrayIcon.HideTaskbar;
  {$ENDIF}
end;

procedure TfrmMain.menuConfigClick(Sender: TObject);
begin
  ShowConfig(FPad, imglstButtons);
end;

procedure TfrmMain.menuEnabledClick(Sender: TObject);
begin
  menuEnabled.IsChecked := not menuEnabled.IsChecked;
  timerUpdate.Enabled := menuEnabled.IsChecked;
end;

procedure TfrmMain.menuExitClick(Sender: TObject);
begin
  TThread.ForceQueue(
    nil,
    procedure
    begin
      Close;
    end
  );
end;

procedure TfrmMain.timerUpdateTimer(Sender: TObject);
begin
  if not menuEnabled.IsChecked then
    Exit;
end;

end.
