(*
 * TBitmapCodecManager Helper
 *
 * PLATFORMS
 *   Windows / macOS / Android / iOS
 *
 * LICENSE
 *   Copyright (c) 2023 HOSOKAWA Jun
 *   Released under the MIT license
 *   http://opensource.org/licenses/mit-license.php
 *
 * 2023/11/26 Version 1.0.0
 * Programmed by HOSOKAWA Jun (twitter: @pik)
 *)

unit PK.Graphic.BitmapCodecManagerHelper;

interface

uses
  System.Classes
  , System.SysUtils
  , FMX.Consts
  , FMX.Graphics
  ;

type
  TBitmapCodecManagerHelper = class helper for TBitmapCodecManager
    class function
      GetDialogFilter(const AExcludes: TArray<String> = []): String;
  end;

implementation

class function TBitmapCodecManagerHelper.GetDialogFilter(
  const AExcludes: TArray<String>): String;
var
  Desc: TStringList;
  Exts: TStringList;
  SB: TStringBuilder;

  procedure AppendExts;
  begin
    for var E in Exts do
    begin
      SB.Append(E);
      SB.Append(';');
    end;
    SB.Remove(SB.Length - 1, 1);
  end;

begin
  Desc := nil;
  Exts := nil;
  try
    Desc := TStringList.Create;
    Exts := TStringList.Create;

    var Filters := TBitmapCodecManager.GetFilterString.Split(['|']);
    var Len := Length(Filters) div 2;

    for var i := 1 to Len - 1 do
    begin
      var Index := i * 2;
      var D := Filters[Index + 0];
      var F := Filters[Index + 1];

      var IsExclude := False;
      for var Ex in AExcludes do
        if F.EndsWith(Ex) then
        begin
          IsExclude := True;
          Break;
        end;

      if IsExclude then
        Continue;

      Desc.Add(D);
      Exts.Add(F);
    end;

    SB := TStringBuilder.Create;
    try
      SB.Append(SVAllFiles);
      SB.Append(' (');
      AppendExts;
      SB.Append(')|');
      AppendExts;
      SB.Append('|');

      for var i := 0 to Desc.Count - 1 do
      begin
        SB.Append(Desc[i]);
        SB.Append('|');
        SB.Append(Exts[i]);
        SB.Append('|');
      end;
      SB.Remove(SB.Length - 1, 1);

      Result := SB.ToString;
    finally
      SB.Free;
    end;
  finally
    Desc.Free;
    Exts.Free;
  end;
end;

end.
