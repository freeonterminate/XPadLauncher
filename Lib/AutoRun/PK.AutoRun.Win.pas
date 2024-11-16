unit PK.AutoRun.Win;

{$IFNDEF MSWINDOWS}
{$WARN GARBAGE OFF}
interface
implementation
end.
{$ENDIF}

interface

implementation

uses
  System.SysUtils
  , System.Win.Registry
  , Winapi.Windows
  , FMX.Platform
  , PK.AutoRun.Types
  ;

type
  TAutoRunWin = class(TInterfacedObject, IAutoRun)
  private const
    KEY_RUN = 'Software\Microsoft\Windows\CurrentVersion\Run';
  private class var
    FIsUWP: Boolean;
  public
    class procedure CheckUWP;
  public
    { IAutoRun }
    function Register(const iName: String): Boolean;
    function Unregister(const iName: String): Boolean;
    function GetRegistered(const iName: String): Boolean;
  end;

  TAutoRunFactoryWin = class(TAutoRunFactory)
  public
    function CreateAutoRun: IAutoRun; override;
  end;

{$WARN SYMBOL_PLATFORM OFF}
function GetCurrentPackageId(
  packageFamilyNameLength: PUInt32;
  packageFamilyName: PByte): LONG; stdcall;
  external 'Kernel32.dll' delayed; // Windows 7 以前には存在しないので delayed
{$WARN SYMBOL_PLATFORM DEFAULT}

procedure RegisterAutoRunWin;
begin
  TPlatformServices.Current.AddPlatformService(
    IAutoRunFactory,
    TAutoRunFactoryWin.Create);
end;

{ TAutoRunWinFactory }

function TAutoRunFactoryWin.CreateAutoRun: IAutoRun;
begin
  Result := TAutoRunWin.Create;
end;

{ TAutoRunWin }

class procedure TAutoRunWin.CheckUWP;
const
  APPMODEL_ERROR_NO_PACKAGE = $3D54; // Win32 に対して実行した場合のエラーコード
begin
  if TOSVersion.Check(6, 2) then
  begin
    // Windows 8 以降
    var Len: UInt32 := 0;
    var Res := GetCurrentPackageId(@Len, nil);
    FIsUWP := Res <> APPMODEL_ERROR_NO_PACKAGE;
  end
  else
  begin
    // Windows 7 以前
    FIsUWP := False;
  end;
end;

function TAutoRunWin.GetRegistered(const iName: String): Boolean;
begin
  Result := False;

  if FIsUWP then
    Exit;

  var Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;

    if Reg.OpenKeyReadOnly(KEY_RUN) then
      try
        if Reg.ValueExists(iName) then
          Result := Reg.ReadString(iName).ToUpper = ParamStr(0).ToUpper;
      finally
        Reg.CloseKey;
      end;
  finally
    Reg.Free;
  end;
end;

function TAutoRunWin.Register(const iName: String): Boolean;
begin
  if FIsUWP then
    Exit(False);

  try
    var Reg := TRegistry.Create;;
    try
      Reg.RootKey := HKEY_CURRENT_USER;

      if Reg.OpenKey(KEY_RUN, True) then
        try
          Reg.WriteString(iName, ParamStr(0));
        finally
          Reg.CloseKey;
        end;
    finally
      Reg.Free;
    end;

    Result := GetRegistered(iName);
  except
    Result := False;
  end;
end;

function TAutoRunWin.Unregister(const iName: String): Boolean;
begin
  if FIsUWP then
    Exit(False);

  try
    var Reg := TRegistry.Create;;
    try
      Reg.RootKey := HKEY_CURRENT_USER;

      if Reg.OpenKey(KEY_RUN, True) then
        try
          Reg.DeleteValue(iName);
        finally
          Reg.CloseKey;
        end;
    finally
      Reg.Free;
    end;

    Result := not GetRegistered(iName);
  except
    Result := False;
  end;
end;

initialization
  RegisterAutoRunWin;
  TAutoRunWin.CheckUWP;

end.
