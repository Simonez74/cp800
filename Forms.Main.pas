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
  , system.DateUtils, Frame.Service, Forms.Licenza;

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
    ToolButtonDeleteHistorical: TToolButton;
    ToolButtonLicenza: TToolButton;
    PanelTopLine: TPanel;
    PanelDBStatus: TPanel;
    ShapeDBStatus: TShape;

    // contenitori interni del pannello connessione
    PanelConnectionCard: TPanel;
    PanelConnectionIndicator: TPanel;
    PanelConnectionButtons: TPanel;

    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure ApplicationEvents1Exception(Sender: TObject; E: Exception);
    procedure ButtonRetryConnectionClick(Sender: TObject);
    procedure ToolButtonConfigClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure ToolButtonDeleteHistoricalClick(Sender: TObject);
    procedure ToolButtonLicenzaClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormAfterMonitorDpiChanged(Sender: TObject; OldDPI, NewDPI: Integer);
    procedure PanelCenterResize(Sender: TObject);
  private
    { Private declarations }
    FLicenzaTesto: string;
    FFrameList: TObjectList<TFrameCp800>;
    FFrameConfig: TFrameConfiguration;
    FFrameService: TFrameService;
    FConfigManager: TConfigManager;
    FConfigVisible: Boolean;
    FDatabaseConnected: Boolean;
    FIsClosing: Boolean;

    procedure ShowConnectionPanel(const AMessage: string; AShowRetry: Boolean = False);
    procedure HideConnectionPanel;
    procedure UpdateConnectionStatus(const AStatus: string; AColor: TColor);
    procedure CenterConnectionPanel;
    procedure AggiornaInfoLicenza;

    procedure ConnectToDatabase;
    procedure CreatePanels;

    procedure ToggleConfigPanel;
    procedure UpdateStatusBar;
    procedure StopAllMonitors;

    // callback per liberare FramService
    procedure FrameServiceClose(Sender : TObject);
    // callback pulsante Chiudi del frame configurazione
    procedure FrameConfigClose(Sender : TObject);
    procedure MostraVistaPrincipale;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;


/// il flusso è : ConnectToDatabase -> crea i frame → ogni frame si gestisce da solo.
//  FormDestroy → libera la lista → ogni frame si distrugge → ogni monitor si ferma.

implementation

{$R *.dfm}

uses
  System.Math, LicenseCore;

//uses Myfunc.Utils, Myfunc.Strings;
//uses Myfunc.Utils;

const
  // palette interfaccia (BGR)
  CLR_OK       = $004A9E2E; // verde
  CLR_ERR      = $003834D1; // rosso
  CLR_WAIT     = $0000A1E0; // ambra
  CLR_ACCENT   = $00C06700; // blu icone
  CLR_DISABLED = $00A0A0A0;





{ TMainForm }

procedure TMainForm.AggiornaInfoLicenza;
var
  Info: TLicenseInfo;
  Stato: TLicenseState;
begin
  try
    Stato := StatoLicenza(Info);
    if Stato = lsValid then
      FLicenzaTesto := 'Licenza: ' + Info.Cliente
    else
      FLicenzaTesto := 'Licenza: ' + LicenseStateText(Stato);
  except
    on E: Exception do
    begin
      FLicenzaTesto := 'Licenza: n/d';
      LogToFile('Errore lettura stato licenza: ' + E.Message);
    end;
  end;
end;

procedure TMainForm.CenterConnectionPanel;
var
  W, H, AreaTop, AreaH: Integer;
begin
  if not PanelConnection.Visible then
    Exit;

  // card piu' alta solo quando mostra il dettaglio errore
  W := Min(ScaleValue(480), ClientWidth - ScaleValue(32));
  if MemoConnectionError.Visible then
    H := ScaleValue(380)
  else
    H := ScaleValue(170);

  AreaTop := PanelTopLine.Top + PanelTopLine.Height;
  AreaH := ClientHeight - AreaTop - StatusBar1.Height;
  H := Min(H, AreaH - ScaleValue(16));

  PanelConnection.SetBounds((ClientWidth - W) div 2, AreaTop + (AreaH - H) div 2, W, H);
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  CenterConnectionPanel;
end;

procedure TMainForm.FormAfterMonitorDpiChanged(Sender: TObject; OldDPI, NewDPI: Integer);
begin
  CenterConnectionPanel;
