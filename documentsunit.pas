unit documentsunit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fgl;

procedure AddNewPageLink(ATitle, AFilename: string);
function GetFilename(ATitle: string): string;
procedure GetAllDocumentNames(Names: TStrings);

procedure UpdateList;

var
  DataFolder: string;

implementation

uses
  debugunit;

const
  IndexName = 'index.list';


type
  TPageEntry = class
    PageName: string;
    FileName: string;
  end;

  TPageEntryBase = specialize TFPGObjectList<TPageEntry>;

  { TPageEntries }

  TPageEntries = class(TPageEntryBase)
  public
    procedure LoadFromFile(AFilename: string);
    procedure SaveToFile(AFilename: string);
  end;

var
  PageEntries: TPageEntries;

procedure GetAllDocumentNames(Names: TStrings);
var
  i: Integer;
begin
  Names.Clear;
  for i := 0 to PageEntries.Count - 1 do
    Names.Add(PageEntries[i].PageName)
end;

procedure AddNewPageLink(ATitle, AFilename: string);
var
  NP: TPageEntry;
  i: Integer;
begin
  if ATitle = '' then
    Exit;
  for i := 0 to PageEntries.Count - 1 do
  begin
    if PageEntries[i].PageName = ATitle then
      Exit;
  end;
  NP := TPageEntry.Create;
  NP.PageName := ATitle;
  NP.FileName := AFilename;
  PageEntries.Add(NP);
  UpdateList;
end;

function GetFilename(ATitle: string): string;
var
  i: Integer;
begin
  DebugOut('search for ' + ATitle);
  if ATitle = '' then
    Exit('MainPage.md');
  Result := '';
  for i := 0 to PageEntries.Count - 1 do
  begin
    DebugOut('   ' + PageEntries[i].PageName + ' = ' + ATitle );
    if PageEntries[i].PageName = ATitle then
    begin
      DebugOut('   found');
      Exit(PageEntries[i].FileName);
    end;
  end;
end;

procedure UpdateList;
begin
  PageEntries.SaveToFile(IncludeTrailingPathDelimiter(DataFolder) + IndexName);
end;


function CopyFile(Src, dest: string): Boolean;
var
  SL: TStringList;
begin
  Result := False;
  if not FileExists(Src) then
    Exit;
  SL := TStringList.Create;
  try
    SL.LoadFromFile(Src);
    SL.SaveToFile(Dest);
    Result := True;
  except
    Result := False;
  end;
  SL.Free;
end;

{ TPageEntries }

procedure TPageEntries.LoadFromFile(AFilename: string);
var
  SL: TStringList;
  Line, TemplateFolder: string;
  n: SizeInt;
  NP: TPageEntry;
begin
  Clear;
  SL := TStringList.Create;
  try
    if not FileExists(AFilename) then
    begin
      DebugOut('index not found, copy template');
      TemplateFolder := ExtractFileDir(ParamStr(0)) + '/template/';
      CopyFile(TemplateFolder + IndexName, AFilename);
      CopyFile(TemplateFolder + 'Mainpage.md', ExtractFilePath(AFilename) + 'Mainpage.md');
      CopyFile(TemplateFolder + 'Markdown.md', ExtractFilePath(AFilename) + 'Markdown.md');
    end;
    if not FileExists(AFilename) then
    begin
      DebugOut('Error: Index not found. Abort. ' + AFilename);
      Exit;
    end;
    SL.Clear;
    SL.LoadFromFile(AFilename);
    for Line in SL do
    begin
      n := Pos(#9, Line);
      if n > 1 then
      begin
        NP := TPageEntry.Create;
        NP.PageName := Copy(Line, 1, n - 1);
        NP.FileName := Copy(Line, n + 1);
        PageEntries.Add(NP);
      end;
    end;
  finally
    SL.Free;
  end;
end;

procedure TPageEntries.SaveToFile(AFilename: string);
var
  NP: TPageEntry;
  SL: TStringList;
  i: Integer;
begin
  SL := TStringList.Create;
  try
    for i := 0 to Count - 1 do
    begin
      NP := Items[i];
      SL.Add(NP.PageName + #9 + NP.FileName);
    end;
    SL.SaveToFile(AFilename);
  finally
    SL.Free;
  end;
end;

initialization
  DataFolder := ExtractFileDir(ParamStr(0));
  if DirectoryExists(IncludeTrailingPathDelimiter(DataFolder) + 'Data') then
    DataFolder := IncludeTrailingPathDelimiter(DataFolder) + 'Data';
  PageEntries := TPageEntries.Create(True);
  PageEntries.LoadFromFile(IncludeTrailingPathDelimiter(DataFolder) + IndexName);
finalization;
  PageEntries.Free;

end.

