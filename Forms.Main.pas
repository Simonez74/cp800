unit Forms.Main;

(*
1. Forms_Main.CreatePanels
   └─ FFrame.Start()
       ├─ Crea FMonitor, lo avvia
       └─ InitWeightMonitor() → crea FMonitorWeight (NON lo avvia)

2. Primo ciclo FMonitor (dopo ~200ms)
   └─ MonitorParsed popola le label
       └─ lbl1102 cambia → UpdateMonitorState
            └─ FMonitorWeight.UpdateState('P: 1', true, '1')
                 └─ ApplyStateChange IMMEDIATAMENTE (no timer!)
                      ├─ FCurrentState := NewState  ← VALORIZZATO
                      └─ Start()  ← AVVIA thread FTP pesi

3. Secondo ciclo FMonitorWeight
   └─ ProcessWeightData
       └─ CurrentOutputPath := FCurrentState.OutputFileName  ← OK!
       └─ Scrive i pesi sul CSV

*)


interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics,  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.AppEvnts,
 FireDAC.Comp.DataSet, FireDAC.Comp.Client,
   Vcl.ExtCtrls
  , System.IOUtils, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup, System.Actions, Vcl.ActnList,
  Vcl.ComCtrls
  ,system.UITypes, System.ImageList, Vcl.ImgList, Vcl.StdCtrls, Vcl.WinXCtrls, Vcl.ToolWin
  ,FrameMain
  ,System.Generics.Collections

  ,Frame.Configuration, ConfigManager
  //MyThreadLog
  ,System.Threading
  ,DMI_Console,  TypeUnit, MyThreadLog,   funzioni
  , system.DateUtils;

const
//   FTPData_056.txt
  StartFileName = 'FTPData_';
  StartFileProdName = 'FTPData2_';

type

 { TMioTabSheet = class (TTabSheet)
  private
    FIdCp800 : String;
  public
    property idCp800 : String read FIdCp800 write FIdCp800;
  end;
  }


  TMainForm = class(TForm)
    ApplicationEvents1: TApplicationEvents;
    ActionList1: TActionList;
    ActionConfigurazione: TAction;
    MainPageControl: TPageControl;
    PanelTop: TPanel;
    ToolBar1: TToolBar;
    ToolButtonConfig: TToolButton;
    ToolButton1: TToolButton;
    PanelConfig: TPanel;
    ImageList1: TImageList;
    LabelDBStatus: TLabel;
    PanelMain: TPanel;
    StatusBar1: TStatusBar;

    // pannello connessione
    PanelConnection: TPanel;
    LabelConnectionStatus: TLabel;
    AnimationConnection: TActivityIndicator;
    MemoConnectionError: TMemo;
    ButtonRetryConnection: TButton;

    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure ApplicationEvents1Exception(Sender: TObject; E: Exception);
    procedure ButtonRetryConnectionClick(Sender: TObject);
    procedure ToolButtonConfigClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    { Private declarations }
    FFrameList: TObjectList<TFrameCp800>;
    FFrameConfig: TFrameConfiguration;
    FConfigManager: TConfigManager;
    FConfigVisible: Boolean;
    FDatabaseConnected: Boolean;
    FIsClosing: Boolean;

    // flag per sapere se c'erano frame attivi prima della config
    FFramesWereActive: Boolean;

    procedure ShowConnectionPanel(const AMessage: string; AShowRetry: Boolean = False);
    procedure HideConnectionPanel;
    procedure UpdateConnectionStatus(const AStatus: string; AColor: TColor);

    procedure ConnectToDatabase;
    procedure CreatePanels;

    procedure EnterConfigurationMode;    // Ferma e libera tutto
    procedure ExitConfigurationMode;     // Ricrea tutto

    procedure ToggleConfigPanel;
    procedure UpdateStatusBar;
    procedure ApplyConfigurationToApp;


    procedure StopAllMonitors;
    procedure DestroyAllFrames;
    procedure RestartAllMonitors;

  public
    { Public declarations }

  end;

var
  MainForm: TMainForm;


/// il flusso è : ConnectToDatabase -> crea i frame → ogni frame si gestisce da solo.
//  FormDestroy → libera la lista → ogni frame si distrugge → ogni monitor si ferma.

implementation

{$R *.dfm}

//uses Myfunc.Utils, Myfunc.Strings;
//uses Myfunc.Utils;

{ TForm1 }




