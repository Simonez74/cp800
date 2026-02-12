unit FrameMain;

interface

uses
  Winapi.Windows
  , Winapi.Messages
  , System.SysUtils
  , System.Variants
  , System.Classes
  , Vcl.Graphics
  , Vcl.Controls
  , Vcl.Forms
  , Vcl.Dialogs
  , Vcl.Imaging.pngimage
  , Vcl.ExtCtrls
  , Vcl.StdCtrls
  , Vcl.ComCtrls
  , System.ImageList
  , Vcl.ImgList
  , IdBaseComponent
  , IdComponent
  , IdTCPConnection
  , IdTCPClient
  , IdExplicitTLSClientServerBase
  , IdFTP
  , IdFTPCommon
  , Vcl.BaseImageCollection
  , Vcl.ImageCollection
  , Vcl.VirtualImageList
  , FireDAC.Stan.Intf
  ,idstack
  , FireDAC.Stan.Option
  , FireDAC.Stan.Param
  , FireDAC.Stan.Error
  , FireDAC.DatS
  , FireDAC.Phys.Intf
  , FireDAC.DApt.Intf
  ,FireDAC.Stan.Async
  , FireDAC.DApt
  , Data.DB
  , FireDAC.Comp.DataSet
  , FireDAC.Comp.Client
  , IdCustomTCPServer
  , IdTCPServer
  , IdContext
  , Vcl.Grids
  , Vcl.DBGrids
  , Vcl.Buttons
  , Vcl.DBCtrls
  , Vcl.Mask
 // , VclTee.TeeGDIPlus
//  , VCLTee.TeEngine
//  , VCLTee.Series
  , VCLTee.TeeProcs
//  , VCLTee.Chart
  , System.StrUtils
  , Vcl.WinXCtrls
  , consts
  , System.IOUtils
  , System.Threading
  , System.SyncObjs
  , System.Types
  ,System.Generics.Defaults
  , System.Generics.Collections
  , Math
  , system.UITypes
  ///// TaskManager,
  ,Vcl.VirtualImage
//  FTPFileReader,
//  FireDAC.Comp.BatchMove, FireDAC.Comp.BatchMove.Text, FireDAC.Comp.BatchMove.DataSet,
//  FireDAC.Stan.StorageBin
//  , FtpDownloaderTask,
//  Vcl.WinXPanels, VCLTee.DBChart,
  ,SormaLabelOnChange
  ,Vcl.WinXPickers, Vcl.WinXPanels, VclTee.TeeGDIPlus, VCLTee.Series, VCLTee.TeEngine, VCLTee.Chart,
  Vcl.ButtonStylesAttributes, Vcl.StyledDbNavigator,
  Vcl.StyledButton, Vcl.Menus
  // VirtualTrees.HeaderPopup

  ,UnitFtpMonitor
  ,TypeUnit
  ,UnitFtpMonitor.WeightData, MyThreadLog
  ;


const
//   FTPData_056.txt
  StartFileName = 'FTPData_';
  StartFileProdName = 'FTPData2_';

type

  TFrameCp800 = class(TFrame)
    ScrollBox1: TScrollBox;
    Memo1: TMemo;
    Panel6: TPanel;
    LabelProgramNo: TLabel;
    Lbl1101: TLabel;
    LblDescProgram: TLabel;
    LblDescProgram3: TLabel;
    lbl2005: TLabel;
    LabelStatus: TLabel;
    VirtualImageList1: TVirtualImageList;
    ImageCollection1: TImageCollection;
    SplitView1: TSplitView;
    BtnDati: TButton;
    BtnLog: TButton;
    PanelMenu: TPanel;
    VirtualImage2: TVirtualImage;
    CardPanel1: TCardPanel;
    CardAltriDati: TCard;
    CardDati: TCard;
    Image1: TImage;
    StatusBar: TStatusBar;
    MemoProd: TMemo;
    CardStorico: TCard;
    Panel5: TPanel;
    Label1: TLabel;
    BtnStorico: TButton;
    DsStorico: TDataSource;
    QStorico: TFDQuery;
    DateTimeStorico: TDateTimePicker;
    cbDescrProgram: TComboBox;
    CbSessionId: TComboBox;
    Label2: TLabel;
    Label3: TLabel;
    DBNavigator2: TDBNavigator;
    DBGridStorico: TDBGrid;
    lbl1102: TSimonLabel;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    BtnStop: TButton;
    BtnStart: TButton;
    Lbl4015: TLabel;
    lbl4016: TLabel;
    lbl4017: TLabel;
    lbl4018: TLabel;
    lbl4019: TLabel;
    lbl4020: TLabel;
    lbl4021: TLabel;
    lbl4022: TLabel;
    lbl4023: TLabel;
    lbl4024: TLabel;
    lbl4025: TLabel;
    lbl4026: TLabel;
    lbl4005: TLabel;
    lbl4006: TLabel;
    LabelTime: TLabel;
    lbl2008: TSimonLabel;
    LblBelt: TLabel;
    LblBeltA: TLabel;
    LblBeltB: TLabel;
    LblBeltC: TLabel;
    LblBeltD: TLabel;
    LblSpeed: TLabel;
    LblTotalsKg: TLabel;
    LblTotalPacks: TLabel;
    LblDescProgram2: TLabel;
    lbl2003: TLabel;
    lbl2004: TLabel;
    lbl2002: TLabel;
    lbl2001: TLabel;
    LblDescProgram1: TLabel;
    LblSetPoint: TLabel;
    LblDescProgram9: TLabel;
    LblTotals: TLabel;
    LblWeightA: TLabel;
    LblWeightC: TLabel;
    LblWeightD: TLabel;
    LblWeightB: TLabel;
    lblTotSpeed: TLabel;
    Bevel1: TBevel;
    lbl5001: TSimonLabel;
    lbl9001: TLabel;
    Bevel2: TBevel;
    Bevel3: TBevel;
    Bevel4: TBevel;
    procedure BtnDatiClick(Sender: TObject);
    procedure VirtualImage2Click(Sender: TObject);
    procedure lbl5001CaptionChange(Sender: TObject; const NewCaption: string);
    procedure DateTimeStoricoCloseUp(Sender: TObject);
    procedure cbDescrProgramChange(Sender: TObject);
    procedure lbl1102CaptionChange(Sender: TObject; const NewCaption: string);
    procedure DBGridStoricoDrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn;
      State: TGridDrawState);
    procedure BtnStartClick(Sender: TObject);
    procedure BtnStopClick(Sender: TObject);
  private

    //scarica un file FTP con coppie key=value e aggiorna le label sul frame
    FMonitor: TFtpMonitor;

    // scarica il file pesi (FTPData2_051.txt),  scrive CSV automaticamente,
    // si avvia/ferma da solo in base a ProgramNumber / IsRunning / PackMode
    FMonitorWeight: TWeightFtpMonitor;


    FCodeMap: TDictionary<string,string>;
