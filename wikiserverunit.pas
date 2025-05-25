unit wikiserverunit;

{$mode objfpc}{$H+}

interface

uses
  sysutils, Classes, fphttpserver, fpmimetypes,
  URIParser, sockets,
  MarkdownProcessor,
  MarkdownUtils;

Type

  TWriteInfoMethod = procedure(S: string) of object;

  { TWikiServer }

  TWikiServer = Class(TFPHTTPServer)
  private
    //FBaseDir : String;
    //FCount : Integer;
    FMimeLoaded : Boolean;
    FMimeTypesFile: String;
    FWriteInfo: TWriteInfoMethod;
  Protected
    procedure CheckMimeLoaded;

    Property MimeLoaded : Boolean Read FMimeLoaded;
  public
    procedure HandleRequest(Var ARequest: TFPHTTPConnectionRequest;
                            Var AResponse : TFPHTTPConnectionResponse); override;
    //Property BaseDir : String Read FBaseDir Write SetBaseDir;
    Property MimeTypesFile : String Read FMimeTypesFile Write FMimeTypesFile;
    Property WriteInfo: TWriteInfoMethod Read FWriteInfo Write FWriteInfo;
  end;

var
  AllowRemoteEdit: Boolean = False;
  ServerPort: Integer = 8080;

implementation

uses
  documentsunit, editunit, searchunit, httpprotocol, templateunit, debugunit;

{ TWikiServer }

procedure TWikiServer.CheckMimeLoaded;
begin
  if (not MimeLoaded) and (MimeTypesFile <> '') then
  begin
    MimeTypes.LoadFromFile(MimeTypesFile);
    FMimeLoaded := True;
  end;
end;

procedure LoadImage(Path: string; AResponse: TFPHTTPConnectionResponse);
var
  FileName: String;
  FS: TFileStream;
begin
  FileName := DataFolder + Path;
  if not FileExists(Filename) then
  begin
    Send404(AResponse);
    Exit;
  end;

  FS := TFileStream.Create(Filename, fmOpenRead);
  try
    AResponse.ContentType:=MimeTypes.GetMimeType(ExtractFileExt(FileName));
    //WriteInfo('Connection ('+aRequest.Connection.ConnectionID+') - Request ['+aRequest.RequestID+']: Serving file: "'+Fn+'". Reported Mime type: '+AResponse.ContentType);
    AResponse.ContentLength:=FS.Size;
    AResponse.ContentStream:=FS;
    AResponse.SendContent;
    AResponse.ContentStream:=Nil;
  finally
    FS.Free;
  end;
end;

procedure TWikiServer.HandleRequest(var ARequest: TFPHTTPConnectionRequest;
  var AResponse: TFPHTTPConnectionResponse);

Var
  //F : TFileStream;
  Mem: TStringStream;
  FN , Txt, AFilename, HtmlTxt: String;
  URI: TURI;
  MD: TMarkdownProcessor;
  AName: string;
  IsLocalCall: Boolean;

  function CheckIfAllowed(): Boolean;
  begin
    Result := IsLocalCall;
    if not Result then
    begin
      if AllowRemoteEdit then
        Exit(True);
      Send403(AResponse);
    end;
  end;

begin
  IsLocalCall := NetAddrToStr(ARequest.Connection.Socket.RemoteAddress.sin_addr) = '127.0.0.1';
  WriteInfo('Connection ('+aRequest.Connection.ConnectionID+') - Request ['+aRequest.RequestID+'] from ' + NetAddrToStr(ARequest.Connection.Socket.RemoteAddress.sin_addr) + ': ' + ARequest.Url);
  try
    URI:=ParseURI(ARequest.Url, True);
    DebugOut('Path: ' + URI.Path);
    DebugOut('Document:' + URI.Document);
    FN:=URI.Path+URI.Document;
    if HTTPDecode(URI.Document) = 'Main Page' then
      URI.Document := '';
    if Uri.Path <> '/' then
    begin
      CheckMimeLoaded;
      //
      case Uri.Path of
        '/edit/': if CheckIfAllowed() then EditDocument(URI.Document, False, AResponse);
        '/new/': if CheckIfAllowed() then EditDocument(URI.Document, True, AResponse);
        '/save/': if CheckIfAllowed() then SaveDocument(ARequest.ContentFields, AResponse);
        '/list/': ListAllFiles(AResponse);
        '/pics/': LoadImage(FN, AResponse);
        '/search/': SearchDocument(ARequest.ContentFields, AResponse);
        else
        begin
          Send404(AResponse);
        end;
      end;
      // we have a command
      Exit;
    end;



    AName := HTTPDecode(URI.Document);

    MD := TMarkdownProcessor.CreateDialect(mdCommonMark);
    AFilename := '';
    if URI.Document <> '' then
      AFilename := IncludeTrailingPathDelimiter(DataFolder) + GetFilename(AName)
    else
      AFilename := IncludeTrailingPathDelimiter(DataFolder) + 'Mainpage.md';
    WriteInfo('read file ' + AFilename);
    if not FileExists(AFilename) then
    begin
      if CheckIfAllowed() then
        EditDocument(URI.Document, False, AResponse);
      Exit;
    end;

    Txt := MD.processFile(AFilename);
    MD.Free;
    //
    HtmlTxt := PageTemplate;
    HtmlTxt := StringReplace(HtmlTxt, '%name%', INetString(Aname), [rfReplaceAll]);
    HtmlTxt := StringReplace(HtmlTxt, '%doclink%', URI.Document, [rfReplaceAll]);
    HtmlTxt := StringReplace(HtmlTxt, '%txt%', Txt, [rfReplaceAll]);
    Mem := TStringStream.Create(HtmlTxt);
    Mem.Position := 0;
    try
      AResponse.ContentType:=MimeTypes.GetMimeType('.html');
      WriteInfo('Connection ('+aRequest.Connection.ConnectionID+') - Request ['+aRequest.RequestID+']: Serving file: "'+Fn+'". Reported Mime type: '+AResponse.ContentType);
      AResponse.ContentLength:=Mem.Size;
      AResponse.ContentStream:=Mem;
      AResponse.SendContent;
      AResponse.ContentStream:=Nil;
    finally
      Mem.Free;
    end;
  except
    on E: Exception do
    begin
      WriteInfo('Connection ('+aRequest.Connection.ConnectionID+') - Request ['+aRequest.RequestID+'] exception: ' + E.Message);
      Send404(AResponse);
    end;
  end;
end;

end.

