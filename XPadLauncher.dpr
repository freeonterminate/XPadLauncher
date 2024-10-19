program XPadLauncher;

uses
  System.StartUpCopy,
  FMX.Forms,
  uConfigForm in 'uConfigForm.pas' {frmConfig},
  uMain in 'uMain.pas' {frmMain},
  uXPadCommand in 'uXPadCommand.pas',
  uCommandPanel in 'uCommandPanel.pas',
  uButtonIndexes in 'uButtonIndexes.pas',
  PK.Device.GamePad.Types in 'Lib\Device\PK.Device.GamePad.Types.pas',
  PK.Device.GamePad in 'Lib\Device\PK.Device.GamePad.pas',
  PK.Device.GamePad.Win in 'Lib\Device\PK.Device.GamePad.Win.pas',
  PK.Graphic.IconConverter.Win in 'Lib\Graphics\PK.Graphic.IconConverter.Win.pas',
  PK.Graphic.IconUtils.Win in 'Lib\Graphics\PK.Graphic.IconUtils.Win.pas',
  PK.Utils.Application in 'Lib\Utils\PK.Utils.Application.pas',
  PK.Utils.Log in 'Lib\Utils\PK.Utils.Log.pas',
  PK.Utils.ProhibitMultiExec in 'Lib\Utils\PK.Utils.ProhibitMultiExec.pas',
  PK.TrayIcon.Win in 'Lib\TrayIcon\PK.TrayIcon.Win.pas',
  PK.TrayIcon.Default in 'Lib\TrayIcon\PK.TrayIcon.Default.pas',
  PK.TrayIcon.Mac in 'Lib\TrayIcon\PK.TrayIcon.Mac.pas',
  PK.TrayIcon in 'Lib\TrayIcon\PK.TrayIcon.pas',
  PK.GUI.NativePopupMenu.Win in 'Lib\GUI\PK.GUI.NativePopupMenu.Win.pas',
  uConfig in 'uConfig.pas',
  PK.Utils.ImageListHelper in 'Lib\Utils\PK.Utils.ImageListHelper.pas',
  PK.GUI.DarkMode.Win in 'Lib\GUI\PK.GUI.DarkMode.Win.pas';

{$R *.res}

begin
  if RegisterInstance('128DB3BC-1978-4EF6-8EF2-7474A0FA82F7') then
    try
      {$IFDEF DEBUG}
      ReportMemoryLeaksOnShutdown := True;
      {$ENDIF}

      Application.Initialize;
      Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
    finally
      UnregisterInstance;
    end;
end.
