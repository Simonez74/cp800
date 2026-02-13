unit Frame.Service;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  // Vcl.Dialogs,
  // Data.DB,
//  Vcl.Samples.Spin,
  Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.DBCtrls, Vcl.Mask, Vcl.ExtCtrls, Vcl.Buttons
  , DMI_Console
  ,system.UITypes
  ,  System.Threading
, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS
  ,  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client

  ;

type

  TLogEvent = procedure(Sender: TObject; const Msg: string) of object;

  TFrameService = class(TFrame)
    DeleteOlds_DateTimePicker: TDateTimePicker;
    ButDeleteOlds: TButton;
    Memo1: TMemo;
    btnChiudi: TButton;
    lblResult: TLabel;
    ComboBox1: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    procedure ButDeleteOldsClick(Sender: TObject);
    procedure btnChiudiClick(Sender: TObject);
  private
    FOnCloseRequest: TNotifyEvent;
    procedure CaricaComboBox (Combo: TComboBox; Campo, Tabella: string);

    { Private declarations }
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    property OnCloseRequest: TNotifyEvent read FOnCloseRequest write FOnCloseRequest;
  end;

implementation

{$R *.dfm}

procedure TFrameService.btnChiudiClick(Sender: TObject);
begin
  if assigned (FOnCloseRequest) then
    FOnCloseRequest(self);
end;

procedure TFrameService.ButDeleteOldsClick(Sender: TObject);
begin
  // Esegui scrittura DB in background
  TTask.Run(
    procedure
    var
      Ldate: string;
      Success: Boolean;
      ErrorMsg: string;
      QDelete : TFDQuery;
    begin
      ldate := FormatDateTime('yyyy/mm/dd',  DeleteOlds_DateTimePicker.date );
      Success := False;
      ErrorMsg := '';


      Qdelete := TFDQuery.Create(nil);
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
          Success := True;
        except
          on E: Exception do
           ErrorMsg := E.Message;
        end;
      finally
        QDelete.Free;
      end;
      // Ritorna al thread principale per il log
      TThread.Queue(nil,
        procedure
        begin
          if Success then
            lblResult.Caption:='Historical deletion successfully completed'
          else
            lblResult.Caption:= 'Error on Historical deletion';
        end);
    end);
end;


procedure TFrameService.CaricaComboBox(Combo: TComboBox; Campo, Tabella: string);
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

constructor TFrameService.Create(AOwner: TComponent);
begin
  inherited;
  DeleteOlds_DateTimePicker.Date := now;
  CaricaComboBox(ComboBox1,'cp800_name','cp800_setup');
end;

end.
