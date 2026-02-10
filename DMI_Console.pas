unit DMI_Console;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.MySQL,
  FireDAC.Phys.MySQLDef, FireDAC.VCLUI.Wait, Data.DB, FireDAC.Comp.Client
  ,Graphics

  ,Forms
  ,FireDAC.Stan.ExprFuncs
  ,FireDAC.Phys.SQLiteWrapper.Stat
  ,FireDAC.Phys.SQLiteDef
  ,FireDAC.Phys.SQLite
  ,Dialogs
  ,IniFiles
  ,DateUtils, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet
  // Myfunc.Utils
  ,System.IOUtils, MyThreadLog
//  , MyThreadLog
  ;

type

  TConnectionResult = record
    Success: Boolean;
    ErrorMessage: string;
    ErrorClass: string;
  end;


  TCP800StoricoRecord = record
    Start : boolean;
    Cp800_id : String;
    TotalWeight: String;
    TotalPacks: String;
    NumPrg : string;
    DsPrg : string;
  end;

  TConfigDBMySql = record
     Host: string; // IP/Hostname server Mysql sorma_cs
     Port: integer; // Porta database Mysql sorma_cs
     DbName: string; // Nome database Mysql sorma_cs
     User: string; // UserName database Mysql  sorma_cs
     Pwd: string; // Psw database Mysql  sorma_cs
   end;


   TParametriConsole = record
     Language : String;  // Linguaggio interfaccia
     DeleteEventsOldsThan:integer; // elimina eventi registrati più vecchi dei giorni
     SalvaPesoConfezioni : boolean;
     ConfigDBMySql : TConfigDBMySql;
   end;

  TDMIConsole = class(TDataModule)
    FDPhysMySQLDriverLink1: TFDPhysMySQLDriverLink;
    FDConnection: TFDConnection;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    { Private declarations }
    FLastConnectionError: string;
    FConnectionAttempts: Integer;
    procedure LogConnectionInfo(const AMessage: string);
  public
    { Public declarations }

    Function  CalcolaSessione ( const FlStart : boolean; Const IDCp800 : String ;Const NumeroProgramma : String) : integer; virtual;
    procedure ScriviRecordCp800Storico( CP800StoricoRecord :  TCP800StoricoRecord) ; virtual;



    //////////////
    // Metodi di connessione
    function Connect(const AHost: string; APort: Integer;
                    const ADatabase, AUser, APassword: string): TConnectionResult;

    function ConnectWithRetry(const AHost: string; APort: Integer;
                             const ADatabase, AUser, APassword: string;
                             AMaxRetries: Integer = 3;
                             ARetryDelayMs: Integer = 1000): TConnectionResult;

    procedure Disconnect;

    function IsConnected: Boolean;
    function TestConnection(const AHost: string;
                           APort: Integer;
                           const ADatabase, AUser, APassword: string): TConnectionResult;

    // Proprietà
    property LastConnectionError: string read FLastConnectionError;
    property ConnectionAttempts: Integer read FConnectionAttempts;


  end;

var
  DMIConsole: TDMIConsole;
////  ParametriConsole: TParametriConsole;


implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}



{$R *.dfm}

{ TDMIConsole }



procedure TDMIConsole.DataModuleCreate(Sender: TObject);
begin
  FLastConnectionError := '';
  FConnectionAttempts := 0;

  // Configuro driver MySQL
  FDPhysMySQLDriverLink1.VendorLib := 'libmysql.dll';

  LogConnectionInfo('DataModule creato');
end;

procedure TDMIConsole.DataModuleDestroy(Sender: TObject);
begin
  Disconnect;
  LogConnectionInfo('DataModule distrutto');
end;


procedure TDMIConsole.LogConnectionInfo(const AMessage: string);
begin
  try
     LogToFile('[DMI_Console] ' + AMessage);
  except
    // Ignoro errori di logging
  end;
end;

function TDMIConsole.Connect(const AHost: string; APort: Integer; const ADatabase, AUser,
  APassword: string): TConnectionResult;
begin
  Result.Success := False;
  Result.ErrorMessage := '';
  Result.ErrorClass := '';
  FLastConnectionError := '';
  Inc(FConnectionAttempts);

  try
    // Disconnetto se già connesso
    if FDConnection.Connected then
      FDConnection.Connected := False;

    // Configuro parametri
    FDConnection.Params.Clear;
    FDConnection.DriverName := 'MySQL';
    FDConnection.Params.Values['Server'] := AHost;
    FDConnection.Params.Values['Port'] := APort.ToString;
    FDConnection.Params.Values['Database'] := ADatabase;
    FDConnection.Params.Values['User_Name'] := AUser;
    FDConnection.Params.Values['Password'] := APassword;
    FDConnection.Params.Values['CharacterSet'] := 'utf8mb4';

    // Timeout di connessione (opzionale)
    FDConnection.Params.Values['LoginTimeout'] := '10';  // 10 secondi

