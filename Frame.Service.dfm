object FrameService: TFrameService
  Left = 0
  Top = 0
  Width = 692
  Height = 480
  TabOrder = 0
  object PanelConfigHeader: TPanel
    Left = 0
    Top = 0
    Width = 692
    Height = 34
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object LabelConfigTitle: TLabel
      Left = 0
      Top = 0
      Width = 692
      Height = 34
      Align = alClient
      Alignment = taCenter
      AutoSize = False
      Caption = 'Settings'
      Color = clGray
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clMaroon
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      Layout = tlCenter
      ExplicitTop = -1
    end
  end
  object DeleteOlds_DateTimePicker: TDateTimePicker
    Left = 169
    Top = 140
    Width = 113
    Height = 23
    Date = 45699.000000000000000000
    Time = 0.523965844906342700
    TabOrder = 1
  end
  object ButDeleteOlds: TButton
    Left = 10
    Top = 138
    Width = 137
    Height = 25
    Caption = 'Delete older ones from:'
    TabOrder = 2
    OnClick = ButDeleteOldsClick
  end
  object Memo1: TMemo
    Left = 10
    Top = 56
    Width = 509
    Height = 66
    Lines.Strings = (
      'Clicking the "Delete older ones from:" button'
      'deletes all records from the "cp800Storico" table'
      'previous to the entered date.')
    ReadOnly = True
    TabOrder = 3
  end
end
