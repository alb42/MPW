unit searchunit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, fphttpserver, httpprotocol;

procedure SearchDocument(Params: TStrings; var AResponse: TFPHTTPConnectionResponse);

implementation

uses
  templateunit, documentsunit, responsehelper, editunit, debugunit;

procedure SearchDocument(Params: TStrings; var AResponse: TFPHTTPConnectionResponse);
var
  SearchStr, ResStr, Line, Results, inFiles, FullLine: String;
  SL, FullText: TStringList;
  NumFound: Integer;
  SearchInFiles: Boolean;
  n: SizeInt;
begin
  SearchStr := Params.Values['search'];
  inFiles := Trim(Params.Values['infiles']);
  DebugOut('in files ' + inFiles);
  ResStr := StringReplace(SearchTemplate, '%search%', SearchStr, [rfReplaceAll]);
  ResStr := StringReplace(ResStr, '%infile%', ifthen(inFiles <> '', 'checked', ''), [rfReplaceAll]);
  SearchInFiles :=  inFiles <> '';
  FullText := nil;
  SL := nil;
  if Trim(SearchStr) = '' then
  begin
    ResStr := StringReplace(ResStr, '%sresults%', '', [rfReplaceAll]);
  end
  else
  begin
    Results := '';
    NumFound := 0;
    SearchStr := LowerCase(SearchStr);
    SL := TStringList.Create;
    FullText := TStringList.Create;
    GetAllDocumentNames(SL);
    for Line in SL do
    begin
      if Pos(SearchStr, LowerCase(Line)) > 0 then
      begin
        Results := Results + '<li><a href="/' + httpencode(Line) + '">' + INetString(Line) + '</a>'#10;
        Inc(NumFound);
      end
      else
      if SearchInFiles then
      begin
        FullText.Clear;
        try
          FullText.LoadFromFile(IncludeTrailingPathDelimiter(DataFolder) + GetFilename(Line));
          for FullLine in FullText do
          begin
            n := Pos(SearchStr, LowerCase(FullLine));
            if n > 0 then
            begin
              Results := Results + '<li><a href="/' + httpencode(Line) + '">' + INetString(Line) + '</a><br>'#10 +
                                   '<font color="#999999">' + Copy(FullLine, 1, n - 1) + '</font><font color="#ff00ff">' +
                                   Copy(FullLine, n, Length(SearchStr)) + '</font><font color="#999999">' +
                                   Copy(FullLine, n + Length(SearchStr)) + '</font>';

              Inc(NumFound);
              Break;
            end;
          end;
        except

        end;
      end;
    end;
    if NumFound = 0 then
    begin
      Results := '<li>No results found. Do you want to create a ne Page with this Title? use this Link <a href="/edit/' + HTTPEncode(Params.Values['search']) + '">' + INetString(Params.Values['search']) + '</a>';
    end;
    SL.Free;
    FullText.Free;
    ResStr := StringReplace(ResStr, '%sresults%', Results, [rfReplaceAll]);
  end;
  SendText(ResStr, AResponse);

end;

end.