{    FDConnection.Params.Add('Database=' + ParametriConsole.ConfigDBMySql.DbName );
    FDConnection.Params.Add('User_Name=' +  ParametriConsole.ConfigDBMySql.User);
    FDConnection.Params.Add('Password=' + ParametriConsole.ConfigDBMySql.Pwd);
    FDConnection.Params.Add('Server='+  ParametriConsole.ConfigDBMySql.Host);
    FDConnection.Params.Add('Port='+  ParametriConsole.ConfigDBMySql.Port.ToString);
 }


    LogConnectionInfo(Format('Tentativo connessione a %s:%d database=%s user=%s',
                            [AHost, APort, ADatabase, AUser]));

    // Tento la connessione
    FDConnection.Connected := True;

    Result.Success := True;
    LogConnectionInfo(Format('Connessione riuscita (tentativo #%d)',
                            [FConnectionAttempts]));

  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
      Result.ErrorClass := E.ClassName;
      FLastConnectionError := E.Message;

      LogConnectionInfo(Format('Connessione fallita: [%s] %s',
                              [E.ClassName, E.Message]));
    end;
  end;
end;

function TDMIConsole.ConnectWithRetry(const AHost: string; APort: Integer; const ADatabase, AUser, APassword: string;
  AMaxRetries, ARetryDelayMs: Integer): TConnectionResult;
var
  Attempt: Integer;
begin
  Result.Success := False;

  for Attempt := 1 to AMaxRetries do
  begin
    LogConnectionInfo(Format('Tentativo di connessione %d di %d',
                            [Attempt, AMaxRetries]));

    Result := Connect(AHost, APort, ADatabase, AUser, APassword);

    if Result.Success then
      Exit;

    // Se non è l'ultimo tentativo, attendo prima di riprovare
    if Attempt < AMaxRetries then
    begin
      LogConnectionInfo(Format('Attesa di %d ms prima del prossimo tentativo...',
                              [ARetryDelayMs]));
      Sleep(ARetryDelayMs);
    end;
  end;

  LogConnectionInfo(Format('Tutti i %d tentativi di connessione falliti',
                          [AMaxRetries]));
end;

procedure TDMIConsole.Disconnect;
begin
  try
    if FDConnection.Connected then
    begin
      FDConnection.Connected := False;
      LogConnectionInfo('Database disconnesso');
    end;
  except
    on E: Exception do
      LogConnectionInfo('Errore durante disconnessione: ' + E.Message);
  end;
end;

function TDMIConsole.IsConnected: Boolean;
begin
  Result := Assigned(FDConnection) and FDConnection.Connected;
end;


function TDMIConsole.TestConnection(const AHost: string; APort: Integer; const ADatabase, AUser,
  APassword: string): TConnectionResult;
var
  TestConn: TFDConnection;
begin
  Result.Success := False;
  Result.ErrorMessage := '';
  Result.ErrorClass := '';

  TestConn := TFDConnection.Create(nil);
  try
    TestConn.DriverName := 'MySQL';
    TestConn.Params.Values['Server'] := AHost;
    TestConn.Params.Values['Port'] := APort.ToString;
    TestConn.Params.Values['Database'] := ADatabase;
    TestConn.Params.Values['User_Name'] := AUser;
    TestConn.Params.Values['Password'] := APassword;
    TestConn.Params.Values['CharacterSet'] := 'utf8mb4';
    TestConn.Params.Values['LoginTimeout'] := '10';

    LogConnectionInfo('Test connessione in corso...');

    try
      TestConn.Connected := True;
      Result.Success := True;
      LogConnectionInfo('Test connessione riuscito');
      TestConn.Connected := False;
    except
      on E: Exception do
      begin
        Result.Success := False;
        Result.ErrorMessage := E.Message;
        Result.ErrorClass := E.ClassName;
        LogConnectionInfo(Format('Test connessione fallito: [%s] %s',
                                [E.ClassName, E.Message]));
      end;
    end;
  finally
    TestConn.Free;
  end;

end;




function TDMIConsole.CalcolaSessione(const FlStart : boolean; Const IDCp800 : String ; Const NumeroProgramma : String ): integer;
var
  QSessione : TFDQuery;
begin
  // se CP800StoricoRecord.Start = true significa che inizio lavoro
  // per cui calcolo  session_id
  result := 0;
  QSessione := TFDQuery.Create(nil);
  try
    try
      QSessione.Connection := FDConnection;
      QSessione.sql.Add('select max(session_id) as NumSessionId from cp800Storico');
      QSessione.sql.Add(' where cp800_ID = ' + QuotedStr(IDCp800) );
      QSessione.sql.Add(' and NumProgram = ' + QuotedStr(NumeroProgramma) );
      QSessione.sql.Add(' and Date(DataTime) = ' + quotedStr( FormatDateTime('yyyy-mm-dd' , now())));
      if not Flstart then
      QSessione.sql.Add(' and StartStop = 1 ');

      QSessione.Open;
      if not QSessione.eof then
      begin
        result:= QSessione.FieldByName('NumSessionId').AsInteger;
        if Flstart then
          result := result + 1;
      end
      else
        result := 1;
    except
       on e: Exception do
       begin
         LogToFile('CalcolaSessione: ' + e.Message );
