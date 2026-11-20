unit UnitFtpMonitor.WeightData;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.IOUtils,
  UnitFtpMonitor, TypeUnit
  ,System.SyncObjs
  ,Vcl.ExtCtrls;

type
  TWeightEvent = procedure(Sender: TObject; const WeightData: TWeightRecord) of object;

  // Monitor specializzato per file pesi con auto start/stop
  TWeightFtpMonitor = class(TFtpMonitor)
  private
    FUltimoIdProcessato : string;
    FOnWeight: TWeightEvent;
    FBaseOutputPath: string;

    // Stato corrente (protetto da FStateLock)
    FStatoAttuale: TSituazioneXLog;
    FStateLock: TCriticalSection;


    // Periodo aggiuntivo - continua a scaricare dopo stop
    FPeriodoAggiuntivoMs: Cardinal;
    FInPeriodoAggiuntivo: Boolean;
    FPeriodoAggiuntivoTimer: TTimer;  // Timer non bloccante per grace period

    // Ultime condizioni macchina ricevute e non ancora applicate (protette da FStateLock).
    // Durante il periodo aggiuntivo vengono solo memorizzate e applicate al termine.
    FPendProgram: string;
    FPendInStart: Boolean;
    FPendPackMode: string;
    FHasPending: Boolean;

    procedure ParseRigaPesi(const Line: string; out WeightData: TWeightRecord);
    procedure ProcessaDatiPesi(const APairs: TStringList);
    procedure ElaboraCondizioniPendenti;
    procedure ApplicaCambioSituazione (const NuovaSituazione: TSituazioneXLog);
    function BuildOutputFileName(const DsProgram: string): string;
    procedure LeggiUltimoIdProcessato(const ALastIDFile: string);
    procedure SalvaUltimoIdProcessato(const ALastIDFile, AUltimoId: string);
    procedure QueueWeight(const AOnWeight: TWeightEvent; const AData: TWeightRecord);

    // Callback per il timer del periodo aggiuntivo
    procedure OnPeriodoAggiuntivoTerminato(Sender: TObject);
  protected
    procedure DoQueueParsed(const APairs: TStringList); override;
    function VariabileDaLeggere(const AKey: string): Boolean; override;
  public
    constructor Create(Const AServerCfg :  TServerConfig; const ACodeMap: TDictionary<string,string>);
    destructor Destroy; override;

    // Aggiorna stato e decide se Start/Stop in base ai parametri
    procedure AggiornaCondizioni(const AProgram: string; AInstart: Boolean; const APackMode: string);

    // ottengo thread-safe stato corrente
    function GetCurrentState: TSituazioneXLog;

    // Override Stop per gestire periodo aggiuntivo
    procedure Stop; reintroduce;


    property OnWeight: TWeightEvent read FOnWeight write FOnWeight;
    property PeriodoAggiuntivoMs: Cardinal read FPeriodoAggiuntivoMs write FPeriodoAggiuntivoMs;
  end;

// Funzione helper (vedere funzioni !)
function ContaFile(const APath, APattern: string): Integer;

implementation

function ContaFile(const APath, APattern: string): Integer;
// Conta le sessioni esistenti: APattern.csv + APattern_*.csv
// (non usa APattern*.csv, altrimenti il programma "P1" conterebbe anche i file di "P10")
var
  SearchRec: TSearchRec;
  FilePath: string;
begin
  Result := 0;
  if TFile.Exists(TPath.Combine(APath, APattern + '.csv')) then
    Inc(Result);

  FilePath := TPath.Combine(APath, APattern + '_*.csv');

  if FindFirst(FilePath, faAnyFile, SearchRec) = 0 then
  begin
    try
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
          Inc(Result);
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;
end;



{ TWeightFtpMonitor }
constructor TWeightFtpMonitor.Create(const AServerCfg : TServerConfig; const ACodeMap: TDictionary<string,string> );
begin
  inherited Create(AServerCfg, ACodeMap);

  FBaseOutputPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Weight', AServerCfg.NameMachine);

  FStateLock := TCriticalSection.Create;

  // Inizializzo Periodo aggiuntivo  (default 1 secondo)
  FPeriodoAggiuntivoMs := 1000; // 1 secondo
  FInPeriodoAggiuntivo := False;

  // Crea timer per grace period (inizialmente disabilitato)
  FPeriodoAggiuntivoTimer := TTimer.Create(nil);
  FPeriodoAggiuntivoTimer.Enabled := False;
  FPeriodoAggiuntivoTimer.OnTimer := OnPeriodoAggiuntivoTerminato;

  // Inizializza stato vuoto
  FStatoAttuale := Default(TSituazioneXLog);
  FStatoAttuale.ShouldRun := False;
  FHasPending := False;

  if (FBaseOutputPath <> '') and (not TDirectory.Exists(FBaseOutputPath)) then
    TDirectory.CreateDirectory(FBaseOutputPath);