//    FCodeMap: TList<string>;


    // Mappa dinamica: codice (es. "4001") ? riferimento alla TLabel corrispondente.
    // Viene costruita una volta in Configure scansionando i componenti del frame.
    FLabelMap: TDictionary<string, TLabel>;


    FIsRunning: Boolean;
    FIsShuttingDown: Boolean;
    FServerCfg : TServerConfig;

//    FWeightPath : String;
//    FIsRunningWeight: Boolean;

    ///
    procedure MonitorParsed(Sender: TObject; APairs: TStringList);
    procedure MonitorLog(Sender: TObject; const Msg: string);
    procedure MonitorError(Sender: TObject; E: Exception);

    // Event handlers Weight Monitor
    procedure MonitorWeight(Sender: TObject; const WeightData: TWeightRecord);
    procedure MonitorWeightLog(Sender: TObject; const Msg: string);
    procedure MonitorWeightError(Sender: TObject; E: Exception);

    procedure AddLog(Amemo : Tmemo; const Msg: string);

    function ExtractNumberInString ( Stringa : String ): String ;

    procedure FTPStatusHandler(const Status: string; AStatus: TIdStatus);

    // Scansiona i componenti del frame e costruisce FLabelMap
    procedure BuildLabelMap;
    // Estrae il codice numerico dal nome di una label (es. "lbl4001" ? "4001")
    function ExtractCodeFromName(const AName: string): string;


    // procedure per gestione storico
    procedure CaricaComboBox (Combo: TComboBox; Campo, Tabella: string);
    procedure ElaboraStorico ;
    procedure AggiornaCondizioniLog;
    procedure InitWeightMonitor;

  public
    { Public declarations }
//    constructor Create(AOwner: TComponent; const FCp800Id: string); reintroduce;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Configure(Const AServerCfg : TServerConfig );
    procedure Start;
//    procedure Stop;
    procedure Shutdown;

    property IsRunning: Boolean read FIsRunning;
  end;

implementation

{$R *.dfm}

//uses DMI_Console, Myfunc.Utils, ConfigManager;
uses DMI_Console,  ConfigManager;

constructor TFrameCp800.Create(AOwner: TComponent);
begin
  inherited;
  FMonitor := nil;
  FMonitorWeight := nil;

  FCodeMap := nil;
  FIsRunning := False;
end;

destructor TFrameCp800.Destroy;
begin
(*
12/02/206

// Assicurati che tutto sia fermo
  if not FIsShuttingDown then
    Shutdown;

  if assigned(FLabelMap) then
    FreeAndNil(FLabelMap);

  if Assigned(FCodeMap) then
    FreeAndNil(FCodeMap);
*)

 FIsShuttingDown := True;

  // DISCONNETTI eventi PRIMA
  if Assigned(FMonitor) then
  begin
    FMonitor.OnParsed := nil;
    FMonitor.OnLog := nil;
    FMonitor.OnError := nil;
    FMonitor.OnStatus := nil;
  end;

  if Assigned(FMonitorWeight) then
  begin
    FMonitorWeight.OnParsed := nil;
    FMonitorWeight.OnLog := nil;
    FMonitorWeight.OnError := nil;
    FMonitorWeight.OnStatus := nil;
    FMonitorWeight.OnWeight := nil;
  end;

  // SHUTDOWN dei monitor
  try
    Shutdown;
  except
  end;

  // Questo forza il decremento del RefCount delle stringhe
  FServerCfg.Inizializza ;


  // Forza liberazione monitor (doppia protezione)
  try
    if Assigned(FMonitor) then
      FreeAndNil(FMonitor);
  except
  end;

  try
    if Assigned(FMonitorWeight) then
      FreeAndNil(FMonitorWeight);
  except
  end;

  // Dizionari
  try
    if assigned(FLabelMap) then
      FreeAndNil(FLabelMap);
  except
  end;

  try
    if Assigned(FCodeMap) then
      FreeAndNil(FCodeMap);
  except
  end;



  inherited;
