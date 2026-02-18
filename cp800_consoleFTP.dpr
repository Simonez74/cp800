program cp800_consoleFTP;

uses
  {$IFDEF DEBUG}
  FastMM4 in 'FastMM4.pas',
  FastMM4Messages in 'FastMM4Messages.pas',
  {$ENDIF}
  Vcl.Forms,
  Forms.Main in 'Forms.Main.pas' {MainForm},
  DMI_Console in 'DMI_Console.pas' {DMIConsole: TDataModule},
  FrameMain in 'FrameMain.pas' {FrameCp800: TFrame},
  Frame.Configuration in 'Frame.Configuration.pas' {FrameConfiguration: TFrame},
  ConfigManager in 'ConfigManager.pas',
  UnitFtpMonitor in 'UnitFtpMonitor.pas',
  TypeUnit in 'TypeUnit.pas',
  UnitFtpMonitor.WeightData in 'UnitFtpMonitor.WeightData.pas',
  MyThreadLog in '..\..\Common\MyThreadLog.pas',
  funzioni in '..\..\Common\funzioni.pas',
  Frame.Service in 'Frame.Service.pas' {FrameService: TFrame};

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := true;
  {$ENDIF}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDMIConsole, DMIConsole);
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
