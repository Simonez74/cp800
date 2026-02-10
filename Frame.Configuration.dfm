object FrameConfiguration: TFrameConfiguration
  Left = 0
  Top = 0
  Width = 692
  Height = 480
  TabOrder = 0
  object PageControl: TPageControl
    Left = 0
    Top = 34
    Width = 692
    Height = 446
    ActivePage = TsParametriDatabase
    Align = alClient
    TabOrder = 0
    OnChange = PageControlChange
    OnChanging = PageControlChanging
    object TsParametriDatabase: TTabSheet
      Caption = 'Param database'
      object lbl1: TLabel
        Left = 153
        Top = 23
        Width = 107
        Height = 15
        Alignment = taRightJustify
        Caption = 'Hostname/IP server:'
      end
      object lbl2: TLabel
        Left = 200
        Top = 57
        Width = 60
        Height = 15
        Alignment = taRightJustify
        Caption = 'Server port:'
      end
      object lbl3: TLabel
        Left = 176
        Top = 90
        Width = 84
        Height = 15
        Alignment = taRightJustify
        Caption = 'Database name:'
      end
      object lbl4: TLabel
        Left = 199
        Top = 120
        Width = 61
        Height = 15
        Alignment = taRightJustify
        Caption = 'User Name:'
      end
      object lbl5: TLabel
        Left = 207
        Top = 150
        Width = 53
        Height = 15
        Alignment = taRightJustify
        Caption = 'Password:'
      end
      object Label7: TLabel
        Left = 22
        Top = 176
        Width = 238
        Height = 23
        AutoSize = False
        Caption = 'Automatically delete events older than days:'
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlack
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Pitch = fpVariable
        Font.Style = []
        Font.Quality = fqDraft
        ParentFont = False
        Layout = tlCenter
        WordWrap = True
      end
      object Label1: TLabel
        Left = 484
        Top = 176
        Width = 163
        Height = 15
        Caption = 'Unloading belts configurations'
      end
      object EdMySqlIP: TEdit
        Left = 267
        Top = 23
        Width = 130
        Height = 23
        TabOrder = 0
        Text = 'localhost'
        TextHint = 'localhost'
      end
      object ButtonTestDB: TButton
        Left = 356
        Top = 55
        Width = 41
        Height = 21
        Caption = 'Test'
        TabOrder = 6
        OnClick = ButtonTestDBClick
      end
      object EdMySqlDbName: TEdit
        Left = 267
        Top = 86
        Width = 130
        Height = 23
        TabOrder = 2
      end
      object EdMySqlUserName: TEdit
        Left = 267
        Top = 116
        Width = 130
        Height = 23
        TabOrder = 3
      end
      object EdMySqlPsw: TEdit
        Left = 267
        Top = 146
        Width = 130
        Height = 23
        TabOrder = 4
      end
      object SpinEditDBPort: TSpinEdit
        Left = 266
        Top = 52
        Width = 72
        Height = 24
        MaxValue = 0
        MinValue = 0
        TabOrder = 1
        Value = 3306
      end
      object SpinEditDelEventsOlderThan: TSpinEdit
        Left = 266
        Top = 175
        Width = 72
        Height = 24
        MaxValue = 0
        MinValue = 0
        TabOrder = 5
        Value = 7
      end
      object MemoDBInfo: TMemo
        Left = 0
        Top = 292
        Width = 684
        Height = 124
        Align = alBottom
        TabOrder = 7
      end
      object CbBeltB: TCheckBox
        Left = 266
        Top = 212
        Width = 97
        Height = 17
        Caption = 'Belt B enabled'
        TabOrder = 8
      end
      object CbBeltC: TCheckBox
        Left = 267
        Top = 235
        Width = 97
        Height = 17
        Caption = 'Belt C enabled '
        TabOrder = 9
      end
      object CbBeltD: TCheckBox
        Left = 267
        Top = 258
        Width = 97
        Height = 17
        Caption = 'Belt D enabled '
        TabOrder = 10
      end
    end
    object TsCp800_setup: TTabSheet
      Caption = 'Machines'
      ImageIndex = 2
      object DBGrid1: TDBGrid
        Left = 0
        Top = 0
        Width = 684
        Height = 199
        Align = alClient
        DataSource = DsCp800_setup
        Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -12
        TitleFont.Name = 'Segoe UI'
        TitleFont.Style = []
        Columns = <
          item
            Expanded = False
            FieldName = 'cp800_ID'
            Title.Caption = 'ID'
            Width = 30
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'cp800_name'
            Title.Caption = 'Name'
            Width = 171
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'cp800_IP'
            Title.Caption = 'IP'
            Width = 117
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'FtpPort'
            Title.Caption = 'Ftp Port'
            Width = 50
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'FtpUser'
            Title.Caption = 'Ftp User'
            Width = 93
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'FtpPassword'
            Title.Caption = 'Ftp Password'
            Width = 104
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'FtpIdle'
            Title.Caption = 'Ftp Idle'
            Width = 49
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'cp800_enabled'
            Title.Caption = 'Enabled'
            Visible = True
          end>
      end
      object DBNavigator1: TDBNavigator
        Left = 0
        Top = 199
        Width = 684
        Height = 25
        DataSource = DsCp800_setup
        Align = alBottom
        TabOrder = 1
      end
      object PanelDatiDatabase: TPanel
        Left = 0
        Top = 224
        Width = 684
        Height = 192
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 2
        object Label39: TLabel
          Left = 12
          Top = 0
          Width = 13
          Height = 15
          Caption = 'Id:'
        end
        object Label40: TLabel
          Left = 92
          Top = 0
          Width = 35
          Height = 15
          Caption = 'Name:'
        end
        object Label41: TLabel
          Left = 15
          Top = 42
          Width = 13
          Height = 15
          Caption = 'IP:'
          FocusControl = DbEd_cp800_IP
        end
        object Label4: TLabel
          Left = 186
          Top = 42
          Width = 25
          Height = 15
          Caption = 'Port:'
        end
        object Label5: TLabel
          Left = 320
          Top = 42
          Width = 74
          Height = 15
          Caption = 'Read timeout:'
        end
        object DbEd_cp800_IP: TDBEdit
          Left = 12
          Top = 57
          Width = 160
          Height = 23
          DataField = 'cp800_IP'
          DataSource = DsCp800_setup
          TabOrder = 2
        end
        object EDcp800SDO_Active: TDBCheckBox
          Left = 484
          Top = 19
          Width = 84
          Height = 17
          Caption = 'Enabled'
          DataField = 'cp800_enabled'
          DataSource = DsCp800_setup
          TabOrder = 5
          ValueChecked = '1'
          ValueUnchecked = '0'
        end
        object DBcp800_Port: TDBEdit
          Left = 186
          Top = 57
          Width = 121
          Height = 23
          DataField = 'cp800_Port'
          DataSource = DsCp800_setup
          TabOrder = 3
        end
        object DBcp800_timeoutread: TDBEdit
          Left = 320
          Top = 57
          Width = 95
          Height = 23
          DataField = 'cp800_timeoutread'
          DataSource = DsCp800_setup
          TabOrder = 4
        end
        object GbParametriFTP: TGroupBox
          Left = 0
          Top = 89
          Width = 684
          Height = 103
          Align = alBottom
          Caption = 'Settings Ftp'
          TabOrder = 6
          object Label45: TLabel
            Left = 9
            Top = 15
            Width = 34
            Height = 13
            AutoSize = False
            Caption = 'User:'
          end
          object Label46: TLabel
            Left = 178
            Top = 15
            Width = 60
            Height = 13
            AutoSize = False
            Caption = 'Password:'
          end
          object Label42: TLabel
            Left = 394
            Top = 13
            Width = 25
            Height = 15
            Caption = 'Port:'
          end
          object Label47: TLabel
            Left = 10
            Top = 56
            Width = 58
            Height = 13
            AutoSize = False
            Caption = 'Idle time:'
          end
          object Label6: TLabel
            Left = 154
            Top = 56
            Width = 34
            Height = 13
            AutoSize = False
            Caption = 'Path:'
          end
          object DBEditUser: TDBEdit
            Left = 9
            Top = 29
            Width = 146
            Height = 23
            DataField = 'FtpUser'
            DataSource = DsCp800_setup
            TabOrder = 0
          end
          object DBEditPassword: TDBEdit
            Left = 178
            Top = 29
            Width = 210
            Height = 23
            DataField = 'FtpPassword'
            DataSource = DsCp800_setup
            TabOrder = 1
          end
          object DbEd_cp800_Port: TDBEdit
            Left = 394
            Top = 29
            Width = 60
            Height = 23
            DataField = 'FtpPort'
            DataSource = DsCp800_setup
            TabOrder = 2
          end
          object DBEditIdle: TDBEdit
            Left = 9
            Top = 72
            Width = 121
            Height = 23
            DataField = 'FtpIdle'
            DataSource = DsCp800_setup
            TabOrder = 3
          end
          object DBFTpPath: TDBEdit
            Left = 154
            Top = 72
            Width = 388
            Height = 23
            DataField = 'FTpPath'
            DataSource = DsCp800_setup
            TabOrder = 5
          end
          object DBCheckBox1: TDBCheckBox
            Left = 464
            Top = 32
            Width = 97
            Height = 17
            Caption = 'Passive mode'
            DataField = 'FtpPassiveMode'
            DataSource = DsCp800_setup
            TabOrder = 4
          end
        end
        object DBEdit1: TDBEdit
          Left = 12
          Top = 16
          Width = 61
          Height = 23
          DataField = 'cp800_ID'
          DataSource = DsCp800_setup
          TabOrder = 0
        end
        object DBEdit2: TDBEdit
          Left = 92
          Top = 16
          Width = 373
          Height = 23
          DataField = 'cp800_name'
          DataSource = DsCp800_setup
          TabOrder = 1
        end
      end
    end
    object TsServizi: TTabSheet
      Caption = 'Service'
      ImageIndex = 3
      object Memo1: TMemo
        Left = 8
        Top = 16
        Width = 509
        Height = 66
        Lines.Strings = (
          'Clicking the "Delete older ones from:" button'
          'deletes all records from the "cp800Storico" table'
          'previous to the entered date.')
        ReadOnly = True
        TabOrder = 0
      end
      object DeleteOlds_DateTimePicker: TDateTimePicker
        Left = 167
        Top = 100
        Width = 113
        Height = 23
        Date = 45699.000000000000000000
        Time = 0.523965844906342700
        TabOrder = 1
      end
      object ButDeleteOlds: TButton
        Left = 8
        Top = 98
        Width = 137
        Height = 25
        Caption = 'Delete older ones from:'
        TabOrder = 2
        OnClick = ButDeleteOldsClick
      end
    end
  end
  object PanelConfigHeader: TPanel
    Left = 0
    Top = 0
    Width = 692
    Height = 34
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 1
    object LabelConfigTitle: TLabel
      Left = 250
      Top = 0
      Width = 442
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
      ExplicitLeft = 0
      ExplicitTop = -1
      ExplicitWidth = 692
    end
    object ButtonApply: TButton
      AlignWithMargins = True
      Left = 10
      Top = 3
      Width = 75
      Height = 28
      Margins.Left = 10
      Align = alLeft
      Caption = 'Apply'
      TabOrder = 0
      OnClick = ButtonApplyClick
    end
    object ButtonSave: TButton
      AlignWithMargins = True
      Left = 91
      Top = 3
      Width = 75
      Height = 28
      Align = alLeft
      Caption = 'Save'
      TabOrder = 1
      OnClick = ButtonSaveClick
    end
    object ButtonCancel: TButton
      AlignWithMargins = True
      Left = 172
      Top = 3
      Width = 75
      Height = 28
      Align = alLeft
      Caption = 'Cancel'
      TabOrder = 2
      OnClick = ButtonCancelClick
    end
  end
  object DsCp800_setup: TDataSource
    DataSet = Qcp800_setup
    Left = 448
    Top = 134
  end
  object Qcp800_setup: TFDQuery
    Connection = DMIConsole.FDConnection
    SQL.Strings = (
      'SELECT * FROM cp800_setup')
    Left = 440
    Top = 70
  end
end