end;

destructor TWeightFtpMonitor.Destroy;
begin
  // 1. Disabilita eventi per evitare callback su oggetto in destroy
  OnWeight := nil;

  // 2. Fermo e libero il timer (niente periodo aggiuntivo in distruzione)
  if Assigned(FPeriodoAggiuntivoTimer) then
  begin
    FPeriodoAggiuntivoTimer.OnTimer := nil;
    FPeriodoAggiuntivoTimer.Enabled := False;
    FreeAndNil(FPeriodoAggiuntivoTimer);
  end;

  // 3. Blocco eventuali AggiornaCondizioni rientranti e fermo subito il thread
  if Assigned(FStateLock) then
  begin
    FStateLock.Enter;
    try
      FInPeriodoAggiuntivo := True;
      FHasPending := False;
    finally
      FStateLock.Leave;
    end;
  end;
  inherited Stop;

  // 4. Salvo ultimo ID prima di distruggere
  if Assigned(FStateLock) then
  begin
    FStateLock.Enter;
    try
      SalvaUltimoIdProcessato(FStatoAttuale.LastIDFile, FUltimoIdProcessato);
    finally
      FStateLock.Leave;
    end;
  end;


  // 5. ORA azzero (dopo aver salvato)
  FUltimoIdProcessato := '';
  FBaseOutputPath := '';


  FStatoAttuale.DsProgram := string.empty;
  FStatoAttuale.PackMode := string.empty;
  FStatoAttuale.OutputFileName := string.empty;
  FStatoAttuale.LastIDFile :=  string.empty;

  // 6. Libero FStateLock
  if Assigned(FStateLock) then
    FreeAndNil(FStateLock);


  // 7. Chiamo inherited (che libera FStopEvent e FLock della classe base)
  inherited;
end;

function TWeightFtpMonitor.BuildOutputFileName(const DsProgram: string): string;
var
  LNomeFile: string;
  lNumSessione: Integer;
  c :char;
