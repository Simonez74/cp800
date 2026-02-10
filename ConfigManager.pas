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
    FBeltD: boolean;
    FBeltB: boolean;
    FBeltC: boolean;
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

    property BeltB : boolean read FBeltB write FBeltB;
    property BeltC : boolean read FBeltC write FBeltC;
    property BeltD : boolean read FBeltD write FBeltD;

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
  IniFile: TIniFile;
begin
  if not FileExists(FConfigFile) then
    exit;

  IniFile := TIniFile.Create(FConfigFile);
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

    FConfig.BeltB := IniFile.ReadBool('General','BeltB', false);
    FConfig.BeltC := IniFile.ReadBool('General','BeltC', false);
    FConfig.BeltD := IniFile.ReadBool('General','BeltD', false);

  finally
    IniFile.Free;
  end;
end;

procedure TConfigManager.SaveToFile;
var
  IniFile: TIniFile;
begin
 IniFile := TIniFile.Create(FConfigFile);
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
    IniFile.WriteBool('General','BeltB', FConfig.BeltB);
    IniFile.WriteBool('General','BeltC', FConfig.BeltC);
    IniFile.WriteBool('General','BeltD', FConfig.BeltD);

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
  FBeltB := false;
  FBeltC := false;
  FBeltD := false;
end;



end.