procedure TMainForm.FormCreate(Sender: TObject);
begin
  FDatabaseConnected := False;
  FIsClosing := False;

  // Creo il ConfigManager
  FConfigManager := TConfigManager.Create;
  // Carica configurazione
  try
    FConfigManager.LoadFromFile;
  except
    on E: Exception do
      MyThreadLog.LogToFile('Errore caricamento configurazione: ' + E.Message);
  end;

  FFrameList := TObjectList<TFrameCp800>.Create(true);

  // Crea frame configurazione
  FFrameConfig := TFrameConfiguration.Create(Self);
  FFrameConfig.Parent := PanelConfig;
  FFrameConfig.Align := alClient;
  FFrameConfig.SetConfigManager(FConfigManager);

  FConfigVisible := False;

  // Setup pannello connessione (inizialmente nascosto)
  PanelConnection.Visible := False;

  // Configurazione degli ApplicationEvents
  ApplicationEvents1.OnException := ApplicationEvents1Exception;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  Caption :=  Application.title +  ' Version: ' +  VersionInformation;

  // Mostra pannello (gira nel thread principale)
  ShowConnectionPanel('Connessione al database in corso...', False);

  ConnectToDatabase;
end;

procedure TMainForm.ShowConnectionPanel(const AMessage: string; AShowRetry: Boolean);
begin
  PanelConnection.Visible := True;
  PanelConnection.BringToFront;

  LabelConnectionStatus.Caption := AMessage;
  AnimationConnection.Animate := not AShowRetry;
  ButtonRetryConnection.Visible := AShowRetry;
  MemoConnectionError.Visible := AShowRetry;

  if not AShowRetry then
    MemoConnectionError.Lines.Clear;
end;

procedure TMainForm.StopAllMonitors;
var
  frame : TFrameCp800;
  i: Integer;
  ErrorCount, StoppedCount: Integer;
  StartTime: TDateTime;
const
  MAX_WAIT_MS = 5000; // 5 secondi max per frame
begin
  if not Assigned(FFrameList) or (FFrameList.Count = 0) then
  begin
    LogToFile('StopAllMonitors: No frames to stop');
    Exit;
  end;

  StoppedCount := 0;
  ErrorCount := 0;

  Screen.Cursor := crHourGlass;
  try
    LogToFile(Format('Stopping %d monitors...', [FFrameList.Count]));

    // PASSO 1:
    // Fermo tutti i monitor in ordine inverso (ultimo creato, primo fermato)
    for i := FFrameList.Count - 1 downto 0 do
    begin
      frame := FFrameList[i];
      if Assigned(frame) then
      begin
        try
          StartTime := Now;
//          frame.StopAllMonitoring;

          // Shutdown ferma i thread e libera FMonitor/FMonitorWeight
          frame.Shutdown;

          // aspetto che il cleanup finisca
          while frame.IsRunning and
                (MilliSecondsBetween(Now, StartTime) < MAX_WAIT_MS) do
          begin
            Application.ProcessMessages;
            Sleep(50);
          end;


          if frame.IsRunning then
          begin
            LogToFile(Format('  WARNING: Frame %d still running after timeout', [i]));
            Inc(ErrorCount);
          end
          else
          begin
            Inc(StoppedCount);
            LogToFile(Format('  Frame %d stopped successfully', [i]));
          end;

        except
          on E: Exception do
          begin
            Inc(ErrorCount);
            LogToFile(Format('Errore durante stop monitor %d: %s', [i, E.Message]));
            // Log dell'errore (opzionale)
            // ShowMessage('Error stopping monitor: ' + E.Message);
          end;
        end;
      end;
    end;


    // Log finale
    LogToFile(Format('StopAllMonitors completed: %d stopped, %d error',
                     [StoppedCount, ErrorCount]));

    // mostro un messaggio se ci sono stati errori
    if ErrorCount > 0 then
      ShowMessage(Format('Attention: %d monitors generated errors during shutdown.' +
                         sLineBreak + 'See log for details.',
                         [ErrorCount]));
//    else
//      ShowMessage('Tutti i monitor sono stati fermati correttamente.');


  finally
    Screen.Cursor := crDefault;
    // Aggiorna la status bar
    UpdateStatusBar;
  end;


end;

procedure TMainForm.HideConnectionPanel;
begin
  AnimationConnection.Animate := False;
  PanelConnection.Visible := False;
end;

procedure TMainForm.UpdateConnectionStatus(const AStatus: string; AColor: TColor);
begin
  LabelDBStatus.Caption := AStatus;
  LabelDBStatus.Font.Color := AColor;

  if Assigned(StatusBar1) and (StatusBar1.Panels.Count > 0) then
    StatusBar1.Panels[0].Text := AStatus;
end;