const
// CaratteriDaRimuovere = ['\', '/', ':', '*', '?', '"', '<', '>', '|'];
 CaratteriInvalidi: TSysCharSet = ['\', '/', ':', '*', '?', '"', '<', '>', '|'];
begin
  LNomeFile := string.empty;
  for C in DsProgram do
    if not CharInSet(C , CaratteriInvalidi) then
      LNomeFile := LNomeFile + C;

  // yyyymmdd_ProgramNumber
  LNomeFile := Format('%s_%s', [  FormatDateTime('yyyymmdd', Now),Trim(LNomeFile)]);

  // Conta sessioni esistenti
  lNumSessione := ContaFile(IncludeTrailingPathDelimiter(FBaseOutputPath), LNomeFile );

  if lNumSessione > 0 then
    LNomeFile := Format('%s_%d', [LNomeFile, lNumSessione]);

//  LNomeFile := LNomeFile + '.csv';
  Result := TPath.Combine(FBaseOutputPath, LNomeFile + '.csv');

  DoQueueLog(Format('Output file: %s', [LNomeFile + '.csv']));
end;


procedure TWeightFtpMonitor.LeggiUltimoIdProcessato(const ALastIDFile: string);
var
  LUltimoId: string;
begin
  LUltimoId := '';

  if (ALastIDFile = '') or (not TFile.Exists(ALastIDFile)) then
    DoQueueLog('LastID file not found, starting from beginning')
  else
  begin
    try
      LUltimoId := TFile.ReadAllText(ALastIDFile, TEncoding.UTF8).Trim;

      if LUltimoId <> '' then
        DoQueueLog(Format('Resumed from ID: %s', [LUltimoId]))
      else
        DoQueueLog('LastID file empty, starting from beginning');
    except
      on E: Exception do
      begin
        DoQueueLog('Error loading LastID: ' + E.Message);
        LUltimoId := '';
      end;
    end;
  end;

  FStateLock.Enter;
  try
    FUltimoIdProcessato := LUltimoId;
  finally
    FStateLock.Leave;
  end;
end;

procedure TWeightFtpMonitor.OnPeriodoAggiuntivoTerminato(Sender: TObject);
//  Callback chiamata quando il periodo aggiuntivo termina
begin
  // Fermo il timer
  FPeriodoAggiuntivoTimer.Enabled := False;

  // Fermo davvero il thread FTP. FInPeriodoAggiuntivo resta True fino a stop
  // concluso: WaitFor esegue le Synchronize pendenti e può richiamare
  // AggiornaCondizioni, che così si limita a memorizzare le condizioni.
  inherited Stop;

  // Termino il periodo aggiuntivo
  FStateLock.Enter;
  try
    FInPeriodoAggiuntivo := False;
  finally
    FStateLock.Leave;
  end;

  DoQueueLog('Monitor stopped after grace period');

  // Applico le condizioni arrivate durante il periodo aggiuntivo
  // (es. ripartenza macchina o cambio programma): senza questo il monitor
  // resterebbe fermo fino al successivo cambio di stato
  ElaboraCondizioniPendenti;
end;

procedure TWeightFtpMonitor.SalvaUltimoIdProcessato(const ALastIDFile, AUltimoId: string);
begin
  if (ALastIDFile = '') or (AUltimoId = '') then
    Exit;

  try
    TFile.WriteAllText(ALastIDFile, AUltimoId, TEncoding.UTF8);
  except
    on E: Exception do
      DoQueueLog('Error saving LastID: ' + E.Message);
  end;
end;

function TWeightFtpMonitor.VariabileDaLeggere(const AKey: string): Boolean;
begin
  // Accetto tutte le chiavi: il file pesi ha chiavi numeriche
  // non presenti in FCodeMap
  // non deve essere fatto alcun filtro
  Result := True;
end;

procedure TWeightFtpMonitor.Stop;
//  Override Stop con periodo aggiuntivo NON BLOCCANTE
begin
  // Niente da fermare: evito di avviare il periodo aggiuntivo a vuoto
  if not Assigned(FThread) then
    Exit;

  // Controlla se siamo gi� in grace period
  FStateLock.Enter;
  try
    if FInPeriodoAggiuntivo then
    begin
      DoQueueLog('Stop already in progress (grace period active)');
      Exit;
    end;

    FInPeriodoAggiuntivo := True;
  finally
    FStateLock.Leave;
  end;

  DoQueueLog(Format('Stop requested, grace period active for %d ms', [FPeriodoAggiuntivoMs]));


  // Uso TTimer invece di Sleep - NON blocca la UI
  //    Il thread FTP continua a girare per altri FPeriodoAggiuntivoMs millisecondi
  FPeriodoAggiuntivoTimer.Interval := FPeriodoAggiuntivoMs;
  FPeriodoAggiuntivoTimer.Enabled := True;

  // Il timer chiamer� OnPeriodoAggiuntivoTerminato dopo FPeriodoAggiuntivoMs millisecondi
  // Nel frattempo:
  // - UI rimane responsive
  // - Thread FTP continua a scaricare dati

end;

procedure TWeightFtpMonitor.AggiornaCondizioni(const AProgram: string; AInstart: Boolean; const APackMode: string);
var
  InAggiuntaPeriodo: Boolean;
begin
  // Memorizzo sempre le ultime condizioni ricevute
  FStateLock.Enter;
  try
    FPendProgram := Trim(AProgram);
    FPendInStart := AInstart;
    FPendPackMode := Trim(APackMode);
    FHasPending := True;
    InAggiuntaPeriodo := FInPeriodoAggiuntivo;
  finally
    FStateLock.Leave;
  end;

  // In periodo aggiuntivo NON scarto il cambio: verrà applicato
  // da OnPeriodoAggiuntivoTerminato a thread fermo
  if InAggiuntaPeriodo then
  begin
    DoQueueLog('Cambio stato posticipato (periodo aggiuntivo in corso)');
    Exit;
  end;

  ElaboraCondizioniPendenti;
end;

procedure TWeightFtpMonitor.ElaboraCondizioniPendenti;
var
  NewState: TSituazioneXLog;
  StatoCorrente: TSituazioneXLog;
  NomeProgramma: string;
begin
  NewState := Default(TSituazioneXLog);

  FStateLock.Enter;
  try
    if not FHasPending then
      Exit;
    NewState.DsProgram := FPendProgram;
    NewState.InStart := FPendInStart;
    NewState.PackMode := FPendPackMode;
    StatoCorrente := FStatoAttuale;
  finally
    FStateLock.Leave;
  end;

  // Cambio programma con thread attivo: prima fermo il thread con il periodo
  // aggiuntivo (che continua a scrivere sul file del programma precedente).
  // Le condizioni restano pendenti e vengono applicate a stop concluso.
  if (NewState.DsProgram <> StatoCorrente.DsProgram) and Assigned(FThread) then
  begin
    Stop;
    Exit;
  end;

  FStateLock.Enter;
  try
    FHasPending := False;
  finally
    FStateLock.Leave;
  end;

  // Calcolo se dovrebbe girare in base allo stato macchina
  NewState.ShouldRun := NewState.InStart and
                        (NewState.PackMode <> '3') and
                        (NewState.PackMode <> '4');

  if (NewState.DsProgram = StatoCorrente.DsProgram) and (StatoCorrente.OutputFileName <> '') then
  begin
    // Programma invariato: riutilizzo i percorsi dello stato corrente
    NewState.OutputFileName := StatoCorrente.OutputFileName;
    NewState.LastIDFile := StatoCorrente.LastIDFile;
  end
  else
  begin
    // Programma cambiato (o primo avvio): nuovo file di sessione
    if NewState.DsProgram <> '' then
      NomeProgramma := NewState.DsProgram
    else
      NomeProgramma := 'BlankProgramm';
    NewState.OutputFileName := BuildOutputFileName(NomeProgramma);
    NewState.LastIDFile := ChangeFileExt(NewState.OutputFileName, '.lastid');
  end;

  ApplicaCambioSituazione(NewState);
end;

procedure TWeightFtpMonitor.ApplicaCambioSituazione(const NuovaSituazione: TSituazioneXLog);
// Chiamata solo da ElaboraCondizioniPendenti: se cambia il file di output
// il thread è sicuramente fermo
var
  VecchiaSituazione: TSituazioneXLog;
  CambioStato: Boolean;
  CambioFile: Boolean;
begin
  FStateLock.Enter;
  try
    VecchiaSituazione := FStatoAttuale;
    CambioStato := NuovaSituazione.HasChanged(VecchiaSituazione);
    CambioFile := NuovaSituazione.LastIDFile <> VecchiaSituazione.LastIDFile;

    // Salvo ultimo ID del file vecchio
    if CambioFile then
      SalvaUltimoIdProcessato(VecchiaSituazione.LastIDFile, FUltimoIdProcessato);

    FStatoAttuale := NuovaSituazione;
  finally
    FStateLock.Leave;
  end;

  if CambioStato then
    DoQueueLog(Format('State change: Prog=%s, Run=%s, Mode=%s', [
      NuovaSituazione.DsProgram,
      BoolToStr(NuovaSituazione.InStart, True),
      NuovaSituazione.PackMode
    ]));

  if CambioFile then
  begin
    // Carico ultimo ID del file nuovo
    LeggiUltimoIdProcessato(NuovaSituazione.LastIDFile);

    if NuovaSituazione.OutputFileName <> '' then
    begin
      DoQueueLog('Output file: ' + ExtractFileName(NuovaSituazione.OutputFileName));
      DoQueueLog('LastID file: ' + ExtractFileName(NuovaSituazione.LastIDFile));
    end;
  end;

  // Allineo sempre il thread allo stato desiderato (Start/Stop loggano già)
  if NuovaSituazione.ShouldRun and NuovaSituazione.IsValid then
  begin
    if not Assigned(FThread) then
      Start;
  end
  else if Assigned(FThread) then
    Stop;
end;

function TWeightFtpMonitor.GetCurrentState: TSituazioneXLog;
begin
  FStateLock.Enter;
  try
    Result := FStatoAttuale;
  finally
    FStateLock.Leave;
  end;
end;

procedure TWeightFtpMonitor.ParseRigaPesi(const Line: string; out WeightData: TWeightRecord);
var
  Parts: TArray<string>;
  Values: TArray<string>;
begin
  // Default() e non FillChar: il record contiene stringhe (tipi gestiti)
  WeightData := Default(TWeightRecord);
  WeightData.RawLine := Line;

  Parts := Line.Split(['=']);
  if Length(Parts) < 2 then
    Exit;

  WeightData.ID := Parts[0];

  Values := Parts[1].Split([';']);
  if Length(Values) < 6 then
    Exit;

  WeightData.PartNumber := Values[0];
  WeightData.Time := Values[1];

  WeightData.ValA := StrToIntDef(StringReplace(Values[2], '.', '', []), 0);
  WeightData.ValB := StrToIntDef(StringReplace(Values[3], '.', '', []), 0);
  WeightData.ValC := StrToIntDef(StringReplace(Values[4], '.', '', []), 0);
  WeightData.ValD := StrToIntDef(StringReplace(Values[5], '.', '', []), 0);

  if Length(Values) > 6 then
    WeightData.Counter := StrToIntDef(Values[6], 0);
end;

procedure TWeightFtpMonitor.ProcessaDatiPesi(const APairs: TStringList);
var
  i, StartIndex: Integer;
  Line: string;
  WeightData: TWeightRecord;
  AttualeOutputFileName, AttualeLastIDFile: string;
  ProcessedCount: Integer;
  LocalOnWeight : TWeightEvent;
  UltimoIdIniziale, UltimoId: string;
  Righe: TStringBuilder;
begin
  // FUltimoIdProcessato è condiviso con il thread principale:
  // lavoro su una copia locale e la riscrivo sotto lock alla fine
  FStateLock.Enter;
  try
    LocalOnWeight := FOnWeight;
    AttualeOutputFileName := FStatoAttuale.OutputFileName;
    AttualeLastIDFile := FStatoAttuale.LastIDFile;
    UltimoIdIniziale := FUltimoIdProcessato;
  finally
    FStateLock.Leave;
  end;
  UltimoId := UltimoIdIniziale;

  if AttualeOutputFileName = '' then
  begin
    DoQueueLog('File name to downaload not set, skipping weight data processing');
    Exit;
  end;

  StartIndex := 0;
  ProcessedCount := 0;

  // Cerco ultimo ID processato per evitare duplicati
  if UltimoId <> '' then
  begin
    for i := 0 to APairs.Count - 1 do
    begin
      Line := APairs[i];
      if Line.StartsWith(UltimoId + '=') then
      begin
        StartIndex := i + 1;
        Break;
      end;
    end;
  end;

  // Accumulo le righe e scrivo il CSV una sola volta per ciclo
  // (prima il file veniva aperto/chiuso per ogni riga)
  Righe := TStringBuilder.Create;
  try
    // Processo righe nuove
    for i := StartIndex to APairs.Count - 1 do
    begin
      Line := APairs[i];
      if Line.Trim = '' then
        Continue;

      ParseRigaPesi(Line, WeightData);

      if WeightData.ID = '' then
        Continue;

      UltimoId := WeightData.ID;

      if WeightData.HasNonZeroWeight then
      begin
        Inc(ProcessedCount);
        Righe.AppendFormat('%s;%s;%s'#13#10, [
          WeightData.ID,
          WeightData.GetNonZeroChannel,
          WeightData.GetNonZeroValue
        ]);

        if Assigned(LocalOnWeight) then
          QueueWeight(LocalOnWeight, WeightData);
      end;
    end;

    if Righe.Length > 0 then
    try
      TFile.AppendAllText(AttualeOutputFileName, Righe.ToString, TEncoding.UTF8);
    except
      on E: Exception do
        DoQueueLog('Write error: ' + E.Message);
    end;
  finally
    Righe.Free;
  end;

  // Salvo ultimo ID dopo processing (anche se le righe nuove avevano peso zero)
  if UltimoId <> UltimoIdIniziale then
  begin
    FStateLock.Enter;
    try
      FUltimoIdProcessato := UltimoId;
    finally
      FStateLock.Leave;
    end;
    SalvaUltimoIdProcessato(AttualeLastIDFile, UltimoId);
    if ProcessedCount > 0 then
      DoQueueLog(Format('Processed %d records, LastID: %s', [ProcessedCount, UltimoId]));
  end;
