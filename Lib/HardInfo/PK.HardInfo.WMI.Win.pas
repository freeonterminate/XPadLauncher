(*
 * WMI Class
 *
 * PLATFORMS
 *   Windows
 *
 * LICENSE
 *   Copyright (c) 2018 HOSOKAWA Jun
 *   Released under the MIT license
 *   http://opensource.org/licenses/mit-license.php
 *
 * 2018/08/30 Version 1.0.0
 * 2024/11/03 Version 2.0.0
 *
 * Programmed by HOSOKAWA Jun (twitter: @pik)
 *)

unit PK.HardInfo.WMI.Win;

interface

uses
  System.SysUtils
  , System.Generics.Collections
  , Winapi.Wbem
  ;

type
  TWMI = record
  public type
    TWbemPropDicPair = TPair<String, Variant>;
    TWbemPropDic = TDictionary<String, Variant>;
  private type
    TWbemGetPropHandler = reference to procedure(const iProps: TWbemPropDic);
  public
    class function Exec(
      const AWQL: String;
      const APropName: array of String;
      const AHandler: TWbemGetPropHandler): Boolean; static;
    class function GetProperty(
      const AClassName: String;
      const APropName: array of String;
      const AHandler: TWbemGetPropHandler): Boolean; static;
  end;


implementation

uses
  Winapi.Windows
  , Winapi.ActiveX
  , Winapi.ComAdmin
  , System.Win.ComObj
  , System.Variants
  ;

{ TWMI }

class function TWMI.Exec(
  const AWQL: String;
  const APropName: array of String;
  const AHandler: TWbemGetPropHandler): Boolean;
begin
  var WbemLocator: OLEVariant := CreateOleObject('WbemScripting.SWbemLocator');
  var WMIService: OLEVariant :=
    WbemLocator.ConnectServer(
      'localhost',
      'root\CIMV2',
      '',
      '');

  var WbemObjectSet: OLEVariant :=
    WMIService.ExecQuery(AWQL, 'WQL', WBEM_FLAG_FORWARD_ONLY);

  var Fetched: LongWord;
  var WbemObject: OLEVariant;
  var Enum: IEnumvariant := IUnknown(WbemObjectSet._NewEnum) as IEnumVariant;

  while Enum.Next(1, WbemObject, Fetched) = 0 do
  begin
    var Dispatch := IDispatch(WbemObject);
    if Dispatch = nil then
      Continue;

    var DispIntfID: TDispID;

    var DispParams: TDispParams;
    DispParams.rgvarg := nil;
    DispParams.cArgs := 0;
    DispParams.cNamedArgs := 0;

    var Dic := TWbemPropDic.Create;
    try
      for var  i := 0 to High(APropName) do
      begin
        if
          Failed(
            Dispatch.GetIDsOfNames(
              GUID_NULL,
              @APropName[i],
              1,
              LOCALE_USER_DEFAULT,
              @DispIntfID
            )
          )
        then
          Continue;

        var Prop: Variant;
        var ExcepInfo: TExcepInfo;

        var Res :=
          Dispatch.Invoke(
            DispIntfID,
            GUID_NULL,
            LOCALE_USER_DEFAULT,
            DISPATCH_PROPERTYGET,
            DispParams,
            @Prop,
            @ExcepInfo,
            nil);

        if Failed(Res) then
          Continue;

        Dic.AddOrSetValue(APropName[i], Prop);
      end;

      if (Dic.Count > 0) and Assigned(AHandler) then
        AHandler(Dic);
    finally
      Dic.Free;
    end;

    WbemObject:=Unassigned;
  end;

  Result := True;
end;

class function TWMI.GetProperty(
  const AClassName: String;
  const APropName: array of String;
  const AHandler: TWbemGetPropHandler): Boolean;
begin;
  Result := Exec('SELECT * FROM ' + AClassName, APropName, AHandler);
end;

initialization
begin
  CoInitialize(nil);
  CoInitializeSecurity(
    nil,
    -1,
    nil,
    nil,
    COMAdminAuthenticationDefault,
    COMAdminImpersonationImpersonate,
    nil,
    COMAdminAuthenticationCapabilitiesNone,
    nil);
end;

finalization
begin
  CoUninitialize;
end;

end.
