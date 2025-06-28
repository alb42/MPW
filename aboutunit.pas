unit aboutunit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fphttpserver;

procedure PrintAbout(Document: string; AResponse: TFPHTTPConnectionResponse);

implementation

uses
  EditUnit, Exec;

const
  Units: array[0..4] of string = ('', 'k', 'M', 'G', 'T');

function FormatMem(Bytes: Single): string;
var
  i: Integer;
begin
  for i := 0 to High(Units) do
  begin
    if Bytes < 1024 then
    begin
      Result := FloatToStrF(Bytes, ffFixed, 8, 1) + ' ' + Units[i] + 'bytes';
      Exit;
    end;
    Bytes := Bytes / 1024;
  end;
  Result := FloatToStrF(Bytes, ffFixed, 8, 1) + ' ' + Units[High(Units)] + 'bytes';
end;

function GetCPUName: string;
var
  MyExecBase: PExecBase;
begin
  MyExecBase := PExecBase(_ExecBase);
  if (MyExecBase^.AttnFlags and AFF_68060 <> 0) then Exit('68060');
  if (MyExecBase^.AttnFlags and AFF_68040 <> 0) then Exit('68040');
  if (MyExecBase^.AttnFlags and AFF_68030 <> 0) then Exit('68030');
  if (MyExecBase^.AttnFlags and AFF_68020 <> 0) then Exit('68020');
  if (MyExecBase^.AttnFlags and AFF_68010 <> 0) then Exit('68010');
  Result := '68000';
end;

type
  { THostEnt Object }
  THostEnt = record
    H_Name     : PAnsiChar;   { Official name }
    H_Aliases  : PPAnsiChar;  { Null-terminated list of aliases}
    H_Addrtype : longint;     { Host address type }
    H_length   : longint;     { Length of address }
    H_Addr     : PPAnsiChar;  { null-terminated list of adresses }
  end;
  PHostEntry = ^THostEnt;

var
  SocketBase: PLibrary;

function GetHostname(AName: PChar location 'a0'; NameLen: Integer location 'd0'): Integer; syscall SocketBase 282;
function GetHostbyName(Name: PAnsiChar location 'a0'): PHostEntry; syscall SocketBase 210;

function GetMyHostname: string;
var
  PC: PChar;
  HostEnt: PHostEntry;
  Add: PByte;
begin
  Result := 'localhost 127.0.0.1';
  SocketBase := OpenLibrary('bsdsocket.library', 0);
  if Assigned(SocketBase) then
  begin
    PC := AllocMem(1024);
    if GetHostName(PC, 1023) = 0 then
      Result := PC;
    HostEnt := GetHostbyName(PC);
    if Assigned(HostEnt) and Assigned(HostEnt^.H_Addr[0]) then
    begin
      Add := PByte(HostEnt^.H_Addr[0]);
      Result := Result + ' ' + IntToStr(add^) + '.';
      Inc(Add);
      Result := Result + IntToStr(add^) + '.';
      Inc(Add);
      Result := Result + IntToStr(add^) + '.';
      Inc(Add);
      Result := Result + IntToStr(add^);
    end;
    if Assigned(HostEnt) and Assigned(HostEnt^.H_Addr[1]) then
    begin
      Add := PByte(HostEnt^.H_Addr[1]);
      Result := Result + ' ' + IntToStr(add^) + '.';
      Inc(Add);
      Result := Result + IntToStr(add^) + '.';
      Inc(Add);
      Result := Result + IntToStr(add^) + '.';
      Inc(Add);
      Result := Result + IntToStr(add^);
    end;


    CloseLibrary(SocketBase);
    SocketBase := nil;
    Freemem(PC);
  end;


end;

procedure PrintAbout(Document: string; AResponse: TFPHTTPConnectionResponse);
var
  Answer: TStringList;
  s: String;
  Mema, Memt: ULONG;
  MyExecBase: PExecBase;
begin
  MyExecBase := PExecBase(_ExecBase);
  s := '';
  Answer := TStringList.Create;
  try
    // Header
    Answer.add('<html><head><title>MPW - About</title></head>');
    Answer.Add('<body>');
    Answer.Add('<H1>About</H1>');
    Answer.Add('<table border="0"><tr><td>');

    Answer.Add('<table border="1">');
    Answer.Add('<tr><th colspan="2" align="center"> Computer </th></tr>');

    Answer.Add('<tr><td valign="top">Type</td><td>Amiga</td></tr>');


    Answer.Add('<tr><td valign="top">CPU</td><td>' + GetCPUName + '</td></tr>');

    Mema := Exec.AvailMem(MEMF_CHIP);
    Memt := Exec.AvailMem(MEMF_CHIP or MEMF_TOTAL);
    s := 'Chip: ' + FormatMem(Memt) + ' ('  + FormatMem(Mema) + ' free)'  + '<BR>';
    
    Mema := Exec.AvailMem(MEMF_FAST);
    Memt := Exec.AvailMem(MEMF_FAST or MEMF_TOTAL);
    s := s + 'Fast: ' + FormatMem(Memt) + ' ('  + FormatMem(Mema) + ' free)'  + '<BR>';

    Answer.Add('<tr><td valign="top">Memory</td><td>' + s + '</td></tr>');

    Answer.Add('<tr><td valign="top">Name</td><td>' + GetMyHostname + '</td></tr>');


    Answer.Add('</table>');



    Answer.Add('</td><tr></table>');
    Answer.Add('</body></html>');
    s := Answer.Text;
  finally
    SendText(s, AResponse);
  end;
end;


end.

