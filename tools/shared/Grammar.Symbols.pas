unit Grammar.Symbols;

interface

uses
  System.Generics.Collections,
  EBNF.Ast;

type

  TSymbolTables = class
  private
    fDefinedNT:TDictionary<string, Integer>; // name -> line
    fRefsNT:TDictionary<string, Integer>; // name -> first ref line
    fTokenRefs:TDictionary<string, Integer>; // token name -> first ref line
    fTokenLits:TDictionary<string, Integer>; // quoted literals -> first ref line
  public
    constructor Create;
    destructor Destroy; override;

    property DefinedNT:TDictionary<string, Integer> read fDefinedNT write fDefinedNT;
    property RefsNT:TDictionary<string, Integer> read fRefsNT write fRefsNT;
    property TokenRefs:TDictionary<string, Integer> read fTokenRefs write fTokenRefs;
    property TokenLits:TDictionary<string, Integer> read fTokenLits write fTokenLits;
  end;


procedure CollectSymbols(G:TGrammar; const TokenNames:TDictionary<string, Boolean>; out S:TSymbolTables);
function ComputeReachable(G:TGrammar; const Start:string; const TokenNames:TDictionary<string, Boolean>):TDictionary<string, Boolean>;


implementation

uses
  System.SysUtils;


constructor TSymbolTables.Create;
begin
  inherited;
  fDefinedNT := TDictionary<string, Integer>.Create;
  fRefsNT := TDictionary<string, Integer>.Create;
  fTokenRefs := TDictionary<string, Integer>.Create;
  fTokenLits := TDictionary<string, Integer>.Create;
end;


destructor TSymbolTables.Destroy;
begin
  fDefinedNT.Free;
  fRefsNT.Free;
  fTokenRefs.Free;
  fTokenLits.Free;
  inherited;
end;


procedure AddRef(dict:TDictionary<string, Integer>; const k:string; line:Integer);
begin
  if not dict.ContainsKey(k) then
    dict.Add(k, line);
end;


procedure WalkNode(N:TNode; const TokenNames:TDictionary<string, Boolean>; RefsNT, TokenRefs, TokenLits:TDictionary<string, Integer>);
var
  i:Integer;
  b:Boolean;
begin
  if N = nil then
    Exit;
  case N.Kind of
    nkTerminal:
      AddRef(TokenLits, TTerminalNode(N).Text, N.line);
    nkIdentRef:
      begin
        if (TokenNames <> nil) and TokenNames.TryGetValue(TIdentRefNode(N).Name, b) then
          AddRef(TokenRefs, TIdentRefNode(N).Name, N.line)
        else
          AddRef(RefsNT, TIdentRefNode(N).Name, N.line);
      end;
    nkSeq:
      for i := 0 to TSeqNode(N).Items.Count - 1 do
        WalkNode(TSeqNode(N).Items[i], TokenNames, RefsNT, TokenRefs, TokenLits);
    nkChoice:
      for i := 0 to TChoiceNode(N).Alts.Count - 1 do
        WalkNode(TChoiceNode(N).Alts[i], TokenNames, RefsNT, TokenRefs, TokenLits);
    nkSuffix:
      WalkNode(TSuffixNode(N).Base, TokenNames, RefsNT, TokenRefs, TokenLits);
    nkGroup:
      WalkNode(TGroupNode(N).Inner, TokenNames, RefsNT, TokenRefs, TokenLits);
    nkOptional:
      WalkNode(TOptNode(N).Inner, TokenNames, RefsNT, TokenRefs, TokenLits);
    nkRepeat:
      WalkNode(TRepeatNode(N).Inner, TokenNames, RefsNT, TokenRefs, TokenLits);
  end;
end;


procedure CollectSymbols(G:TGrammar; const TokenNames:TDictionary<string, Boolean>; out S:TSymbolTables);
var
  P:TProduction;
begin
  S := TSymbolTables.Create;
  // definitions
  for P in G.Prods do
  begin
    if not S.DefinedNT.ContainsKey(P.Name) then
    begin
      S.DefinedNT.Add(P.Name, P.line);
    end;
  end;
  // references
  for P in G.Prods do
  begin
    WalkNode(P.Expr, TokenNames, S.RefsNT, S.TokenRefs, S.TokenLits);
  end;
end;


function BuildAdjacency(G:TGrammar; const TokenNames:TDictionary<string, Boolean>):TDictionary<string, TList<string>>;
var
  map:TDictionary<string, TList<string>>;
  P:TProduction;

  procedure AddEdge(const fromNT, toNT:string);
  var
    L:TList<string>;
  begin
    if not map.TryGetValue(fromNT, L) then
    begin
      L := TList<string>.Create;
      map.Add(fromNT, L);
    end;
    if L.IndexOf(toNT) < 0 then
      L.Add(toNT);
  end;

  procedure Walk(const fromNT:string; N:TNode);
  var
    i:Integer;
    dummy:Boolean;
  begin
    if N = nil then
      Exit;
    case N.Kind of
      nkIdentRef:
        begin
          if (TokenNames <> nil) and TokenNames.TryGetValue(TIdentRefNode(N).Name, dummy) then
          begin
            // token ref: ignore
          end
          else
            AddEdge(fromNT, TIdentRefNode(N).Name);
        end;
      nkSeq:
        for i := 0 to TSeqNode(N).Items.Count - 1 do
          Walk(fromNT, TSeqNode(N).Items[i]);
      nkChoice:
        for i := 0 to TChoiceNode(N).Alts.Count - 1 do
          Walk(fromNT, TChoiceNode(N).Alts[i]);
      nkSuffix:
        Walk(fromNT, TSuffixNode(N).Base);
      nkGroup:
        Walk(fromNT, TGroupNode(N).Inner);
      nkOptional:
        Walk(fromNT, TOptNode(N).Inner);
      nkRepeat:
        Walk(fromNT, TRepeatNode(N).Inner);
    end;
  end;


begin
  map := TDictionary<string, TList<string>>.Create;
  for P in G.Prods do
  begin
    Walk(P.Name, P.Expr);
  end;
  Result := map;
end;


function ComputeReachable(G:TGrammar; const Start:string; const TokenNames:TDictionary<string, Boolean>):TDictionary<string, Boolean>;
var
  Adj:TDictionary<string, TList<string>>;
  Q:TQueue<string>;
  Vis:TDictionary<string, Boolean>;
  Cur:string;
  Neigh:TList<string>;
  nxt:string;
begin
  Adj := BuildAdjacency(G, TokenNames);
  Vis := TDictionary<string, Boolean>.Create;
  try
    Q := TQueue<string>.Create;
    try
      Q.Enqueue(Start);
      Vis.AddOrSetValue(Start, True);
      while Q.Count > 0 do
      begin
        Cur := Q.Dequeue;
        if Adj.TryGetValue(Cur, Neigh) then
        begin
          for nxt in Neigh do
            if not Vis.ContainsKey(nxt) then
            begin
              Vis.Add(nxt, True);
              Q.Enqueue(nxt);
            end;
        end;
      end;
    finally
      Q.Free;
    end;
    Result := Vis;
  finally
    for var kv in Adj do
      kv.Value.Free;
    Adj.Free;
  end;
end;

end.
