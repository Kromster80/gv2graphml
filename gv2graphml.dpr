program gv2graphml;
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  DotGraph in 'DotGraph.pas';


procedure Usage;
begin
  Writeln('Usage: gv2graphml input.gv output.graphml');
end;

begin
  try
    if ParamCount < 2 then
    begin
      Usage;
      Exit;
    end;

    var dg := TDotGraph.Create;
    dg.LoadFromFile(ParamStr(1));
    dg.ExportAsGraphml(ParamStr(2));
    dg.Free;

    Writeln('Done');
  except
    on E: Exception do
      Writeln('Error: ', E.Message);
  end;
end.

