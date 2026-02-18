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



    procedure ParseRigaPesi(const Line: string; out WeightData: TWeightRecord);
    procedure ProcessaDatiPesi(const APairs: TStringList);
    procedure ApplicaCambioSituazione (const NuovaSituazione: TSituazioneXLog);
    function BuildOutputFileName(const DsProgram: string): string;
    procedure LeggiUltimoIdProcessato(const ALastIDFile: string);
    procedure SalvaUltimoIdProcessato(const ALastIDFile: string);

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
var
  SearchRec: TSearchRec;
  FilePath: string;
begin
  Result := 0;
  FilePath := TPath.Combine(APath, APattern + '*.csv');

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
  FillChar(FStatoAttuale, SizeOf(FStatoAttuale), 0);
  FStatoAttuale.ShouldRun := False;

  if (FBaseOutputPath <> '') and (not TDirectory.Exists(FBaseOutputPath)) then
    TDirectory.CreateDirectory(FBaseOutputPath);
end;

destructor TWeightFtpMonitor.Destroy;
begin
  // 1. Disabilita eventi per evitare callback su oggetto in destroy
  OnWeight := nil;


  stop;


  // 2. Fermo e libero il timer
  if Assigned(FPeriodoAggiuntivoTimer) then
  begin
    FPeriodoAggiuntivoTimer.OnTimer := nil;
    FPeriodoAggiuntivoTimer.Enabled := False;
    FreeAndNil(FPeriodoAggiuntivoTimer);
  end;




  // 4. Salvo ultimo ID
  // salvo ultimo ID prima di distruggere
  if Assigned(FStateLock) then
  begin
    FStateLock.Enter;
    try
      if (FStatoAttuale.LastIDFile <> '') and (FUltimoIdProcessato <> '') then
        SalvaUltimoIdProcessato(FStatoAttuale.LastIDFile);
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
begin
  FUltimoIdProcessato := '';

  if (ALastIDFile = '') or (not TFile.Exists(ALastIDFile)) then
  begin
    DoQueueLog('LastID file not found, starting from beginning');
    Exit;
  end;

  try
    FUltimoIdProcessato := TFile.ReadAllText(ALastIDFile, TEncoding.UTF8).Trim;

    if FUltimoIdProcessato <> '' then
      DoQueueLog(Format('Resumed from ID: %s', [FUltimoIdProcessato]))
    else
      DoQueueLog('LastID file empty, starting from beginning');
  except
    on E: Exception do
    begin
      DoQueueLog('Error loading LastID: ' + E.Message);
      FUltimoIdProcessato := '';
    end;
  end;
end;

procedure TWeightFtpMonitor.OnPeriodoAggiuntivoTerminato(Sender: TObject);
//  Callback chiamata quando il periodo aggiuntivo termina
begin
  // Fermo il timer
  FPeriodoAggiuntivoTimer.Enabled := False;

  // Termino il periodo aggiuntivo
  FStateLock.Enter;
  try
    FInPeriodoAggiuntivo := False;
  finally
    FStateLock.Leave;
  end;

  // Ora ferma davvero il thread FTP
  inherited Stop;

  DoQueueLog('Monitor stopped after grace period');
end;

procedure TWeightFtpMonitor.SalvaUltimoIdProcessato(const ALastIDFile: string);
begin
  if (ALastIDFile = '') or (FUltimoIdProcessato = '') then
    Exit;

  try
    // Scrivi atomicamente
    TFile.WriteAllText(ALastIDFile, FUltimoIdProcessato, TEncoding.UTF8);
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
  // Controlla se siamo già in grace period
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

  // Il timer chiamerà OnPeriodoAggiuntivoTerminato dopo FPeriodoAggiuntivoMs millisecondi
  // Nel frattempo:
  // - UI rimane responsive
  // - Thread FTP continua a scaricare dati

end;

procedure TWeightFtpMonitor.AggiornaCondizioni(const AProgram: string; AInstart: Boolean; const APackMode: string);
var
  NewState: TSituazioneXLog;
  CurrentProgram: string;
  InAggiuntaPeriodo: Boolean;
begin
  // Controllo se siamo in periodo aggiuntivo
  FStateLock.Enter;
  try
    InAggiuntaPeriodo := FInPeriodoAggiuntivo;
  finally
    FStateLock.Leave;
  end;

  // Se siamo in grace period, ignora i cambiamenti di stato
  if InAggiuntaPeriodo then
  begin
    DoQueueLog('Ignorato cambio stato - AggiornaCondizioni (in periodo aggiuntivo)');
    Exit;
  end;

  NewState.DsProgram := Trim(AProgram);
  NewState.InStart := AInstart;
  NewState.PackMode := Trim(APackMode);

  // Calcolo se dovrebbe girare in base allo stato macchina
  NewState.ShouldRun := NewState.InStart and
                        (NewState.PackMode <> '3') and
                        (NewState.PackMode <> '4');

  // Leggo il programma corrente in modo thread-safe
  FStateLock.Enter;
  try
    CurrentProgram := FStatoAttuale.DsProgram;
  finally
    FStateLock.Leave;
  end;

  // Costruisco il nome file SOLO se il programma è cambiato (o primo avvio)
  if (NewState.DsProgram <> '') and (NewState.DsProgram <> CurrentProgram) then
  begin
    NewState.OutputFileName := BuildOutputFileName(NewState.DsProgram);
    NewState.LastIDFile := ChangeFileExt(NewState.OutputFileName, '.lastid');
  end
  else if NewState.DsProgram <> '' then
  begin
    // Programma invariato: riutilizzo i percorsi dello stato corrente
    FStateLock.Enter;
    try
      NewState.OutputFileName := FStatoAttuale.OutputFileName;
      NewState.LastIDFile := FStatoAttuale.LastIDFile;
    finally
      FStateLock.Leave;
    end;
  end
  else
  begin
