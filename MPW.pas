program MPW;

{$mode objfpc}{$H+}
{$define UseCThreads}

uses
  {$ifdef HASAMIGA}
  athreads,
  {$endif}
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Exec, AmigaDos, workbench, icon,
  sysutils, strutils,Classes, fphttpserver, fpmimetypes, wikiserverunit, MUIClass.Dialog,
  documentsunit, editunit, templateunit, fphttpclient, mainguiunit, searchunit, debugunit, aboutunit, imagesunit;

Type

  { TMainThread }

  TMainThread = class(TThread)
  private
    FIsRunning: Boolean;
    FShowException: Boolean;
  protected
    procedure Execute; override;
  public
    property ShowException: Boolean read FShowException write FShowException;
    property IsRunning: Boolean read FIsRunning;
  end;

  { THTTPServer }

  THTTPServer = Class(TWikiServer)
  Protected
    Procedure DoIdle(Sender : TObject);
    procedure DoWriteInfo(S: string);
  end;

Var
  Serv : THTTPServer;
  MT: TMainThread = nil;

{ TMainThread }

procedure TMainThread.Execute;
begin
  FIsRunning := True;
  DebugOut('Start Thread');
  Serv:=THTTPServer.Create(Nil);
  try
    try
      Serv.Port := ServerPort;
      Serv.MimeTypesFile:= IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0))) + 'mime.types';
      serv.Threaded := False;
      Serv.AcceptIdleTimeout := 0;
      Serv.OnAcceptIdle := @Serv.DoIdle;
      Serv.WriteInfo := @Serv.DoWriteInfo;
      Serv.KeepConnections := True;
      Serv.Active:=True;
    except
      on E: Exception do
      begin
        if ShowException then
          ShowMessage('Error HTTP server: ' + E.Message)
        else
          writeln('Error HTTP server: ' + E.Message);
      end;
    end;
  finally
    FIsRunning := False;
    DebugOut('end thread');
    Serv.Free;
    if Assigned(OnServerEnd) then
      OnServerEnd(Self);
  end;
end;

{ THTTPServer }

procedure THTTPServer.DoIdle(Sender: TObject);
begin
  //Writeln('Idle, waiting for connections');
end;

procedure THTTPServer.DoWriteInfo(S: string);
begin
  DebugOut(S);
end;


procedure Startme;
var
  WithGUI: Boolean;
  i: Integer;
  DObj: pDiskObject;
begin
  WithGUI := True;
  if FindCmdLineSwitch('h') then
  begin
    Writeln('Usage: ',ExtractFileName(ParamStr(0)),' -noGUI -p [port]');
    writeln('  -noGUI do not show the MUI GUI');
    Writeln('  -p port for the server, Default: 8080');
    Exit;
  end;
  if FindCmdLineSwitch('noGUI') then
  begin
    WithGUI := False;
    writeln('no GUI');
  end;
  //
  if Assigned(System.AOS_wbMsg) then
  begin
    DObj := GetDiskObject(PChar(ParamStr(0)));
    if Assigned(DObj) then
    begin
      ServerPort := StrToIntDef(GetStrToolType(DObj, 'PORT', '8080'), 8080);
      FreeDiskObject(DObj);
    end;
  end;
  //
  for i := 1 to ParamCount do
  begin
    if (ParamStr(i) = '-p') and (i < ParamCount) then
    begin
      ServerPort := StrToIntDef(ParamStr(i + 1), 8080);
      Break;
    end;
  end;
  //
  Serv := nil;
  MT := TMainThread.Create(True);
  MT.ShowException := WithGUI;
  if WithGUI then
  begin // ############ WITH GUI
    MT.Start;
    DebugOut('Server Started');
    StartGUI;
  end
  else
  begin // ############ WITHOUT GUI
    writeln('MPW server at port ', ServerPort);
    writeln('Press Ctrl+C to quit');
    MT.Start;
    Wait(SIGBREAKF_CTRL_C);
    writeln('End server');
  end;
  // quit everything
  if Assigned(Serv) then
  begin
    Serv.Active := False;
    try
      TFPHTTPClient.SimpleGet('http://localhost:' + IntToStr(ServerPort) + '/quit/');
    except
    end;
  end;
  MT.WaitFor;
  MT.Free;
  DebugOut('program end');
end;


begin
  Startme;
end.