end;


procedure TFrameCp800.Configure(Const AServerCfg : TServerConfig );
var
  i :integer;
begin
  FServerCfg := AServerCfg;

  SplitView1.Opened := false;

  // per tutti i tlabel metto caption = string.empty
  for i := 0 to ComponentCount - 1 do
  begin
//   if ( Components[ i ] is TSimonLabel) AND ( Components[ i ].Tag > 0 ) then
//     TSimonLabel(Components[ i ]).Caption := string.Empty;
    if ( Components[ i ] is TLabel ) AND ( Components[ i ].Tag > 0 ) then
      (Components[ i ] as TLabel ).Caption :=string.empty;
  end;

  // Costruisco la mappa codice ? label (va dopo il reset delle caption)
  BuildLabelMap;

  StatusBar.Panels.Items[0].Text:= Format('%s (%s:%d)',
     [ FServerCfg.Id,  FServerCfg.Host, FServerCfg.Port]);

  CardPanel1.ActiveCard := CardDati;

  AddLog(Memo1, Format('Configured: %s:%d %s', [FServerCfg.Host, FServerCfg.Port, FServerCfg.FileName]));
end;


procedure TFrameCp800.AddLog(Amemo : Tmemo;const Msg: string);
begin
  // Se il frame è in fase di distruzione, non loggare
//  if csDestroying in ComponentState then
//    Exit;
  // Evita log durante shutdown
  if FIsShuttingDown then
    Exit;

  try
    // Thread-safe logging con TThread.Queue
    TThread.Queue(nil,
      procedure
      var
        LogMsg : string;
      begin
        if not assigned(amemo) then
          exit;


        // Doppio check: il memo potrebbe essere stato distrutto nel frattempo
        if Assigned(AMemo) and not (csDestroying in AMemo.ComponentState) then
        begin
          try
            LogMsg := (Format('[%s] %s',
              [FormatDateTime('hh:nn:ss', Now), Msg]));
            AMemo.Lines.Add(LogMsg);

            // Auto-scroll all'ultima riga
            AMemo.SelStart := Length(AMemo.Text);
            AMemo.Perform(EM_SCROLLCARET, 0, 0);
            if AMemo.Lines.Count > 1000 then
              AMemo.Lines.Delete(0);
           except
            // Ignoro errori durante logging se il memo è in destroy
          end;
        end;
      end);
  except
    // Ignoro anche errori di Queue
  end;
end;


procedure TFrameCp800.Start;
begin
  if Assigned(FMonitor) then
  begin
    AddLog(memo1, 'Monitor already running');
    Exit;
  end;
  // Creo il monitor
  FMonitor := TFtpMonitor.Create(FServerCfg, FCodeMap);

  // Assegno gli event handlers
  FMonitor.OnParsed := MonitorParsed;
  FMonitor.OnLog := MonitorLog;
  FMonitor.OnError := MonitorError;
  FMonitor.OnStatus := FTPStatusHandler;
  // impostazioni
  FMonitor.IntervalMs := FServerCfg.Intervall;
  FMonitor.RemoteFileDownload :=  FServerCfg.FileName;
  FMonitor.Start;

  FIsRunning := True;
  BtnStart.Enabled := False;
  BtnStop.Enabled := True;

  AddLog(memo1, 'Monitor started');

  // Crea e configura FMonitorWeight ma NON lo avvia.
  // Sarà ApplyStateChange a fare Start quando le label vengono
  // populate dal primo ciclo di FMonitor.
  InitWeightMonitor;
end;


// Crea FMonitorWeight e lo configura, ma NON avvia il thread FTP dei pesi.
// Lo Start viene fatto automaticamente da ApplyStateChange
// quando ShouldRun diventa true (primo ciclo con dati validi).
procedure TFrameCp800.InitWeightMonitor;
begin
  if Assigned(FMonitorWeight) then
  begin
    AddLog(MemoProd, 'Weight Monitor already initialised');
    Exit;
  end;

  FMonitorWeight := TWeightFtpMonitor.Create(FServerCfg, FCodeMap);

  // Assegna i callback
  FMonitorWeight.OnParsed := nil;
  FMonitorWeight.OnWeight := MonitorWeight;
  FMonitorWeight.OnLog := MonitorWeightLog;
  FMonitorWeight.OnError := MonitorWeightError;

  FMonitorWeight.IntervalMs := FServerCfg.Intervall;

  FMonitorWeight.RemoteFileDownload := FServerCfg.FileNameProd;

  // NON chiamiamo .Start() qui.
  // Il primo UpdateState (provocato dalla cambiata caption di lbl1102)
  // calcola ShouldRun e, se serve, avvia il thread internamente
  // tramite ApplyStateChange ? Start.
  AddLog(MemoProd, 'Weight Monitor initialised (waiting for program data...)');
