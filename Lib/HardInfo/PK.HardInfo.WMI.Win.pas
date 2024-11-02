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
  private
    class function GetWbemServices(
      out oWbemServices: IWbemServices): Boolean; static;
    class function EnumObjects(
      const iEnumWbemClassObject: IEnumWbemClassObject;
      const iPropNames: array of String;
      const iHandler: TWbemGetPropHandler): Boolean; static;
  public
    class function Exec(
      const iWQL: String;
      const iPropName: array of String;
      const iHandler: TWbemGetPropHandler): Boolean; static;
    class function GetProperty(
      const iClassName: String;
      const iPropName: array of String;
      const iHandler: TWbemGetPropHandler): Boolean; static;
    class function GetPropertyEx(
      const iClassName: String;
      const iPropName: array of String;
      const iHandler: TWbemGetPropHandler): Boolean; static;
  end;


implementation

uses
  Winapi.Windows
  , Winapi.ActiveX
  , Winapi.ComAdmin
  , Winapi.UserEnv
  , System.Win.ComObj
  , System.Variants
  , PK.Utils.Log
  ;

{ TWMI }

class function TWMI.EnumObjects(
  const iEnumWbemClassObject: IEnumWbemClassObject;
  const iPropNames: array of String;
  const iHandler: TWbemGetPropHandler): Boolean;
var
  WbemObjects: array [0.. WBEM_MAX_OBJECT_NESTING - 1] of IWbemClassObject;
  COMResult: HResult;
  Prop: OleVariant;
  Count: Cardinal;
  i, j: Integer;
  Name: String;
  Dic: TWbemPropDic;
begin
  Result := False;

  while
    Succeeded(
      iEnumWbemClassObject.Next(
        0,
        1,
        WbemObjects[0],
        Count
      )
    )
  do
  begin
    if Count = 0 then
      Break
    else
      Result := True;

    Dic := TWbemPropDic.Create;
    try
      for i := 0 to Count - 1 do
      begin
        Dic.Clear;

        for j := 0 to High(iPropNames) do
        begin
          Name := iPropNames[j];
          WbemObjects[i].Get(PWideChar(WideString(Name)), 0, Prop, nil, nil);

          Dic.AddOrSetValue(Name, Prop);
        end;

        if Dic.Count > 0 then
          iHandler(Dic);
      end;
    finally
      Dic.Free;
    end;

    COMResult := iEnumWbemClassObject.Skip(Integer(WBEM_INFINITE), Count);

    if (Failed(COMResult)) or (COMResult = S_FALSE) then
      Break;
  end;
end;

class function TWMI.Exec(
  const iWQL: String;
  const iPropName: array of String;
  const iHandler: TWbemGetPropHandler): Boolean;
var
  WbemServices: IWbemServices;
  EnumWbemClassObject: IEnumWbemClassObject;
begin
  Result := False;

  // Get WbemServices
  if not GetWbemServices(WbemServices) then
    Exit;

  // Get EnumWbem
  if
    Failed(
      WbemServices.ExecQuery(
        'WQL',
        PWideChar(WideString(iWQL)),
        WBEM_FLAG_FORWARD_ONLY,
        nil,
        EnumWbemClassObject)
    )
  then
    Exit;

  Result := EnumObjects(EnumWbemClassObject, iPropName, iHandler);
end;

class function TWMI.GetProperty(
  const iClassName: String;
  const iPropName: array of String;
  const iHandler: TWbemGetPropHandler): Boolean;
var
  WbemServices: IWbemServices;
  EnumWbemClassObject: IEnumWbemClassObject;
begin
  Result := False;

  // Get WbemServices
  if not GetWbemServices(WbemServices) then
    Exit;

  // Get EnumWbem
  if
    Failed(
      WbemServices.CreateInstanceEnum(
        PWideChar(WideString(iClassName)),
        WBEM_FLAG_SHALLOW or WBEM_FLAG_FORWARD_ONLY,
        nil,
        EnumWbemClassObject)
    )
  then
    Exit;

  Result := EnumObjects(EnumWbemClassObject, iPropName, iHandler);
end;

class function TWMI.GetPropertyEx(
  const iClassName: String;
  const iPropName: array of String;
  const iHandler: TWbemGetPropHandler): Boolean;
begin;
  var WbemLocator: OLEVariant := CreateOleObject('WbemScripting.SWbemLocator');
  var WMIService: OLEVariant :=
    WbemLocator.ConnectServer(
      'localhost',
      'root\CIMV2',
      '',
      '');

  var WbemObjectSet: OLEVariant :=
    WMIService.ExecQuery(
      'SELECT * FROM ' + iClassName,
      'WQL',
      WBEM_FLAG_FORWARD_ONLY);

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
      for var  i := 0 to High(iPropName) do
      begin
        if
          Failed(
            Dispatch.GetIDsOfNames(
              GUID_NULL,
              @iPropName[i],
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

        Dic.AddOrSetValue(iPropName[i], Prop);
      end;

      if Dic.Count > 0 then
        iHandler(Dic);
    finally
      Dic.Free;
    end;

    WbemObject:=Unassigned;
  end;

  Result := True;
end;

class function TWMI.GetWbemServices(out oWbemServices: IWbemServices): Boolean;
var
  WbemLocator: IWbemLocator;
begin
  Result := False;
  oWbemServices := nil;

  if
    (
      Failed(
        CoCreateInstance(
          CLSID_WbemLocator,
          nil,
          CLSCTX_INPROC_SERVER,
          IID_IWbemLocator,
          WbemLocator)
      )
    )
  then
    Exit;

  if
    (
      Failed(
        WbemLocator.ConnectServer(
          'root\cimv2',
          '',
          '',
          '',
          0,
          '',
          nil,
          oWbemServices)
      )
    )
  then
    Exit;

  Result := True;
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
