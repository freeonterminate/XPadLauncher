unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.ImageList,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, PK.TrayIcon, FMX.Menus,
  FMX.ImgList, FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls,
  PK.Device.GamePad, PK.Device.GamePad.Types,
  uConfig
  ;

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
    Button1: TButton;
    menuUpdate: TMenuItem;
    menuSep3: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure menuExitClick(Sender: TObject);
    procedure menuConfigClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure timerUpdateTimer(Sender: TObject);
    procedure menuEnabledClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure menuUpdateClick(Sender: TObject);
  private const
    COMMAND_BUFFER_COUNT = 32;
  private
    FTrayIcon: TTrayIcon;
    FPad: TGamePad;
    FCommands: TSequence;
    FCommandIndex: Integer;
    FPrevTime: TDateTime;
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

uses
  System.DateUtils
  , System.Math
  {$IFDEF MSWINDOWS}
  , PK.GUI.DarkMode.Win
  {$ENDIF}
  , uConfigForm
  , uButtonStatusForm
  , uMisc
  , PK.Utils.Log
  ;

procedure TfrmMain.Button1Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  SetLength(FCommands, COMMAND_BUFFER_COUNT);
  FCommandIndex := 0;

  FPad := TGamePad.Create;
  FPad.ControllerId := Config.ControllerId;

  FTrayIcon := TTrayIcon.Create;
  FTrayIcon.AssignPopupMenu(popupMain);
  FTrayIcon.LButtonPopup := True;
  FTrayIcon.RegisterIcon('Icon', imgLogo.Bitmap);
  FTrayIcon.ChangeIcon('Icon', 'XPad Launcher');
  FTrayIcon.Apply('{A4523C1E-210C-48AE-9A3F-00E0E04DB0BB}');

  imgLogo.Visible := False;

  {$IFDEF RELEASE}
  SetBounds(-MaxInt, -MaxInt, 128, 128);
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
  SetBounds(0, 0, 128, 128);

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

procedure TfrmMain.menuUpdateClick(Sender: TObject);
begin
  FPad.UpdateGamePadInfo;
end;

procedure TfrmMain.timerUpdateTimer(Sender: TObject);
begin
  if not menuEnabled.IsChecked then
    Exit;

  FPad.Check;
  var Status := FPad.NewlyPressedButtons;

  if (FCommands[FCommandIndex] = Status) or (Length(Status) < 1) then
    Exit;

  var Cur: TDateTime := Now;
  if MilliSecondsBetween(Cur, FPrevTime) > 300 then
  begin
    FCommandIndex := 0;
    //Log.d('Rest');
  end
  else
  begin
    Inc(FCommandIndex);
    if FCommandIndex >= COMMAND_BUFFER_COUNT then
      FCommandIndex := 0;
  end;

  FPrevTime := Cur;

  FCommands[FCommandIndex] := Status;
  ShowButtonStatus(imglstButtons, Status);

  { // 入力コマンド確認
  var SB := TStringBuilder.Create;
  try
    for var i := 0 to FCommandIndex do
    begin
      SB.Append(i);
      SB.APpend(' ');
      for var j := 0 to High(FCommands[i]) do
      begin
        SB.Append(FCommands[i][j].ToString);
        SB.APpend(', ');
      end;

      SB.Append(sLineBreak);
    end;

    Log.d(SB.ToString);
  finally
    SB.Free;
  end;
  // }

  var FoundIndex := 0;
  var Found := False;
  var Seq: TGamePadButtonArray;
  for var i := 0 to Config.Count - 1 do
  begin
    var Seqs := Config.Sequence[i];
    var LenSeqs := Length(Seqs);

    for var n := 0 to FCommandIndex - LenSeqs + 1 do
    begin
      Found := True;
      for var j := 0 to LenSeqs - 1 do
      begin
        var ComIndex := j + n;
        Seq := Seqs[j];

        if Length(Seq) <> Length(FCommands[ComIndex]) then
        begin
          Found := False;
          Break;
        end;

        for var k := 0 to High(Seq) do
        begin
          //Log.d([FCommands[ComIndex][k].ToString, ' =?= ', Seq[k].ToString]);
          if FCommands[ComIndex][k] <> Seq[k] then
          begin
            Found := False;
            Break;
          end;
        end;

        if not Found then
          Break;
      end;

      if Found then
        Break;
    end;

    if Found then
    begin
      FoundIndex := i;
      Break;
    end;
  end;

  if Found then
  begin
    // コマンド発動
    // Log.d('OK!');
    var Item := Config.Items[FoundIndex];
    var Bmp := TBitmap.Create;
    try
      Item.GetImage(Bmp);
      ShowIcon(
        Bmp,
        procedure
        begin
          Execute(Item.path);
        end
      );
    finally
      Bmp.Free;
    end;
    FCommandIndex := 0;
  end;
end;

end.
