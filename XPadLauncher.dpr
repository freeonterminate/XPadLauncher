program XPadLauncher;

uses
  System.StartUpCopy,
  FMX.Forms,
  uMain in 'uMain.pas' {frmMain},
  uButtonStatusForm in 'uButtonStatusForm.pas' {frmButtonStatus},
  uConfigForm in 'uConfigForm.pas' {frmConfig},
  uCommandInputForm in 'uCommandInputForm.pas' {frmInputCommand},
  uCommandFrame in 'uCommandFrame.pas' {frameCommand: TFrame},
  uVersion in 'uVersion.pas' {frmVersion},
  uCommandUtils in 'uCommandUtils.pas',
  uConfig in 'uConfig.pas',
  uMisc in 'uMisc.pas',
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
  PK.Utils.ImageListHelper in 'Lib\Utils\PK.Utils.ImageListHelper.pas',
  PK.GUI.DarkMode.Win in 'Lib\GUI\PK.GUI.DarkMode.Win.pas',
  PK.Graphic.BitmapCodecManagerHelper in 'Lib\Graphics\PK.Graphic.BitmapCodecManagerHelper.pas',
  PK.Utils.ScreenHelper in 'Lib\Utils\PK.Utils.ScreenHelper.pas',
  PK.HardInfo.WMI.Win in 'Lib\HardInfo\PK.HardInfo.WMI.Win.pas',
  Winapi.GameInput in 'Lib\Winapi\Winapi.GameInput.pas',
  Winapi.XInput in 'Lib\Winapi\Winapi.XInput.pas',
  PK.AutoRun in 'Lib\AutoRun\PK.AutoRun.Pas',
  PK.AutoRun.Types in 'Lib\AutoRun\PK.AutoRun.Types.pas',
  PK.AutoRun.Win in 'Lib\AutoRun\PK.AutoRun.Win.pas';

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
