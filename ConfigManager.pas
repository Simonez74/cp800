unit ConfigManager;

interface
// Classe dedicata per gestione configurazione
type
  TAppConfig = class
  private
    FDBHost: string;
    FDBPort: Integer;
    FDBName: string;
    FDBUser: string;
    FDBPassword: string;
    FDeleteEventsOldsThan: integer;
  public
    constructor Create;
    // Database
    property DBHost: string read FDBHost write FDBHost;
    property DBPort: Integer read FDBPort write FDBPort;
    property DBName: string read FDBName write FDBName;
    property DBUser: string read FDBUser write FDBUser;
    property DBPassword: string read FDBPassword write FDBPassword;
//    property AutoConnect: Boolean read FAutoConnect write FAutoConnect;
    // Generale
    property DeleteEventsOldsThan: integer read FDeleteEventsOldsThan write FDeleteEventsOldsThan; // elimina eventi registrati più vecchi dei giorni
  end;

  TConfigManager = class
  private
    FConfig: TAppConfig;
    FConfigFile: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromFile; // carica da INI -> TAppConfig
    procedure SaveToFile; // Salva da TAppConfig -> INI
    property Config: TAppConfig read FConfig;
  end;

implementation

uses
//  Form.Configuration, System.IOUtils;
 System.IOUtils, System.SysUtils,   System.IniFiles;

{ TConfigManager }

constructor TConfigManager.Create;
begin
  FConfig := TAppConfig.Create;
  FConfigFile := ChangeFileExt (ParamStr(0), '.ini')
end;

destructor TConfigManager.Destroy;
begin
  FConfig.Free;
  inherited;
end;

procedure TConfigManager.LoadFromFile;
var
  IniFile: TMemIniFile;
begin
  if not FileExists(FConfigFile) then
    exit;

  IniFile := TMemIniFile.Create(FConfigFile, TEncoding.UTF8);
  try
    // Database
    FConfig.DBHost := IniFile.ReadString('Database', 'Host', 'localhost');
    FConfig.DBPort := IniFile.ReadInteger('Database', 'Port', 3306);
    FConfig.DBName := IniFile.ReadString('Database', 'Name', '');
    FConfig.DBUser := IniFile.ReadString('Database', 'User', 'root');
    FConfig.DBPassword := IniFile.ReadString('Database', 'Password', '');
//    FConfig.AutoConnect := IniFile.ReadBool('Database', 'AutoConnect', True);

 // Generale
    FConfig.DeleteEventsOldsThan := IniFile.ReadInteger('General', 'DeleteEventsOldsThan', 0);
  finally
    IniFile.Free;
  end;
end;

procedure TConfigManager.SaveToFile;
var
  IniFile: TMemIniFile;
begin
 IniFile := TMemIniFile.Create(FConfigFile, TEncoding.UTF8);
  try
    // Database
    IniFile.WriteString('Database', 'Host', FConfig.DBHost);
    IniFile.WriteInteger('Database', 'Port', FConfig.DBPort);
    IniFile.WriteString('Database', 'Name', FConfig.DBName);
    IniFile.WriteString('Database', 'User', FConfig.DBUser);
    IniFile.WriteString('Database', 'Password', FConfig.DBPassword);
//    IniFile.WriteBool('Database', 'AutoConnect', FConfig.AutoConnect);

    // Generale
    IniFile.WriteInteger('General', 'DeleteEventsOldsThan', FConfig.DeleteEventsOldsThan);

    IniFile.UpdateFile;  // IMPORTANTE: TMemIniFile scrive su disco solo qui
  finally
    IniFile.Free;
  end;
end;



{ TAppConfig }

constructor TAppConfig.Create;
begin
  inherited;
  // Valori di default
  FDBHost := 'localhost';
  FDBPort := 3306;
  FDBName := '';
  FDBUser := 'root';
  FDBPassword := '';
  // FAutoConnect := True;
  FDeleteEventsOldsThan := 0;
end;



end.
