unit Frame.Configuration;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.Samples.Spin, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.DBCtrls, Vcl.Mask, Vcl.ExtCtrls, Vcl.Buttons, Vcl.Grids, Vcl.DBGrids, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async,
  FireDAC.DApt, FireDAC.Comp.DataSet, FireDAC.Comp.Client
  ,ConfigManager
  , DMI_Console
  ,system.UITypes
  ;

type
  TFrameConfiguration = class(TFrame)
    DsCp800_setup: TDataSource;
    Qcp800_setup: TFDQuery;
    PageControl: TPageControl;
    TsParametriDatabase: TTabSheet;
    TsCp800_setup: TTabSheet;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    PanelDatiDatabase: TPanel;
    Label39: TLabel;
    Label40: TLabel;
    Label41: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    DbEd_cp800_IP: TDBEdit;
    EDcp800SDO_Active: TDBCheckBox;
    DBcp800_Port: TDBEdit;
    DBcp800_timeoutread: TDBEdit;
    GbParametriFTP: TGroupBox;
    Label45: TLabel;
    Label46: TLabel;
    Label42: TLabel;
    Label47: TLabel;
    Label6: TLabel;
    DBEditUser: TDBEdit;
    DBEditPassword: TDBEdit;
    DbEd_cp800_Port: TDBEdit;
    DBEditIdle: TDBEdit;
    DBFTpPath: TDBEdit;
    DBCheckBox1: TDBCheckBox;
    TsServizi: TTabSheet;
    Memo1: TMemo;
    DeleteOlds_DateTimePicker: TDateTimePicker;
    ButDeleteOlds: TButton;
    lbl1: TLabel;
    EdMySqlIP: TEdit;
    lbl2: TLabel;
    ButtonTestDB: TButton;
    EdMySqlDbName: TEdit;
    lbl3: TLabel;
    lbl4: TLabel;
    EdMySqlUserName: TEdit;
    EdMySqlPsw: TEdit;
    lbl5: TLabel;
    Label7: TLabel;
    SpinEditDBPort: TSpinEdit;
    SpinEditDelEventsOlderThan: TSpinEdit;
    MemoDBInfo: TMemo;
    PanelConfigHeader: TPanel;
    LabelConfigTitle: TLabel;
    ButtonApply: TButton;
    ButtonSave: TButton;
    ButtonCancel: TButton;
    DBEdit1: TDBEdit;
    DBEdit2: TDBEdit;
    Label1: TLabel;
    CbBeltB: TCheckBox;
    CbBeltC: TCheckBox;
    CbBeltD: TCheckBox;
    procedure ButtonTestDBClick(Sender: TObject);
    procedure ButtonApplyClick(Sender: TObject);
    procedure ButtonSaveClick(Sender: TObject);
    procedure ButtonCancelClick(Sender: TObject);
    procedure PageControlChanging(Sender: TObject; var AllowChange: Boolean);
    procedure PageControlChange(Sender: TObject);
    procedure ButDeleteOldsClick(Sender: TObject);
    procedure Qcp800_setupBeforePost(DataSet: TDataSet);
  private
    { Private declarations }
    FConfigManager: TConfigManager;  // Riferimento al manager
    FModified: Boolean;

    procedure SetModified(const Value: Boolean);
    procedure MarkAsModified(Sender: TObject);
    procedure LoadFromConfigManager;    // TAppConfig → Controlli
    procedure SaveToConfigManager;      // Controlli → TAppConfig

  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;

    procedure SetConfigManager(AConfigManager: TConfigManager);
    procedure LoadConfiguration; // Carica da ConfigManager ai controlli
    procedure SaveConfiguration; // Salva dai controlli al ConfigManager
    procedure ApplyConfiguration; // Applica senza salvare

    property Modified: Boolean read FModified write SetModified;
  end;

implementation

{$R *.dfm}

constructor TFrameConfiguration.Create(AOwner: TComponent);
begin
  inherited;
  FModified := False;
  FConfigManager := nil;

  // Collega eventi per rilevare modifiche
  EdMySqlIP.OnChange := MarkAsModified;
  SpinEditDBPort.OnChange := MarkAsModified;
  EdMySqlDbName.OnChange := MarkAsModified;
  EdMySqlUserName.OnChange := MarkAsModified;
  EdMySqlPsw.OnChange := MarkAsModified;

  SpinEditDelEventsOlderThan.OnChange := MarkAsModified;



  CbBeltB.OnClick := MarkAsModified;
  CbBeltC.OnClick := MarkAsModified;
  CbBeltD.OnClick := MarkAsModified;