procedure TMainForm.ButtonRetryConnectionClick(Sender: TObject);
begin
  ShowConnectionPanel('Riconnessione in corso...', False);
  Application.ProcessMessages;
  ConnectToDatabase;
end;

procedure TMainForm.CreatePanels;
var
  QAppo : TFDQuery;
  LCountCp800 : integer;
  FFrame : TFrameCp800;
//  TabSheet: TMioTabSheet;
  TabSheet: TTabSheet;
  IpForFile : String;
//  FNameFile : String;
//  FNameFileProd : String;
  ServerCfg: TServerConfig;
  FtpPath  : string;
begin
  if not FDatabaseConnected then
  begin
    ShowMessage('Database non connesso. Impossibile caricare le macchine.');
    Exit;
  end;

  ServerCfg.Inizializza;

  // --- 1) Crea la mappa codici (condivisa tra i due monitor)
  FFrameList.Clear;

  // Rimuovo tutte le tab esistenti
  while MainPageControl.PageCount > 0 do
    MainPageControl.Pages[0].Free;

  qappo := TFDQuery.Create(nil);
  try
    qappo.Connection := DMIConsole.FDConnection;
    qappo.SQL.Add('select * from cp800_setup where cp800_enabled = 1');
    qappo.SQL.Add(' order by cast(CP800_ID as unsigned) ');
    QAppo.Open ;

    LCountCp800 := qappo.RecordCount;

    if not (LCountCp800 > 0)  then
    begin
      ShowMessage('Attenzione! Non risulta attiva nessuna macchina');
      exit;
    end;

    while not QAppo.EOF do
    begin
//      TabSheet := TMioTabSheet.Create(MainPageControl);
      TabSheet := TTabSheet.Create(MainPageControl);
      TabSheet.Caption := Qappo.FieldByName('cp800_Name').AsString;
//      TabSheet.idCp800 := QAppo.FieldByName('cp800_id').asstring;
      TabSheet.PageControl := MainPageControl;
//      TabSheet.Color:= $00FCE7BE;

//      FFrame := TFrameCp800.Create(TabSheet,  QAppo.FieldByName('cp800_id').asstring);
//      FFrame := TFrameCp800.Create( TabSheet );




      FFrame := TFrameCp800.Create( nil );
      FFrame.Align := alClient;
      FFrame.Parent := TabSheet;
      fframe.Name := Format('ServerFrame_%d', [FFrameList.Count + 1]);
      //     FFrame.Cp800id :=  QAppo.FieldByName('cp800_id').asstring ;



      try

        IpForFile := QAppo.FieldByName('cp800_ip').asstring;
        while  Pos('.',IpForFile) > 0 do
          IpForFile := copy ( IpForFile, Pos('.',IpForFile) +1 , length(IpForFile ));
        if length(IpForFile ) < 3 then
          IpForFile:= concat( StringOfChar('0', 3 - length(IpForFile )) , IpForFile )  ;

//        FNameFile:= concat ( StartFileName, IpForFile, '.txt');
//        FNameFileProd:=  concat ( StartFileProdName, IpForFile, '.txt');

        FtpPath := QAppo.FieldByName('FtpPath').AsString;
        if not FtpPath.EndsWith('/') then
          FtpPath := FtpPath + '/';


        var Lhost := QAppo.FieldByName('cp800_ip').asstring;

        ServerCfg.Host := lhost;
