unit DotGraph;
interface
uses
  System.Generics.Collections;

type
  TDotNode = record
    Name: string;
    // And maybe other properties
  end;

  TDotEdge = record
    NodeFrom: Integer;
    NodeTo: Integer;
    AttrText: string; // Raw text, always "[arrowhead=open,style=dashed]"
  end;

  TDotGraph = class
  private
    fNodes: TList<TDotNode>;
    fEdges: TList<TDotEdge>;
    function FindNodeIndex(const aName: string): Integer;
    procedure EnsureNode(const aName: string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromFile(const aFileName: string);
    procedure ExportAsGraphml(const aFileName: string);
  end;


implementation
uses
  System.Classes, System.StrUtils, System.SysUtils, System.Types,
  Xml.VerySimple;


{ TDotGraph }
constructor TDotGraph.Create;
begin
  inherited;

  fNodes := TList<TDotNode>.Create;
  fEdges := TList<TDotEdge>.Create;
end;

destructor TDotGraph.Destroy;
begin
  FreeAndNil(fEdges);
  FreeAndNil(fNodes);
  inherited;
end;


function TDotGraph.FindNodeIndex(const aName: string): Integer;
begin
  Result := -1;
  for var I := 0 to fNodes.Count - 1 do
    if fNodes[I].Name = aName then
      Exit(I);
end;


procedure TDotGraph.EnsureNode(const aName: string);
begin
  if aName = '' then Exit;

  var idx := FindNodeIndex(aName);
  if idx < 0 then
  begin
    var newNode := default(TDotNode);
    newNode.Name := aName;
    fNodes.Add(newNode);
  end;
end;


procedure TDotGraph.LoadFromFile(const aFileName: string);
begin
  var sl := TStringList.Create;
  try
    sl.LoadFromFile(aFileName, TEncoding.UTF8);

    begin
      var sa := SplitString(sl[0], ' ');
      Assert(sa[0] = 'digraph');
      Assert(sa[2] = '{');
    end;

    for var I := 1 to sl.Count - 2 do
    begin
      var sa := SplitString(Trim(sl[I]), ' ');

      EnsureNode(sa[0]);

      // There could be Nodes without any connections
      if Length(sa) = 1 then
        Continue;

      Assert(sa[1] = '->');

      var attrText := sa[High(sa)];
      if attrText = '}' then
        attrText := '';

      if sa[2] = '{' then
      begin
        for var K := 3 to High(sa) - 1 - Ord(attrText <> '') do
        begin
          EnsureNode(sa[K]);

          var newEdge := default(TDotEdge);
          newEdge.NodeFrom := FindNodeIndex(sa[0]);
          newEdge.NodeTo := FindNodeIndex(sa[K]);
          newEdge.AttrText := attrText;

          fEdges.Add(newEdge);
        end
      end else
      begin
        EnsureNode(sa[2]);

        var newEdge := default(TDotEdge);
        newEdge.NodeFrom := FindNodeIndex(sa[0]);
        newEdge.NodeTo := FindNodeIndex(sa[2]);
        newEdge.AttrText := attrText;

        fEdges.Add(newEdge);
      end;
    end;
  finally
    sl.Free;
  end;
end;


procedure TDotGraph.ExportAsGraphml(const aFileName: string);
begin
  //Internally GraphML is an XML document
  var xml := TXmlVerySimple.Create;
  xml.Version := '1.0';
  xml.Encoding := 'UTF-8';
  xml.StandAlone := 'no';
  xml.Options := [doNodeAutoIndent];

  var nodeGraphml := xml.AddChild('graphml');
  nodeGraphml.Attributes['xmlns:y'] := 'http://www.yworks.com/xml/graphml';
  nodeGraphml.Attributes['xmlns:yed'] := 'http://www.yworks.com/xml/yed/3';

  var nodeKey := nodeGraphml.AddChild('key');
  nodeKey.Attributes['id'] := 'd0';
  nodeKey.Attributes['for'] := 'node';
  nodeKey.Attributes['yfiles.type'] := 'nodegraphics';

  nodeKey := nodeGraphml.AddChild('key');
  nodeKey.Attributes['id'] := 'd1';
  nodeKey.Attributes['for'] := 'edge';
  nodeKey.Attributes['yfiles.type'] := 'edgegraphics';

  var nodeGraph := nodeGraphml.AddChild('graph');
  nodeGraph.Attributes['edgedefault'] := 'directed';

  for var I := 0 to fNodes.Count - 1 do
  begin
    var nodeNode := nodeGraph.AddChild('node');
    nodeNode.Attributes['id'] := 'n' + IntToStr(I);

    var nodeData := nodeNode.AddChild('data');
    nodeData.Attributes['key'] := 'd0';
    nodeData.AddChild('y:ShapeNode').AddChild('y:NodeLabel').Text := fNodes[I].Name;
  end;

  var L := 0;
  for var I := 0 to fEdges.Count - 1 do
  begin
    var nodeEdge := nodeGraph.AddChild('edge');
    nodeEdge.Attributes['id'] := 'e' + IntToStr(L);
    nodeEdge.Attributes['source'] := 'n' + IntToStr(fEdges[I].NodeFrom);
    nodeEdge.Attributes['target'] := 'n' + IntToStr(fEdges[I].NodeTo);

    var nodeData := nodeEdge.AddChild('data');
    nodeData.Attributes['key'] := 'd1';

    var nodeLine := nodeData.AddChild('y:PolyLineEdge');
    var lineStyle := nodeLine.AddChild('y:LineStyle');
    if fEdges[I].AttrText <> '' then
    begin
      lineStyle.Attributes['type'] := 'dashed';
      lineStyle.Attributes['color'] := '#808080';
    end
    else
    begin
      lineStyle.Attributes['type'] := 'line';
      lineStyle.Attributes['color'] := '#000000';
    end;

    nodeLine.AddChild('y:Arrows').Attributes['target'] := 'standard';

    Inc(L);
  end;

  xml.SaveToFile(aFileName);
  xml.Free;
end;


end.

