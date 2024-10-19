(*
 * FireMonkey TPopup を Native Menu にして表示する
 *
 * PLATFORMS
 *   Windows 11
 *
 * ENVIRONMENT
 *   Delphi 11.0 Alexandria
 *
 * USAGE
 *   TNativePopupMenuWin.Popup(popupMenu); // popupMenu is FMX.Menus.TPopupMenu
 *
 * LICENSE
 *   Copyright (c) 2021 HOSOKAWA Jun
 *   Released under the MIT license
 *   http://opensource.org/licenses/mit-license.php
 *
 * HISTORY
 *   2021/09/24 Version 1.0.0
 *
 * Programmed by HOSOKAWA Jun (twitter: @pik)
 *)

unit PK.GUI.NativePopupMenu.Win;

interface

uses
  Winapi.Windows
  , Winapi.Messages
  , System.Classes
  , System.Generics.Collections
  , System.SysUtils
  , System.Types
  , FMX.Menus
  , FMX.Platform
  ;

type
  TNativePopupMenuWin = class
  private type
    TMenuInfo = class;
    TMenuInfos = TList<TMenuInfo>;

    TMenuInfo = class
    private
      FID: Integer;
      FText: String;
      FHandler: TNotifyEvent;
      FMenu: HMENU;
      FMenuItem: TMenuItem;
    public
      constructor Create(
        const AParent: HMENU;
        const AItem: TMenuItem); reintroduce;
      destructor Destroy; override;
    end;
  private const
    IM_NOTIFY = WM_USER + 100;
  private class var
    FIndex: Integer;
    FMenus: TMenuInfos;
    FMenuService: IFMXMenuService;
  public
    class procedure Popup(
      const APopup: TPopupMenu;
      const AX: Integer = -MaxInt;
      const AY: Integer = -MaxInt); overload;
    class procedure Popup(
      const AWnd: HWND;
      const APopup: TPopupMenu;
      const AX: Integer = -MaxInt;
      const AY: Integer = -MaxInt); overload;
    class procedure PopupDp(
      const APopup: TPopupMenu;
      const AX, AY: Single);  overload;
    class procedure PopupDp(
      const AWnd: HWND;
      const APopup: TPopupMenu;
      const AX, AY: Single);  overload;
  end;

implementation

uses
  FMX.Forms
  , FMX.Platform.Win
  ;

{ TNativePopupMenuWin.TMenuInfo }

constructor TNativePopupMenuWin.TMenuInfo.Create(
  const AParent: HMENU;
  const AItem: TMenuItem);
begin
  inherited Create;

  FMenus.Add(Self);
  Inc(FIndex);

  FID := FIndex;
  FText := AItem.Text;
  FHandler := AItem.OnClick;
  FMenuItem := AItem;

  if (AItem.ShortCut <> scNone) and (FMenuService <> nil) then
    FText := FText + #9 + FMenuService.ShortCutToText(AItem.ShortCut);

  var Flag := MF_STRING;

  if AItem.Enabled then
    Flag := Flag or MF_ENABLED
  else
    Flag := Flag or MF_GRAYED;

  if AItem.IsChecked then
    Flag := Flag or MF_CHECKED;

  if FText = '-' then
    Flag := MF_SEPARATOR;

  var Count := AItem.ItemsCount;
  if Count > 0 then
  begin
    FMenu := CreatePopupMenu;
    Flag := Flag or MF_POPUP;
    FID := FMenu;
  end;

  AppendMenu(AParent, Flag, FID, PChar(FText));

  if Count > 0 then
    for var i := 0 to Count - 1 do
    begin
      var Item := AItem.Items[i];
      if Item.Visible then
        TMenuInfo.Create(FMenu, Item);
    end;
end;

destructor TNativePopupMenuWin.TMenuInfo.Destroy;
begin
  if FMenu <> 0 then
    DestroyMenu(FMenu);

  inherited;
end;

{ TNativePopupMenuWin }

class procedure TNativePopupMenuWin.Popup(
  const AWnd: HWND;
  const APopup: TPopupMenu;
  const AX, AY: Integer);
begin
  var Pt := Point(AX, AY);
  if (AX = -MaxInt) or (AY = -MaxInt) then
    GetCursorPos(Pt);

  if not TPlatformServices.Current.SupportsPlatformService(
    IFMXMenuService,
    FMenuService)
  then
    FMenuService := nil;

  var Wnd := AWnd;
  if Wnd = 0 then
    Wnd := FormToHWND(Screen.ActiveForm);

  if FMenus <> nil then
    Exit;

  FMenus := TMenuInfos.Create;
  try
    if Assigned(APopup.OnPopup) then
      APopup.OnPopup(APopup);

    var Root := CreatePopupMenu;
    try
      for var i := 0 to APopup.ItemsCount - 1 do
      begin
        var Item := APopup.Items[i];
        if Item.Visible then
          TMenuInfo.Create(Root, Item);
      end;

      var Cmd :=
        NativeInt(
          TrackPopupMenu(
            Root,
            TPM_LEFTBUTTON or
              TPM_RIGHTBUTTON or
              TPM_NONOTIFY or
              TPM_RETURNCMD or
              TPM_NOANIMATION,
            Pt.X,
            Pt.Y,
            0,
            Wnd,
            nil
          )
        );

      for var Info in FMenus do
        if (Info.FID = Cmd) and Assigned(Info.FHandler) then
        begin
          Info.FHandler(Info.FMenuItem);
          Break;
        end;

      for var Info in FMenus do
        Info.Free;
    finally
      DestroyMenu(Root);
    end;
  finally
    FreeAndNil(FMenus);
  end;
end;

class procedure TNativePopupMenuWin.Popup(
  const APopup: TPopupMenu;
  const AX: Integer;
  const AY: Integer);
begin
  Popup(0, APopup, AX, AY);
end;

class procedure TNativePopupMenuWin.PopupDp(
  const APopup: TPopupMenu;
  const AX, AY: Single);
begin
  PopupDp(0, APopup, AX, AY);
end;

class procedure TNativePopupMenuWin.PopupDp(
  const AWnd: HWND;
  const APopup: TPopupMenu;
  const AX, AY: Single);
begin
  var Pt := DpToPx(PointF(AX, AY));
  Popup(AWnd, APopup, Pt.X, Pt.Y);
end;

end.