//        ServerCfg.Host := QAppo.FieldByName('cp800_ip').asstring;
        ServerCfg.Port := QAppo.FieldByName('FtpPort').AsInteger;
        ServerCfg.Username := QAppo.FieldByName('FtpUser').AsString;
        ServerCfg.Password := QAppo.FieldByName('FtpPassword').AsString;
        ServerCfg.RemotePath :=  QAppo.FieldByName('FtpPath').AsString;
        ServerCfg.FileName  := FtpPath + concat ( StartFileName, IpForFile, '.txt');
        ServerCfg.FileNameProd := FtpPath + concat ( StartFileProdName, IpForFile, '.txt');
        ServerCfg.id := QAppo.FieldByName('cp800_id').asstring;
        ServerCfg.NameMachine :=QAppo.FieldByName('cp800_name').asstring;
        ServerCfg.Intervall := QAppo.FieldByName('FtpIdle').AsInteger;
        ServerCfg.PassiveMode := QAppo.FieldByName('FtpPassiveMode').AsBoolean;

        Fframe.Configure( ServerCfg);
  //      Fframe.ConfigureWeightMonitor(  ServerCfg.FileNameData,  'out_server21.csv', 500);
  //      Fframe.ConfigureWeightMonitor( ServerCfg.FileNameData,  QAppo.FieldByName('FtpIdle').AsInteger);


          // ═══════════════════════════════════════════════════════════════════
          // AVVIA IL FRAME - tutto parte da qui!
          // ═══════════════════════════════════════════════════════════════════
          // Start() fa:
          //   1. Crea FMonitor (dati generali) e lo avvia
          //   2. Chiama InitWeightMonitor → crea FMonitorWeight (dati pesi) ma NON lo avvia
          //   3. FMonitorWeight parte automaticamente quando le label vengono populate
          // ═══════════════════════════════════════════════════════════════════
         Fframe.Start;
          //  InitWeightMonitor viene chiamato dentro Start() e il monitor dei pesi
          // parte automaticamente quando serve.
          FFrameList.Add(FFrame);

      except
        on E: Exception do
        begin
          LogToFile(Format('Errore configurazione frame CP800 %s: %s',
                          [QAppo.FieldByName('cp800_id').asstring, E.Message]));
          // Il frame non viene aggiunto alla lista e verrà distrutto con TabSheet
          FFrame.Free;
        end;
      end;

      qappo.next;
    end;

     LogToFile(Format('Caricate %d macchine CP800', [LCountCp800]));

  finally
    if assigned(qappo) then
    begin
      qappo.close;
      qappo.free;
    end;
  end;

  UpdateStatusBar;

  // Seleziona la prima tab
  if MainPageControl.PageCount > 0 then
    MainPageControl.ActivePageIndex := 0;
end;

procedure TMainForm.DestroyAllFrames;
begin

end;

procedure TMainForm.EnterConfigurationMode;
// Ferma e libera TUTTO quando entro in config
var
  i: Integer;
  Frame: TFrameCp800;
begin
  LogToFile('═══ Entering Configuration Mode ═══');

  // Salvo lo stato: i frame erano attivi?
  FFramesWereActive := Assigned(FFrameList) and (FFrameList.Count > 0);

  if not FFramesWereActive then
  begin
    LogToFile('No active frames to stop');
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    // ────────────────────────────────────────────────────────────
    // PASSO 1: FERMO TUTTI I MONITOR (chiamando Shutdown su ogni frame)
    // ────────────────────────────────────────────────────────────
    LogToFile(Format('Stopping %d frames...', [FFrameList.Count]));

    for i := FFrameList.Count - 1 downto 0 do
    begin
      Frame := FFrameList[i];
      if Assigned(Frame) then
      begin
        try
          Frame.Shutdown;  // Ferma FMonitor e FMonitorWeight, libera tutto
          LogToFile(Format('  Frame %d shutdown completed', [i]));
        except
          on E: Exception do
            LogToFile(Format('  ERROR stopping frame %d: %s', [i, E.Message]));
        end;
      end;
    end;

    // Pausa per assicurarsi che i thread siano terminati
    Sleep(200);
    Application.ProcessMessages;

    // ────────────────────────────────────────────────────────────
    // PASSO 2: LIBERO TUTTI I FRAME
    // ────────────────────────────────────────────────────────────
    LogToFile('Destroying all frames...');

    try
      FFrameList.Clear;  // Libero tutti i frame (OwnsObjects=True)
      LogToFile('  Frame list cleared');
    except
      on E: Exception do
      begin
        LogToFile('  ERROR clearing frame list: ' + E.Message);
        // Forzo svuotamento
        try
          while FFrameList.Count > 0 do
            FFrameList.Delete(0);
        except
        end;
      end;
    end;

    // ────────────────────────────────────────────────────────────
    // PASSO 3: LIBERO TUTTE LE TAB
    // ────────────────────────────────────────────────────────────
    LogToFile('Destroying all tabs...');

    try
      while MainPageControl.PageCount > 0 do
      begin
        MainPageControl.Pages[0].Free;
      end;
      LogToFile('  All tabs destroyed');
    except
      on E: Exception do
        LogToFile('  ERROR destroying tabs: ' + E.Message);
    end;

    LogToFile('═══ Configuration Mode Active - All frames stopped ═══');
    UpdateStatusBar;

  finally
    Screen.Cursor := crDefault;
  end;

end;

procedure TMainForm.ExitConfigurationMode;
// Ricrea tutto quando esco dalla config
begin
  LogToFile('═══ Exiting Configuration Mode ═══');

  // Ricrea i frame solo se erano attivi prima
  if FFramesWereActive then
  begin
    LogToFile('Recreating frames...');

    try
      CreatePanels;  // Ricrea tutto come in FormShow
      LogToFile('═══ Frames recreated successfully ═══');
    except
      on E: Exception do
      begin
        LogToFile('ERROR recreating frames: ' + E.Message);
        ShowMessage('Errore nel ricreare le macchine: ' + E.Message + sLineBreak +
                    'Verificare i log per dettagli.');
      end;
    end;
  end
  else
  begin
    LogToFile('No frames to recreate (were not active)');
  end;

  UpdateStatusBar;