end;

procedure TMainForm.PanelCenterResize(Sender: TObject);
var
  Panel: TWinControl;
  C: TControl;
  I: Integer;
begin
  // centra i controlli figli (indicatore di attivita' / pulsante Riprova)
  Panel := Sender as TWinControl;
  for I := 0 to Panel.ControlCount - 1 do
  begin
    C := Panel.Controls[I];
    C.SetBounds((Panel.ClientWidth - C.Width) div 2, (Panel.ClientHeight - C.Height) div 2,
      C.Width, C.Height);
  end;
end;


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
  FFrameConfig.OnCloseRequest := FrameConfigClose;

  FConfigVisible := False;

  // Setup pannello connessione (inizialmente nascosto)
  PanelConnection.Visible := False;

  // Configurazione degli ApplicationEvents
  ApplicationEvents1.OnException := ApplicationEvents1Exception;

  UpdateConnectionStatus('Database: Non connesso', CLR_ERR);
  AggiornaInfoLicenza;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  Caption :=  Application.title +  ' Version: ' +  VersionInformation;

  // Mostra pannello (gira nel thread principale)
  ShowConnectionPanel('Connessione al database in corso...', False);

  ConnectToDatabase;
end;

procedure TMainForm.FrameConfigClose(Sender: TObject);
begin
  // stesso percorso del pulsante Config della toolbar (modifiche non salvate, ricreazione frame)
  if FConfigVisible then
    ToggleConfigPanel;
end;

procedure TMainForm.MostraVistaPrincipale;
begin
  PanelConfig.Visible := False;
  PanelMain.Visible := True;
  PanelMain.BringToFront;
  // il pannello connessione (se visibile) deve restare sopra le tab
  if PanelConnection.Visible then
    PanelConnection.BringToFront;
end;

procedure TMainForm.FrameServiceClose(Sender: TObject);
begin
  // nascondo il frame
  if Assigned(FFrameService) then
    FFrameService.Visible := False;
  FFrameConfig.Visible := True;

  // Nascondo pannello configurazione
  MostraVistaPrincipale;

  ToolButtonConfig.Enabled := true;
  ToolButtonDeleteHistorical.Enabled := true;


  //   if assigned (FFrameService ) then
//    FreeAndNil(FFrameService );

  // Libero il frame dopo che tutti i messaggi sono stati processati
{  TThread.ForceQueue(nil,
    procedure
    begin
      if Assigned(FFrameService) then
      begin
        try
          FFrameService.Parent := nil;  // Importante: rimuovi il parent prima
          FreeAndNil(FFrameService);
          LogToFile('FrameService freed successfully');
        except
          on E: Exception do
            LogToFile('Errore durante free FrameService: ' + E.Message);
        end;
      end;
    end);
 }



end;

