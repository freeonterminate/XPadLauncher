(*
 * XPad Launcher
 *
 * PLATFORMS
 *   Windows
 *
 * LICENSE
 *   Copyright (c) 2024 HOSOKAWA Jun
 *   Released under the MIT license
 *   http://opensource.org/licenses/mit-license.php
 *
 * HISTORY
 *   2024/11/16  Ver 1.0.0  Release
 *
 * Programmed by HOSOKAWA Jun (twitter: @pik)
 *)

unit uVersion;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo, FMX.StdCtrls, FMX.Objects, FMX.Controls.Presentation,
  FMX.Layouts;

type
  TfrmVersion = class(TForm)
    layRoot: TLayout;
    layTopLeft: TLayout;
    imgIcon: TImage;
    layTopClient: TLayout;
    lblTitle: TLabel;
    lblVersion: TLabel;
    lineSep: TLine;
    imgDelphi: TImage;
    layClientButtonBase: TLayout;
    btnClose: TButton;
    memoLicense: TMemo;
    lblDelphi: TLabel;
    styleBlueClear: TStyleBook;
    procedure FormCreate(Sender: TObject);
  private
  public
  end;

procedure ShowVersion;

implementation

{$R *.fmx}

uses
  PK.Utils.Application;

procedure ShowVersion;
begin
  var F := TfrmVersion.Create(nil);
  try
    F.ShowModal;
  finally
    F.ReleaseForm;
  end;
end;

procedure TfrmVersion.FormCreate(Sender: TObject);
begin
  lblVersion.Text := 'Version ' + Application.Version;
end;

end.