end;



procedure TMainForm.RestartAllMonitors;
// (magari per un bottone "Restart" futuro)
var
  Frame: TFrameCp800;
  i: Integer;
begin
  for i := 0 to FFrameList.Count - 1 do
  begin
    Frame := FFrameList[i];
    if Assigned(Frame) then
    begin
      try
        // Se non è in esecuzione, lo avvio
        if not Frame.IsRunning then
          Frame.Start;
      except
        on E: Exception do
          LogToFile(Format('Errore riavviando frame %d: %s', [i, E.Message]));
      end;
    end;
  end;

  UpdateStatusBar;
  LogToFile('Restart all monitors completed');
end;

procedure TMainForm.UpdateStatusBar;
begin
  if not Assigned(StatusBar1) then
    Exit;

  if StatusBar1.Panels.Count < 4 then
    Exit;

  // Pannello 0: Stato connessione
  if FDatabaseConnected then
    StatusBar1.Panels[0].Text := 'Database: Connesso'
  else
    StatusBar1.Panels[0].Text := 'Database: Non connesso';

  // Pannello 1: Numero macchine
  StatusBar1.Panels[1].Text := Format('CP800 Attivi: %d', [FFrameList.Count]);

  // Pannello 2: Ultimo aggiornamento
  StatusBar1.Panels[2].Text := 'Ultimo aggiornamento: ' + FormatDateTime('hh:nn:ss', Now);

  // Pannello 3: Vuoto (per eventuali usi futuri)
  StatusBar1.Panels[3].Text := '';
end;

procedure TMainForm.ApplyConfigurationToApp;
begin
  // Chiudi connessione esistente
  if DMIConsole.FDConnection.Connected then
  begin
    try
      DMIConsole.FDConnection.Connected := False;
      FDatabaseConnected := False;
    except
      on E: Exception do
        LogToFile('Errore chiusura connessione: ' + E.Message);
    end;
  end;

  // Tenta nuova connessione con i parametri aggiornati
  ConnectToDatabase ;
end;

procedure TMainForm.ConnectToDatabase ;
begin

  // Verifica se già connesso
  if Assigned(DMIConsole) and DMIConsole.FDConnection.Connected then
  begin
    FDatabaseConnected := True;
    Exit;
  end;

  if not Assigned(DMIConsole) then
  begin
    LogToFile('ERRORE: DMIConsole non inizializzato');
    ShowConnectionPanel('Errore: DataModule non disponibile', True);
    Exit;
  end;


  LogToFile('Connessione al database riuscita: ' +
                FConfigManager.Config.DBHost + ':' +
                FConfigManager.Config.DBPort.ToString);

  // Lancia un thread separato
  TTask.Run(
    procedure
    var
//      ErrorMsg: string;
      ConnResult: TConnectionResult;
    begin
      try
        //  QUESTO CODICE GIRA IN UN THREAD SEPARATO
        //  NON nel thread principale!
        // per cui NON blocca la UI
        ConnResult := DMIConsole.Connect(
          FConfigManager.Config.DBHost,
          FConfigManager.Config.DBPort,
          FConfigManager.Config.DBName,
          FConfigManager.Config.DBUser,
          FConfigManager.Config.DBPassword
        );

        { // OPZIONE 2: Connessione con retry automatico
        ConnResult := DMIConsole.ConnectWithRetry(
          FConfigManager.Config.DBHost,
          FConfigManager.Config.DBPort,
          FConfigManager.Config.DBName,
          FConfigManager.Config.DBUser,
          FConfigManager.Config.DBPassword,
          3,     // Max 3 tentativi
          2000   // Attesa 2 secondi tra un tentativo e l'altro
        );
        }
        // Torna al thread principale per aggiornare la UI
        TThread.Synchronize(nil,
          procedure
          begin
            //  QUESTO CODICE GIRA NEL THREAD PRINCIPALE
            //  Qui modifico la UI           │
            FDatabaseConnected := ConnResult.Success;
            if ConnResult.Success then
            begin
              HideConnectionPanel;
              UpdateConnectionStatus('Database: Connesso', clGreen);
              // Carico le macchine
              try
                CreatePanels;
                UpdateStatusBar;
              except
                on E: Exception do
                begin
                  ShowConnectionPanel('Errore: ' + E.Message, True);
                  LogToFile('Errore CreatePanels: ' + E.Message);
                end;
              end;
            end
            else
            begin
              // Connessione fallita
              UpdateConnectionStatus('Database: Non connesso', clRed);
              UpdateStatusBar;

              MemoConnectionError.Lines.Clear;
              MemoConnectionError.Lines.Add('Impossibile connettersi al database');
              MemoConnectionError.Lines.Add('');
              MemoConnectionError.Lines.Add('Dettagli errore:');
              MemoConnectionError.Lines.Add(Format('[%s] %s',
                                                  [ConnResult.ErrorClass,
                                                   ConnResult.ErrorMessage]));
              MemoConnectionError.Lines.Add('');
              MemoConnectionError.Lines.Add('Parametri di connessione:');
              MemoConnectionError.Lines.Add('Host: ' + FConfigManager.Config.DBHost);
              MemoConnectionError.Lines.Add('Porta: ' + FConfigManager.Config.DBPort.ToString);
              MemoConnectionError.Lines.Add('Database: ' + FConfigManager.Config.DBName);
              MemoConnectionError.Lines.Add('Utente: ' + FConfigManager.Config.DBUser);
              MemoConnectionError.Lines.Add('');
              MemoConnectionError.Lines.Add(Format('Tentativi effettuati: %d',
                                                  [DMIConsole.ConnectionAttempts]));

              ShowConnectionPanel('', True);  // Mostra pannello con bottone Retry
              ButtonRetryConnection.Visible := True;
            end;
          end
        );
        except
        on E: Exception do
        begin
          LogToFile('ERRORE in task connessione: ' + E.Message);
          TThread.Synchronize(nil,
            procedure
            begin
              ShowConnectionPanel('Errore di connessione: ' + E.Message, True);
              UpdateConnectionStatus('Database: Errore', clRed);
            end
          );
        end;
      end;
    end
  );
