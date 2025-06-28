unit imagesunit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fphttpserver;

procedure ImagesPage(AResponse: TFPHTTPConnectionResponse);

implementation

uses
  documentsunit, editunit;

procedure ImagesPage(AResponse: TFPHTTPConnectionResponse);
var
  Info: TRawByteSearchRec;
  PicsPath: String;
  SL: TStringList;
begin
  SL := TStringList.Create;
  SL.Add('<html><head><title>MPW - Images</title></head><body><h1>Images</h1>');
  SL.Add('<p><form action="/uploadimg/">');
  SL.Add('  <input type="file" id="myFile" name="filename">');
  SL.Add('  <input type="submit">');
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

end.

