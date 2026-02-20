object DMIConsole: TDMIConsole
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 237
  Width = 503
  object FDPhysMySQLDriverLink1: TFDPhysMySQLDriverLink
    VendorLib = 'libmysql.dll'
    Left = 260
    Top = 80
  end
  object FDConnection: TFDConnection
    Params.Strings = (
      'Password=root'
      'DriverID=MySQL'
      'Database=sorma'
      'User_Name=root'
      'Server=192.168.255.201')
    LoginPrompt = False
    Left = 104
    Top = 76
  end
end