end;
       {
procedure TFrameCp800.Stop;
begin
  if not Assigned(FMonitor) then
  begin
    AddLog(memo1, 'Monitor not running');
    Exit;
  end;

  try
    // Disconnetto eventi PRIMA di fermare
    FMonitor.OnParsed := nil;
    FMonitor.OnLog := nil;
    FMonitor.OnError := nil;
    FMonitor.OnStatus := nil;

    // fermo il thread
    FMonitor.Stop;

     // Aspetto completamento
    if FMonitor.AttendoCompletamento(3000) then
      AddLog(memo1, 'Monitor stopped cleanly')
    else
      AddLog(memo1, 'Monitor timeout - forcing cleanup');

    // LIBERO L'OGGETTO
    FreeAndNil(FMonitor);
    AddLog(memo1, 'Monitor freed successfully');

  except
    // log opzionale
     on E: Exception do
     begin
       AddLog(memo1,'Error stopping monitor: ' + E.Message);
      // Libero anche in caso di errore
      if Assigned(FMonitor) then
        FreeAndNil(FMonitor);
     end;
  end;


  FIsRunning := False;
  // Aggiorna UI se i bottoni esistono ancora
  if Assigned(BtnStart) then
    BtnStart.Enabled := True;
  if Assigned(BtnStop) then
    BtnStop.Enabled := False;
end;
}

procedure TFrameCp800.AggiornaCondizioniLog;
begin
  if not Assigned(FMonitorWeight) then
    Exit;

  if FIsShuttingDown then  // ← Evita chiamate durante shutdown
    Exit;


  FMonitorWeight.AggiornaCondizioni(
    lbl1102.Caption,                      // Programma lavoro
    UpperCase(lbl5001.Caption) = 'TRUE',  // Status start/stop
    lbl2008.Caption                       // Mode
  );
end;

procedure TFrameCp800.Shutdown;
begin
  FIsShuttingDown := True;
  // PASSO 1: DISCONNETTO PRIMA GLI EVENT HANDLER
  // disconnetto gli handler per evitare che queued-procedure chiamino il frame già libero
  if Assigned(FMonitor) then
  begin
    FMonitor.OnParsed := nil;
    FMonitor.OnLog := nil;
    FMonitor.OnError := nil;
    FMonitor.OnStatus := nil;
  end;

  if Assigned(FMonitorWeight) then
  begin
    FMonitorWeight.OnParsed := nil;
    FMonitorWeight.OnLog := nil;
    FMonitorWeight.OnError := nil;
    FMonitorWeight.OnStatus := nil;
    FMonitorWeight.OnWeight := nil;
  end;

  // PASSO 2: FERMO I THREAD
  // fermo il monitor e libero l'istanza
  if Assigned(FMonitor) then
  begin
    try
      try
        FMonitor.Stop;

        // ASPETTO che il thread finisca DAVVERO
        if FMonitor.AttendoCompletamento(3000) then
          AddLog(Memo1, 'Monitor stopped cleanly')
        else
          // TIMEOUT: il thread non ha finito
          AddLog(Memo1, 'Monitor timeout - will force cleanup');
      except
        on E: Exception do
        begin
          AddLog(Memo1, 'Shutdown error: ' + E.Message);
          // Log su debugger se disponibile
      //  OutputDebugString(PChar('Shutdown FMonitor error: ' + E.Message));
        end;
      end;
    finally
      try
        // SEMPRE chiamare FreeAndNil - questo libera FStopEvent sul destroy
        if Assigned(FMonitor) then
          FreeAndNil(FMonitor);
      except
      end;
    end;
  end;

  if Assigned(FMonitorWeight) then
  begin
    try
      try
        FMonitorWeight.Stop;

          // ASPETTO che il thread finisca DAVVERO
        if FMonitorWeight.AttendoCompletamento(2000) then
          AddLog(Memo1, ' Weight Monitor stopped cleanly')
        else
         // TIMEOUT: il thread non ha finito
          AddLog(Memo1, 'Weight Monitor timeout - will force cleanup');
        // SEMPRE chiamare FreeAndNil - questo libera FStopEvent sul destroy

      // FreeAndNil(FMonitorWeight);
      except
        on E: Exception do
        begin
         AddLog(Memo1, 'Shutdown error: ' + E.Message);
//        OutputDebugString(PChar('Shutdown FMonitorWeight error: ' + E.Message));
        end;
      end;
    finally
      try
        if Assigned(FMonitorWeight) then
          FreeAndNil(FMonitorWeight);
      except
      end;
    end;

  end;
  FIsRunning := False;
  FIsShuttingDown := False;
end;

procedure TFrameCp800.VirtualImage2Click(Sender: TObject);
begin
  if SplitView1.Opened then
    SplitView1.Close
  else
    SplitView1.Open;
end;

