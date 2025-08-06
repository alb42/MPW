unit mainguiunit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  Exec, Utility, iffparse,
  muihelper, mui, workbench, icon,
  MUIClass.Base, MUIClass.Window, MUIClass.Area, MUIClass.Group,
  MUIClass.Dialog, MUIClass.Gadget, MUIClass.Image;

type

  { TMainWindow }

  TMainWindow = class(TMUIWindow)
  private
    MainGrp: TMUIGroup;
    Edit: TMUIString;
    procedure ButtonClick(Sender: TObject);
    procedure CopyClick(Sender: TObject);
    procedure EndServerEvent(Sender: TObject);
    procedure ReloadTemplatesEvent(Sender: TObject);
    procedure RemoteEditChange(Sender: TObject);
  public
    constructor Create; override;
  end;


var
  OpenURLBase: PLibrary = nil;
  OnServerEnd: TNotifyEvent = nil;
{$ifdef AMIGA68K}
function URL_OpenA(URL: STRPTR location 'a0'; Tags: PTagItem location 'a1'): LongWord; syscall OpenURLBase 30;
{$endif}

function GetStrToolType(DObj: PDiskObject; Entry: string; Default: string): string;

procedure StartGUI;

var
  MainWin: TMainWindow;

implementation

uses
  Debugunit, wikiserverunit, responsehelper;

function GetStrToolType(DObj: PDiskObject; Entry: string; Default: string): string;
var
  Res: PChar;
begin
  Result := Default;
  // easier here to check if icon is found
  if not assigned(Dobj) then
    Exit;
  // and if there are tooltypes at all
  if not Assigned(Dobj^.do_Tooltypes) then
    Exit;
  // the actual search
  Res := FindToolType(Dobj^.do_Tooltypes, PChar(Entry));
  // check if found
  if Assigned(Res) then
    Result := Res;
end;

procedure StartGUI;
var
  DObj: PDiskObject;
begin
  OpenURLBase := OpenLibrary('openurl.library', 0);
  MUIApp.Version := VERSION;
  MUIApp.Author := 'Marcus "ALB42" Sackrow';
  MUIApp.Description := 'My personal Wiki (Markdown)';
  DObj := GetDiskObject(PChar(ParamStr(0)));
  if Assigned(DObj) then
    MUIApp.DiskObject := DObj;
  MainWin := TMainWindow.Create;
  DebugOut('GUI Started');
  MUIApp.Run;
  if Assigned(DObj) then
    FreeDiskObject(DObj);
  DebugOut('GUI ended');
  OnServerEnd := nil;
end;

{ TMainWindow }

procedure TMainWindow.ButtonClick(Sender: TObject);
begin
  if Assigned(OpenURLBase) then
    URL_OpenA(PAnsiChar('http://localhost:' + IntToStr(ServerPort)), nil)
  else
    ShowMessage('openurl.library is not installed');
end;

const
  ID_FTXT = 1179932756;
  ID_CHRS = 1128813139;

function PutTextToClip(ClipUnit: Byte; Text: AnsiString): Boolean;
var
  Iff: PIffHandle;
  TText: AnsiString;
  Len: Integer;
begin
  PutTextToClip := False;
  Iff := AllocIff;
  if Assigned(Iff) then
  begin
    Iff^.iff_Stream := LongWord(OpenClipboard(ClipUnit));
    if Iff^.iff_Stream <> 0 then
    begin
      InitIffAsClip(iff);
      if OpenIff(Iff, IFFF_WRITE) = 0 then
      begin
        if PushChunk(iff, ID_FTXT, ID_FORM, IFFSIZE_UNKNOWN) = 0 then
        begin
          if PushChunk(iff, 0, ID_CHRS, IFFSIZE_UNKNOWN) = 0 then
          begin
            Len := Length(Text);
            TText := Text + #0;
            PutTextToClip := WriteChunkBytes(iff, @(TText[1]), Len) = len;
            PopChunk(iff);
          end;
          PopChunk(iff);
        end;
        CloseIff(iff);
      end;
      CloseClipboard(PClipBoardHandle(iff^.iff_Stream));
    end;
    FreeIFF(Iff);
  end;
end;

procedure TMainWindow.CopyClick(Sender: TObject);
begin
  PutTextToClip(0, 'http://localhost:' + IntToStr(ServerPort));
end;

procedure TMainWindow.EndServerEvent(Sender: TObject);
begin
  MainGrp.Disabled := True;
end;

procedure TMainWindow.ReloadTemplatesEvent(Sender: TObject);
begin
  //
end;

procedure TMainWindow.RemoteEditChange(Sender: TObject);
begin
  if Sender is TMUIArea then
    AllowRemoteEdit := TMUIArea(Sender).Selected;
end;

constructor TMainWindow.Create;
var
  Grp, Grp2: TMUIGroup;
  Button: TMUIButton;
  ChooseRemoteEdit: TMUIImage;
begin
  inherited Create;

  ID := MAKE_ID('M', 'P', 'W', 'M');

  Title := 'MPW 0.1';
  ScreenTitle := 'MPW';

  Grp := TMUIGroup.Create;
  with Grp do
  begin
    FrameTitle := '   My personal Wiki   ';
    Parent := Self;
  end;
  MainGrp := Grp;

  Grp2 := TMUIGroup.Create;
  Grp2.Frame := MUIV_Frame_None;
  Grp2.Horiz := True;
  Grp2.Parent := Grp;

  Edit := TMUIString.Create;
  with Edit do
  begin
    FixWidthTxt := '       http://localhost:' + IntToStr(ServerPort);
    Contents := 'http://localhost:' + IntToStr(ServerPort);
    Parent := Grp2;
  end;

  Button := TMUIButton.Create('Copy');
  Button.OnClick  := @CopyClick;
  Button.Parent := Grp2;
  //
  Button := TMUIButton.Create('   Open Browser   ');
  Button.Disabled := not Assigned(OpenURLBase);
  Button.OnClick  := @ButtonClick;
  Button.Parent := Grp;

  Grp2 := TMUIGroup.Create;
  Grp2.Frame := MUIV_Frame_None;
  Grp2.Horiz := True;
  Grp2.Parent := Grp;

  TMUIRectangle.Create.Parent := Grp2;
  TMUIText.Create('Allow remote Editing').Parent := Grp2;
  ChooseRemoteEdit := TMUIImage.Create;
  ChooseRemoteEdit.Spec.Spec := MUII_CheckMark;
  ChooseRemoteEdit.InputMode := MUIV_InputMode_Toggle;
  ChooseRemoteEdit.OnSelected := @RemoteEditChange;
  ChooseRemoteEdit.Parent := Grp2;

  Grp2 := TMUIGroup.Create;
  Grp2.Frame := MUIV_Frame_None;
  Grp2.Horiz := True;
  Grp2.Parent := Grp;

  TMUIRectangle.Create.Parent := Grp2;
  with TMUIButton.Create('Reload Templates') do
  begin
    OnClick  := @ReloadTemplatesEvent;
    Parent := Grp2;
  end;

  OnServerEnd  := @EndServerEvent;
end;

end.

