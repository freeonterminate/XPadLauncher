(*
 * TrayIcon / StatusBar Icon Utility
 *
 * PLATFORMS
 *   Windows / macOS
 *
 * LICENSE
 *   Copyright (c) 2018 HOSOKAWA Jun
 *   Released under the MIT license
 *   http://opensource.org/licenses/mit-license.php
 *
 * HOW TO USE
 *   uses PK.TrayIcon;
 *
 *   type
 *     TForm1 = class(TForm)
 *       procedure FormCreate(Sender: TObject);
 *     private
 *       FTray: TTrayIcon;
 *     end;
 *
 *   procedure TForm1.FormCreate(Sender: TObject);
 *   begin
 *     FTray := TTrayIcon.Create;
 *     FTray.AddMenu('Foo', FooClick);    // Right Click Menu
 *     FTray.RegisterIcon('Bar', BarBmp); // BarBmp is TBitmap Instance
 *     FTray.RegisterOnClick(TrayClick);  // TrayIcon Clicked Event (Win Only)
 *     FTray.Apply;
 *   end;
 *
 * 2018/04/17 Version 1.0.0
 * 2020/11/06 Version 1.1.0  Support Native PopupMenu / Eliminate VCL Components
 * 2024/11/16 Version 1.2.0  Delete GUID Member (Failed in Windows 11)
 *
 * Programmed by HOSOKAWA Jun (twitter: @pik)
 *)

unit PK.TrayIcon.Win;

{$IFNDEF MSWINDOWS}
{$WARNINGS OFF 1011}
interface
implementation
end.
{$ENDIF}

interface

implementation

uses
  Winapi.Windows
  , Winapi.Messages
  , Winapi.ShellAPI
  , System.Classes
  , System.Generics.Collections
  , System.SysUtils
  , System.UITypes
  , FMX.Forms
  , FMX.Graphics
  , FMX.Menus
  , FMX.Platform
  , FMX.Platform.Win
  , FMX.Surfaces
  , FMX.Types
  , PK.GUI.NativePopupMenu.Win
  , PK.TrayIcon.Default
  , PK.Utils.Log
  ;

type
  TTrayIconWin = class(TInterfacedObject, ITrayIcon)
  private type
    TIconDic = TDictionary<String, HICON>;
    TMenuRec = record
      FID: Integer;
      FText: String;
      FHandler: TNotifyEvent;
    end;
    TMenuItemArray = TArray<TMenuRec>;
  private const
    IM_NOTIFY = WM_USER + 100;
  private var
    FHandle: HWND;
    FIcon: HICON;
    FHint: String;
    FVisible: Boolean;
    FEnabled: Boolean;
    FLButtonPopup: Boolean;
    FMenu: HMENU;
    FPopupMenu: TPopupMenu;
    FMenuItems: TMenuItemArray;
    FIcons: TIconDic;
    FTaskbarRestart: NativeUInt;
    FPopuping: Boolean;
    FLButtonUpTime: UInt64;
    FOnClick: TNotifyEvent;
    FOnBeginPopup: TNotifyEvent;
    FOnEndPopup: TNotifyEvent;
  private
    function FindMenu(const iName: String): TMenuRec;
    function CreateIcon(const iIcon: TBitmap): HICON;
    procedure ClearIcon;
    procedure CreateMaskBitmap(const iMask, iSource: TBitmap);
    procedure InitNID(var ioNID: TNotifyIconData);
  protected
    procedure WndProc(var Msg: TMessage); virtual;
    procedure TaskTrayMessage(var ioMsg: TMessage); virtual;
    procedure SetVisible(const Value: Boolean); virtual;
    { ITrayIcon }
    function GetEnabled: Boolean;
    procedure SetEnabled(const iEnabled: Boolean);
    function GetLButtonPopup: Boolean;
    procedure SetLButtonPopup(const iValue: Boolean);
    function GetOnBeginPopup: TNotifyEvent;
    procedure SetOnBeginPopup(const iEvent: TNotifyEvent);
    function GetOnEndPopup: TNotifyEvent;
    procedure SetOnEndPopup(const iEvent: TNotifyEvent);
    procedure HideTaskbar;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
    procedure Apply;
    procedure AssignPopupMenu(const iPopup: TPopupMenu);
    procedure AddMenu(const iText: String; const iEvent: TNotifyEvent);
    procedure EnableMenu(const iText: String; const iEnabled: Boolean);
    procedure RegisterOnClick(const iEvent: TNotifyEvent);
    procedure RegisterIcon(
      const iName: String;
      const iIcon: FMX.Graphics.TBitmap);
    procedure ChangeIcon(const iName, iHint: String);
    property Visible: Boolean read FVisible write SetVisible;
    property Enabled: Boolean read GetEnabled write SetEnabled;
    property Popuping: Boolean read FPopuping;
    property OnBeginPopup: TNotifyEvent read FOnBeginPopup write FOnBeginPopup;
    property OnEndPopup: TNotifyEvent read FOnEndPopup write FOnEndPopup;
  end;

  TTrayIconFactoryWin = class(TTrayIconFactory)
  public
    function CreateTrayIcon: ITrayIcon; override;
  end;

