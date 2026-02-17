unit UnitFtpMonitor;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.IOUtils,
  IdFTP, IdComponent, IdTCPClient, IdBaseComponent
  ,IdFtpCommon
  ,System.SyncObjs, TypeUnit
  , Winapi.Windows
  , vcl.Forms
  ;

type
  TFtpMonitor = class; // forward

  TParsedEvent = procedure(Sender: TObject; APairs: TStringList) of object;
  TLogEvent = procedure(Sender: TObject; const Msg: string) of object;
  TErrorEvent = procedure(Sender: TObject; E: Exception) of object;
  TFTPStatusEvent = procedure(const Status: string; Operation:  TIdStatus) of object;

  // Thread dichiarato a livello di unit (non annidato)
  TMonitorThread = class(TThread)
  private
    FOwner: TFtpMonitor;
    FIdFTP: TIdFTP;

  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TFtpMonitor);
    destructor Destroy; override;
  end;

  TFtpMonitor = class(TObject)
  private
    FServerCfg : TServerConfig;
    FIntervalMs: Integer;
    FRemoteFileDownload: String;

    FCodeMap: TDictionary<string,string>; // riferimento esterno (non owned)
    FStopEvent: TEvent; // evento per wakeup immediato
    FLock: TCriticalSection; // protezione thread-safety

    FOnParsed: TParsedEvent;
    FOnLog: TLogEvent;
    FOnError: TErrorEvent;
    FStatusEvent: TFTPStatusEvent;

    procedure DoQueueError(E: Exception);
    procedure OnFTPStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
  protected
    FThread: TMonitorThread;
    procedure DoQueueParsed(const APairs: TStringList); virtual;
    procedure DoQueueLog(const Msg: string); virtual;
  public
    constructor Create(const AServerCfg : TServerConfig; const ACodeMap: TDictionary<string,string>);
    destructor Destroy; override;

    procedure Start;
    procedure Stop;

   function ThreadInEsecuzione: Boolean;
   function AttendoCompletamento (TimeoutMs: Cardinal = 2000): Boolean;


    // Proprietà pubbliche di rapido accesso
    property IntervalMs: Integer read FIntervalMs write FIntervalMs;
//    property OutputFilePath: string read GetOutputFilePath write SetOutputFilePath;
//    property WatchKeys: TArray<string> read FWatchKeys write FWatchKeys;
//    property WatchKeys: TArray<string> read GetWatchKeys write SetWatchKeys;

    // Eventi
    property OnParsed: TParsedEvent read FOnParsed write FOnParsed;
    property OnLog: TLogEvent read FOnLog write FOnLog;
    property OnError: TErrorEvent read FOnError write FOnError;
    property OnStatus: TFTPStatusEvent read FStatusEvent write FStatusEvent;

    // Riferimento alla mappa (read-only)
    property CodeMap: TDictionary<string,string> read FCodeMap;

    property RemoteFileDownload : String read FRemoteFileDownload write FRemoteFileDownload;
  end;

implementation

uses
  System.StrUtils,  System.Types;

{ TMonitorThread }

constructor TMonitorThread.Create(AOwner: TFtpMonitor);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FOwner := AOwner;
end;

destructor TMonitorThread.Destroy;
begin
  try
    if Assigned(FIdFTP) then
    begin
      try
        if FIdFTP.Connected then
          FIdFTP.Disconnect;
      except
      end;
      FreeAndNil(FIdFTP);
    end;
  finally
    inherited;
  end;
end;

procedure TMonitorThread.Execute;
const
  RETRY_DELAY_MS = 1000;
var
  ms: TMemoryStream;
  ss: TStringStream;
  txt: string;
  lines: TStringList;
  pairs: TStringList;
  i: Integer;
  line: string;
  attemptConnect: Boolean;
  waitRes: TWaitResult;
  localHost: string;
  localPort: Integer;
  localUser: string;
  localPass: string;
  localRemoteFile: string;
