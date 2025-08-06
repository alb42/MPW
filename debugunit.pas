unit debugunit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs;

procedure DebugOut(Txt: string);

var
  DebugToCON: Boolean;
  DebugToDebug: Boolean;
implementation

var
  DebugWriteLock: TCriticalSection;

procedure DebugOut(Txt: string);
begin
  DebugWriteLock.Enter;
  try
    if DebugToCON then
      writeln(Txt);
    if DebugToDebug then
      SysDebugLn(Txt);
  finally
    DebugWriteLock.Leave;
  end;
end;



initialization
  DebugWriteLock := TCriticalSection.Create;

finalization
  DebugWriteLock.Free;


end.

