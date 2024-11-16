(*
 * ScreenHelper
 *
 * PLATFORMS
 *   Windows, macOS, iOS, Android
 *
 * LICENSE
 *   Copyright (c) 2024 HOSOKAWA Jun
 *   Released under the MIT license
 *   http://opensource.org/licenses/mit-license.php
 *
 * HISTORY
 *   2018/06/23  Ver 1.0.0  Release
 *
 * Programmed by HOSOKAWA Jun (twitter: @pik)
 *)

unit PK.Utils.ScreenHelper;

interface

uses
  FMX.Forms;

type
  TScreenHelper = class helper for TScreen
  private
    function GetScale: Single;
  public
    function CalcScale(const iValue: Single): Single;
    function CalcScaleToInt(const iValue: Single): Integer;
    property Scale: Single read GetScale;
  end;

implementation

uses
  System.SysUtils
  , FMX.Controls
  ;

{ TScreenHelper }

function TScreenHelper.CalcScale(const iValue: Single): Single;
begin
  Result := GetScale * iValue;
end;

function TScreenHelper.CalcScaleToInt(const iValue: Single): Integer;
begin
  Result := Round(CalcScale(iValue));
end;

function TScreenHelper.GetScale: Single;
var
  Form: TCommonCustomForm;
  Scene: IScene;
begin
  Form := ActiveForm;
  if Form = nil then
    Form := Application.MainForm;

  if Supports(Form, IScene, Scene) then
    Result := Scene.GetSceneScale
  else
    Result := 1;
end;

end.