procedure TMainForm.ShowConnectionPanel(const AMessage: string; AShowRetry: Boolean);
begin
  LabelConnectionStatus.Caption := AMessage;

  // in attesa: solo indicatore; in errore: dettaglio + pulsante Riprova
  AnimationConnection.Animate := not AShowRetry;
  PanelConnectionIndicator.Visible := not AShowRetry;
  PanelConnectionButtons.Visible := AShowRetry;
  ButtonRetryConnection.Visible := AShowRetry;
  MemoConnectionError.Visible := AShowRetry;

  if not AShowRetry then
  begin
    MemoConnectionError.Lines.Clear;
    UpdateConnectionStatus('Database: connessione in corso...', CLR_WAIT);
  end;

  PanelConnection.Visible := True;
  CenterConnectionPanel;
  PanelConnection.BringToFront;
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
  // testo sempre leggibile, lo stato e' dato dal colore del pallino
  LabelDBStatus.Caption := AStatus;
  LabelDBStatus.Hint := AStatus;
  ShapeDBStatus.Brush.Color := AColor;

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
    ShowMessage('Database not connected. Unable to load machines.');
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
      ShowMessage('Attention. No machines are active.');
      exit;
    end;

    while not QAppo.EOF do
    begin
      TabSheet := nil;
      FFrame := nil;

      try
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

        IpForFile := QAppo.FieldByName('cp800_ip').asstring;
        while  Pos('.',IpForFile) > 0 do
          IpForFile := copy ( IpForFile, Pos('.',IpForFile) +1 , length(IpForFile ));
        if length(IpForFile ) < 3 then
          IpForFile:= concat( StringOfChar('0', 3 - length(IpForFile )) , IpForFile )  ;

        FtpPath := QAppo.FieldByName('FtpPath').AsString;
        if not FtpPath.EndsWith('/') then
          FtpPath := FtpPath + '/';

        ServerCfg.Host := QAppo.FieldByName('cp800_ip').asstring;
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
        ServerCfg.ManagementBeltB := QAppo.FieldByName('BeltB').AsBoolean;
        ServerCfg.ManagementBeltC := QAppo.FieldByName('BeltC').AsBoolean;
        ServerCfg.ManagementBeltD := QAppo.FieldByName('BeltD').AsBoolean;
        ServerCfg.ConnectTimeout := FConfigManager.Config.FtpConnectTimeout;
        ServerCfg.ReadTimeout := FConfigManager.Config.FtpReadTimeout;

        Fframe.Configure( ServerCfg);

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
          // Libero ENTRAMBI in caso di errore
          if Assigned(FFrame) then
            FFrame.Free;

          if Assigned(TabSheet) then
            TabSheet.Free;
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

  // Pannello 3: cliente della licenza
  StatusBar1.Panels[3].Text := FLicenzaTesto;
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


  LogToFile('Connessione al database in corso: ' +
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
              UpdateConnectionStatus('Database: Connesso', CLR_OK);
              // se nel frattempo l'utente e' entrato in configurazione i frame
              // verranno creati all'uscita (ToggleConfigPanel)
              if FConfigVisible then
                Exit;
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
              UpdateConnectionStatus('Database: Non connesso', CLR_ERR);
              UpdateStatusBar;

              MemoConnectionError.Lines.Clear;
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

              ShowConnectionPanel('Impossibile connettersi al database', True);
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
              UpdateConnectionStatus('Database: Errore', CLR_ERR);
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
      if AskConfirmation( Format('There are %d monitor active FTP.' + sLineBreak +
               'To access the configuration they will be stopped.' + sLineBreak + sLineBreak +
               'when exiting the configuration they will be automatically recreated.' + sLineBreak + sLineBreak +
               'Continue?', [FFrameList.Count]),
               [],
                   5000) <> mrYes then
      begin
        // Annulla: il click su un tbsCheck ha gia' abbassato il pulsante
        FConfigVisible := False;
        ToolButtonConfig.Down := False;
        Exit;
      end;
    end;
    try
      StopAllMonitors;
      if Assigned(FFrameList) then
      begin
        try
          FFrameList.Clear;
        except
          on E: Exception do
          begin
            LogToFile('FormClose - Error during FormClose: ' + E.Message);
            // Forzo svuotamento
            try
              while FFrameList.Count > 0 do
              begin
                FFrameList.Delete(0);
                LogToFile('FormClose - Error during FormClose forced emptying: ' + E.Message);
              end;
            except
            end;
          end;
        end;
      end;
      while MainPageControl.PageCount > 0 do
        MainPageControl.Pages[0].Free;

      // l'eventuale pannello connessione/errore DB non deve restare sotto la configurazione
      HideConnectionPanel;

      // Mostro pannello configurazione (solo il frame configurazione, non il Service)
      if Assigned(FFrameService) then
        FFrameService.Visible := False;
      FFrameConfig.Visible := True;
      PanelConfig.Visible := True;
      PanelConfig.Align := alClient;
      PanelConfig.BringToFront;
      PanelMain.Visible := False;

      // durante la configurazione il servizio storico non e' disponibile
      ToolButtonDeleteHistorical.Enabled := False;
      ToolButtonConfig.Down := True;
      ToolButtonConfig.Caption := 'Chiudi config';

      FFrameConfig.LoadConfiguration;

      LogToFile('Configuration panel opened');
    except
      on E: Exception do
      LogToFile('ToggleConfigPanel - Error opening configuration: ' + E.Message);
    end;
  end
  else
  begin
    // ─────────────────────────────────────────────────────────
    // ESCO DALLA MODALITÀ CONFIGURAZIONE
    // ─────────────────────────────────────────────────────────

    // Gestisco modifiche non salvate
    if FFrameConfig.Modified then
    begin
      case AskConfirmation( 'There are unsaved changes. What do you want to do??' + sLineBreak + sLineBreak +
        'Yes = Save and apply' + sLineBreak +
        'No = Discard changes' + sLineBreak ,
        [ tcbYes, tcbNo, tcbCancel ],
                   5000)
      of
        mrYes:
          // Salvo configurazione
          FFrameConfig.SaveConfiguration;
        mrNo:
          // Ricarico configurazione originale (scarto modifiche)
          FFrameConfig.LoadConfiguration;
      else
        // Annulla / dialogo chiuso: rimango in configurazione
        FConfigVisible := True;
        ToolButtonConfig.Down := True;
        Exit;
      end;
    end;

    // Torno SEMPRE alla vista principale, qualunque sia lo stato del database
    MostraVistaPrincipale;
    ToolButtonConfig.Down := False;
    ToolButtonConfig.Caption := 'Config';
    ToolButtonDeleteHistorical.Enabled := True;

    // RICREO TUTTO
    if FDatabaseConnected then
      CreatePanels
    else
    begin
      // database non connesso (es. parametri appena corretti): riprovo la connessione,
      // CreatePanels viene chiamato da ConnectToDatabase → Synchronize
      ShowConnectionPanel('Connessione al database in corso...', False);
      ConnectToDatabase;
    end;

    LogToFile('Configuration panel closed');
  end;
end;

procedure TMainForm.ToolButtonConfigClick(Sender: TObject);
begin
  ToggleConfigPanel;
end;

procedure TMainForm.ToolButtonDeleteHistoricalClick(Sender: TObject);
begin
  // Creo frame Service solo se non esiste
  if not Assigned(FFrameService) then
  begin
//    FFrameService := TFrameService.Create(nil);
    FFrameService := TFrameService.Create(self);
    FFrameService.Parent := PanelConfig;
    FFrameService.Align := alClient;
    FFrameService.OnCloseRequest := FrameServiceClose;
  end;

  // PanelConfig contiene anche il frame configurazione: mostro solo il Service
  // (dopo una prima chiusura il Service era rimasto nascosto)
  FFrameConfig.Visible := False;
  FFrameService.Visible := True;
  FFrameService.BringToFront;

  PanelConfig.Visible := True;
  PanelConfig.Align := alClient;
  PanelConfig.BringToFront;
  PanelMain.Visible := False;

  ToolButtonConfig.Enabled := false;
  ToolButtonDeleteHistorical.Enabled := false;

end;

procedure TMainForm.ToolButtonLicenzaClick(Sender: TObject);
begin
  // Consultazione / sostituzione della licenza: i monitor continuano a girare
  MostraLicenza;
  AggiornaInfoLicenza;
  UpdateStatusBar;
end;

procedure TMainForm.ApplicationEvents1Exception(Sender: TObject; E: Exception);
var
  ErrorMsg: string;
//  IsShutdownException: Boolean;
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

  // Durante shutdown: esco im maniera silenziosa
 { IsShutdownException :=
    Application.Terminated or
    FIsClosing or
    (csDestroying in ComponentState);
  }

  if Application.Terminated or
    FIsClosing or
    (csDestroying in ComponentState) then
      exit;





{  if IsShutdownException and
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
}

  // EAccessViolation / EOutOfMemory: stato potenzialmente corrotto
  // meglio riavviare che continuare a rischio
  if (E is EAccessViolation) or (E is EOutOfMemory) then
  begin
    LogToFile('CRITICAL - forcing application close' + e.Message);
    // Mostra un messaggio di errore all'utente
    MessageBox(Handle,
                 PChar('Critical Error' + sLineBreak + ErrorMsg + sLineBreak +
                       'The application will close' ),
                 'Critical Error',
                 MB_OK or MB_ICONERROR or MB_SYSTEMMODAL );

    Application.Terminate;
    exit;
  end;

  // Per tutto il resto: loggo e notifico senza bloccare
  UpdateConnectionStatus('ERRORE: ' + E.Message, CLR_ERR);
  LogToFile('Non-critical exception handled, continuing.');
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
   response := AskConfirmation('FTP monitors are still active. Do you want to stop them and close the application?',
                [], 5000) ;



    {
    response := MessageDlg(
      'FTP monitors are still active. Do you want to stop them and close the application?',
      mtConfirmation,
      [mbYes, mbNo],
      0
    );
    }

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