end;

procedure TMainForm.ToggleConfigPanel;
begin
  FConfigVisible := not FConfigVisible;
   if FConfigVisible then
  begin
    // ─────────────────────────────────────────────────────────
    // ENTRO IN MODALITÀ CONFIGURAZIONE
    // ─────────────────────────────────────────────────────────

    // Chiedo conferma se ci sono frame attivi
    if Assigned(FFrameList) and (FFrameList.Count > 0) then
    begin
      if MessageDlg(
        Format('There are %d monitor active FTP.' + sLineBreak +
               'To access the configuration they will be stopped.' + sLineBreak + sLineBreak +
               'when exiting the configuration they will be automatically recreated.' + sLineBreak + sLineBreak +
               'Continue?', [FFrameList.Count]),
        mtConfirmation,
        [mbYes, mbNo],
        0
      ) <> mrYes then
      begin
        // Annulla
        FConfigVisible := False;
        Exit;
      end;
    end;

    // FERMO E LIBERA TUTTO
    EnterConfigurationMode;

    // Mostro pannello configurazione
    PanelConfig.Visible := True;
    PanelConfig.Align := alClient;
    PanelConfig.BringToFront;
    PanelMain.Visible := False;

    FFrameConfig.LoadConfiguration;
    ToolButtonConfig.Down := True;

    LogToFile('Configuration panel opened');
  end
  else
  begin
    // ─────────────────────────────────────────────────────────
    // ESCO DALLA MODALITÀ CONFIGURAZIONE
    // ─────────────────────────────────────────────────────────

    // Gestisco modifiche non salvate
    if FFrameConfig.Modified then
    begin
      case MessageDlg(
        'There are unsaved changes. What do you want to do??' + sLineBreak + sLineBreak +
        'Yes = Save and apply' + sLineBreak +
        'No = Discard changes' + sLineBreak +
        'Cancel = Go back to setup',
        mtConfirmation,
        [mbYes, mbNo, mbCancel],
        0
      ) of
        mrYes:
        begin
          // Salvo configurazione
          FFrameConfig.SaveConfiguration;
          ApplyConfigurationToApp;

          // Riconnetto al database se necessario
          if not FDatabaseConnected then
          begin
            ShowMessage('Connecting to the database in progress...');
            ConnectToDatabase;
          end;
        end;

        mrNo:
        begin
          // Ricarico configurazione originale (scarto modifiche)
          FFrameConfig.LoadConfiguration;
        end;

        mrCancel:
        begin
          // Rimango in configurazione
          FConfigVisible := True;
          PanelConfig.Visible := True;
          ToolButtonConfig.Down := True;
          Exit;
        end;
      end;
    end;

    // Nascondo pannello configurazione
    PanelConfig.Visible := False;
    PanelMain.Visible := True;
    PanelMain.BringToFront;
    ToolButtonConfig.Down := False;

    // RICREO TUTTO
    ExitConfigurationMode;

    LogToFile('Configuration panel closed');
  end;
