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
 *   2024/11/23  Ver 1.0.0  Release
 *
 * Programmed by HOSOKAWA Jun (twitter: @pik)
 *)

unit uVersion;

interface

uses
  System.Classes
  , FMX.Types
  , FMX.Controls
  , FMX.Forms
  , FMX.Memo
  , FMX.StdCtrls
  , FMX.Objects
  , FMX.Layouts, FMX.Memo.Types, FMX.ScrollBox, FMX.Controls.Presentation
  ;

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