end;

procedure TFrameConfiguration.SetConfigManager(AConfigManager: TConfigManager);
begin
  FConfigManager := AConfigManager;
  LoadConfiguration;
//  PageControl.ActivePage := TsCp800_setup;
end;

procedure TFrameConfiguration.MarkAsModified(Sender: TObject);
begin
  Modified := True;
end;

procedure TFrameConfiguration.PageControlChange(Sender: TObject);
begin
  if PageControl.ActivePage = TsCp800_setup then
  begin
    if dscp800_setup.DataSet.Active then
      dscp800_setup.DataSet.close;
    dscp800_setup.DataSet.Open;
  end
  else
  begin
    if dscp800_setup.DataSet.Active then
      dscp800_setup.DataSet.close;
  end;
end;

procedure TFrameConfiguration.PageControlChanging(Sender: TObject; var AllowChange: Boolean);
begin
	AllowChange := True;
  if PageControl.ActivePage = TsParametriDatabase then
    AllowChange := DMIConsole.IsConnected;
end;

procedure TFrameConfiguration.Qcp800_setupBeforePost(DataSet: TDataSet);
begin
 Modified := True;
end;

procedure TFrameConfiguration.SetModified(const Value: Boolean);
begin
  FModified := Value;
  ButtonApply.Enabled := Value;
  ButtonSave.Enabled := Value;
end;

procedure TFrameConfiguration.LoadFromConfigManager;
begin
  if not Assigned(FConfigManager) then
    Exit;

  // Database
  EdMySqlIP.Text := FConfigManager.Config.DBHost;
  SpinEditDBPort.Value := FConfigManager.Config.DBPort;
  EdMySqlDbName.Text := FConfigManager.Config.DBName;
  EdMySqlUserName.Text := FConfigManager.Config.DBUser;
  EdMySqlPsw.Text := FConfigManager.Config.DBPassword;
//  CheckBoxAutoConnect.Checked := FConfigManager.Config.AutoConnect;

  // Generale
  SpinEditDelEventsOlderThan.Value := FConfigManager.Config.DeleteEventsOldsThan;

  CbBeltB.Checked := FConfigManager.Config.BeltB;
  CbBeltC.Checked := FConfigManager.Config.BeltC;
  CbBeltD.Checked := FConfigManager.Config.BeltD;

  Modified := False;
end;

procedure TFrameConfiguration.SaveToConfigManager;
begin
if not Assigned(FConfigManager) then
    Exit;

  // Database
  FConfigManager.Config.DBHost := EdMySqlIP.Text;
  FConfigManager.Config.DBPort := SpinEditDBPort.Value;
  FConfigManager.Config.DBName := EdMySqlDbName.Text;
  FConfigManager.Config.DBUser := EdMySqlUserName.Text;
  FConfigManager.Config.DBPassword := EdMySqlPsw.Text;
//  FConfigManager.Config.AutoConnect := CheckBoxAutoConnect.Checked;

  // Generale
  FConfigManager.Config.DeleteEventsOldsThan := SpinEditDelEventsOlderThan.Value;

  FConfigManager.Config.BeltB := CbBeltB.Checked;
  FConfigManager.Config.BeltC := CbBeltC.Checked;
  FConfigManager.Config.BeltD := CbBeltD.Checked;
end;


procedure TFrameConfiguration.ButDeleteOldsClick(Sender: TObject);
var
  Ldate: string;
  QDelete : TFDQuery;
begin
  qdelete := TFDQuery.Create(nil);
  try
    QDelete.Connection := DMIConsole.FDConnection;
    try
      ldate := FormatDateTime('yyyy/mm/dd',  DeleteOlds_DateTimePicker.date );
  //    LDate :=  IntToStr(DateToyyyymmdd(DeleteOlds_DateTimePicker.Date));
      QDelete.SQL.Clear;
      QDelete.sql.Add('delete from cp800Storico ');
      QDelete.sql.Add('where ');
      QDelete.sql.Add(' Date(DataTime) <  ' + quotedstr(LDate) );

      QDelete.ExecSQL;
    except
      on E: Exception do
      begin
        showmessage('Error on deleting: ' + E.Message);
      end;
    end;
  finally
    QDelete.Free;
  end;