//    NewState.OutputFileName := '';
//    NewState.LastIDFile := '';
    NewState.OutputFileName := BuildOutputFileName('BlankProgramm');
    NewState.LastIDFile := ChangeFileExt(NewState.OutputFileName, '.lastid');;


  end;

  // Applico il cambio di stato IMMEDIATAMENTE
  ApplicaCambioSituazione(NewState);
end;

procedure TWeightFtpMonitor.ApplicaCambioSituazione(const NuovaSituazione: TSituazioneXLog);
var
  VecchiaSituazione: TSituazioneXLog;
  NeedRestart: Boolean;
begin
  FStateLock.Enter;
  try
    VecchiaSituazione := FStatoAttuale;

    if not NuovaSituazione.HasChanged(VecchiaSituazione) then
      Exit;

    // Salvo ultimo ID del file vecchio
    if (VecchiaSituazione.LastIDFile <> '') and (FUltimoIdProcessato <> '') then
      SalvaUltimoIdProcessato(VecchiaSituazione.LastIDFile);

    FStatoAttuale := NuovaSituazione;
    NeedRestart := (NuovaSituazione.DsProgram <> VecchiaSituazione.DsProgram);
  finally
    FStateLock.Leave;
  end;

  DoQueueLog(Format('State change: Prog=%s, Run=%s, Mode=%s', [
    NuovaSituazione.DsProgram,
    BoolToStr(NuovaSituazione.InStart, True),
    NuovaSituazione.PackMode
  ]));

  if NeedRestart then
  begin
    if Assigned(FThread) then
      Stop;

    // Carico ultimo ID del file nuovo
    LeggiUltimoIdProcessato(NuovaSituazione.LastIDFile);

    if NuovaSituazione.OutputFileName <> '' then
    begin
//      OutputFilePath := NewState.OutputFileName;
      DoQueueLog('Output file: ' + ExtractFileName(NuovaSituazione.OutputFileName));
      DoQueueLog('LastID file: ' + ExtractFileName(NuovaSituazione.LastIDFile));
    end;
  end;

  if NuovaSituazione.ShouldRun and NuovaSituazione.IsValid then
  begin
    if not Assigned(FThread) then
    begin
      Start;
      DoQueueLog('Monitor started');
    end;
  end
  else
  begin
    if Assigned(FThread) then
    begin
      Stop;
      DoQueueLog('Monitor stopped');
    end;
  end;
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
  FillChar(WeightData, SizeOf(WeightData), 0);
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
begin
  FStateLock.Enter;
  try
    LocalOnWeight := FOnWeight;
    AttualeOutputFileName := FStatoAttuale.OutputFileName;
    AttualeLastIDFile := FStatoAttuale.LastIDFile;
  finally
    FStateLock.Leave;
  end;

  if AttualeOutputFileName = '' then
  begin
    DoQueueLog('File name to downaload not set, skipping weight data processing');
    Exit;
  end;

  StartIndex := 0;
  ProcessedCount := 0;

  // Cerco ultimo ID processato per evitare duplicati
  if FUltimoIdProcessato <> '' then
  begin
    for i := 0 to APairs.Count - 1 do
    begin
      Line := APairs[i];
      if Line.StartsWith(FUltimoIdProcessato + '=') then
      begin
        StartIndex := i + 1;
        Break;
      end;
    end;
  end;

  // Processo righe nuove
  for i := StartIndex to APairs.Count - 1 do
  begin
    Line := APairs[i];
    if Line.Trim = '' then
      Continue;

    ParseRigaPesi(Line, WeightData);

    if WeightData.ID = '' then
      Continue;

    FUltimoIdProcessato := WeightData.ID;

    if WeightData.HasNonZeroWeight then
    begin
      Inc(ProcessedCount);
      try
        TFile.AppendAllText(
          AttualeOutputFileName,
          Format('%s;%s;%s'#13#10, [
            WeightData.ID,
            WeightData.GetNonZeroChannel,
            WeightData.GetNonZeroValue
          ]),
          TEncoding.UTF8
        );

      except
        on E: Exception do
          DoQueueLog('Write error: ' + E.Message);
      end;


//      if Assigned(FOnWeight) then
      if Assigned(LocalOnWeight) then
      begin
        TThread.Queue(nil,
          procedure
          var
            LocalData: TWeightRecord;
          begin
            LocalData := WeightData;
            try
//              FOnWeight(Self, LocalData);
              LocalOnWeight(Self, LocalData);
            except
            end;
          end);
      end;
    end;
  end;

  // Salvo ultimo ID dopo processing
  if (ProcessedCount > 0) and (FUltimoIdProcessato <> '') and (AttualeLastIDFile <> '') then
  begin
    SalvaUltimoIdProcessato(AttualeLastIDFile);
    DoQueueLog(Format('Processed %d records, LastID: %s', [ProcessedCount, FUltimoIdProcessato]));
  end;
end;

procedure TWeightFtpMonitor.DoQueueParsed(const APairs: TStringList);
var
  localOnParsed: TParsedEvent;
begin
  ProcessaDatiPesi(APairs);

  // Se c'è un handler OnParsed collegato, lo chiamo direttamente
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
