unit PK.Graphic.IconUtils.Win;

interface

uses
  Winapi.Windows
  , Winapi.Messages
  , Winapi.ShellAPI
  , Winapi.GDIPOBJ
  , FMX.Graphics
  , FMX.Forms
  ;

type
  TWinIcon = HICON;

  TIconUtils = class
  public type
    TIconProc = reference to procedure (const AIcon: TWinIcon);
  public
    class function GetAppIcon(
      const AExePath: String;
      const AIndex: Integer = 0): TWinIcon; overload;
    class procedure GetAppIcon(
      const AExePath: String;
      const AProc: TIconProc); overload;
    class procedure SetIconToForm(
      const AIcon: TWinIcon;
      const AForm: TCommonCustomForm);
    class procedure FreeIcon(const AIcon: TWinIcon);
  end;

implementation

uses
  System.SysUtils
  , FMX.Platform.Win
  ;

{ TIconUtils }

class procedure TIconUtils.FreeIcon(const AIcon: TWinIcon);
begin
  if AIcon <> 0 then
    DestroyIcon(AIcon);
end;

class function TIconUtils.GetAppIcon(
  const AExePath: String;
  const AIndex: Integer): TWinIcon;
begin
  Result := ExtractIcon(HInstance, PChar(AExePath), AIndex);
end;

class procedure TIconUtils.GetAppIcon(
  const AExePath: String;
  const AProc: TIconProc);
begin
  var Icon := GetAppIcon(AExePath);
  try
    if Assigned(AProc) then
      AProc(Icon);
  finally
    FreeIcon(Icon);
  end;
end;

class procedure TIconUtils.SetIconToForm(
  const AIcon: TWinIcon;
  const AForm: TCommonCustomForm);
begin
  if AIcon = 0 then
    Exit;

  var Wnd := FormToHWND(AForm);
  SendMessage(Wnd, WM_SETICON, ICON_SMALL, AIcon);
  SendMessage(Wnd, WM_SETICON, ICON_BIG, AIcon);
end;

end.
