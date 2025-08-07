unit imagesunit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fphttpserver, HTTPDefs;

procedure ImagesPage(AResponse: TFPHTTPConnectionResponse);
procedure UploadImg(ARequest: TFPHTTPConnectionRequest; AResponse: TFPHTTPConnectionResponse);

implementation

uses
  documentsunit, debugunit, responsehelper;


procedure ImagesPage(AResponse: TFPHTTPConnectionResponse);
var
  Info: TRawByteSearchRec;
  PicsPath: String;
  SL: TStringList;
begin
  SL := TStringList.Create;
  SL.Add('<html><head><title>MPW - Images</title></head><body><h1>Images</h1>');
  SL.Add('<p><form method="POST" id="form" enctype="multipart/form-data" action="/uploadimg/">');
  SL.Add('  <input type="file" name="input">');
  SL.Add('  <input type="submit" value="Upload">');
  SL.Add('<BR>Overwrite: <input type="checkbox" name="overwrite" value="yes">');

  SL.Add('</form></p><HR>');
  SL.Add('Available Images with ready to use markdown line<ul>');
  try
    PicsPath := IncludeTrailingPathDelimiter(DataFolder) + 'pics/';
    if FindFirst(PicsPath + '*', faAnyFile, Info) = 0 then
    begin
      repeat
        //Inc(Count);
        if (Info.Attr and faDirectory) = 0 then
          SL.Add('<li><a href="/pics/' + Info.Name +'">' + Info.Name + '</a>&nbsp;&nbsp;![](/pics/' + Info.Name + ')')
      until FindNext(info)<>0;
      FindClose(Info);
    end;
    SL.Add('</ul>');
  finally
    SL.Add('</body></html>');
    SendText(SL, AResponse);
    SL.Free;
  end;
end;

procedure UploadImg(ARequest: TFPHTTPConnectionRequest; AResponse: TFPHTTPConnectionResponse);
var
  FirstFile: TUploadedFile;
  FS: TFileStream;
  PicsPath, Filename, FullFilename: String;
begin
  Debugout('Method: ' + ARequest.Method);
  DebugOut('UploadImg Triggered Files: ' + IntToStr(ARequest.Files.Count) + ' overwrite: ' + ARequest.ContentFields.Values['overwrite']);
  FirstFile := ARequest.Files.First;
  if not Assigned(FirstFile) then
  begin
    SendCode(AResponse, 404, 'Not Found.', 'No uploaded file found');
    Exit;
  end;
  DebugOut('got first file ' + HexStr(FirstFile) + ' content: ' + ARequest.Content);
  Filename := FirstFile.FileName;
  DebugOut('got filename ' + Filename);
  if Pos('image', FirstFile.ContentType) <= 0 then
  begin
    SendCode(AResponse, 406, 'Not Acceptable.', 'Illegal Filetype, only images allowed to upload (this is a ' + FirstFile.ContentType + ')');
    Exit;
  end;
  PicsPath := IncludeTrailingPathDelimiter(DataFolder) + 'pics/';
  FullFilename := PicsPath + Filename;
  if FileExists(FullFilename) and (ARequest.ContentFields.Values['overwrite'] <> 'yes') then
  begin
    SendCode(AResponse, 423, 'Locked.', 'File Already exists.');
    Exit;
  end;
  FS := TFileStream.Create(FullFilename, fmCreate);
  FirstFile.Stream.Position := 0;
  FS.CopyFrom(FirstFile.Stream, FirstFile.Stream.Size);
  FS.Free;
  // show images page as response
  ImagesPage(AResponse);
end;


end.

