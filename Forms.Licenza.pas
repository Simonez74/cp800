unit Forms.Licenza;

{ Gestione licenza (stesso schema di LicenzeDelphi\LicDemo).
  Mostra:
   - l'ID macchina da inviare al fornitore per ottenere la licenza
   - lo stato della licenza installata
   - l'importazione del file .lic ricevuto

  Uso:
   - all'avvio (dpr) VerificaLicenza: se la licenza non e' valida apre la form;
     se alla chiusura non e' ancora valida il programma non parte
   - dal pulsante Licenza della toolbar MostraLicenza }

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils, System.UITypes,
  Vcl.Graphics, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.Dialogs, Vcl.Clipbrd,
  LicenseCore, LicensePublicKey;

const
  APP_PRODOTTO = '3000-5000'; // deve coincidere con -p passato a SormaKeyGenerator
  APP_MAGGIORE = 1;                      // versione maggiore di questo programma

type
  TFormLicenza = class(TForm)
    lblIdCaption: TLabel;
    edtId: TEdit;
    btnCopy: TButton;
    lblState: TLabel;
    memInfo: TMemo;
    btnImport: TButton;
    btnChiudi: TButton;
    dlgOpenLic: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
    procedure btnImportClick(Sender: TObject);
  private
    FStato: TLicenseState;
    procedure RefreshLicense;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    property Stato: TLicenseState read FStato;
  end;

// Cartella in cui si cercano i file *.lic (cartella dell'eseguibile)
function CartellaLicenza: string;

// Valida la licenza: cerca fra tutti i *.lic della cartella del programma
// (FindLicenseInFolder). LicFile = file usato, Count = numero di .lic trovati.
function StatoLicenza(out Info: TLicenseInfo): TLicenseState; overload;
function StatoLicenza(out Info: TLicenseInfo; out LicFile: string;
  out Count: Integer): TLicenseState; overload;

// Se la licenza non e' valida apre la form licenza (modale).
// Restituisce True se, alla chiusura, la licenza e' valida.
function VerificaLicenza: Boolean;

// Apre sempre la form licenza (consultazione / sostituzione licenza)
procedure MostraLicenza;

implementation

{$R *.dfm}

function CartellaLicenza: string;
begin
  Result := ExtractFilePath(ParamStr(0));
end;

{
function LicensePath: string;
var
  Base: string;
begin
  // ProgramData: scrivibile e condivisa tra utenti Windows
  Base := GetEnvironmentVariable('ProgramData');
  if Base = '' then
    Base := ExtractFilePath(ParamStr(0));
  Result := TPath.Combine(TPath.Combine(Base, APP_PRODOTTO), 'license.lic');
end;
}

function StatoLicenza(out Info: TLicenseInfo; out LicFile: string;
  out Count: Integer): TLicenseState;
begin
  if PUBLIC_KEY_HEX = '' then
  begin
    Info := Default(TLicenseInfo);
    LicFile := '';
    Count := 0;
    Exit(lsBadSignature);
  end;
  // CartellaLicenza e' una cartella: ValidateLicenseFile vuole un file,
  // FindLicenseInFolder valuta tutti i *.lic presenti
  Result := FindLicenseInFolder(CartellaLicenza, PUBLIC_KEY_HEX, APP_PRODOTTO, APP_MAGGIORE,
    Info, LicFile, Count);
end;

function StatoLicenza(out Info: TLicenseInfo): TLicenseState;
var
  LicFile: string;
  Count: Integer;
begin
  Result := StatoLicenza(Info, LicFile, Count);
end;

function VerificaLicenza: Boolean;
var
  Info: TLicenseInfo;
  Form: TFormLicenza;
begin
  Result := StatoLicenza(Info) = lsValid;
  if Result then
    Exit;

  Form := TFormLicenza.Create(nil);
  try
    Form.ShowModal;
    Result := Form.Stato = lsValid;
  finally
    Form.Free;
  end;
end;

procedure MostraLicenza;
var
  Form: TFormLicenza;
begin
  Form := TFormLicenza.Create(nil);
  try
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

{ TFormLicenza }

procedure TFormLicenza.CreateParams(var Params: TCreateParams);
begin
  inherited;
  // All'avvio la form principale non esiste ancora (MainFormOnTaskbar = True):
  // senza questo flag la form licenza non avrebbe il pulsante sulla barra applicazioni
  if Application.MainForm = nil then
    Params.ExStyle := Params.ExStyle or WS_EX_APPWINDOW;
