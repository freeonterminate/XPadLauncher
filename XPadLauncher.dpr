program XPadLauncher;

uses
  System.StartUpCopy,
  FMX.Forms,
  uMain in 'uMain.pas' {frmConfig},
  uXPadCommand in 'uXPadCommand.pas',
  PK.Device.GamePad.Types in 'Lib\Device\PK.Device.GamePad.Types.pas',
  PK.Device.GamePad in 'Lib\Device\PK.Device.GamePad.pas',
  PK.Device.GamePad.Win in 'Lib\Device\PK.Device.GamePad.Win.pas',
  uCommandPanel in 'uCommandPanel.pas',
  uButtonIndexes in 'uButtonIndexes.pas';

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}

  Application.Initialize;
  Application.CreateForm(TfrmConfig, frmConfig);
  Application.Run;
end.
