(*
 * アプリケーションをダークモードに対応させる
 *
 * PLATFORMS
 *   Windows 10, Windows 11
 *
 * ENVIRONMENT
 *   Delphi 10.4.2, 11
 *
 * USAGE
 *   Just add this unit to uses
 *   > uses PK.GUI.DarkMode.Win;
 *
 * LICENSE
 *   Copyright (c) 2021 HOSOKAWA Jun
 *   Released under the MIT license
 *   http://opensource.org/licenses/mit-license.php
 *
 * HISTORY
 *   2021/11/18 Version 1.0.0
 *
 * Programmed by HOSOKAWA Jun (twitter: @pik)
 *)

unit PK.GUI.DarkMode.Win;

interface

uses
  FMX.Forms
  ;

// DarkMode をサポートしているバージョンの Windows かどうかを返す
function IsSupportedDarkMode: Boolean;

// DarkMode を自分で制御する場合
procedure SetDarkMode(const AForm: TCommonCustomForm);
procedure SetDarkModeByHandle(const AWnd: UIntPtr); // UIntPtr = HWND;

implementation

uses
  Winapi.Windows
  , Winapi.DwmApi
  , Winapi.UxTheme
  , System.SysUtils
  , FMX.Platform.Win
  ;

type
  TPreferredAppMode = (
    APPMODE_DEFAULT = 0,
    APPMODE_ALLOWDARK = 1,
    APPMODE_FORCEDARK = 2,
    APPMODE_FORCELIGHT = 3,
    APPMODE_MAX = 4
  );

// API 定義
procedure RefreshImmersiveColorPolicyState; stdcall; forward;
function AllowDarkModeForWindow(Wnd: HWND; Allow: BOOL): BOOL; stdcall; forward;
function AllowDarkModeForApp(AllowDarkMode: BOOL): BOOL; stdcall; forward;
function SetPreferredAppMode(
  AppMode: TPreferredAppMode): TPreferredAppMode; stdcall; forward;
procedure FlushMenuThemes; stdcall; forward;

function IsSupportedDarkMode: Boolean;
begin
  Result :=
    (TOSVersion.Major > 10) or
    ((TOSVersion.Major = 10) and (TOSVersion.Build >= 1809));
end;

procedure SetDarkMode(const AForm: TCommonCustomForm);
begin
  SetDarkModeByHandle(FormToHWND(AForm));
end;

procedure SetDarkModeByHandle(const AWnd: UIntPtr);
begin
  if not IsSupportedDarkMode then
    Exit;

  AllowDarkModeForWindow(AWnd, True);
  SetWindowTheme(AWnd, 'Explorer', nil);
end;

const
  DLL_NAME = 'uxtheme.dll';

{$WARNINGS OFF W1002}
procedure RefreshImmersiveColorPolicyState; external DLL_NAME index 104 delayed;
function AllowDarkModeForWindow; external DLL_NAME index 133;
// 同じ index で Build 1809 は AllowDarkModeForApp が
// 1903 以降は SetPreferredAppMode が使える
function AllowDarkModeForApp; external DLL_NAME index 135 delayed;
function SetPreferredAppMode; external DLL_NAME index 135 delayed;
procedure FlushMenuThemes; external DLL_NAME index 136 delayed;
{$WARNINGS ON}

initialization
begin
  if IsSupportedDarkMode then
  begin
    // 一回何かを呼ばないと正しく設定できない
    SetPreferredAppMode(TPreferredAppMode.APPMODE_DEFAULT);
    SetPreferredAppMode(TPreferredAppMode.APPMODE_ALLOWDARK);
    RefreshImmersiveColorPolicyState;
  end;
end;

end.