end;

procedure TFormLicenza.FormCreate(Sender: TObject);
begin
  Caption := Application.Title + ' - Licenza';
  RefreshLicense;
end;

procedure TFormLicenza.RefreshLicense;
var
  Info: TLicenseInfo;
  LicFile: string;
  Count: Integer;
begin
  edtId.Text := GetMachineId;
  memInfo.Clear;

  if PUBLIC_KEY_HEX = '' then
  begin
    FStato := lsBadSignature;
    lblState.Caption := 'Chiave pubblica non configurata';
    lblState.Font.Color := clMaroon;
    memInfo.Lines.Add('Copia LicensePublicKey.pas generato dal fornitore e ricompila.');
    Exit;
  end;

  // stessa funzione usata da VerificaLicenza all'avvio
  FStato := StatoLicenza(Info, LicFile, Count);
  lblState.Caption := LicenseStateText(FStato);

  if FStato = lsValid then
  begin
    lblState.Font.Color := clGreen;
    memInfo.Lines.Add('Cliente  : ' + Info.Cliente);
    memInfo.Lines.Add('Prodotto : ' + Info.Prodotto);
    memInfo.Lines.Add('Versione : ' + IntToStr(Info.MajorVersion) + '.x');
    memInfo.Lines.Add('Emessa il: ' + Info.DataEmissione);
    memInfo.Lines.Add('File     : ' + ExtractFileName(LicFile));
    if Count > 1 then
      memInfo.Lines.Add(Format('(%d file .lic nella cartella, usato quello sopra)', [Count]));
    btnChiudi.Caption := 'Chiudi';
  end
  else
  begin
    lblState.Font.Color := clRed;
    if Count = 0 then
      memInfo.Lines.Add('Nessun file .lic nella cartella del programma:')
    else
      memInfo.Lines.Add(Format('%d file .lic nella cartella del programma, nessuno valido ' +
        '(mostrato l''errore di %s):', [Count, ExtractFileName(LicFile)]));
    memInfo.Lines.Add('  ' + CartellaLicenza);
    memInfo.Lines.Add('');
    memInfo.Lines.Add('Il programma non puo'' essere avviato senza una licenza valida.');
    memInfo.Lines.Add('Invia l''ID macchina qui sopra per ricevere il file di licenza,');
    memInfo.Lines.Add('poi usa "Importa file licenza...".');
    btnChiudi.Caption := 'Esci';
  end;
end;

procedure TFormLicenza.btnCopyClick(Sender: TObject);
begin
  Clipboard.AsText := edtId.Text;
end;

procedure TFormLicenza.btnImportClick(Sender: TObject);
var
  Tmp: TLicenseInfo;
  St: TLicenseState;
  Dest: string;
begin
  if not dlgOpenLic.Execute then
    Exit;

  // Valida PRIMA di installare: non sovrascrivere una licenza buona con una errata
  St := ValidateLicenseFile(dlgOpenLic.FileName, PUBLIC_KEY_HEX, APP_PRODOTTO, APP_MAGGIORE, Tmp);
  if St <> lsValid then
  begin
    MessageDlg('Licenza non accettata:' + sLineBreak + LicenseStateText(St),
      mtError, [mbOK], 0);
    Exit;
  end;

  // Si mantiene il nome originale (es. Cliente_Prodotto_v1.lic)
  Dest := TPath.Combine(CartellaLicenza, ExtractFileName(dlgOpenLic.FileName));
  if not SameFileName(ExpandFileName(dlgOpenLic.FileName), ExpandFileName(Dest)) then
    try
      TFile.Copy(dlgOpenLic.FileName, Dest, True);
    except
      on E: Exception do
      begin
        MessageDlg('Impossibile copiare la licenza nella cartella del programma:' +
          sLineBreak + CartellaLicenza + sLineBreak + sLineBreak + E.Message + sLineBreak +
          sLineBreak + 'Se il programma e'' installato in "Programmi", copia il file ' +
          'manualmente come amministratore oppure avvia il programma come amministratore.',
          mtError, [mbOK], 0);
        Exit;
      end;
    end;
  RefreshLicense;
  MessageDlg('Licenza installata correttamente.', mtInformation, [mbOK], 0);
end;

end.