end;

procedure TMainForm.ToolButtonConfigClick(Sender: TObject);
begin
  ToggleConfigPanel;
end;

procedure TMainForm.ApplicationEvents1Exception(Sender: TObject; E: Exception);
var
  ErrorMsg: string;
  IsShutdownException: Boolean;
//  IsCritical: Boolean;
begin
  // ═══════════════════════════════════════════════════════════
  // 1. LOGGO SEMPRE L'ERRORE
  // ═══════════════════════════════════════════════════════════
  try
    ErrorMsg := Format('ERRORE [%s] %s', [E.ClassName, E.Message]);
    LogToFile( 'Eccezione non gestita -> ' +  ErrorMsg);
  except
    // Se anche il log fallisce, ignoro
  end;

  // Durante la chiusura dell'app, evita popup/gestioni rumorose su eccezioni note.
  IsShutdownException :=
    Application.Terminated or
    FIsClosing or
    (csDestroying in ComponentState);

  if IsShutdownException and
     ((E is EAccessViolation) or
      (E is EInvalidPointer) or
      (E.Message.Contains('canvas')) or
      (E.Message.Contains('destroyed')) or
      (E.Message.Contains('cannot focus')))  then
  begin
    try
      LogToFile('Eccezione ignorata durante chiusura applicazione: ' + ErrorMsg);
    except
    end;
    Exit;
  end;



    // Mostra un messaggio di errore all'utente
 { try
    MessageBox(Application.Handle,
               PChar('Si è verificato un errore critico nell''applicazione.' + sLineBreak +
                     'L''applicazione verrà chiusa.' + sLineBreak + sLineBreak +
                     'Dettagli: ' + E.Message),
               'Errore Critico',
               MB_OK or MB_ICONERROR);
  except
    // Ignora errori durante la visualizzazione del messaggio
  end;
  }
  {
  // Durante la chiusura, ignoro alcuni errori comuni
  if Application.Terminated then
  begin
    // Ignoro errori di accesso a componenti durante shutdown
    if (E is EAccessViolation) or
       (E is EInvalidPointer) or
       (E.Message.Contains('canvas')) or
       (E.Message.Contains('destroyed')) then
    begin
      LogToFile('Eccezione ignorata durante chiusura applicazione');
      Exit;
    end;
  end;

  }


  try
    ShowMessage('Errore: ' + E.Message + sLineBreak + sLineBreak +
                'L''errore è stato registrato. L''applicazione continuerà.');
  except
  end;
  // non chiudo mai applicazione ma loggo errore eventualemnte l'operatore può decidere se chiudere


  (*
  // ═══════════════════════════════════════════════════════════
  // 2. DETERMINO SE L'ERRORE È CRITICO
  // ═══════════════════════════════════════════════════════════
  IsCritical := False;

  // Errori critici che richiedono chiusura dell'applicazione
  if (E is EOutOfMemory) or           // Memoria esaurita
     (E is EStackOverflow) or         // Stack overflow
     (E is EAccessViolation) or       // Access violation (puntatori invalidi)
     (E is EInvalidPointer) or        // Puntatore invalido
     (E is EExternalException) then   // Eccezione esterna (es. SO)
  begin
    IsCritical := True;
    LogToFile('ERRORE CRITICO RILEVATO - Chiusura applicazione necessaria - ' + E.Message);
  end;

 // ═══════════════════════════════════════════════════════════
  // 3. GESTIONE IN BASE ALLA GRAVITÀ
  // ═══════════════════════════════════════════════════════════
  if IsCritical then
  begin
    // ───────────────────────────────────────────────────────
    // ERRORE CRITICO - Chiudi l'applicazione
    // ───────────────────────────────────────────────────────
    try
      // Mostra messaggio all'utente
      MessageBox(
        Application.Handle,
        PChar('Si è verificato un errore critico.' + sLineBreak +
              'L''applicazione verrà chiusa.' + sLineBreak + sLineBreak +
              'Dettagli: ' + E.Message + sLineBreak + sLineBreak +
              'Consultare il file di log per maggiori informazioni.'),
        'Errore Critico',
        MB_OK or MB_ICONERROR or MB_SYSTEMMODAL
      );
    except
      // Ignora errori nel mostrare il messaggio
    end;

    // Esegui pulizia controllata
    try
      PerformEmergencyCleanup;
    except
      // Ignora errori durante la pulizia
    end;

    // Termina SUBITO l'applicazione
    Halt(1);
  end
  else
  begin
    // ───────────────────────────────────────────────────────
    // ERRORE NON CRITICO - Mostra messaggio e continua
    // ───────────────────────────────────────────────────────
    try
      MessageBox(
        Application.Handle,
        PChar('Si è verificato un errore:' + sLineBreak + sLineBreak +
              E.Message + sLineBreak + sLineBreak +
              'L''errore è stato registrato nel log.' + sLineBreak +
              'L''applicazione continuerà a funzionare.'),
        'Errore',
        MB_OK or MB_ICONWARNING
      );
    except
      // Ignora errori nel mostrare il messaggio
    end;

    // L'applicazione CONTINUA a funzionare
    // L'eccezione viene considerata "gestita"
  end;
  *)