end;

procedure TFrameConfiguration.ButtonApplyClick(Sender: TObject);
begin
  ApplyConfiguration;
end;

procedure TFrameConfiguration.ButtonCancelClick(Sender: TObject);
begin
  if Modified then
  begin
    if MessageDlg('There are unsaved changes. Discard ?',
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      LoadConfiguration;  // Ricarica configurazione originale
      Modified := False;
    end;
  end;
end;

procedure TFrameConfiguration.ButtonSaveClick(Sender: TObject);
begin
  SaveConfiguration;
end;

procedure TFrameConfiguration.ButtonTestDBClick(Sender: TObject);
var
  TestConn: TFDConnection;
begin
  TestConn := TFDConnection.Create(nil);
  try
    TestConn.DriverName := 'MySQL';
    TestConn.Params.Values['Server'] := EdMySqlIP.Text;
    TestConn.Params.Values['Port'] := SpinEditDBPort.Value.ToString;
    TestConn.Params.Values['Database'] := EdMySqlDbName.Text;
    TestConn.Params.Values['User_Name'] := EdMySqlUserName.Text;
    TestConn.Params.Values['Password'] := EdMySqlPsw.Text;

    try
      Screen.Cursor := crHourGlass;
      TestConn.Connected := True;
      ShowMessage('Connection to database OK !');
    except
      on E: Exception do
        ShowMessage('Error connection to database: ' + E.Message);
    end;
  finally
    Screen.Cursor := crDefault;
    TestConn.Free;
  end;

end;

procedure TFrameConfiguration.LoadConfiguration;
begin
  if not Assigned(FConfigManager) then
    Exit;

  // Ricarica dal file INI
  FConfigManager.LoadFromFile;

  // Popola i controlli
  LoadFromConfigManager;

  // Carica griglia CP800
  /////  ButtonRefreshCP800Click(nil);
end;


procedure TFrameConfiguration.SaveConfiguration;
begin
  if not Assigned(FConfigManager) then
    Exit;

  // Salva dai controlli all'oggetto Config
  SaveToConfigManager;

  // Salva su file INI
  FConfigManager.SaveToFile;

  Modified := False;
//  ShowMessage('Configurazione salvata con successo');
end;


procedure TFrameConfiguration.ApplyConfiguration;
begin
  if not Assigned(FConfigManager) then
    Exit;

  // Salvo dai controlli all'oggetto Config (senza salvare su file)
  SaveToConfigManager;

  // Applica al database
  if DMIConsole.FDConnection.Connected then
    DMIConsole.FDConnection.Connected := False;

  DMIConsole.FDConnection.Params.Values['Server'] :=
    FConfigManager.Config.DBHost;
  DMIConsole.FDConnection.Params.Values['Port'] :=
    FConfigManager.Config.DBPort.ToString;
  DMIConsole.FDConnection.Params.Values['Database'] :=
    FConfigManager.Config.DBName;
  DMIConsole.FDConnection.Params.Values['User_Name'] :=
    FConfigManager.Config.DBUser;
  DMIConsole.FDConnection.Params.Values['Password'] :=
    FConfigManager.Config.DBPassword;



    {  FDConnection.DriverName := 'MySQL';
  FDConnection.Params.Add('Database=' + ParametriConsole.ConfigDBMySql.DbName );
  FDConnection.Params.Add('User_Name=' +  ParametriConsole.ConfigDBMySql.User);
  FDConnection.Params.Add('Password=' + ParametriConsole.ConfigDBMySql.Pwd);
  FDConnection.Params.Add('Server='+  ParametriConsole.ConfigDBMySql.Host);
  FDConnection.Params.Add('Port='+  ParametriConsole.ConfigDBMySql.Port.ToString);
    }


  try
    DMIConsole.FDConnection.Connected := True;
    MemoDBInfo.Lines.Clear;
    MemoDBInfo.Lines.Add('Connessione applicata con successo');
    ShowMessage('Configurazione applicata con successo');
    Modified := False;
  except
    on E: Exception do
    begin
      MemoDBInfo.Lines.Clear;
      MemoDBInfo.Lines.Add('Errore: ' + E.Message);
      ShowMessage('Errore nell''applicare la configurazione: ' + E.Message);
    end;
  end;
end;

end.
