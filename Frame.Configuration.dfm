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
      Caption = 'Params database'
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
        Left = 87
        Top = 212
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
        Top = 281
        Width = 684
        Height = 101
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
      object Panel1: TPanel
        Left = 0
        Top = 382
        Width = 684
        Height = 34
        Align = alBottom
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 11
        ExplicitLeft = -3
        ExplicitTop = 398
        object ButtonApply: TButton
          AlignWithMargins = True
          Left = 501
          Top = 3
          Width = 75
          Height = 28
          Margins.Right = 20
          Align = alRight
          Caption = 'Apply'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -16
          Font.Name = 'Segoe UI'
          Font.Style = []
          ImageIndex = 2
          Images = ImageList1
          ParentFont = False
          TabOrder = 0
          OnClick = ButtonApplyClick
          ExplicitLeft = 437
          ExplicitTop = 6
        end
        object ButtonSave: TButton
          AlignWithMargins = True
          Left = 403
          Top = 3
          Width = 75
          Height = 28
          Margins.Right = 20
          Align = alRight
          Caption = 'Save'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -16
          Font.Name = 'Segoe UI'
          Font.Style = []
          ImageIndex = 0
          Images = ImageList1
          ParentFont = False
          TabOrder = 1
          OnClick = ButtonSaveClick
          ExplicitLeft = 519
          ExplicitTop = -1
        end
        object ButtonCancel: TButton
          AlignWithMargins = True
          Left = 599
          Top = 3
          Width = 75
          Height = 28
          Margins.Right = 10
          Align = alRight
          Caption = 'Cancel'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -16
          Font.Name = 'Segoe UI'
          Font.Style = []
          ImageIndex = 1
          Images = ImageList1
          ParentFont = False
          TabOrder = 2
          OnClick = ButtonCancelClick
          ExplicitLeft = 600
          ExplicitTop = -1
        end
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
      Font.Height = -19
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      Layout = tlCenter
      ExplicitHeight = 28
    end
  end
  object DsCp800_setup: TDataSource
    DataSet = Qcp800_setup
    Left = 448
    Top = 134
  end
  object Qcp800_setup: TFDQuery
    BeforePost = Qcp800_setupBeforePost
    Connection = DMIConsole.FDConnection
    SQL.Strings = (
      'SELECT * FROM cp800_setup')
    Left = 440
    Top = 70
  end
  object ImageList1: TImageList
    Left = 536
    Top = 108
    Bitmap = {
      494C010103000800040010001000FFFFFFFFFF10FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000400000001000000001002000000000000010
      00000000000000000000000000000000000000000000888888776060609F6060
      609F6060609F6060609F6060609F6060609F6060609F6060609F6060609F6060
      609F6060609F6161619EE7E7E718000000000000000000000000000000000000
      000000000000EAE7E359D0CBC0C8C5BEB0FBC8C2B5EBDBD6CE9BFBFBFA0E0000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000EBF1EC15FBFBFB040000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000E0E0EF1D6AC00FFDDBA00FFE3C6
      00FFE9D200FFEFDE00FFF4E800FFF7EF00FFF6EC00FFF1E300FFECD800FFE6CC
      00FFE0C000FFDBB400FF624D00FFE6E6E619000000000000000000000000DEDA
      D28CC5BEB0FFD3CEC3BEF0EFEC3AFEFEFE03F9F8F815E4E0DA72C4BDAFFDC5BE
      B0FAFCFCFC090000000000000000000000000000000000000000000000000000
      000000000000ADDDAD7563D065FCA4D9A68EFEFEFE0100000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000004D3C00FFD8AF00FFDFC130FFF9F5
      E7FFF9F5E7FFF9F5E7FFF9F5E7FFF9F5E7FFF9F5E7FFF9F5E7FFF9F5E7FFF9F5
      E7FFF5EFD8FFDBB500FFD5A800FF6161619E0000000000000000C9C2B5EACDC8
      BCD600000000000000000000000000000000000000000000000000000000F3F2
      EF33C5BEB0FFF2F1EE310000000000000000000000000000000000000000FEFE
      FE019FD69E7F50C34EFE5ECE5FFF6DD872FBD0E5D14200000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000004F3D00FFD8AE00FFEEDC7FFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFDBB500FFD5A800FF6060609F00000000CEC8BCD3D4CFC5B60000
      0000000000000000000000000000000000000000000000000000000000000000
      0000FEFEFD05C5BEB0FFFCFCFC09000000000000000000000000FEFEFE0190CE
      8D8940B539FF4CBF48FF59CA59FF67D66BFF82DA87DAEFF2F010000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000004E3C00FFD6AB00FFEDDA7FFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFDAB200FFD4A500FF6060609FF5F4F226C4BDAFFC000000000000
      0000A6A7F36FC8C9F743000000000000000000000000000000008183EE9EFDFD
      FF0200000000F3F2EF33C5BEB0FA0000000000000000FDFDFD0281C57C9330A9
      25FF3BB132FF47BB42FF53C652FF61D062FF6EDC74FFA4DCA894FDFDFD020000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000004E3B00FFD4A700FFECD87FFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFD7AD00FFD2A100FF6060609FC6BFB1F6F6F5F323000000000000
      00003539E5FF3539E5FFB9BAF5570000000000000000373BE4FB3539E5FF8082
      ED9F0000000000000000C4BDAFFDFBFBFA0EFCFDFC0377BF709C239E14FF2BA5
      1FFF35AD2CFF45B73FFA7ACD78CF59CA59FF65D468FF70DB76FCCEE4CF450000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000004D3900FFD2A100FFEAD47FFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFD4A700FFCF9C00FF6060609FC5BEB0FF00000000000000000000
      0000B9BAF5573539E5FF3539E5FFB9BAF557373BE4FB3539E5FF373BE4FB0000
      00000000000000000000E4E1DB72DBD7CE9B9DD0988441A732FF279E18FF26A1
      19FF3AAC30F4BFE1BE4FEDF7ED1868CA67EF5ACC5BFF65D468FF7CD680DCEFF3
      F011000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000004B3600FFCE9A00FFE8D07FFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFD19F00FFCC9500FF6060609FC5BEB0FF00000000000000000000
      000000000000B9BAF5573539E5FF3539E5FF3539E5FF373BE4FB000000000000
      00000000000000000000F9F9F815C9C2B5EB80C278B943A834FF44AA36FF43AB
      38ECCCE6CB3B0000000000000000BCE5BC6955C553FF59CB59FF62D265FF9BD5
      9C98FDFDFD020000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000004A3300FFCA9200FFE6CC7EFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFCC9600FFC88D00FF6060609FC5BEB0FF00000000000000000000
      00000000000000000000373BE4FB3539E5FF3539E5FFB9BAF557000000000000
      00000000000000000000FEFEFE03C5BEB0FBD5EAD43D70BB67CF7CC274B6DEEE
      DD29000000000000000000000000FDFDFD027DCE7BC84DC14AFF55C754FF5DCC
      5EFCC8E1C9480000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000483000FFC68900FFCA9100FFCD98
      00FFD09E00FFD2A300FFD4A600FFD5A700FFD4A700FFD3A500FFD1A100FFCF9B
      00FFCC9500FFC88D00FFC48400FF6060609FC5BEB0FF00000000000000000000
      000000000000373BE4FB3539E5FF373BE4FB3539E5FF3539E5FFB9BAF5570000
      00000000000000000000F1EFEC3AD0CBBFCB0000000000000000000000000000
      000000000000000000000000000000000000DDF1DD305AC055FB51C04DFF55C4
      52FF6CC86BDEEDF1ED1300000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000472D00FFC17F00FFC58600FFC88D
      00FFC89300FFCA9700FFCB9900FFCB9A00FFCB9A00FFCA9800FFC99500FFC891
      00FFC68A00FFC38300FFBF7B00FF6060609FC5BEB0FF00000000000000000000
      0000373BE4FB3539E5FF373BE4FB00000000B9BAF5573539E5FF3539E5FFC9CA
      F7430000000000000000D3CEC3BEEAE7E2590000000000000000000000000000
      00000000000000000000000000000000000000000000A8DBA68E59BE52FF5AC0
      55FF5DC358FF94CE939BFDFDFD02000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000452900FFBC7500FFC07C00FFC282
      00FFE5E1DEFFEEECEAFFE8E5E2FFDCD7D2FFCCC5BEFFBBB1A7FFA89B8EFFB188
      28FFC17F00FFBE7800FFBA7100FF6060609FDAD6CD9DDAD6CE9B000000000000
      00003539E5FF373BE4FB000000000000000000000000B9BAF5573539E5FFA6A7
      F36F0000000000000000C5BEB0FF000000000000000000000000000000000000
      00000000000000000000000000000000000000000000F4FBF40C70C46AE252B9
      49FF54BB4CFF56BB50FDC4DDC34C000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000432500FFB76A00FFBA7100FFBD76
      00FFDBD7D2FFE8E5E2FFEEECEAFFE5E2DEFFD7D2CCFF956E12FFAD9D80FFB58A
      2DFFBC7400FFB96E00FF533E00FFC1C1C13E00000000C5BEB0FFFBFBFB0C0000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000CDC7BCD6DEDAD28C000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000C9E7C95153B5
      49FF4DB342FF4EB544FF62BA5BE0ECF0EC140000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000432400FFB36100FFB56500FFB76A
      00FFD1CBC4FFE0DBD7FFEBE9E6FFECEAE7FFE1DDD9FFA7800BFFBBAC8CFFB88B
      32FFB66800FF4D3A00FFC6C6C6390000000000000000F6F5F324C5BEB0FFFBFB
      FB0C000000000000000000000000000000000000000000000000000000000000
      0000D5D0C6B5C9C2B5EA00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000008BCC
      85B247AE3BFF48AE3CFF48AF3CFFA8D2A5720000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000001B1500FFB36100FFB36100FFB361
      00FFC5BDB5FFD6D0CAFFE3E0DCFFEEEBE9FFEAE7E4FFD0C08EFFCCC3B2FFBB8D
      36FF453400FFCBCBCB3400000000000000000000000000000000F5F4F324C5BE
      B0FFDBD7CE9B0000000000000000000000000000000000000000F6F5F323C5BE
      B0FBCEC8BCD30000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000000000E7F4
      E71F59B34EF443AA36FF44AA36FFA5D2A1760000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000C2C2C23D171300FF453A00FF453A
      00FF46423EFF4C4A47FF52504EFF575654FF595857FF555453FF504E4CFF2D29
      15FFD4D4D42B0000000000000000000000000000000000000000000000000000
      0000DAD6CD9DC5BEB0FFC5BEB0FFC5BEB0FFC5BEB0FFC5BEB0FFC6C0B2F5F6F5
      F225000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000CEE8CD477FC477B99BD1968AF6F9F6090000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000040000000100000000100010000000000800000000000000000000000
      000000000000000000000000FFFFFF008001F81FFCFF00000000E007F87F0000
      0000CFE3E07F000000009FF1C03F0000000033C9801F00000000318C001F0000
      0000701C000F00000000783C0607000000007C3C0E0700000000781CFF030000
      0000710CFF8100000000338DFF81000000009FF9FFC0000000018FF3FFE00000
      0003C7C7FFE000000007F00FFFF0000000000000000000000000000000000000
      000000000000}
  end
end