procedure TFrameCp800.BtnDatiClick(Sender: TObject);
begin
  if (sender = BtnDati) then
  begin
    CardPanel1.ActiveCard := CardDati;

  end
  else if (sender = BtnLog) then
  begin
    CardPanel1.ActiveCard := CardAltriDati;

  end
  else if (sender = BtnStorico) then
  begin
    DateTimeStorico.Date := now;
    CaricaComboBox(cbDescrProgram,'DsProgram','cp800storico');
    CaricaComboBox(CbSessionId,'Session_ID','cp800storico');
    DateTimeStoricoCloseUp(DateTimeStorico);
    CardPanel1.ActiveCard := CardStorico;
  end
end;

procedure TFrameCp800.BtnStartClick(Sender: TObject);
begin
  start;
end;

procedure TFrameCp800.BtnStopClick(Sender: TObject);
begin
  Shutdown;
//  stop;
end;


// Scansiona tutti i componenti del frame.
// Per ogni TLabel (inclusi i TSimonLabel che ereditano da TLabel) con Tag > 0:
//   - estrae il codice dal nome (es. lbl4001 ? "4001")
//   - se il codice è valido, lo inserisce in FLabelMap
procedure TFrameCp800.BuildLabelMap;
var
  i: Integer;
  comp: TComponent;
  lbl: TLabel;
  code: string;
begin
  if not Assigned(FLabelMap) then
    FLabelMap := TDictionary<string, TLabel>.Create;

  if not Assigned(FCodeMap) then
    FCodeMap := TDictionary<string, string>.Create;

  FCodeMap.Clear;

  FLabelMap.Clear;

  for i := 0 to ComponentCount - 1 do
  begin
    comp := Components[i];

    // TSimonLabel è un discendente di TLabel, quindi "is TLabel" la cattura entrambe
    if (comp is TLabel) and (comp.Tag > 0) then
    begin
      lbl := comp as TLabel;
      code := ExtractCodeFromName(comp.Name);

      if (code <> '') and (not FLabelMap.ContainsKey(code)) then
      begin
        FLabelMap.AddOrSetValue(code, lbl);
        FCodeMap.AddOrSetValue(code, code);
      end;
    end;
  end;

  AddLog(Memo1, Format('LabelMap built: %d codici mappati', [FLabelMap.Count]));

end;

procedure TFrameCp800.FTPStatusHandler(const Status: string; AStatus: TIdStatus);
begin
    {
    TThread.Queue(nil, procedure
  begin
    Memo1.Lines.Add(Format('[Status] %s %s', [FormatDateTime('hh:mm:ss:zzz', now()), AStatusText]));
    StatusBar.Panels.Items[1].Text:= Format('[Status] %s %s', [FormatDateTime('hh:mm:ss:zzz', now()), AStatusText]);;
  end);}
  Memo1.Lines.Add(Format('[Status] %s %s', [FormatDateTime('hh:mm:ss:zzz', now()), Status]));
  StatusBar.Panels.Items[1].Text:= Format('[Status] %s %s', [FormatDateTime('hh:mm:ss:zzz', now()), Status]);;
end;



procedure TFrameCp800.ElaboraStorico;
begin
  if QStorico.Active then
    QStorico.Close;
  QStorico.SQL.Clear;
  QStorico.SQL.add( 'select NumProgram,DsProgram,'
                 + ' max(case when startstop = 1 then dataTime end) as StartTime, '
                 + ' max(case when startstop = 0 then dataTime end) as EndTime, '
                 + ' max(case when startstop = 1 then TotalWeight end) as StartWeight,'
                 + ' max(case when startstop = 0 then TotalWeight end) as EndtWeight, '
                 + ' max(case when startstop = 1 then TotalPacks end) as StartPacks, '
                 + ' max(case when startstop = 0 then TotalPacks end) as EndPacks, '
//                   Calcoli delle differenze
                 + ' max(case WHEN StartStop = 0 THEN TotalWeight END) - '
                 + ' max(case WHEN StartStop = 1 THEN TotalWeight END) AS WeightDifference, '
                 + ' max(case WHEN StartStop = 0 THEN TotalPacks END) - '
                 + ' max(case WHEN StartStop = 1 THEN TotalPacks END) AS PacksDifference, '
                 + ' ( TIMESTAMPDIFF(MINUTE,  max(case when startstop = 1 then dataTime end), max(case when startstop = 0 then dataTime end)  ) ) as DurationMinute, '
                 + ' (MAX(CASE WHEN StartStop = 0 THEN TotalPacks END) -  MAX(CASE WHEN StartStop = 1 THEN TotalPacks END) ) / '
                 + ' ( TIMESTAMPDIFF(MINUTE,  max(case when startstop = 1 then dataTime end), max(case when startstop = 0 then dataTime end)  ) ) as packMin, '
                 + ' ( MAX(CASE WHEN StartStop = 0 THEN TotalWeight END) -   MAX(CASE WHEN StartStop = 1 THEN TotalWeight END) ) '
                 + ' / ( TIMESTAMPDIFF(MINUTE,  max(case when startstop = 1 then dataTime end), max(case when startstop = 0 then dataTime end)  ) ) as WeightMin '
                 + ' from cp800Storico '
                 + ' where '
//                 + ' on s.numProgram = e.NumProgram'
//                 + ' and s.Session_id = e.Session_id'
                 + ' cp800_ID = ' +  QuotedStr( FServerCfg.id ));
  if DateTimeStorico.Checked  then
    QStorico.SQL.add( ' and date( datatime) = ' + quotedstr( FormatDateTime('yyyy-mm-dd', DateTimeStorico.DateTime)));
  if cbDescrProgram.ItemIndex > 0 then
      QStorico.SQL.add(' and DsProgram = '+ QuotedStr( cbDescrProgram.Items[cbDescrProgram.ItemIndex]) );
  if CbSessionId.ItemIndex > 0 then
      QStorico.SQL.add(' and Session_ID = '+ CbSessionId.Items[CbSessionId.ItemIndex]);

   // QStorico.SQL.add (' group by NumProgram, session_id ');
  QStorico.SQL.add (' group by NumProgram,DsProgram, session_id ');
  QStorico.Open;
