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
 *     FTray.AddMenu('Foo', FooClick);    // Right Click Menu (Deprecated)
 *     FTray.AssignPopupMenu(PopupMenu1); // Right Click Menu
 *     FTray.RegisterIcon('Bar', BarBmp); // BarBmp is TBitmap Instance
 *     FTray.RegisterOnClick(TrayClick);  // TrayIcon Clicked Event (Win Only)
 *     FTray.Apply('{FED0B67E-7C6E-41C3-A257-E4EB588E3E94}');
 *   end;
 *
 * 2018/04/17 Version 1.0.0
 * Programmed by HOSOKAWA Jun (twitter: @pik)
 *)

unit PK.TrayIcon;

interface

uses
  System.SysUtils
  , System.Classes
  , FMX.Graphics
  , FMX.Menus
  , PK.TrayIcon.Default
  ;

type
  TTrayIcon = class
  private var
    FTrayIcon: ITrayIcon;
  private
    function GetOnBeginPopup: TNotifyEvent;
    procedure SetOnBeginPopup(const iEvent: TNotifyEvent);
    function GetOnEndPopup: TNotifyEvent;
    procedure SetOnEndPopup(const iEvent: TNotifyEvent);
    function GetEnabled: Boolean;
    procedure SetEnabled(const iEnabled: Boolean);
    function GetLButtonPopup: Boolean;
    procedure SetLButtonPopup(const iValue: Boolean);
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
    procedure Apply(const iGUID: TGUID); overload;
    procedure Apply(const iGUIDString: String); overload;
    procedure Apply; overload;
    procedure AssignPopupMenu(const iPopupMenu: TPopupMenu);
    procedure AddMenu(const iText: String; const iEvent: TNotifyEvent);
      deprecated 'Insted AssignPopupMenu';
    procedure EnableMenu(const iText: String; const iEnabled: Boolean);
      deprecated 'Insted AssignPopupMenu';
    procedure RegisterOnClick(const iEvent: TNotifyEvent);
    procedure RegisterIcon(const iName: String; const iIcon: TBitmap);
    procedure ChangeIcon(const iName, iHint: String);
    procedure HideTaskbar;
    property Enabled: Boolean read GetEnabled write SetEnabled;
    property LButtonPopup: Boolean read GetLButtonPopup write SetLButtonPopup;
    property OnBeginPopup: TNotifyEvent
      read GetOnBeginPopup write SetOnBeginPopup;
    property OnEndPopup: TNotifyEvent read GetOnEndPopup write SetOnEndPopup;
  end;

implementation

uses
  FMX.Platform
  {$IFDEF MSWINDOWS}
  , PK.TrayIcon.Win
  {$ENDIF}
  {$IFDEF OSX}
  , PK.TrayIcon.Mac
  {$ENDIF}
  ;

{ TTrayIcon }

procedure TTrayIcon.AddMenu(const iText: String; const iEvent: TNotifyEvent);
begin
  {$WARNINGS OFF}
  if FTrayIcon <> nil then
    FTrayIcon.AddMenu(iText, iEvent);
  {$WARNINGS ON}
end;

procedure TTrayIcon.Apply(const iGUID: TGUID);
begin
  if FTrayIcon <> nil then
    FTrayIcon.ApplyGUID(iGUID);
end;

procedure TTrayIcon.Apply;
begin
  if FTrayIcon <> nil then
    FTrayIcon.Apply;
end;

procedure TTrayIcon.Apply(const iGUIDString: String);
begin
  Apply(TGUID.Create(iGUIDString));
end;

procedure TTrayIcon.AssignPopupMenu(const iPopupMenu: TPopupMenu);
begin
  if FTrayIcon <> nil then
    FTrayIcon.AssignPopupMenu(iPopupMenu);
end;

procedure TTrayIcon.ChangeIcon(const iName, iHint: String);
begin
  if FTrayIcon <> nil then
    FTrayIcon.ChangeIcon(iName, iHint);
end;

constructor TTrayIcon.Create;
var
  TrayIconFactory: ITrayIconFactory;
begin
  inherited Create;

  if
    (
      TPlatformServices.Current.SupportsPlatformService(
        ITrayIconFactory,
        IInterface(TrayIconFactory)
      )
    )
  then
    FTrayIcon := TrayIconFactory.CreateTrayIcon;
end;

destructor TTrayIcon.Destroy;
begin
  FTrayIcon := nil;

  inherited;
end;

procedure TTrayIcon.EnableMenu(const iText: String; const iEnabled: Boolean);
begin
  {$WARNINGS OFF}
  if FTrayIcon <> nil then
    FTrayIcon.EnableMenu(iText, iEnabled);
  {$WARNINGS ON}
end;

function TTrayIcon.GetEnabled: Boolean;
begin
  if FTrayIcon = nil then
    Result := False
  else
    Result := FTrayIcon.GetEnabled;
end;

function TTrayIcon.GetLButtonPopup: Boolean;
begin
  if FTrayIcon = nil then
    Result := False
  else
    Result := FTrayIcon.GetLButtonPopup;
end;

function TTrayIcon.GetOnBeginPopup: TNotifyEvent;
begin
  if FTrayIcon = nil then
    Result := nil
  else
    Result := FTrayIcon.OnBeginPopup;
end;

function TTrayIcon.GetOnEndPopup: TNotifyEvent;
begin
  if FTrayIcon = nil then
    Result := nil
  else
    Result := FTrayIcon.OnEndPopup;
end;

procedure TTrayIcon.HideTaskbar;
begin
  if FTrayIcon <> nil then
    FTrayIcon.HideTaskbar;
end;

procedure TTrayIcon.RegisterIcon(const iName: String; const iIcon: TBitmap);
begin
  if FTrayIcon <> nil then
    FTrayIcon.RegisterIcon(iName, iIcon);
end;

procedure TTrayIcon.RegisterOnClick(const iEvent: TNotifyEvent);
begin
  if FTrayIcon <> nil then
    FTrayIcon.RegisterOnClick(iEvent);
end;

procedure TTrayIcon.SetEnabled(const iEnabled: Boolean);
begin
  if FTrayIcon <> nil then
    FTrayIcon.SetEnabled(iEnabled);
end;

procedure TTrayIcon.SetLButtonPopup(const iValue: Boolean);
begin
  if FTrayIcon <> nil then
    FTrayIcon.SetLButtonPopup(iValue);
end;

procedure TTrayIcon.SetOnBeginPopup(const iEvent: TNotifyEvent);
begin
  if FTrayIcon <> nil then
    FTrayIcon.OnBeginPopup := iEvent;
end;

procedure TTrayIcon.SetOnEndPopup(const iEvent: TNotifyEvent);
begin
  if FTrayIcon <> nil then
    FTrayIcon.OnEndPopup := iEvent;
end;

end.
