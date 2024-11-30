(*
 * Browser Utils
 *
 * PLATFORMS
 *   Windows / macOS / iOS / Android / Linux (needs xdg-utils)
 *
 * USAGE
 *   OpenBrowser with URL
 *     TBrowserUtils.Open('URL');
 *
 * LICENSE
 *   Copyright (c) 2015, 2021 HOSOKAWA Jun
 *   Released under the MIT license
 *   http://opensource.org/licenses/mit-license.php
 *
 * HISTORY
 *   2015/11/27 Ver 1.0.0
 *   2021/01/20 Ver 1.0.1  macOS: _system open -> NSWorkspace.openURL
 *   2021/01/30 Ver 1.0.2  iOS: openURL -> openURL:options:completionHandler:
 *   2021/01/31 Ver 1.1.0  Global procedure -> record
 *
 * Programmed by HOSOKAWA Jun (twitter: @pik)
 *)

unit PK.Utils.Browser;

interface

type
  TBrowserUtils = record
  public
    class procedure Open(const iURL: String); static;
  end;

implementation

uses
  System.SysUtils

  {$IFDEF MSWINDOWS}
    , Winapi.Windows
    , Winapi.ShellAPI
  {$ENDIF}

  {$IFDEF OSX}
    , Macapi.AppKit
    , Macapi.Helpers
  {$ENDIF}

  {$IFDEF ANDROID}
    , Androidapi.JNI.Net
    , Androidapi.JNI.App
    , Androidapi.JNI.GraphicsContentViewText
    , Androidapi.Helpers
    , FMX.Helpers.Android
  {$ENDIF}

  {$IFDEF IOS}
    , iOSapi.Foundation
    , iOSapi.UIKit
    , Macapi.Helpers
    , Macapi.ObjectiveC
    , FMX.Helpers.IOS
  {$ENDIF}

  {$IFDEF LINUX}
    , Posix.StdLib
  {$ENDIF}
  ;

{$IFDEF IOS}
type
  // openURL は iOS 10.0 で deprecated になり
  // openURL:options:completionHandler: に変更しなくてはならなくなった
  // だが 2021/2 現在の Delphi 10.4.1 の UIApplication では
  // openURL:options:completionHandler: は定義されていないため自分で定義する
  UIApplicationEx = interface(UIApplication)
    [MethodName('openURL:options:completionHandler:')]
    function OpenURLoptionsCompletionHandler(
      url: NSURL;
      options: Pointer;
      completionHandler: Pointer): Boolean; cdecl;
  end;
  TUIApplicationEx =
    class(TOCGenericImport<UIApplicationClass, UIApplicationEx>)
    end;
{$ENDIF}

class procedure TBrowserUtils.Open(const iURL: String);
begin
  {$IFDEF MSWINDOWS}
    if (ShellExecute(0, 'open', PChar(iURL), nil, nil, SW_SHOW) < 32) then
      WinExec(PAnsiChar(AnsiString('explorer ' + iURL)), SW_SHOW)
  {$ENDIF}

  {$IFDEF OSX}
    var Workspace := TNSWorkspace.Wrap(TNSWorkspace.OCClass.sharedWorkspace);
    Workspace.openURL(StrToNSUrl(iURL));
  {$ENDIF}

  {$IFDEF ANDROID}
    var Intent :=
      TJIntent.JavaClass.init(
        TJIntent.JavaClass.ACTION_VIEW,
        StrToJURI(iURL));

    {$IF RTLVersion < 30}
      SharedActivity.startActivity(Intent);
    {$ELSE}
      TAndroidHelper.Activity.startActivity(Intent);
    {$ENDIF}
  {$ENDIF}

  {$IFDEF IOS}
    var App := TUIApplicationEx.Wrap(TUIApplication.OCClass.sharedApplication);
    var URI := TNSURL.Wrap(TNSURL.OCClass.URLWithString(StrToNSStr(iURL)));

    if TOSVersion.Check(10, 0) then
    begin
      var Dic := TNSDictionary.OCClass.dictionary;
      App.OpenURLoptionsCompletionHandler(URI, Dic, nil);
    end
    else
      App.OpenURL(URI);
  {$ENDIF}

  {$IFDEF LINUX}
    _system(PAnsiChar('xdg-open '+ AnsiString(iURL.QuotedString('"'))));
  {$ENDIF}
end;

end.
