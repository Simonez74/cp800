object FormLicenza: TFormLicenza
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Licenza'
  ClientHeight = 340
  ClientWidth = 560
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object lblIdCaption: TLabel
    Left = 16
    Top = 16
    Width = 294
    Height = 15
    Caption = 'ID macchina (invialo al fornitore per ottenere la licenza):'
  end
  object lblState: TLabel
    Left = 16
    Top = 84
    Width = 4
    Height = 21
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object edtId: TEdit
    Left = 16
    Top = 38
    Width = 430
    Height = 26
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    TabOrder = 0
  end
  object btnCopy: TButton
    Left = 456
    Top = 36
    Width = 88
    Height = 27
    Caption = 'Copia'
    TabOrder = 1
    OnClick = btnCopyClick
  end
  object memInfo: TMemo
    Left = 16
    Top = 114
    Width = 528
    Height = 160
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object btnImport: TButton
    Left = 8
    Top = 300
    Width = 200
    Height = 32
    Caption = 'Importa file licenza...'
    TabOrder = 3
    OnClick = btnImportClick
  end
  object btnChiudi: TButton
    Left = 424
    Top = 300
    Width = 120
    Height = 32
    Cancel = True
    Caption = 'Chiudi'
    ModalResult = 2
    TabOrder = 4
  end
  object dlgOpenLic: TOpenDialog
    Filter = 'File licenza (*.lic)|*.lic|Tutti i file (*.*)|*.*'
    Left = 336
    Top = 288
  end
end
