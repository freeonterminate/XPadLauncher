unit PK.Graphic.IconConverter.Win;

interface

uses
  Winapi.Windows
  , Winapi.GDIPAPI
  , Winapi.GDIPOBJ
  , FMX.Graphics
  ;

type
  TIconConverter = class
  public
    class function BitmapToIcon(const ABitmap: TBitmap): HICON;
    class procedure IconToBitmap(const AIcon: HICON; const ABitmap: TBitmap);
  end;

implementation

uses
  System.SysUtils
  , FMX.Helpers.Win
  ;

{ TIconConverter }

class function TIconConverter.BitmapToIcon(const ABitmap: TBitmap): HICON;
begin
  Result := BitmapToIcon(ABitmap);
end;

class procedure TIconConverter.IconToBitmap(
  const AIcon: HICON;
  const ABitmap: TBitmap);
begin
  ABitmap.SetSize(0, 0);

  var W: Int64 := 0;
  var H: Int64 := 0;

  // Icon Bitmap 取得
  var IconInfo: TIconInfo;
  if GetIconInfo(AIcon, IconInfo) then
    try
      if IconInfo.hbmColor <> 0 then
      begin
        var IconBmp: BITMAP;
        GetObject(IconInfo.hbmColor, SizeOf(IconBmp), @IconBmp);

        W := IconBmp.bmWidth;
        H := IconBmp.bmHeight;
      end;
    finally
      DeleteObject(IconInfo.hbmColor);
      DeleteObject(IconInfo.hbmMask);
    end;

  if W * H = 0 then
    Exit;

  // ピクセルデータバッファ確保
  var Colors: TArray<UInt32>;
  SetLength(Colors, W * H);

  // Icon to HBitmap
  var ScreenDC := GetDC(0);
  try
    var HBitmap := CreateCompatibleBitmap(ScreenDC, W, H);
    try
      var BmpDC := CreateCompatibleDC(0);
      try
        var Old := SelectObject(BmpDC, HBitmap);
        try
          DrawIconEx(BmpDC, 0, 0, AIcon, W, H, 0, 0, DI_NORMAL);

          // Icon Bitmap Info 取得
          var Info: TBitmapInfo;
          ZeroMemory(@Info, SizeOf(Info));

          Info.bmiHeader.biSize := SizeOf(Info.bmiHeader);
          Info.bmiHeader.biWidth := W;
          Info.bmiHeader.biHeight := -H;
          Info.bmiHeader.biPlanes := 1;
          Info.bmiHeader.biBitCount := 32;
          Info.bmiHeader.biCompression := BI_RGB;

          GetDIBits(BmpDC, HBitmap, 0, H, Colors, Info, DIB_RGB_COLORS);
        finally
          SelectObject(BmpDC, Old);
        end;
      finally
        DeleteDC(BmpDC);
      end;
    finally
      DeleteObject(HBitmap);
    end;
  finally
    ReleaseDC(0, ScreenDC);
  end;

  // ピクセル転送
  ABitmap.SetSize(W, H);

  var Data: TBitmapData;
  ABitmap.Map(TMapAccess.Write, Data);
  try
    for var Y := 0 to H - 1 do
      Move(Colors[Y * W], Data.GetScanline(Y)^, W * 4);
  finally
    ABitmap.Unmap(Data);
  end;
end;

end.
