program gv2graphml;
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  DotGraph in 'DotGraph.pas';


begin
  try
    if (ParamCount < 1) or (ParamCount > 2) then
    begin
      Writeln('Usage:');
      Writeln('  gv2graphml.exe input.gv');
      Writeln('  gv2graphml.exe input.gv output.graphml');
      Exit;
    end;

    var filenameGv := ParamStr(1);
    var filenameGraphml := ChangeFileExt(ParamStr(2), '.graphml');

    if ParamCount = 2 then
      filenameGraphml := ParamStr(2);

    var dg := TDotGraph.Create;
    dg.LoadFromFile(filenameGv);
    dg.ExportAsGraphml(filenameGraphml);
    dg.Free;

    Writeln('Done');
  except
    on E: Exception do
      Writeln('Error: ', E.Message);
  end;
end.

