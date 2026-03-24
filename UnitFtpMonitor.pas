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

    function ParseStreamToPairs(AStream: TStream   ): TStringList;
    function ParseStreamFastToPairs(AStream: TStream   ): TStringList;
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
    function VariabileDaLeggere ( Const AKey : string):boolean; virtual;

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
//  ss: TStringStream;
//  txt: string;
//  lines: TStringList;
  pairs: TStringList;
//  i: Integer;
//  line: string;
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
//    FIdFTP.TransferType := ftASCII;
    FIdFTP.TransferType := ftBinary;
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
//          pairs := ParseStreamToPairs(ms);
          pairs := ParseStreamFastToPairs(ms);
          try
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
            FOwner.DoQueueError( E);
            FOwner.DoQueueLog('Error ftp get' + e.Message);
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

  if Assigned(FStopEvent) then
    FreeAndNil(FStopEvent);

  if Assigned(FLock) then
    FreeAndNil(FLock);

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
begin
  if not Assigned(FThread) then
    Exit;

  // Segnalo l'evento per svegliare immediatamente il thread se è in WaitFor
  // 1) Segnalo l'evento: se il thread è in WaitFor(IntervalMs) esce subito
  if Assigned(FStopEvent) then
    FStopEvent.SetEvent;

  // 2) Imposto Terminate per sicurezza (il thread controlla anche "Terminated" nel while)
  FThread.Terminate;
  FThread.WaitFor; // bloccante
  FreeAndNil(FThread);

  // Se non è ancora terminato dopo il timeout, lasco che venga liberato altrove.
  DoQueueLog('FTPMonitor stopped');
end;

function TFtpMonitor.ThreadInEsecuzione: Boolean;
begin
  Result := Assigned(FThread) and not FThread.Finished;
end;

function TFtpMonitor.VariabileDaLeggere(const AKey: string): boolean;
begin
  Result := Assigned(FCodeMap) and FCodeMap.ContainsKey(AKey);
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

function TMonitorThread.ParseStreamFastToPairs(AStream: TStream): TStringList;
var
//  Owned: Boolean;
  Key, Val: string;

  Buffer: TBytes;
  Text: string;
  Encoding28595: TEncoding; // encoding per cirillico e ansi
  P, LineStart, EqPos: PChar;

  function TrimRange(StartP, EndP: PChar): string;
  begin
    while (StartP <= EndP) and (StartP^ <= ' ') do Inc(StartP);
    while (EndP >= StartP) and (EndP^ <= ' ') do Dec(EndP);

    if EndP >= StartP then
      SetString(Result, StartP, EndP - StartP + 1)
    else
      Result := '';
  end;


begin
  Result := TStringList.Create;
  Result.NameValueSeparator := '=';

  AStream.Position := 0;
  SetLength(Buffer, AStream.Size);
  if Length(Buffer) > 0 then
    AStream.ReadBuffer(Buffer[0], Length(Buffer));

  Encoding28595 := TEncoding.GetEncoding(28595);
  try
    Text := Encoding28595.GetString(Buffer);
  finally
    Encoding28595.Free;
  end;

  P := PChar(Text);
  LineStart := P;

  while P^ <> #0 do
  begin
    if (P^ = #13) or (P^ = #10) then
    begin
      EqPos := LineStart;
      while (EqPos < P) and (EqPos^ <> '=') do
        Inc(EqPos);

      if EqPos < P then
      begin
        Key := TrimRange(LineStart, EqPos - 1);
        Val := TrimRange(EqPos + 1, P - 1);

        if (Key <> '') and fOwner.VariabileDaLeggere(Key) then
          Result.Values[Key] := Val;
      end;

      Inc(P);
      if (P^ = #10) and ((P - 1)^ = #13) then Inc(P);

      LineStart := P;
      Continue;
    end;

    Inc(P);
  end;

  {
  // ultima riga (se non termina con CR/LF)
  if LineStart < P then
  begin
    EqPos := LineStart;
    while (EqPos < P) and (EqPos^ <> '=') do Inc(EqPos);

    if EqPos < P then
    begin
      Key := TrimRange(LineStart, EqPos - 1);
      Val := TrimRange(EqPos + 1, P - 1);

      if (Key <> '') and AOwner.VariabileDaLeggere(Key) then
        Result.Values[Key] := Val;
    end;
  end;
  }
end;

function TMonitorThread.ParseStreamToPairs(AStream: TStream): TStringList;
var
//  Owned: Boolean;
  Reader: TStreamReader;
  Line, Key, Val: string;
  P: Integer;
  Encoding28595: TEncoding; // encoding per cirillico e ansi
begin
  Result := TStringList.Create;
  Result.NameValueSeparator := '=';

  AStream.Position := 0;

  Encoding28595 := TEncoding.GetEncoding(28595);
//  Reader := TStreamReader.Create(AStream,  TEncoding.GetEncoding(28595));
  Reader := TStreamReader.Create(AStream,  Encoding28595);
  try
    while not Reader.EndOfStream do
    begin
      Line := Trim(Reader.ReadLine);

      if (Line = '') or
         ((Length(Line) >= 2) and (Line[1] = '/') and (Line[2] = '/')) then
        Continue;

      Line := StringReplace(Line, #9, ' ', [rfReplaceAll]);

      P := Pos('=', Line);
      if P > 0 then
      begin
        Key := Trim(Copy(Line, 1, P - 1));
        Val := Trim(Copy(Line, P + 1, MaxInt));

        if (Key <> '') and FOwner.VariabileDaLeggere(Key) then
          Result.Values[Key] := Val;
      end;
    end;
  finally
    Reader.Free;
    Encoding28595.Free;
  end;
end;

end.
