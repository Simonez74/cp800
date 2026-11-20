program cp800_consoleFTP;

uses
  {$IFDEF DEBUG}
  FastMM4 in 'FastMM4.pas',
  {$ENDIF }
  Vcl.Forms,
  Forms.Main in 'Forms.Main.pas' {MainForm},
  DMI_Console in 'DMI_Console.pas' {DMIConsole: TDataModule},
  FrameMain in 'FrameMain.pas' {FrameCp800: TFrame},
  Frame.Configuration in 'Frame.Configuration.pas' {FrameConfiguration: TFrame},
  ConfigManager in 'ConfigManager.pas',
  UnitFtpMonitor in 'UnitFtpMonitor.pas',
  TypeUnit in 'TypeUnit.pas',
  UnitFtpMonitor.WeightData in 'UnitFtpMonitor.WeightData.pas',
  Frame.Service in 'Frame.Service.pas' {FrameService: TFrame},
  Forms.Licenza in 'Forms.Licenza.pas' {FormLicenza},
  funzioni in '\\172.17.0.14\UT_Elettrico\Sorgenti_Delphi\DelphiSorma\Common\funzioni.pas',
  MyThreadLog in '\\172.17.0.14\UT_Elettrico\Sorgenti_Delphi\DelphiSorma\Common\MyThreadLog.pas',
  LicenseCore in '\\172.17.0.14\UT_Elettrico\Sorgenti_Delphi\DelphiSorma\LicenzeDelphi\Common\LicenseCore.pas',
  LicensePublicKey in '\\172.17.0.14\UT_Elettrico\Sorgenti_Delphi\DelphiSorma\LicenzeDelphi\Common\LicensePublicKey.pas';

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := true;
  {$ENDIF}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;

  // Licenza: se non valida mostro la form licenza (ID macchina + importazione).
  // Senza licenza valida il programma non parte (niente DB, niente monitor FTP).
  if not VerificaLicenza then
    Exit;

  Application.CreateForm(TDMIConsole, DMIConsole);
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
