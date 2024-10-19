(*
 * ImageListHelper
 *
 * PLATFORMS
 *   All
 *
 * LICENSE
 *   Copyright (c) 2018 HOSOKAWA Jun
 *   Released under the MIT license
 *   http://opensource.org/licenses/mit-license.php
 *
 * 2018/04/08 Version 1.0.0
 * Programmed by HOSOKAWA Jun (twitter: @pik)
 *)

unit PK.Utils.ImageListHelper;

interface

uses
  FMX.Graphics
  , FMX.ImgList
  ;

type
  TImageListHelper = class helper for TImageList
  public
    function GetBitmap(const iName: String; var ioBmp: TBitmap): Boolean;
  end;

implementation

uses
  System.Types
  , FMX.MultiResBitmap
  ;

{ TImageHelper }

function TImageListHelper.GetBitmap(
  const iName: String;
  var ioBmp: TBitmap): Boolean;
var
  Item: TCustomBitmapItem;
  Size: TSize;
  Bmp: TBitmap;
begin
  Result := BitmapItemByName(iName, Item, Size);
  if (not Result) or (ioBmp = nil) then
    Exit;

  Bmp := Item.MultiResBitmap.Bitmaps[1];;
  Result := Bmp <> nil;

  if Result then
    ioBmp.Assign(Bmp);
end;

end.