procedure RegisterTrayIconWin;
begin
  TPlatformServices.Current.AddPlatformService(
    ITrayIconFactory,
    TTrayIconFactoryWin.Create);
end;

{ TTrayIconWin }

procedure TTrayIconWin.AddMenu(const iText: String; const iEvent: TNotifyEvent);
begin
  var Len := Length(FMenuItems);
  SetLength(FMenuItems, Len + 1);

  with FMenuItems[Len] do
  begin
    FID := Len + 1;
    FText := iText;
    FHandler := iEvent;

    var Flag := MF_STRING or MF_ENABLED;
    if FText = '-' then
      Flag := MF_SEPARATOR;

    AppendMenu(FMenu, Flag, FID, PChar(FText));
  end;
end;

procedure TTrayIconWin.Apply;
begin
  SetVisible(True);
end;

procedure TTrayIconWin.AssignPopupMenu(const iPopup: TPopupMenu);
begin
  FPopupMenu := iPopup;
end;

procedure TTrayIconWin.ChangeIcon(const iName, iHint: String);
var
  Icon: HICON;
  NID: TNotifyICONData;
begin
  if FIcons.TryGetValue(iName, Icon) then
    FIcon := Icon;

  FHint := iHint;

  if FVisible then
  begin
    InitNID(NID);
    Shell_NotifyICON(NIM_MODIFY, @NID);
  end
  else
    SetVisible(True);
end;

procedure TTrayIconWin.ClearIcon;
begin
  SetVisible(False);

  for var Pair in FIcons do
    DestroyIcon(Pair.Value);

  FIcons.Clear;
end;

constructor TTrayIconWin.Create;
begin
  inherited Create;

  FIcons := TIconDic.Create;
  FMenu := CreatePopupMenu;
  FHint := Application.Title;
  FHandle := AllocateHWnd(WndProc);
  FTaskbarRestart := RegisterWindowMessage('TaskbarCreated'); // DO NOT LOCALIZE

  FEnabled := True;
end;

function TTrayIconWin.CreateIcon(const iIcon: TBitmap): HICON;

  function ToHBitmap(const iBmp: TBitmap): HBITMAP;
  var
    Info: PBitmapInfo;
  begin
    var W: NativeUInt := iBmp.Width;
    var H: NativeUInt := iBmp.Height;

    GetMem(Info, SizeOf(TBitmapInfoHeader));
    try
      with Info^, bmiHeader do
      begin
        ZeroMemory(@bmiHeader, SizeOf(bmiHeader));

        biSize := SizeOf(bmiHeader);
        biWidth := iBmp.Width;
        biHeight := -iBmp.Height; // top down Bitmap
        biPlanes := 1;
        biBitCount := 32;
        biCompression := BI_RGB;
      end;

      var DIBW: NativeUInt := (W shl 2) and $fffffffc; // DIB Word 境界に合せる
      var Pixels: TArray<Byte>;
      SetLength(Pixels, DIBW * H);

      var Data: TBitmapData;
      iBmp.Map(TMapAccess.Read, Data);
      try
        for var Y := 0 to H - 1 do
          Move(Data.GetScanline(Y)^, Pixels[Y * DIBW], W * 4);
      finally
        iBmp.Unmap(Data);
      end;

      var DC := GetDC(0); // 0 = ScreenDC
      try
        Result :=
          CreateDIBitmap(
            DC,
            Info^.bmiHeader,
            CBM_INIT,
            Pixels,
            Info^,
            DIB_RGB_COLORS);
      finally
        ReleaseDC(0, DC);
      end;
    finally
      FreeMem(Info);
    end;
  end;

