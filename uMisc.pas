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
 *   2024/11/23  Ver 1.0.0  Release
 *
 * Programmed by HOSOKAWA Jun (twitter: @pik)
 *)

unit uMisc;

interface

uses
  System.SysUtils
  {$IFDEF MSWINDOWS}
  , Winapi.Windows
  , Winapi.ShellAPI
  {$ENDIF}
  , FMX.Graphics
  , PK.Device.GamePad.Types
  ;


procedure GetAppIconImage(const APath: String; const AImage: TBitmap);
procedure Execute(const APath: String);

implementation

uses
  System.IOUtils
  {$IFDEF MSWINDOWS}
  , PK.Graphic.IconConverter.Win
  , PK.Graphic.IconUtils.Win
  {$ENDIF}
  {$IFDEF OSX}
  , Posix.StdLib
  {$ENDIF}
  ;

procedure GetAppIconImage(const APath: String; const AImage: TBitmap);
begin
  AImage.Assign(nil);

  {$IFDEF MSWINDOWS}
  if TFile.Exists(APath) then
  begin
    var Icon := TIconUtils.GetAppIcon(APath, 0);
    try
      TIconConverter.IconToBitmap(Icon, AImage);
    finally
      TIconUtils.FreeIcon(Icon);
    end;
  end;
  {$ENDIF}
end;

procedure Execute(const APath: String);
begin
  {$IFDEF MSWINDOWS}
  if TFile.Exists(APath) then
  begin
    if (ShellExecute(0, 'open', PChar(APath), nil, nil, SW_SHOW) < 32) then
      WinExec(PAnsiChar(AnsiString(APath)), SW_SHOW)
  end;
  {$ENDIF}

  {$IFDEF OSX}
  _system(PAnsiChar(AnsiString('open '+ APath)));
  {$ENDIF}
end;

end.
