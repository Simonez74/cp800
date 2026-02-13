object FrameService: TFrameService
  Left = 0
  Top = 0
  Width = 538
  Height = 425
  TabOrder = 0
  DesignSize = (
    538
    425)
  object lblResult: TLabel
    Left = 24
    Top = 256
    Width = 497
    Height = 25
    Caption = '---------'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clMaroon
    Font.Height = -19
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object Label1: TLabel
    Left = 165
    Top = 121
    Width = 75
    Height = 22
    Caption = 'Machine:'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
  end
  object Label2: TLabel
    Left = 43
    Top = 160
    Width = 200
    Height = 22
    Caption = 'Delete older ones from:'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
  end
  object DeleteOlds_DateTimePicker: TDateTimePicker
    Left = 249
    Top = 160
    Width = 113
    Height = 23
    Date = 45699.000000000000000000
    Time = 0.523965844906342700
    TabOrder = 0
  end
  object ButDeleteOlds: TButton
    Left = 299
    Top = 198
    Width = 229
    Height = 47
    Caption = 'Start'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    OnClick = ButDeleteOldsClick
  end
  object Memo1: TMemo
    Left = 10
    Top = 8
    Width = 518
    Height = 82
    Anchors = [akLeft, akTop, akRight]
    Lines.Strings = (
      'Clicking the "Delete older ones from:" button'
      'deletes all records from historical table'
      'previous to the entered date.')
    ReadOnly = True
    TabOrder = 2
  end
  object btnChiudi: TButton
    Left = 299
    Top = 340
    Width = 229
    Height = 53
    Anchors = [akTop, akRight, akBottom]
    Caption = 'Close'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
    OnClick = btnChiudiClick
  end
  object ComboBox1: TComboBox
    Left = 249
    Top = 120
    Width = 279
    Height = 23
    TabOrder = 4
    Text = 'ComboBox1'
  end
end