end;



function TFrameCp800.ExtractCodeFromName(const AName: string): string;
// Estrae il codice numerico dal nome della label.
// Regola: cerca la prima sequenza di cifre alla fine del nome.
//   "lbl4001"      ? "4001"
//   "Lbl4015"      ? "4015"
//   "lbl5001"      ? "5001"
//   "LabelTime"    ? ""  (nessuna sequenza numerica alla fine)
//   "lbl2008"      ? "2008"
var
  i: Integer;
  CodeStart: Integer;
begin
  Result := '';
  if AName = '' then
    Exit;

  // Cerca dalla fine: trova la posizione dove inizia la sequenza finale di cifre
  CodeStart := 0;
  for i := Length(AName) downto 1 do
  begin
    if CharInSet(AName[i], ['0'..'9']) then
      CodeStart := i
    else
      Break;  // prima carattere non-cifra dalla fine: fermati
  end;

  if CodeStart > 0 then
    Result := Copy(AName, CodeStart, Length(AName) - CodeStart + 1);

end;

function TFrameCp800.ExtractNumberInString(Stringa: String): String;
var
  i: Integer ;
begin
  Result := '' ;
  for i := 1 to length( Stringa ) do
  begin
//    if  Stringa[ i ] in ['0'..'9'] then
    if  charinset ( Stringa[ i ] , ['0'..'9']) then
      Result := Result + Stringa[ i ] ;
  end ;
end;

{
function TFrameCp800.IsTaskRunning(const ATask: ITask): Boolean;
var
  I: Integer;
begin
  Result := False;
  FLock.Enter;
  try
    for I := 0 to FTaskList.Count - 1 do
    begin
      // Confronta i task (potrebbe variare a seconda di come vuoi confrontarli)
    //  if (FTaskList[I] = ATask) or
//         ((FTaskList[I] as ITask).Status in [TTaskStatus.Running, TTaskStatus.WaitingToRun]) then
      if (FTaskList[I] = ATask) then
      begin
        Result := True;
        Exit;
      end;
    end;
  finally
    FLock.Release;
  end;
end;
 }



procedure TFrameCp800.lbl1102CaptionChange(Sender: TObject; const NewCaption: string);
// var
//  lNumsessione : integer;
//  LNomeFile : String;
begin

  AddLog(Memo1, Format(' bl1102CaptionChange: %s', [NewCaption]));
  AggiornaCondizioniLog;
    {
  if not Assigned(FMonitorWeight) then
    Exit;



//  LNomeFile := concat( FormatDateTime('yyyyddmm' , now()), '_'    );
  LNomeFile := concat( FormatDateTime('yyyymmdd' , now()), '_',  trim( NewCaption)  );
//  LNomeFile := concat( FormatDateTime('yyyyddmm' , now()), '_' );
  lNumsessione :=  ContaFile( IncludeTrailingPathDelimiter( TPath.Combine(  ExtractFilePath(paramstr(0)) , 'Weight')), LNomeFile);
  if lNumsessione > 0  then
    LNomeFile := concat ( LNomeFile , '_', lNumsessione.ToString ) ;
//  lNumsessione := DMIConsole.CalcolaSessione(Cp800id, ExtractNumberInString( NewCaption) );

//  FMonitorWeight.OnProgramNumberChanged(NewCaption);

//////////////  FMonitorWeight.OnProgramNumberChanged(concat(LNomeFile, '.csv'));
  FMonitorWeight.OnProgramNumberChanged(NewCaption);///

// sistemare  FDownloader.NomeFilePacks := concat(LNomeFile, '.csv');
    }
end;

procedure TFrameCp800.lbl5001CaptionChange(Sender: TObject; const NewCaption: string);
var
  LCp800StoricoRecord :  TCP800StoricoRecord;
