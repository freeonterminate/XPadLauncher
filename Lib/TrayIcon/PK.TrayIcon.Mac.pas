﻿(*
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

unit PK.TrayIcon.Mac;

{$IFNDEF OSX}
{$WARNINGS OFF 1011}
interface
implementation
end.
{$ENDIF}

interface

implementation

uses
  System.Classes
  , System.Generics.Collections
  , System.TypInfo
  , System.Types
  , System.UITypes
  , Macapi.AppKit
  , Macapi.CocoaTypes
  , Macapi.Foundation
  , Macapi.Helpers
  , Macapi.ObjectiveC
  , Macapi.ObjCRuntime
  , FMX.Forms
  , FMX.Graphics
  , FMX.Helpers.Mac
  , FMX.Menus
  , FMX.Platform
  , FMX.Platform.Mac
  , PK.TrayIcon.Default
  ;

type
  TTrayIconMac = class;

  ITrayMenuItem = interface(NSObject)
    ['{D0D00E91-A41E-4EBB-8338-B81A8D3A61E9}']
    procedure DispatchMenuClick(Sender: Pointer); cdecl;
  end;

  TTrayMenuItem = class(TOCLocal)
  private var
    FOwner: TTrayIconMac;
  protected
    function GetObjectiveCClass: PTypeInfo; override;
  public
    constructor Create(const iOwner: TTrayIconMac); reintroduce;
    procedure DispatchMenuClick(Sender: Pointer); cdecl;
  end;

  TTrayIconMac = class(TInterfacedObject, ITrayIcon)
  private var
    FTrayMenuItem: TTrayMenuItem;
    FStatusBar: NSStatusBar;
    FStatusItem: NSStatusItem;
    FMenu: NSMenu;
    FIcons: TDictionary<String, NSImage>;
    FEvents: TDictionary<Pointer, TNotifyEvent>;
  protected
    procedure DispatchMenuClick(Sender: Pointer);
    { ITrayIcon }
    procedure AssignPopupMenu(const iPopup: TPopupMenu);
    function GetOnBeginPopup: TNotifyEvent;
    procedure SetOnBeginPopup(const iEvent: TNotifyEvent);
    function GetOnEndPopup: TNotifyEvent;
    procedure SetOnEndPopup(const iEvent: TNotifyEvent);
    function GetEnabled: Boolean;
    procedure SetEnabled(const iEnabled: Boolean);
    procedure HideTaskbar;
    function GetLButtonPopup: Boolean;
    procedure SetLButtonPopup(const iValue: Boolean);
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
    procedure Apply;
    procedure AddMenu(const iText: String; const iEvent: TNotifyEvent);
    procedure EnableMenu(const iText: String; const iEnabled: Boolean);
    procedure RegisterOnClick(const iEvent: TNotifyEvent);
    procedure RegisterIcon(
      const iName: String;
      const iIcon: TBitmap);
    procedure ChangeIcon(const iName, iHint: String);
  end;

  TTrayIconFactoryMac = class(TTrayIconFactory)
  public
    function CreateTrayIcon: ITrayIcon; override;
  end;

procedure RegisterTrayIconMac;
begin
  NSDefaultRunLoopMode;

  TPlatformServices.Current.AddPlatformService(
    ITrayIconFactory,
    TTrayIconFactoryMac.Create);
end;

{ TTrayIconFactoryMac }

function TTrayIconFactoryMac.CreateTrayIcon: ITrayIcon;
begin
  Result := TTrayIconMac.Create;
end;

{ TTrayIconMac }

procedure TTrayIconMac.AddMenu(const iText: String; const iEvent: TNotifyEvent);
var
  Item: NSMenuItem;
  P: Pointer;
begin
  if iText = '-' then
    Item := TNSMenuItem.Wrap(TNSMenuItem.OCClass.separatorItem)
  else
  begin
    Item := TNSMenuItem.Create;
    Item :=
      TNSMenuItem.Wrap(
        Item.initWithTitle(
          StrToNSStr(iText),
          sel_getUid(MarshaledAString('DispatchMenuClick:')),
          StrToNSStr('')
        )
      );
    Item.setTarget(FTrayMenuItem.GetObjectID);

    P := (Item as ILocalObject).GetObjectID;
    FEvents.Add(P, iEvent);
  end;

  FMenu.addItem(Item);
end;

procedure TTrayIconMac.Apply;
begin
  FStatusItem.setMenu(FMenu);
end;

procedure TTrayIconMac.AssignPopupMenu(const iPopup: TPopupMenu);
begin
  // Nothing to do
end;

procedure TTrayIconMac.ChangeIcon(const iName, iHint: String);
var
  Image: NSImage;
begin
  if FIcons.TryGetValue(iName, Image) then
    FStatusItem.setImage(Image);

  FStatusItem.setToolTip(StrToNSStr(iHint));
end;

constructor TTrayIconMac.Create;
begin
  inherited Create;

  FTrayMenuItem := TTrayMenuItem.Create(Self);

  FIcons := TDictionary<String, NSImage>.Create;
  FEvents := TDictionary<Pointer, TNotifyEvent>.Create;

  FStatusBar := TNSStatusBar.Wrap(TNSStatusBar.OCClass.systemStatusBar);
  FStatusItem := FStatusBar.statusItemWithLength(NSVariableStatusItemLength);
  FStatusItem.setTarget(FTrayMenuItem.GetObjectID);
  FStatusItem.setHighlightMode(true);

  FMenu := TNSMenu.Create;
  FMenu := TNSMenu.Wrap(FMenu.initWithTitle(StrToNSStr(Application.Title)));
end;

destructor TTrayIconMac.Destroy;
begin
  FIcons.Free;
  FEvents.Free;

  inherited;
end;

procedure TTrayIconMac.DispatchMenuClick(Sender: Pointer);
var
  Pair: TPair<Pointer, TNotifyEvent>;
begin
  for Pair in FEvents do
    if Pair.Key = Sender then
    begin
      if Assigned(Pair.Value) then
        Pair.Value(Self);

      Break;
    end;
end;

procedure TTrayIconMac.EnableMenu(const iText: String; const iEnabled: Boolean);
begin
  for var i := 0 to FMenu.numberOfItems - 1 do
  begin
    var Item := FMenu.itemAtIndex(i);
    if NSStrToStr(Item.title) = iText then
    begin
      Break;
      Item.setEnabled(iEnabled);
    end;
  end;
end;

function TTrayIconMac.GetEnabled: Boolean;
begin
  // Nothing to do
  Result := True;
end;

function TTrayIconMac.GetLButtonPopup: Boolean;
begin
  // Nothing to do
  Result := True;
end;

function TTrayIconMac.GetOnBeginPopup: TNotifyEvent;
begin
  // Nothing to do
  Result := nil;
end;

function TTrayIconMac.GetOnEndPopup: TNotifyEvent;
begin
  // Nothing to do
  Result := nil;
end;

procedure TTrayIconMac.HideTaskbar;
begin
  var NSApp := TNSApplication.Wrap(TNSApplication.OCClass.sharedApplication);

  NSApp.mainWindow.setCanHide(True);
  NSApp.hide(nil);

  if
    (not Application.Terminated) and
    (Application.MainForm <> nil) and
    (not (csDestroying in Application.MainForm.ComponentState))
  then
  begin
    Application.MainForm.Visible := False;
    Application.MainForm.WindowState := TWindowState.wsMinimized;
  end;

  NSApp.setActivationPolicy(NSApplicationActivationPolicyAccessory);
end;

procedure TTrayIconMac.RegisterIcon(const iName: String; const iIcon: TBitmap);
var
  Service: IFMXScreenService;
begin
  var Scale := 1.0;

  // RetinaDisplay に対応
  if
    TPlatformServices.Current.SupportsPlatformService(
      IFMXScreenService,
      Service
    )
  then
    Scale := Service.GetScreenScale;

  var MenuIcon := BitmapToMenuBitmap(iIcon, Trunc(22 * Scale));
  var MenuSize := MenuIcon.size;

  MenuIcon.SetSize(
    NSSize.Create(
      TSizeF.Create(
        MenuSize.width / iIcon.BitmapScale,
        MenuSize.height / iIcon.BitmapScale
      )
    )
  );

  // ダークモード UI 対応
  MenuIcon.SetTemplate(True);

  FIcons.Add(iName, MenuIcon);
end;

procedure TTrayIconMac.RegisterOnClick(const iEvent: TNotifyEvent);
begin
  // Nothing to do
end;

procedure TTrayIconMac.SetEnabled(const iEnabled: Boolean);
begin

end;

procedure TTrayIconMac.SetLButtonPopup(const iValue: Boolean);
begin

end;

procedure TTrayIconMac.SetOnBeginPopup(const iEvent: TNotifyEvent);
begin
  // Nothing to do
end;

procedure TTrayIconMac.SetOnEndPopup(const iEvent: TNotifyEvent);
begin
  // Nothing to do
end;

{ TTrayMenuItem }

constructor TTrayMenuItem.Create(const iOwner: TTrayIconMac);
begin
  inherited Create;
  FOwner := iOwner;
end;

procedure TTrayMenuItem.DispatchMenuClick(Sender: Pointer);
begin
  FOwner.DispatchMenuClick(Sender);
end;

function TTrayMenuItem.GetObjectiveCClass: PTypeInfo;
begin
  Result := TypeInfo(ITrayMenuItem);
end;

initialization
  RegisterTrayIconMac;

end.