begin
  var Mask := TBitmap.Create;
  try
    CreateMaskBitmap(Mask, iIcon);

    var IconInfo: TIconInfo;
    ZeroMemory(@IconInfo, SizeOf(IconInfo));

    try
      IconInfo.fIcon := True;
      IconInfo.hbmMask := ToHBitmap(Mask);
      IconInfo.hbmColor := ToHBitmap(iIcon);

      Result := CreateIconIndirect(IconInfo);
    finally
      DeleteObject(IconInfo.hbmMask);
      DeleteObject(IconInfo.hbmColor);
    end;
  finally
    Mask.Free;
  end;
end;

procedure TTrayIconWin.CreateMaskBitmap(const iMask, iSource: TBitmap);
const
  BW: array [Boolean] of UInt32 = ($00000000, $ffffffff);
var
  M, S: TBitmapData;
begin
  var W := iSource.Width;
  var H := iSource.Height;

  iMask.SetSize(W, H);

  iMask.Map(TMapAccess.Write, M);
  try
    iSource.Map(TMapAccess.Read, S);
    try
      for var Y := 0 to H - 1 do
        for var X := 0 to W - 1 do
          M.SetPixel(X, Y, BW[TAlphaColorRec(S.GetPixel(X, Y)).A = 0])
    finally
      iSource.Unmap(S);
    end;
  finally
    iMask.Unmap(M);
  end;
end;

destructor TTrayIconWin.Destroy;
begin
  ClearIcon;

  DeallocateHWnd(FHandle);

  DestroyMenu(FMenu);
  FIcons.Free;

  inherited;
end;

procedure TTrayIconWin.EnableMenu(const iText: String; const iEnabled: Boolean);
const
  ENABLED: array [Boolean] of UInt32 = (MF_GRAYED, MF_ENABLED);
begin
  var Item := FindMenu(iText);
  if Item.FID > -1 then
    EnableMenuItem(
      FMenu,
      Item.FID,
      MF_STRING or MF_BYCOMMAND or ENABLED[iEnabled]
    );
end;

function TTrayIconWin.FindMenu(const iName: String): TMenuRec;
begin
  Result.FID := -1;

  for var Item in FMenuItems do
    if Item.FText = iName then
    begin
      Result := Item;
      Break;
    end
end;

function TTrayIconWin.GetEnabled: Boolean;
begin
  Result := FEnabled;
end;

function TTrayIconWin.GetLButtonPopup: Boolean;
begin
  Result := FLButtonPopup;
end;

function TTrayIconWin.GetOnBeginPopup: TNotifyEvent;
begin
  Result := FOnBeginPopup;
end;

function TTrayIconWin.GetOnEndPopup: TNotifyEvent;
begin
  Result := FOnEndPopup;
end;

procedure TTrayIconWin.HideTaskbar;
begin
  if Application.MainForm = nil then
    Exit;

  Application.MainForm.Hide;
  ShowWindow(FormToHWND(Application.MainForm), SW_HIDE);
  ShowWindow(ApplicationHWND, SW_HIDE);

  SetWindowLong(
    ApplicationHWND,
    GWL_EXSTYLE,
    WS_EX_TOOLWINDOW or WS_EX_NOACTIVATE);
end;

procedure TTrayIconWin.InitNID(var ioNID: TNotifyIconData);
begin
  ZeroMemory(@ioNID, SizeOf(ioNID));

  with ioNID do
  begin
    cbSize := SizeOf;
    hIcon := FIcon;
    uFlags := NIF_ICON;
    uID := FHandle;
    Wnd := FHandle;

    if FHint <> '' then
    begin
      StrPLCopy(szTip, FHint, 63);
      uFlags := uFlags or NIF_TIP;
    end;
  end;
end;

procedure TTrayIconWin.RegisterIcon(
  const iName: String;
  const iIcon: FMX.Graphics.TBitmap);
