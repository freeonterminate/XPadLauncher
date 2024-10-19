(*
 * ProhibitMultiExec Utils
 *
 * PLATFORMS
 *   Windows / macOS
 *
 * LICENSE
 *   Copyright (c) 2018 HOSOKAWA Jun
 *   Released under the MIT license
 *   http://opensource.org/licenses/mit-license.php
 *
 * 2018/04/20 Version 1.0.0
 * 2018/05/13 Version 1.0.1  Display the already running app on the forefront
 * Programmed by HOSOKAWA Jun (twitter: @pik)
 *)

unit PK.Utils.ProhibitMultiExec;

interface

function RegisterInstance(const iName: String): Boolean;
procedure UnregisterInstance;

implementation

{$IFDEF MSWINDOWS}

uses
  System.SysUtils
  , Winapi.Windows
  , Winapi.Messages
  , FMX.Platform.Win
  ;

var
  GHandle: THandle;
  GName: String;

function EnumWindowsProc(iWnd: HWND; ilParam: LPARAM): BOOL; stdcall;
var
  ActiveThreadID: DWORD;
  TargetID: DWORD;
  SelfIconic: Boolean;
begin
  Result := True;

  if GetProp(iWnd, PChar(GName)) <> 0 then
  begin
    Result := False;

    SelfIconic := not IsIconic(iWnd);
    if SelfIconic then
      SendMessage(iWnd, WM_SYSCOMMAND, SC_MINIMIZE, 0);

    ActiveThreadID := GetWindowThreadProcessId(GetForegroundWindow, nil);
    TargetID := GetWindowThreadProcessId(iWnd, nil);

    AttachThreadInput(TargetID, ActiveThreadID, True);
    try
      if SelfIconic then
        OpenIcon(iWnd);

      SetWindowPos(
        iWnd,
        HWND_TOP,
        0, 0,
        0, 0,
        SWP_NOSIZE or SWP_NOMOVE or SWP_SHOWWINDOW);
    finally
      AttachThreadInput(TargetID, ActiveThreadID, False);
    end;
  end;
end;

function RegisterInstance(const iName: String): Boolean;
var
  Err: Integer;
  Wnd: HWND;
begin
  Result := False;

  GName := iName;

  GHandle := CreateMutex(nil, False, PChar(GName));
  Err := GetLastError;
  if Err = ERROR_ALREADY_EXISTS then
  begin
    ReleaseMutex(GHandle);
    GHandle := 0;

    EnumWindows(@EnumWindowsProc, 0);

    Exit;
  end;

  Result := (GHandle <> 0);
  if Result then
  begin
    Wnd := ApplicationHWND;
    SetProp(Wnd, PChar(iName), Wnd);
  end;
end;

procedure UnregisterInstance;
begin
  if (GHandle <> 0) then
  begin
    ReleaseMutex(GHandle);
    CloseHandle(GHandle);

    GHandle := 0;

    RemoveProp(ApplicationHWND, PChar(GName));
  end;
end;

{$ELSE}

{$IFDEF OSX}

uses
  Macapi.AppKit
  , Macapi.Foundation
  ;

function RegisterInstance(const iName: String): Boolean;
var
  Apps: NSArray;
  MyBundleId: NSString;
  App: NSApplication;
begin
  MyBundleId :=
    TNSBundle.Wrap(TNSBundle.OCClass.mainBundle).bundleIdentifier;

  Apps :=
    TNSRunningApplication
    .OCClass
    .runningApplicationsWithBundleIdentifier(MyBundleId);

  Result := Apps.count < 2;

  if not Result then
  begin
    App := TNSApplication.Wrap(Apps.objectAtIndex(0));

    if App.mainWindow <> nil then
    begin
      App.activateIgnoringOtherApps(True);
      App.mainWindow.makeKeyAndOrderFront(nil);
    end;
  end;
end;

procedure UnregisterInstance;
begin
end;

{$ELSE}

function RegisterInstance(const iName: String): Boolean;
begin
  Result := True;
end;

procedure UnregisterInstance;
begin
end;

{$ENDIF}

{$ENDIF}

end.
