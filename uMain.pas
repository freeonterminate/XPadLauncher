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

unit uMain;

interface

uses
  System.SysUtils
  , System.Classes
  , System.ImageList
  , FMX.Types
  , FMX.Forms
  , FMX.Controls
  , FMX.Graphics
  , PK.TrayIcon
  , FMX.Menus
  , FMX.ImgList
  , FMX.Objects
  , PK.Device.GamePad
  , PK.Device.GamePad.Types
  , uConfig
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
    procedure FormCreate(Sender: TObject);
    procedure menuExitClick(Sender: TObject);
    procedure menuConfigClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure timerUpdateTimer(Sender: TObject);
    procedure menuEnabledClick(Sender: TObject);
    procedure menuVersionClick(Sender: TObject);
    procedure imgLogoClick(Sender: TObject);
  private const
    COMMAND_BUFFER_COUNT = 32;
    COMMAND_LIMIT = 300;
    TIMER_INTERVAL_WAITING = 100;
    TIMER_INTERVAL_ACTIVE = 16;
  private var
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

  {$IFDEF MSWINDOWS}

  {$ENDIF}
  , uConfigForm
  , uButtonStatusForm
  , uVersion
  , uMisc
  ;

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
  FTrayIcon.Apply;

  SetBounds(-MaxInt, -MaxInt, 1, 1);

  if Config.IsFirstRun then
    TThread.ForceQueue(
      nil,
      procedure
      begin
        menuConfigClick(nil);
      end
    );

  timerUpdate.Enabled := True;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FTrayIcon.Free;
  FPad.Free;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  FTrayIcon.HideTaskbar;
end;

procedure TfrmMain.imgLogoClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.menuConfigClick(Sender: TObject);
begin
  timerUpdate.Enabled := False;
  try
    ShowConfig(FPad, imglstButtons);
  finally
    timerUpdate.Enabled := True;
  end;
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

procedure TfrmMain.menuVersionClick(Sender: TObject);
begin
  ShowVersion;
end;

procedure TfrmMain.timerUpdateTimer(Sender: TObject);
begin
  if not menuEnabled.IsChecked then
    Exit;

  if not FPad.Available then
  begin
    if FPad.CheckController then
      FPad.ControllerId := Config.ControllerId;
    Exit;
  end;

  FPad.Check;
  var Status := FPad.NewlyPressedButtons;

  if (FCommands[FCommandIndex] = Status) or (Length(Status) < 1) then
    Exit;

  var Cur: TDateTime := Now;
  if MilliSecondsBetween(Cur, FPrevTime) > COMMAND_LIMIT then
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

  timerUpdate.Interval := TIMER_INTERVAL_ACTIVE;

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
    var Seqs := Config.SortedSequence[i];
    var LenSeqs := Length(Seqs);

    if LenSeqs = 0 then
      Continue;

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
      FoundIndex := Config.SortedIndexToIndex(i);
      Break;
    end;
  end;

  if Found then
  begin
    // コマンド発動
    TThread.CreateAnonymousThread(
      procedure
      begin
        Sleep(100);

        TThread.Synchronize(
          nil,
          procedure
          begin
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
          end
        );
      end
    ).Start;

    FCommandIndex := 0;
    timerUpdate.Interval := TIMER_INTERVAL_WAITING;
  end;
end;

end.
