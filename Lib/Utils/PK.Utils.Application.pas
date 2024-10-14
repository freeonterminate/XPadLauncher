(*
 * Application Utils
 *
 * PLATFORMS
 *   Windows / macOS / Android / iOS
 *
 * LICENSE
 *   Copyright (c) 2018 HOSOKAWA Jun
 *   Released under the MIT license
 *   http://opensource.org/licenses/mit-license.php
 *
 * 2018/04/08 Version 1.0.0
 * 2022/12/19 Version 1.1.0  GetVersion support Android / iOS
 *
 * Programmed by HOSOKAWA Jun (twitter: @pik)
 *)

unit PK.Utils.Application;

interface

uses
  FMX.Forms
  {$IFDEF ANDROID}
  , Androidapi.JNI.GraphicsContentViewText
  {$ENDIF}
  ;

type
  TApplicationHelper = class helper for TApplication
  private
    function GetVersion: String;
    {$IFDEF ANDROID}
    function GetPackageInfo: JPackageInfo;
    {$ENDIF}
  public
    function Path: String; // Path Only
    function ExeName: String; // Full Path with FileName
    property Version: String read GetVersion;
  end;


implementation

uses
  System.Classes
  , System.SysUtils
  , System.IOUtils
  {$IFDEF MSWINDOWS}
  {$ENDIF}
  {$IFDEF OSX}
  , Macapi.CoreFoundation
  {$ENDIF}
  {$IFDEF ANDROID}
  , Androidapi.Helpers
  , Androidapi.JNI.JavaTypes
  , Androidapi.JNI.App
  , Androidapi.NativeActivity
  {$ENDIF}
  {$IFDEF IOS}
  , Macapi.Helpers
  , iOSapi.Foundation
  {$ENDIF}
  ;

{ TApplicationHelper }

function TApplicationHelper.Path: String;
begin
  {$IFDEF MSWINDOWS}
  Result := ExtractFilePath(ParamStr(0));
  {$ENDIF}

  {$IFDEF ANDROID}
  var Info := GetPackageInfo;
  if Info = nil then
    Result := ''
  else
    Result := JStringToString(Info.applicationInfo.sourceDir);
  {$ENDIF}

  {$IFDEF MACOS} // macOS & iOS
  Result := '';

  var SL := TStringList.Create;
  try
    SL.Text := ParamStr(0).Replace(TPath.DirectorySeparatorChar, sLineBreak);

    var Count := SL.Count - 1;
    for var i := 0 to Count do
    begin
      var Str := SL[i];
      if Str.EndsWith('.app') then
        Break;

      Result := Result + Str + TPath.DirectorySeparatorChar;
    end;
  finally
    SL.DisposeOf;
  end;
  {$ENDIF}
end;

function TApplicationHelper.ExeName: String;
begin
  {$IFDEF ANDROID}
  var Info := GetPackageInfo;
  if Info = nil then
    Result := ''
  else
    Result := JStringToString(Info.packageName);
  {$ELSE}
  Result := ParamStr(0);
  {$ENDIF}
end;

{$IFDEF ANDROID}
function TApplicationHelper.GetPackageInfo: JPackageInfo;
begin
  var Activity :=
    TJNativeActivity.Wrap(PANativeActivity(System.DelphiActivity)^.clazz);
  Result :=
    Activity.getPackageManager.getPackageInfo(Activity.getPackageName, 0);
end;
{$ENDIF}

function TApplicationHelper.GetVersion: String;
begin
  Result := 'unknown';

  {$IFDEF MSWINDOWS}
  var Major, Minor, Build: Cardinal;

  if GetProductVersion(ExeName, Major, Minor, Build) then
    Result := Format('%d.%d.%d', [Major, Minor, Build]);
  {$ENDIF}

  {$IFDEF OSX}
  var CFStr: CFStringRef :=
    CFBundleGetValueForInfoDictionaryKey(
      CFBundleGetMainBundle,
      kCFBundleVersionKey
    );

  var Range: CFRange;
  Range.location := 0;
  Range.length := CFStringGetLength(CFStr);
  SetLength(Result, Range.length);

  CFStringGetCharacters(CFStr, Range, PChar(Result));

  Result := Result.Trim;
  {$ENDIF}

  {$IFDEF IOS}
  var Ver :=
    TNSBundle
    .Wrap(TNSBundle.OCClass.mainBundle)
    .infoDictionary
    .objectForKey(StringToID('CFBundleVersion'));

  if Ver <> nil then
    Result := NSStrToStr(TNSString.Wrap(Ver));
  {$ENDIF}

  {$IFDEF ANDROID}
  var Info := GetPackageInfo;
  if Info <> nil then
    Result := JStringToString(Info.versionName);
  {$ENDIF}
end;

end.