//         raise;
       end;
    end;
  finally
    QSessione.free;
  end;
end;






procedure TDMIConsole.ScriviRecordCp800Storico(CP800StoricoRecord: TCP800StoricoRecord);
var
//  QCalcolaSessione : TFDQuery;
  QUpdate : TFDQuery;
  LSession : integer;
  LStart : integer;
begin
  if (CP800StoricoRecord.TotalWeight.IsEmpty) or (CP800StoricoRecord.TotalPacks.IsEmpty) then
    exit;

  // per salvare valore corretto di db mysql
  if CP800StoricoRecord.Start then
   lstart := 1
  else
   lstart := 0;


  QUpdate := TFDQuery.Create(nil);
  try
    try
      QUpdate.Connection := FDConnection;


      // se stato macchina = stop -> record 5001 = false
      // nel caso in cui ho chiuso il programma e lo faccio ripartire
      // scrivo il record solo se non già presente
      if lstart = 0 then
      begin
        QUpdate.sql.Clear;
        QUpdate.sql.Add('select * from cp800Storico');
        QUpdate.sql.Add(' where cp800_ID = ' + QuotedStr(CP800StoricoRecord.Cp800_id) );
        QUpdate.sql.Add(' and NumProgram = ' + QuotedStr(CP800StoricoRecord.NumPrg) );
        QUpdate.sql.Add(' and Date(DataTime) = ' + quotedStr( FormatDateTime('yyyy-mm-dd' , now())));
        QUpdate.sql.Add(' and TotalWeight = ' + CP800StoricoRecord.TotalWeight);
        QUpdate.sql.Add(' and TotalPacks = ' + CP800StoricoRecord.TotalPacks);
        QUpdate.Open;
        if QUpdate.RecordCount > 0 then
          exit;
      end;

      if QUpdate.Active then
        QUpdate.Close;
      QUpdate.sql.Clear;
      // se CP800StoricoRecord.Start = true significa che inizio lavoro
      // per cui calcolo  session_id
      if CP800StoricoRecord.Start then
      begin
        QUpdate.sql.Add('select max(session_id) as NumSessionId from cp800Storico');
        QUpdate.sql.Add(' where cp800_ID = ' + QuotedStr(CP800StoricoRecord.Cp800_id) );
        QUpdate.sql.Add(' and NumProgram = ' + QuotedStr(CP800StoricoRecord.NumPrg) );
        QUpdate.sql.Add(' and Date(DataTime) = ' + quotedStr( FormatDateTime('yyyy-mm-dd' , now())));
        QUpdate.Open;
        if not QUpdate.eof then
          LSession:= QUpdate.FieldByName('NumSessionId').AsInteger + 1
        else
          LSession := 1;
      end
      else
      begin
        QUpdate.sql.Add('select max(session_id) as lastSession  from cp800Storico');
        // cerco record già inseriti come inizio -> startstop = 1
        QUpdate.sql.Add(' where StartStop = 1 and  cp800_ID = ' + QuotedStr(CP800StoricoRecord.Cp800_id) );
        QUpdate.sql.Add(' and NumProgram = ' + QuotedStr(CP800StoricoRecord.NumPrg) );
        QUpdate.sql.Add(' and Date(DataTime) = ' + quotedStr( FormatDateTime('yyyy-mm-dd' , now())));
        QUpdate.Open;
        if not QUpdate.eof then
          LSession:= QUpdate.FieldByName('lastSession').AsInteger
        else
          LSession := 1;
      end;

      if CP800StoricoRecord.TotalWeight.IsEmpty then
        CP800StoricoRecord.TotalWeight := '0';
      if CP800StoricoRecord.TotalPacks.IsEmpty then
        CP800StoricoRecord.TotalPacks := '0';

      if QUpdate.Active then
        QUpdate.Close;
      QUpdate.sql.Clear;
      QUpdate.SQL.Text:= 'INSERT INTO cp800Storico'
                      + ' ( `CP800_ID`,`DataTime`, `Session_ID`, `StartStop`, `NumProgram`, `DsProgram` '
                      + ' ,`TotalWeight`, `TotalPacks` ) '
                             + ' VALUE ( ' + QuotedStr( CP800StoricoRecord.Cp800_id) + ','
                             + quotedstr(  FormatDateTime('yyyy-mm-dd hh:mm:ss',now))+ ','
                             + LSession.ToString + ','
                             + lstart.ToString + ','
                             + CP800StoricoRecord.NumPrg +','
                             + quotedstr(CP800StoricoRecord.DsPrg) +','
                             + CP800StoricoRecord.TotalWeight + ','
                             + CP800StoricoRecord.TotalPacks
                             + ')';
      QUpdate.ExecSQL;
    except
       on e: Exception do
       begin
         LogToFile('ScriviRecordCp800Dashboard:' + e.Message );
//         raise;
       end;

    end;

  finally
    QUpdate.free;
  end;
end;



end.
