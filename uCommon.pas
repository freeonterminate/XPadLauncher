unit uCommon;

interface

uses
  System.SysUtils
  , FMX.Graphics
  ;

procedure GetAppIconImage(const APath: String; const AImage: TBitmap);

implementation

uses
  System.IOUtils
  {$IFDEF MSWINDOWS}
  , PK.Graphic.IconConverter.Win
  , PK.Graphic.IconUtils.Win
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

end.
