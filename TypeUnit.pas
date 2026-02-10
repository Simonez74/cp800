unit TypeUnit;

interface

uses  System.Generics.Collections
      ,system.SysUtils
      ,VCL.StdCtrls
      ;




type

  // Tipo per la callback di logging
  TLogProc = reference to procedure(const AMsg: string);


  TServerConfig = record
    Host: string;
    Port: Integer;
    Username: string;
    Password: string;
    RemotePath: string;
    FileName: string;
    FileNameProd: string;
    Id: string;
    NameMachine : String;
    Intervall : integer;
    PassiveMode : boolean;
  end;

  TServerData = record
//    Values: TDictionary<string, Integer>;
    Values: TDictionary<string, string>;
    LastUpdate: TDateTime;
    ErrorMessage: string;
    IsOnline: Boolean;
    IsConnected: Boolean;
    DownloadCount: Int64;
    ErrorCount: Int64;
  end;

  // Record per dati pesatura
  TWeightRecord = record
    ID: string;
    PartNumber: string;
    Time: string;
    ValA: integer;
    ValB: integer;
    ValC: integer;
    ValD: integer;
    Counter: Integer;
    RawLine: string;

    function HasNonZeroWeight: Boolean;
    function GetNonZeroChannel: string;
    function GetNonZeroValue: string;
  end;


   // Snapshot immutabile dello stato
  TSituazioneXLog = record
    DsProgram: string;
    InStart: Boolean;
    PackMode: string;
    ShouldRun: Boolean;
    OutputFileName: string;
    LastIDFile: string;

    function IsValid: Boolean;
    function HasChanged(const Other: TSituazioneXLog): Boolean;
  end;


  TLabelType = (ltStandard, ltSimonLabel);

  TLabelInfo = record
    Label1: TLabel;
    LabelType: TLabelType;
  end;






implementation



{ TWeightRecord }

function TWeightRecord.GetNonZeroChannel: string;
begin
  if ValA <> 0 then
    Result := 'A'
  else if ValB <> 0 then
    Result := 'B'
  else if ValC <> 0 then
    Result := 'C'
  else if ValD <> 0 then
    Result := 'D'
  else
    Result := '';
end;

function TWeightRecord.GetNonZeroValue: string;
begin
  if ValA <> 0 then
//    Result := FloatToStr(ValA)
    Result := IntToStr(ValA)
  else if ValB <> 0 then
//    Result := FloatToStr(ValB)
    Result := IntToStr(ValB)
  else if ValC <> 0 then
    // Result := FloatToStr(ValC)
    Result := IntToStr(ValC)
  else if ValD <> 0 then
//    Result := FloatToStr(ValD)
    Result := IntToStr(ValD)
  else
    Result := '';
end;

function TWeightRecord.HasNonZeroWeight: Boolean;
begin
  Result := (ValA <> 0) or (ValB <> 0) or (ValC <> 0) or (ValD <> 0);
end;

{ TSituazioneXLog }

function TSituazioneXLog.HasChanged(const Other: TSituazioneXLog): Boolean;
begin
  Result := (DsProgram <> Other.DsProgram) or
            (InStart <> Other.InStart) or
            (PackMode <> Other.PackMode);
end;

function TSituazioneXLog.IsValid: Boolean;
begin
  Result := (DsProgram <> '') and (OutputFileName <> '');
end;

end.