end;


// =================================================================
// CHIUSURA - ordine corretto:
//   1) FormCloseQuery  → chiedi conferma
//   2) FormClose       → fermoa i monitor (Clear), poi il database
//   3) FormDestroy     → libero le liste (già vuote)
// =================================================================
procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
//var
//  i : integer;
begin
  FIsClosing := True;

  LogToFile('═══ Application closing ═══');

  // PASSO 1: Fermo tutti i monitor
  try
    StopAllMonitors;



  except
    on E: Exception do
      LogToFile('FormClose - Errore durante StopAllMonitors: ' + E.Message);
  end;


  // Piccola pausa per assicurarsi che tutti i thread siano terminati
  Sleep(500);
  Application.ProcessMessages;

  // PASSO 2: Ora posso liberare i frame (i monitor sono fermati)
  if Assigned(FFrameList) then
  begin
    try
      FFrameList.Clear;
      LogToFile('Frame list cleared successfully');
    except
      on E: Exception do
      begin
        LogToFile('FormClose - Errore durante FormClose: ' + E.Message);
        // Forzo svuotamento
        try
          while FFrameList.Count > 0 do
          begin
            FFrameList.Delete(0);
            LogToFile('FormClose - Errore durante FormClose svuotamento forzato: ' + E.Message);
          end;
        except
        end;
      end;
    end;
  end;

  // PASSO 3: ora libero le tab (a questo punto i frame non ci sono più).
  try
    while MainPageControl.PageCount > 0 do
      MainPageControl.Pages[0].Free;
    LogToFile(' FormClose - All tabs destroyed');
  except
    on E: Exception do
      LogToFile('FormClose - Errore durante clear tab pages: ' + E.Message);
  end;





  // Chiudi connessione database
  // PASSO 4: Solo ora chiudo il database.
  // I monitor sono già fermati, nessun thread cercherà di usare la connessione.
  if DMIConsole.FDConnection.Connected then
  begin
    try
      DMIConsole.FDConnection.Connected := False;
      LogToFile('Database disconnected successfully');
    except
      on E: Exception do
        LogToFile('FormClose - Errore chiusura database: ' + E.Message);
    end;
  end;

  LogToFile('═══ FormClose completed ═══');

//  action := TCloseAction.caFree;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  response: Integer;
begin
  // Chiedi conferma prima di chiudere se ci sono monitor attivi
   if Assigned(FFrameList) and ( FFrameList.Count > 0 ) then
  begin
    response := MessageDlg(
      'I monitor FTP sono ancora attivi. Vuoi fermarli e chiudere l''applicazione?',
      mtConfirmation,
      [mbYes, mbNo],
      0
    );

    if response = mrYes then
    begin
      // Ferma tutti i monitor prima di chiudere
   ///////// 03/02   StopAllMonitors;
      CanClose := True;
      FIsClosing := True;
    end
    else
    begin
      CanClose := False;
     FIsClosing := False;
    end;
  end
  else
  begin
    CanClose := True;
    FIsClosing := True;
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  // FFrameList è già stato svuotato in FormClose.
  // Qui libero solo la lista stessa e gli altri oggetti.
{  try
    if DMIConsole.FDConnection.Connected then
      DMIConsole.FDConnection.Connected := False;
  except
  end;
 }
  // A questo punto FFrameList dovrebbe già essere vuota
  try
    if assigned(FFrameList) then
      FreeAndNil(FFrameList);
  except
    on E: Exception do
      LogToFile('FormDestroy - Errore free frame list: ' + E.Message);
  end;

  try
    if Assigned(FConfigManager) then
      FreeAndNil(FConfigManager);
  except
    on E: Exception do
      LogToFile('FormDestroy - Errore free config manager: ' + E.Message);
  end;

  LogToFile('Applicazione chiusa normalmente');
end;

end.