begin
  if iIcon <> nil then
  begin
    var HI := CreateIcon(iIcon);
    if FIcon = 0 then
      FIcon := HI;

    FIcons.Add(iName, HI);
  end;
end;

procedure TTrayIconWin.RegisterOnClick(const iEvent: TNotifyEvent);
begin
  FOnClick := iEvent;
end;

procedure TTrayIconWin.SetEnabled(const iEnabled: Boolean);
begin
  FEnabled := iEnabled;
end;

procedure TTrayIconWin.SetLButtonPopup(const iValue: Boolean);
begin
  FLButtonPopup := iValue;
end;

procedure TTrayIconWin.SetOnBeginPopup(const iEvent: TNotifyEvent);
begin
  FOnBeginPopup := iEvent;
end;

procedure TTrayIconWin.SetOnEndPopup(const iEvent: TNotifyEvent);
begin
  FOnEndPopup := iEvent;
end;

procedure TTrayIconWin.SetVisible(const Value: Boolean);
var
  NID: TNotifyICONData;
begin
  if FVisible = Value then
    Exit;

  FVisible := Value;

  try
    InitNID(NID);
    with NID do
    begin
      uCallbackMessage := IM_NOTIFY;
      uFlags := uFlags or NIF_MESSAGE;
    end;

    if (FVisible) then
    begin
      Shell_NotifyICON(NIM_ADD, @NID);
    end
    else
    begin
      NID.uFlags := NID.uFlags and not NIF_GUID;
      Shell_NotifyICON(NIM_DELETE, @NID);
    end;
  except
  end;
end;

procedure TTrayIconWin.TaskTrayMessage(var ioMsg: TMessage);

  procedure Popup;
  var
    tmpPos: TPoint;
  begin
    FPopuping := True;
    try
      SetForegroundWindow(FHandle);
      GetCursorPos(tmpPos);

      if (Assigned(FOnBeginPopup)) then
        FOnBeginPopup(Self);

      var Cmd := -1;
      if FPopupMenu = nil then
        Cmd :=
          NativeInt(
            TrackPopupMenu(
              FMenu,
              TPM_LEFTBUTTON or
                TPM_RIGHTBUTTON or
                TPM_RETURNCMD or
                TPM_BOTTOMALIGN or
                TPM_NOANIMATION,
              tmpPos.X,
              tmpPos.Y,
              0,
              FHandle,
              nil
            )
          )
      else
        TNativePopupMenuWin.Popup(FHandle, FPopupMenu);

      if (Assigned(FOnEndPopup)) then
        FOnEndPopup(Self);

      for var Item in FMenuItems do
        if (Item.FID = Cmd) and Assigned(Item.FHandler) then
        begin
          Item.FHandler(Self);
          Break;
        end;
    finally
      FPopuping := False;
    end;
  end;

begin
  case ioMsg.lParam of
    WM_LBUTTONUP:
    begin
      var Diff := GetTickCount64 - FLButtonUpTime;

      if Assigned(FOnClick) and (Diff > GetDoubleClickTime) then
      begin
        FLButtonUpTime := GetTickCount64;
        FOnClick(Self);
      end;

      if FLButtonPopup then
        Popup;
    end;

    WM_RBUTTONUP:
    begin
      Popup;
    end;
  end;
end;

procedure TTrayIconWin.WndProc(var Msg: TMessage);

  procedure Default;
  begin
    Msg.Result := DefWindowProc(FHandle, Msg.Msg, Msg.wParam, Msg.lParam);
  end;

begin
  case Msg.Msg of
    IM_NOTIFY:
      if FEnabled then
        TaskTrayMessage(Msg);

    WM_ENDSESSION:
      SetVisible(False);

    WM_SYSCOMMAND:
      if (Msg.WParam = SC_CLOSE) then
        Msg.Result := 0
      else
        Default;
  else
    if Msg.Msg = FTaskbarRestart then
    begin
      if FVisible then
      begin
        FVisible := False;
        SetVisible(True);
      end;
    end
    else
      Default;
  end;
end;

{ TTrayIconFactoryWin }

function TTrayIconFactoryWin.CreateTrayIcon: ITrayIcon;
begin
  Result := TTrayIconWin.Create;
end;

initialization
  RegisterTrayIconWin;

end.
