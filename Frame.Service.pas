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
  ;

type
  TFrameService = class(TFrame)
    PanelConfigHeader: TPanel;
    LabelConfigTitle: TLabel;
    DeleteOlds_DateTimePicker: TDateTimePicker;
    ButDeleteOlds: TButton;
    Memo1: TMemo;
    procedure ButDeleteOldsClick(Sender: TObject);
  private
    { Private declarations }

  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

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
            AddLog(Memo1, Format('Storico salvato: %s - %s',
                                [RecordCopy.NumPrg, RecordCopy.DsPrg]))
          else
            AddLog(Memo1, Format('ERRORE scrittura storico: %s', [ErrorMsg]));
        end);
    end);






end;

end.
