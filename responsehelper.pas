unit responsehelper;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, Classes, fphttpserver;


procedure SendCode(var AResponse: TFPHTTPConnectionResponse; Code: Integer; CodeStr, Desc: string);

procedure Send404(var AResponse: TFPHTTPConnectionResponse);
procedure Send403(var AResponse: TFPHTTPConnectionResponse);

procedure SendText(TextToSend: TStrings; var AResponse: TFPHTTPConnectionResponse); overload;
procedure SendText(var TextToSend: string; var AResponse: TFPHTTPConnectionResponse); overload;

const
  VERSION = '$VER: MPW 0.2 (03.08.2025)';

implementation

uses
  fpmimetypes;

procedure Send404(var AResponse: TFPHTTPConnectionResponse); inline;
begin
  SendCode(AResponse, 404, 'Not Found', 'The requested URL was not found on the server.');
end;

procedure Send403(var AResponse: TFPHTTPConnectionResponse); inline;
begin
  SendCode(AResponse, 403, 'Forbidden', 'You have no access to this page.');
end;

procedure SendCode(var AResponse: TFPHTTPConnectionResponse; Code: Integer; CodeStr, Desc: string);
var
  Mem: TStringStream;
begin
  Mem := TStringStream.Create('<HTML><Title>' +  IntToStr(Code) + ' - ' + CodeStr + '</title><body><H1>' + IntToStr(Code)  + ' - ' + CodeStr + '</H1><p>' + Desc + '</p><p>Back to <a href="/">Main Page</a></p><HR><address>' + Copy(VERSION, 6, Pos('(', VERSION) - 6) + ' </address></body></html>');
  Mem.Position := 0;
  try
    AResponse.ContentType := MimeTypes.GetMimeType('.html');
    AResponse.ContentLength := Mem.Size;
    AResponse.ContentStream := Mem;
    AResponse.Code := Code;
    AResponse.CodeText := CodeStr;
    AResponse.SendContent;
    AResponse.ContentStream := nil;
  finally
    Mem.Free;
  end;
end;

procedure SendText(var TextToSend: string; var AResponse: TFPHTTPConnectionResponse);
var
  Mem: TStringStream;
begin
  Mem := TStringStream.Create(TextToSend);
  Mem.Position := 0;
  try
    AResponse.ContentType := MimeTypes.GetMimeType('.html');
    AResponse.ContentLength := Mem.Size;
    AResponse.ContentStream := Mem;
    AResponse.Code := 200;
    AResponse.SendContent;
    AResponse.ContentStream := nil;
  finally
    Mem.Free;
  end;
end;

procedure SendText(TextToSend: TStrings; var AResponse: TFPHTTPConnectionResponse);
var
  s: String;
begin
  s := TextToSend.Text;
  SendText(s, AResponse);
end;


end.

