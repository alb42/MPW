unit debugunit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs;

procedure DebugOut(Txt: string);

implementation

var
  DebugWriteLock: TCriticalSection;

procedure DebugOut(Txt: string);
begin
  DebugWriteLock.Enter;
  try
    //writeln(Txt);
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