begin

  // Copia thread-safe dei parametri di configurazione
  FOwner.FLock.Enter;
  try
    localHost := FOwner.FServerCfg.Host;
    localPort := FOwner.FServerCfg.Port;
    localUser := FOwner.FServerCfg.Username;
    localPass := FOwner.FServerCfg.Password;
    localRemoteFile := FOwner.RemoteFileDownload ;
  finally
    FOwner.FLock.Leave;
  end;



  FIdFTP := TIdFTP.Create(nil);
  try
    FIdFTP.TransferType := ftASCII;
    FIdFTP.Passive := True;
    FIdFTP.Host := localHost;
    FIdFTP.Port := localPort;
    FIdFTP.Username := localUser;
    FIdFTP.Password := localPass;
    FIdFTP.ConnectTimeout := 5000;
    FIdFTP.ReadTimeout := 5000;
    FIdFTP.OnStatus := FOwner.OnFTPStatus;

    attemptConnect := True;
    while not Terminated do
    begin
      if attemptConnect then
      begin
        try
          if not FIdFTP.Connected then
            FIdFTP.Connect;
          attemptConnect := False;
          FOwner.DoQueueLog('FTP connected successfully');
        except
          on E: Exception do
          begin
            attemptConnect := True;
            FOwner.DoQueueLog('FTP connect failed, retrying...');