begin
  AggiornaCondizioniLog;
  // Prepara il record nel thread principale (accesso sicuro alle label)
  LCp800StoricoRecord.Start := UpperCase(NewCaption) = 'TRUE';
  LCp800StoricoRecord.Cp800_id := FServerCfg.id;
  LCp800StoricoRecord.NumPrg := ExtractNumberInString(lbl1101.Caption);
  LCp800StoricoRecord.DsPrg := lbl1102.Caption;
  LCp800StoricoRecord.TotalWeight := ExtractNumberInString(lbl4005.Caption);
  LCp800StoricoRecord.TotalPacks := ExtractNumberInString(lbl4006.Caption);

  // Esegui scrittura DB in background
  TTask.Run(
    procedure
    var
      RecordCopy: TCP800StoricoRecord;
      Success: Boolean;
      ErrorMsg: string;
    begin
      RecordCopy := LCp800StoricoRecord; // Copia locale per sicurezza
      Success := False;
      ErrorMsg := '';

      try
        DMIConsole.ScriviRecordCp800Storico(RecordCopy);
        Success := True;
      except
        on E: Exception do
        begin
          ErrorMsg := E.Message;
          {// Log errore in modo thread-safe
          TThread.Queue(nil,
            procedure
            begin
              LogToFile(Format('Errore scrittura storico CP800 %s: %s',
                              [RecordCopy.Cp800_id, E.Message]));
            end);}
        end;
      end;

      // Ritorna al thread principale per il log
      TThread.Queue(nil,
        procedure
        begin
          if Success then
            AddLog(Memo1, Format('Storico salvato: %s - %s',
                                [RecordCopy.NumPrg, RecordCopy.DsPrg]))
          else
            AddLog(Memo1, Format('ERRORE scrittura storico: %s', [ErrorMsg]));
        end);
    end);
end;



procedure TFrameCp800.MonitorError(Sender: TObject; E: Exception);
begin
   AddLog(memo1,'ERROR: ' + E.Message);
end;

procedure TFrameCp800.MonitorLog(Sender: TObject; const Msg: string);
begin
    AddLog(memo1, Msg);
end;

procedure TFrameCp800.MonitorParsed(Sender: TObject; APairs: TStringList);
var
  key: string;
  val: string;
////  lbl: TLabel;
  totSpeed : integer;
begin

  // APairs viene liberato automaticamente dal monitor dopo l'esecuzione di questo handler

  // ========================================
  // AGGIORNA LE LABEL CON I VALORI
  // ========================================
  val := APairs.Values['1101'];
//  if (val <> '') and Assigned(FCodeMap) and FCodeMap.ContainsKey('1101') then
  if (val <> '') then
//    Lbl1101.Caption := Format('%s: %s (%s)', ['1101', val, FCodeMap['1101']])
    Lbl1101.Caption := val
  else
    Lbl1101.Caption := string.Empty;
//    Lbl1101.Caption := Format('%s: %s', ['1101', val]);

  val := APairs.Values['1102'];
//  if (val <> '') and Assigned(FCodeMap) and FCodeMap.ContainsKey('1102') then
  if (val <> '')  then
//    Lbl1102.Caption := Format('%s: %s (%s)', ['1102', val, FCodeMap['1102']])
    Lbl1102.Caption := val
  else
//    Lbl1102.Caption := Format('%s: %s', ['1102', val]);
    Lbl1102.Caption := String.Empty;





  val := APairs.Values['2001'];
//  if (val <> '') and Assigned(FCodeMap) and FCodeMap.ContainsKey('2001') then
  if (val <> '') then
//    Lbl2001.Caption := Format('%s: %s (%s)', ['2001', val, FCodeMap['2001']])
    Lbl2001.Caption := val
  else
//    Lbl2001.Caption := Format('%s: %s', ['2001', val]);
    Lbl2001.Caption := String.Empty;

  val := APairs.Values['2002'];
//  if (val <> '') and Assigned(FCodeMap) and FCodeMap.ContainsKey('2002') then
  if (val <> '')  then
//    Lbl2002.Caption := Format('%s: %s (%s)', ['2002', val, FCodeMap['2002']])
    Lbl2002.Caption := val
  else
//    Lbl2002.Caption := Format('%s: %s', ['2002', val]);
    Lbl2002.Caption := string.Empty;


//  Lbl2003.Caption := FCodeMap['2003'] + APairs.Values['2003'];

  Lbl2003.Caption := APairs.Values['2003'];
