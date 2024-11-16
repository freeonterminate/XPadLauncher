﻿(*
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
 *   2024/11/16  Ver 1.0.0  Release
 *
 * Programmed by HOSOKAWA Jun (twitter: @pik)
 *)

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
  , uCommandFrame
  ;

type
  TfrmConfig = class(TForm)
    timerUpdate: TTimer;
    glpA: TGlyph;
    styleBlueClear: TStyleBook;
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
    imgIcon: TImage;
    dlgOpen: TOpenDialog;
    laySeqAppImageBase: TLayout;
    lblSeqMessage: TLabel;
    layContollerIndexBase: TLayout;
    lblControllerIndex: TLabel;
    cmbbxControllerIndex: TComboBox;
    btnControllerUpdate: TButton;
    btControllerVibe: TButton;
    imgControllerVibeIcon: TImage;
    pathReload: TPath;
    Layout1: TLayout;
    chbxAutoStart: TCheckBox;
    btnCancel: TButton;
    pathCancel: TPath;
    Path1: TPath;
    procedure FormDestroy(Sender: TObject);
    procedure timerUpdateTimer(Sender: TObject);
    procedure rectSeqAddButtonMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure cmbbxControllerIndexChange(Sender: TObject);
    procedure btnControllerUpdateClick(Sender: TObject);
    procedure btControllerVibeClick(Sender: TObject);
    procedure cmbbxControllerIndexPopup(Sender: TObject);
    procedure chbxAutoStartChange(Sender: TObject);
  private var
    FUpdating: Boolean;
    FPad: TGamePad;
    FImageList: TImageList;
    FCommandFrames: TCommandFrames;
    FOrgControllerId: String;
  private
    procedure Init(const APad: TGamePad; const AImageList: TImageList);
    procedure UpdateDeviceList;
    procedure Vibrate(const AProc: TProc);
  public
  end;

procedure ShowConfig(const APad: TGamePad; const AImageList: TImageList);

implementation

{$R *.fmx}

uses
  System.DateUtils
  , FMX.Pickers
  , PK.Device.GamePad.Types
  , uCommandUtils
  , uConfig
  , PK.Utils.Log
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

type
  TOpenPopup = class(TPopup) end;

{ TfrmConfig }

procedure TfrmConfig.btControllerVibeClick(Sender: TObject);
begin
  Vibrate(nil);
end;

procedure TfrmConfig.btnControllerUpdateClick(Sender: TObject);
begin
  UpdateDeviceList;
end;

procedure TfrmConfig.chbxAutoStartChange(Sender: TObject);
begin
  if chbxAutoStart.IsChecked then
    TConfig.AutoRun.Register
  else
    TConfig.AutoRun.Unregister;
end;

procedure TfrmConfig.cmbbxControllerIndexChange(Sender: TObject);
begin
  cmbbxControllerIndex.Hint := cmbbxControllerIndex.Text;

  var Info := FPad.GamePadInfos[cmbbxControllerIndex.ItemIndex];
  if not Info.Valid then
    Exit;

  FPad.ControllerId := FPad.GamePadInfos[cmbbxControllerIndex.ItemIndex].Id;

  if not FUpdating then
    btControllerVibeClick(nil);
end;

procedure TfrmConfig.cmbbxControllerIndexPopup(Sender: TObject);

  function ListUp(const AObject: TFmxObject): Boolean;
  begin
    Result := False;

    if AObject is TCustomListBox then
    begin
      TCustomListBox(AObject).ShowScrollBars := False;
      Exit(True);
    end;

    for var i := 0 to AObject.ChildrenCount - 1 do
      if ListUp(AObject.Children[i]) then
      begin
        Result := True;
        Break;
      end;
  end;

begin
  // ComboBox のスクロールバーを消す
  // 恐らく Style 側の不備

  // ListPicker
  var RType := SharedContext.GetType(cmbbxControllerIndex.ClassType);
  if RType = nil then
    Exit;

  var RField := RType.GetField('FListPicker');
  if RField = nil then
    Exit;

  var Picker: TCustomListPicker := nil;
  if
    not RField.GetValue(cmbbxControllerIndex)
    .TryAsType<TCustomListPicker>(Picker, False)
  then
    Exit;

  // PopupListPicker
  RType := SharedContext.GetType(Picker.ClassType);
  if RType = nil then
    Exit;

  RField := RType.GetField('FPopupListPicker');
  if RField = nil then
    Exit;

  var ListPicker: TPopup := nil;
  if
    not RField.GetValue(Picker)
    .TryAsType<TPopup>(ListPicker, False)
  then
    Exit;

  // Form
  var Form := TCustomPopupForm(TOpenPopup(ListPicker).PopupForm);
  if Form = nil then
    Exit;

  // ListBox を探す
  for var i := 0 to Form.ChildrenCount - 1 do
  begin
    if ListUp(Form.Children[i]) then
      Break;
  end;
end;

procedure TfrmConfig.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;

  if ModalResult = mrOK then
  begin
    FCommandFrames.Save;
    Config.ControllerId := FPad.ControllerId;
  end
  else
    FPad.ControllerId := FOrgControllerId;
end;

procedure TfrmConfig.FormDestroy(Sender: TObject);
begin
  FCommandFrames.Free;
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

  var BorderH := Height - ClientHeight;
  var MinH := Constraints.MinHeight;
  Constraints.MinHeight := MinH + BorderH;
  ClientHeight := Trunc(MinH);

  chbxAutoStart.IsChecked := TConfig.AutoRun.Registered;

  FCommandFrames :=
    TCommandFrames.Create(
      FPad,
      FImageList,
      lstbxSequences);

  FOrgControllerId := FPad.ControllerId;

  UpdateDeviceList;

  timerUpdate.Enabled := True;
end;

procedure TfrmConfig.rectSeqAddButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FCommandFrames.Add;
  lstbxSequences.ScrollBy(0, -MaxInt);
end;

procedure TfrmConfig.timerUpdateTimer(Sender: TObject);
begin
  if not FPad.Available then
    Exit;

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

procedure TfrmConfig.UpdateDeviceList;
begin
  FUpdating := True;
  try
    FPad.UpdateGamePadInfo;

    cmbbxControllerIndex.BeginUpdate;
    try
      cmbbxControllerIndex.Clear;

      var Index := -1;
      for var i := 0 to FPad.GamePadInfoCount - 1 do
      begin
        var Info := FPad.GamePadInfos[i];
        var Caption := Info.Caption;

        if not Info.Valid then
          Caption := '(none)';

        if Info.Id = FPad.ControllerId then
          Index := i;

        cmbbxControllerIndex.Items.Add(Format('#%d - %s', [i + 1, Caption]));
      end;

      cmbbxControllerIndex.ItemIndex := Index;
    finally
      cmbbxControllerIndex.EndUpdate;
    end;
  finally
    FUpdating := False;
  end;
end;

procedure TfrmConfig.Vibrate(const AProc: TProc);
begin
 FPad.Vibrate(1.0, 1.0, 200, AProc);
end;

end.
