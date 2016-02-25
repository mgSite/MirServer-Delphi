unit LogDataMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, ExtCtrls, IniFiles, IdBaseComponent,
  IdComponent, IdUDPBase, IdUDPServer, IdSocketHandle;
type
  TFrmLogData = class(TForm)
    Label3: TLabel;
    Label4: TLabel;
    Timer1: TTimer;
    IdUDPServerLog: TIdUDPServer;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure WriteLogFile();
    function IntToString(nInt: Integer): String;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure IdUDPServerLogUDPRead(Sender: TObject; AData: TStream;
      ABinding: TIdSocketHandle);
  private
    LogMsgList: TStringList;
    m_boRemoteClose: Boolean;
    { Private declarations }
  public
    procedure MyMessage(var MsgData: TWmCopyData); message WM_COPYDATA;
    { Public declarations }
  end;

var
  FrmLogData: TFrmLogData;
  {This file is generated by DeDe Ver 3.50.02 Copyright (c) 1999-2002 DaFixer}

implementation

uses LDShare, Grobal2, HUtil32;

{$R *.DFM}

procedure TFrmLogData.FormCreate(Sender: TObject);
var
  Conf: TIniFile;
  nX, nY: Integer;
begin
  g_dwGameCenterHandle := Str_ToInt(ParamStr(1), 0);
  nX := Str_ToInt(ParamStr(2), -1);
  nY := Str_ToInt(ParamStr(3), -1);
  if (nX >= 0) or (nY >= 0) then begin
    Left := nX;
    Top := nY;
  end;
  m_boRemoteClose := False;
  SendGameCenterMsg(SG_FORMHANDLE, IntToStr(Self.Handle));
  SendGameCenterMsg(SG_STARTNOW, '正在启动日志服务器...');
  LogMsgList := TStringList.Create;
  Conf := TIniFile.Create('.\logdata.ini');
  if Conf <> nil then begin
    sBaseDir := Conf.ReadString('Setup', 'BaseDir', sBaseDir);
    sServerName := Conf.ReadString('Setup', 'Caption', sServerName);
    sServerName := Conf.ReadString('Setup', 'ServerName', sServerName);
    nServerPort := Conf.ReadInteger('Setup', 'Port', nServerPort);
    Conf.Free;
  end;
  Caption := sCaption + ' (' + sServerName + ')';
  IdUDPServerLog.DefaultPort := nServerPort;
  IdUDPServerLog.Active := TRUE;
  //MUDP.LocalPort := nServerPort;
  SendGameCenterMsg(SG_STARTOK, '日志服务器启动完成...');
end;

procedure TFrmLogData.FormDestroy(Sender: TObject);
begin
  LogMsgList.Free;
end;

procedure TFrmLogData.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  if m_boRemoteClose then exit;
  if Application.MessageBox('是否确认退出服务器？',
    '提示信息',
    MB_YESNO + MB_ICONQUESTION) = IDYES then begin
  end else CanClose := False;
end;

procedure TFrmLogData.Timer1Timer(Sender: TObject);
begin
  WriteLogFile();
end;

procedure TFrmLogData.WriteLogFile();
var
  I: Integer;
  Year, Month, Day, Hour, Min, Sec, MSec: Word;
  sLogDir, sLogFile: String;
  s2E8: String;
  F: TextFile;
begin
  if LogMsgList.Count <= 0 then exit;
  DecodeDate(Date, Year, Month, Day);
  DecodeTime(Time, Hour, Min, Sec, MSec);
  sLogDir := sBaseDir + IntToStr(Year) + '-' + IntToString(Month) + '-' + IntToString(Day);
  if not FileExists(sLogDir) then begin
    CreateDirectoryA(PChar(sLogDir), nil);
  end;
  sLogFile := sLogDir + '\Log-' + IntToString(Hour) + 'h' + IntToString((Min div 10) * 2) + 'm.txt';
  Label4.Caption := sLogFile;
  try
    AssignFile(F, sLogFile);
    if not FileExists(sLogFile) then Rewrite(F)
    else Append(F);
    for I := 0 to LogMsgList.Count - 1 do begin
      Writeln(F, LogMsgList.Strings[I] + #9 + FormatDateTime('yyyy-mm-dd hh:mm:ss', Now));
      Flush(F)
    end;
    LogMsgList.Clear;
  finally
    CloseFile(F);
  end;
end;

procedure TFrmLogData.IdUDPServerLogUDPRead(Sender: TObject; AData: TStream;
  ABinding: TIdSocketHandle);
var
  LogStr: String;
begin
  try
    SetLength(LogStr, AData.Size);
    AData.Read(LogStr[1], AData.Size);
    LogMsgList.Add(LogStr);
  except

  end;
end;

function TFrmLogData.IntToString(nInt: Integer): String;
begin
  if nInt < 10 then Result := '0' + IntToStr(nInt)
  else Result := IntToStr(nInt);
end;

procedure TFrmLogData.MyMessage(var MsgData: TWmCopyData);
var
  sData: String;
  //ProgramType: TProgamType;
  wIdent: Word;
begin
  wIdent := HiWord(MsgData.From);
  //  ProgramType:=TProgamType(LoWord(MsgData.From));
  sData := StrPas(MsgData.CopyDataStruct^.lpData);
  case wIdent of //
    GS_QUIT: begin
        m_boRemoteClose := TRUE;
        Close();
      end;
    1: ;
    2: ;
    3: ;
  end; // case
end;

end.