//  Lbl2004.Caption := FCodeMap['2004'] + APairs.Values['2004'];
  Lbl2004.Caption := APairs.Values['2004'];
  Lbl2005.Caption := APairs.Values['2005'];

  Lbl4005.Caption := APairs.Values['4005'];
  Lbl4006.Caption := APairs.Values['4006'];

  Lbl4015.Caption := APairs.Values['4015'];
  Lbl4016.Caption := APairs.Values['4016'];
  Lbl4017.Caption := APairs.Values['4017'];
  Lbl4018.Caption := APairs.Values['4018'];
  Lbl4019.Caption := APairs.Values['4019'];
  Lbl4020.Caption := APairs.Values['4020'];
  Lbl4021.Caption := APairs.Values['4021'];
  Lbl4022.Caption := APairs.Values['4022'];
  Lbl4023.Caption := APairs.Values['4023'];
  Lbl4024.Caption := APairs.Values['4024'];
  Lbl4025.Caption := APairs.Values['4025'];
  Lbl4026.Caption := APairs.Values['4026'];

  Lbl5001.Caption := APairs.Values['5001'];
  Lbl9001.Caption := APairs.Values['9001'];

  try
    totSpeed := strtoint(APairs.Values['4015']) +
                strtoint(APairs.Values['4016']) +
                strtoint(APairs.Values['4017']) +
                strtoint(APairs.Values['4018']) ;
    lblTotSpeed.Caption := IntToStr(totSpeed);
  except
    lblTotSpeed.Caption := 'error';
  end;


  if uppercase(Lbl5001.Caption) = 'TRUE' then
    Lbl9001.Color :=  $0039EA42
  ELSE
    Lbl9001.Color := clMedGray;
  Application.ProcessMessages;

      (*
  // ========================================
  // AGGIORNA LE LABEL CON I VALORI (dinamico)
  // ========================================
  if Assigned(FLabelMap) then
  begin
    for key in FLabelMap.Keys do
    begin
      val := APairs.Values[key];
      lbl := FLabelMap[key];

      // Per 1101 e 1102 (e simili) se il valore è vuoto pulisco la label
      if val <> '' then
        lbl.Caption := val
      else
        lbl.Caption := string.Empty;
    end;
  end;
     *)




  LabelTime.Caption := FormatDateTime('hh:mm:ss:zzz', now());


  // show parsed pairs for debug

  // ========================================
  // LOG DEI VALORI PARSATI (opzionale, per debug)
  // ========================================

  if Memo1.Lines.Count > 1000 then
    Memo1.Clear; // Previeni overflow del log

  Memo1.Lines.Add('--- Parsed values ---');
  for key in APairs do
    Memo1.Lines.Add(Format('  %s = %s', [key, APairs.Values[key]]));



end;

procedure TFrameCp800.MonitorWeight(Sender: TObject; const WeightData: TWeightRecord);
//var
//  DisplayText: string;
begin
  // Aggiorna label con ultimo peso ricevuto
{  DisplayText := Format('ID: %s | Channel %s: %s kg | Time: %s', [
    WeightData.ID,
    WeightData.GetNonZeroChannel,
    WeightData.GetNonZeroValue,
    WeightData.Time
  ]);
 }

  TThread.Queue(nil,
    procedure
    begin
//////      LabelLastWeight.Caption := DisplayText;
  //  LabelWeightStatus.Caption := Format('Total records: %s', [WeightData.ID]);
   {   if WeightData.ValA <> 0 then
        LblWeightA.Caption := Format('%d g', [WeightData.ValA])
      else
        LblWeightA.Caption := '-';
      if WeightData.ValB <> 0 then
        LblWeightB.Caption := Format('%d g', [WeightData.ValB])
      else
        LblWeightB.Caption := '-';
      if WeightData.ValC <> 0 then
        LblWeightC.Caption := Format('%d g', [WeightData.ValC])
      else
        LblWeightC.Caption := '-';
      if WeightData.ValD <> 0 then
        LblWeightD.Caption := Format('%d g', [WeightData.ValD])
      else
        LblWeightD.Caption := '-';
        }
      if WeightData.ValA <> 0 then
        LblWeightA.Caption := Format('%d g', [WeightData.ValA]);

      if WeightData.ValB <> 0 then
        LblWeightB.Caption := Format('%d g', [WeightData.ValB]);

      if WeightData.ValC <> 0 then
        LblWeightC.Caption := Format('%d g', [WeightData.ValC]);

      if WeightData.ValD <> 0 then
        LblWeightD.Caption := Format('%d g', [WeightData.ValD]);


    end);



  // Log opzionale (solo per debug )
  // AddLog(MemoProd, DisplayText);

end;

procedure TFrameCp800.MonitorWeightError(Sender: TObject; E: Exception);
begin
   AddLog(MemoProd,'ERROR: ' + E.Message);
end;

procedure TFrameCp800.MonitorWeightLog(Sender: TObject; const Msg: string);
begin
  AddLog(MemoProd, Msg);
end;

procedure TFrameCp800.CaricaComboBox(Combo: TComboBox; Campo, Tabella: string);
var
  Query: TFDQuery;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := DMIConsole.FDConnection;
    Query.SQL.Text := Format('SELECT DISTINCT %s FROM %s ORDER BY %s', [Campo, Tabella, Campo]);
    Query.Open;

    Combo.Clear;
    Combo.Items.Add('Tutti');

    while not Query.Eof do
    begin
      Combo.Items.Add(Query.FieldByName(Campo).AsString);
      Query.Next;
    end;
  finally
    Query.Free;
  end;
   Combo.ItemIndex := 0;

end;

procedure TFrameCp800.cbDescrProgramChange(Sender: TObject);
begin
  ElaboraStorico;
end;

procedure TFrameCp800.DateTimeStoricoCloseUp(Sender: TObject);
begin
  ElaboraStorico;
end;

procedure TFrameCp800.DBGridStoricoDrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn;
  State: TGridDrawState);
begin
//  DBGridStorico.Canvas.font.Color := $00FCE7BE;
  DBGridStorico.Canvas.Brush.Color := $00FCE7BE;
  DBGridStorico.DefaultDrawColumnCell(rect,datacol,column,state);
end;


end.