//          Sleep(RETRY_DELAY_MS);
            waitRes := FOwner.FStopEvent.WaitFor(RETRY_DELAY_MS);
            if waitRes <> wrTimeout then
             break;    //evento di stop
            Continue;
          end;
        end;
      end;

      ms := TMemoryStream.Create;
      try
        try
          FIdFTP.Get(FOwner.RemoteFileDownload, ms, False);
          ms.Position := 0;
          ss := TStringStream.Create('', TEncoding.UTF8);
          try
            ss.CopyFrom(ms, 0);
            txt := ss.DataString;
             FOwner.DoQueueLog('Download file and convert it to text');
          finally
            ss.Free;
          end;

          pairs := TStringList.Create;
          try
            pairs.NameValueSeparator := '=';
            lines := TStringList.Create;
            try
              lines.Text := txt;
              for i := 0 to lines.Count - 1 do
              begin
                line := Trim(lines[i]);
                if line = '' then
                  Continue;
                if (Length(line) >= 2) and (line[1] = '/') and (line[2] = '/') then
                  Continue;
                line := StringReplace(line, #9, ' ', [rfReplaceAll]);
                var p := Pos('=', line);
                if p > 0 then
                begin
                  var key := Trim(Copy(line, 1, p-1));
                  var val := Trim(Copy(line, p+1, MaxInt));
                  if key <> '' then
//                  if (key <> '') and FOwner.FCodeMap.ContainsKey(key) then
                  begin
               //     if FOwner.FCodeMap.ContainsKey(key) then
                      pairs.Values[key] := val;
                  end;
                end;
              end;
            finally
              lines.Free;
            end;

            // consegno i pairs al proprietario (quest'ultimo farà Queue e libererà la copia)
            FOwner.DoQueueParsed(pairs);
          finally
            pairs.Free;
          end;

        except
          on E: Exception do
          begin
            attemptConnect := True;
            try
              if FIdFTP.Connected then
                FIdFTP.Disconnect;
            except
            end;
            FOwner.DoQueueError(E);
//            Sleep(RETRY_DELAY_MS);
            // attendi con possibilità di sveglio immediato tramite evento Stop
            waitRes := FOwner.FStopEvent.WaitFor(RETRY_DELAY_MS);
            if waitRes <> wrTimeout then
              Break;
          end;
        end;
      finally
        ms.Free;
      end;

//      Sleep(FOwner.FIntervalMs);
       // Invece di Sleep: aspetto l'evento con timeout (così Stop sveglia subito il thread)
      waitRes := FOwner.FStopEvent.WaitFor(FOwner.FIntervalMs);
      if waitRes <> wrTimeout then
        Break; // evento segnalato => uscire
    end;
  finally
    try
      if Assigned(FIdFTP) and FIdFTP.Connected then
        FIdFTP.Disconnect;
    except
    end;
    FreeAndNil(FIdFTP);
  end;
end;

{ TFtpMonitor }

constructor TFtpMonitor.Create(const AServerCfg : TServerConfig; const ACodeMap: TDictionary<string,string>);
begin
  inherited Create;
  FServerCfg := AServerCfg;
  FCodeMap := ACodeMap;
  if FServerCfg.Intervall > 0  then
    FIntervalMs := FServerCfg.Intervall
  else
    FIntervalMs := 200;

  FRemoteFileDownload := FServerCfg.FileName;

  // evento auto-reset (ManualReset = False) inizialmente non segnalato
  FStopEvent := TEvent.Create(nil, False, False, '');

   // Critical section per thread-safety
  FLock := TCriticalSection.Create;
end;

destructor TFtpMonitor.Destroy;
begin
  FCodeMap := nil;

  Stop; // mi assicuro che il thread sia fermo
//  FreeAndNil(FLastValues);


  // libero il thread se ancora assegnato dopo Stop
  if Assigned(FThread) then
  begin
    FThread.Terminate;
    FThread.WaitFor;  // Aspetta terminazione forzata
    FreeAndNil(FThread);
  end;



  if Assigned(FStopEvent) then
  begin
    FreeAndNil(FStopEvent);
//    DoQueueLog('FStopEvent freed'); // Debug
  end;

  if Assigned(FLock) then
  begin
    FreeAndNil(FLock);
  //  DoQueueLog('FLock freed'); // Debug
  end;


  FServerCfg.Inizializza;



  inherited;
end;

function TFtpMonitor.AttendoCompletamento(TimeoutMs: Cardinal): Boolean;
var
  StartTime: Cardinal;
begin
  Result := True;

  if not Assigned(FThread) then
    Exit;

  StartTime := GetTickCount ;

  // Aspetta che il thread finisca, controllando il timeout
  while not FThread.Finished do
  begin
    if GetTickCount - StartTime > TimeoutMs then
    begin
      Result := False; // Timeout scaduto
      DoQueueLog('Warning: Thread did not finish within timeout');
      Break;
    end;

    Sleep(10);
    Application.ProcessMessages;
  end;

end;

procedure TFtpMonitor.Start;
begin
  if Assigned(FThread) then
    Exit;

  // mi assicuro che l'evento sia resettato prima di avviare
  if Assigned(FStopEvent) then
    FStopEvent.ResetEvent;

  FThread := TMonitorThread.Create(Self);
  DoQueueLog('Monitor started');
end;

procedure TFtpMonitor.Stop;
var
  waited: Integer;
  MaxWaitMs: Integer;
begin
  if not Assigned(FThread) then
    Exit;

  MaxWaitMs := 2000;

  // Segnalo l'evento per svegliare immediatamente il thread se è in WaitFor
  // 1) Segnalo l'evento: se il thread è in WaitFor(IntervalMs) esce subito
  if Assigned(FStopEvent) then
    FStopEvent.SetEvent;

  // 2) Imposto Terminate per sicurezza (il thread controlla anche "Terminated" nel while)
  FThread.Terminate;

{  if Assigned(FThread) then
  begin
    FThread.Terminate;
    FThread.WaitFor;
    FreeAndNil(FThread);
    DoQueueLog('Monitor stopped');
  end;
  }
  // Imposto anche Terminate per sicurezza
{  if Assigned(FThread) then
  begin
    FThread.Terminate;

      FThread.WaitFor;
    FreeAndNil(FThread);
    DoQueueLog('Monitor stopped');

  end;}

  // 3) Polling con timeout: aspetto che il thread termini senza bloccare indefinitamente
  // Aspetto per un breve tempo (il thread dovrebbe uscire velocemente grazie all'evento);
  // non blocco indefinitamente l'UI: attendo fino a un timeout ragionevole
  waited := 0;
  while Assigned(FThread) and (not FThread.Finished) and (waited < MaxWaitMs) do
   // and (waited < 2000) do
  begin
    Sleep(10);
    Inc(waited, 10);
    Application.ProcessMessages; // Permetto al thread di completare
  end;

  // 4) Libero solo se il thread è effettivamente finito
  // Se il thread è terminato, lo libero
  if Assigned(FThread) and FThread.Finished then
  begin
    FreeAndNil(FThread);
    DoQueueLog('Monitor stopped');
  end
  else
  begin
    // Se non è ancora terminato dopo il timeout, lasco che venga liberato altrove.
    DoQueueLog('Stop: thread did not finish within timeout; will be freed later');
      // Il thread verrà comunque liberato dal destructor
  end;

end;

function TFtpMonitor.ThreadInEsecuzione: Boolean;
begin
  Result := Assigned(FThread) and not FThread.Finished;
end;

procedure TFtpMonitor.DoQueueError(E: Exception);
var
  localOnError: TErrorEvent;
begin
  FLock.Enter;
  try
    localOnError := FOnError;
  finally
    FLock.Leave;
  end;

  if Assigned(localOnError) then
    TThread.Queue(nil,
      procedure
      begin
        try
         // FOnError(Self, E);
         localOnError(Self, E);
        except
        end;
      end);
end;

procedure TFtpMonitor.DoQueueLog(const Msg: string);
var
  localOnLog: TLogEvent;
begin
  FLock.Enter;
  try
    localOnLog := FOnLog;
  finally
    FLock.Leave;
  end;
  if Assigned(localOnLog) then
    TThread.Queue(nil,
      procedure
      begin
        try
        //  FOnLog(Self, Msg);
         localOnLog(Self, Msg);
        except
        end;
      end);
end;

{
procedure TFtpMonitor.DoQueueParsed(const APairs: TStringList);
var
  FilteredPairs : TStringList ;
  i: Integer;
  key, val: string;
  localOnParsed: TParsedEvent;
begin
// ========================================
  // SEZIONE PROTETTA: copia atomica e check
  // ========================================
  FLock.Enter;
  try
    // 1. Copia locale delle proprietà condivise
    localOnParsed := FOnParsed;

    // Creo una copia filtrata solo se c'è un handler
    if Assigned(localOnParsed) and assigned(FCodeMap ) then
    begin
      FilteredPairs := TStringList.Create;
      FilteredPairs.NameValueSeparator := '=';

      // copio solo le chiavi presenti in FCodeMap
      for i:= 0 to APairs.Count -1 do
      begin
        key := APairs.Names[i];
        if (key <> '' ) and FCodeMap.ContainsKey(key) then
        begin
          val := APairs.ValueFromIndex[i];
          FilteredPairs.Values[key] := val;
        end;
      end;

    end
    else
      FilteredPairs := nil;
  finally
    FLock.Leave;
  end;

  if Assigned(FilteredPairs) then
  begin
    TThread.Synchronize(nil,
      procedure
      begin
        try
          localOnParsed(Self, FilteredPairs);
        finally
          FilteredPairs.Free;
        end;
      end) ;

  end;
end;
 }


 procedure TFtpMonitor.DoQueueParsed(const APairs: TStringList);
var
  FilteredPairs : TStringList ;
//  i: Integer;
//  key, val: string;
  localOnParsed: TParsedEvent;
begin
// ========================================
  // SEZIONE PROTETTA: copia atomica e check
  // ========================================
  FLock.Enter;
  try
    // 1. Copia locale delle proprietà condivise
    localOnParsed := FOnParsed;

    // Creo una copia filtrata solo se c'è un handler
    if Assigned(localOnParsed) and assigned(FCodeMap ) then
    begin
      FilteredPairs := TStringList.Create;
//      FilteredPairs.NameValueSeparator := '=';
      // Copio tutto il contenuto di APairs
      FilteredPairs.Assign(APairs);
    end
    else
      FilteredPairs := nil;
  finally
    FLock.Leave;
  end;

  if Assigned(FilteredPairs) then
  begin
    TThread.Synchronize(nil,
      procedure
      begin
        try
          localOnParsed(Self, FilteredPairs);
        finally
          FilteredPairs.Free;
        end;
      end) ;
  end;
end;




procedure TFtpMonitor.OnFTPStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
begin
  if assigned (FStatusEvent) then
    TThread.Queue(nil,
    procedure
    begin
       FStatusEvent(AStatusText, AStatus )
    end);
end;

end.
