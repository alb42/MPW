unit templateunit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

var
  PageTemplate: string = '<html><body><div align=right><a href="/edit/%doclink%">Edit</a></div>%txt%</body></html>';
  EditTemplate: string = '<html><body><form method="POST" action="/save/"><H1 align="center">Edit Document: %name%</H1><textarea id="content" name="content" cols=80 rows=25>%txt%</textarea><br><input type="hidden" id="name" name="name" value="%name%"><button type="submit">Save</button></form><hr></body></html>';
  NewTemplate: string = '<html><body><form method="POST" action="/save/"><H1 align="center">Edit new Document</H1><textarea id="content" name="content" cols=80 rows=25>%txt%</textarea><br><input type="text" id="name" name="name" value="New Page"><button type="submit">Save</button></form><hr></body></html>';
  SearchTemplate: string = '<html><body><form method="POST" action="/search/"><input type="text" id="search" name="search" value="%search%"><button type="submit">Search</button><br><label>in files</label><input type="checkbox" id="infiles" name="infiles" value="yes" %infile%></form><hr><ul>%sresults%</u></body></html>';

procedure ReloadTemplates;

implementation

uses
  Debugunit;

procedure LoadTemplate(Filename: string; var Template: string);
var
  Path: string;
begin
  Path := ExtractFilePath(ParamStr(0)) + 'fixed/' + Filename;
  if FileExists(Path) then
  begin
    with TStringList.Create do
    begin
      LoadFromFile(Path);
      Template := Text;
      Free;
    end;
  end
  else
    DebugOut(Filename + ' does not exist ' + path);
end;

procedure ReloadTemplates;
begin
  LoadTemplate('edit.html', EditTemplate);
  LoadTemplate('new.html', NewTemplate);
  LoadTemplate('page.html', PageTemplate);
  LoadTemplate('search.html', SearchTemplate);
end;

initialization
  ReloadTemplates;
end.

