(*
 * AutoRun
 *
 * PLATFORMS
 *   Windows
 *
 * LICENSE
 *   Copyright (c) 2021 HOSOKAWA Jun
 *   Released under the MIT license
 *   http://opensource.org/licenses/mit-license.php
 *
 * HISTORY
 *   2017/06/08  Ver 1.0.0  Release
 *
 * Programmed by HOSOKAWA Jun (twitter: @pik)
 *)

unit PK.AutoRun;

interface

uses
  PK.AutoRun.Types;

type
  TAutoRun = class
  private var
    FKey: String;
    FAutoRun: IAutoRun;
  private
    function GetRegistered: Boolean;
    procedure SetRegistered(const iValue: Boolean);
  public
    constructor Create(const iKey: String); reintroduce;
    function Register: Boolean;
    function Unregister: Boolean;
    property Registered: Boolean read GetRegistered write SetRegistered;
  end;

implementation

uses
  System.SysUtils
  , FMX.Platform
  {$IFDEF MSWINDOWS}
  , PK.AutoRun.Win
  {$ENDIF}
  {$IFDEF OSX}
  , PK.AutoRun.Mac
  {$ENDIF}
  ;

{ TAutoRun }

constructor TAutoRun.Create(const iKey: String);
begin
  inherited Create;

  FKey := iKey;

  var Factory: IAutoRunFactory;

  if
    TPlatformServices.Current.SupportsPlatformService(
      IAutoRunFactory,
      Factory
    )
  then
    FAutoRun := Factory.CreateAutoRun;
end;

function TAutoRun.GetRegistered: Boolean;
begin
  Result := False;
  if FAutoRun <> nil then
    Result := FAutoRun.GetRegistered(FKey);
end;

function TAutoRun.Register: Boolean;
begin
  Result := False;
  if FAutoRun <> nil then
    Result := FAutoRun.Register(FKey);
end;

procedure TAutoRun.SetRegistered(const iValue: Boolean);
begin
  if GetRegistered <> iValue then
  begin
    if iValue then
      Register
    else
      Unregister;
  end;
end;

function TAutoRun.Unregister: Boolean;
begin
  Result := False;
  if FAutoRun <> nil then
    Result := FAutoRun.Unregister(FKey);
end;

end.