end;

procedure TWeightFtpMonitor.QueueWeight(const AOnWeight: TWeightEvent; const AData: TWeightRecord);
// Metodo separato: la closure cattura una copia del record per ogni chiamata.
// Catturando direttamente la variabile del ciclo tutte le callback
// accodate avrebbero ricevuto l'ultimo record.
var
  LData: TWeightRecord;
  LOnWeight: TWeightEvent;
begin
  LData := AData;
  LOnWeight := AOnWeight;
  TThread.Queue(TThread.CurrentThread,
    procedure
    begin
      try
        LOnWeight(Self, LData);
      except
      end;
    end);
end;

procedure TWeightFtpMonitor.DoQueueParsed(const APairs: TStringList);
var
  localOnParsed: TParsedEvent;
begin
  ProcessaDatiPesi(APairs);

  // Se c'� un handler OnParsed collegato, lo chiamo direttamente
  // nel thread principale (senza passare per inherited che farebbe
  // una copia ridondante e un lock aggiuntivo)
  localOnParsed := OnParsed;
  if Assigned(localOnParsed) then
  begin
    TThread.Synchronize(nil,
      procedure
      begin
        try
          localOnParsed(Self, APairs);
        except
          // Ignoro errori nell'handler utente
        end;
      end);
  end;
end;

end.
