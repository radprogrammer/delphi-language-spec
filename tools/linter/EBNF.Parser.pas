unit EBNF.Parser;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  EBNF.Ast,
  EBNF.Lexer;

type

  TEBNFParser = class
  private
    L:TEBNFLexer;
    Cur:TToken;
    procedure Next;
    procedure Expect(k:TTokenKind; const What:string);
    function Accept(k:TTokenKind):Boolean;

    function ParseProduction:TProduction;
    function ParseExpr:TNode;
    function ParseTerm:TNode;
    function ParseFactor:TNode;
    function ParsePrimary:TNode;
  public
    constructor Create(ALexer:TEBNFLexer);

    function Parse:TGrammar;
  end;


implementation


constructor TEBNFParser.Create(ALexer:TEBNFLexer);
begin
  L := ALexer;
  Cur := L.NextToken;
end;


procedure TEBNFParser.Next;
begin
  Cur := L.NextToken;
end;


procedure TEBNFParser.Expect(k:TTokenKind; const What:string);
begin
  if Cur.Kind <> k then
    raise Exception.CreateFmt('Expected %s at line %d col %d', [What, Cur.Line, Cur.Col]);
  Next;
end;


function TEBNFParser.Accept(k:TTokenKind):Boolean;
begin
  Result := Cur.Kind = k;
  if Result then
    Next;
end;


function TEBNFParser.Parse:TGrammar;
begin
  Result := TGrammar.Create;
  while Cur.Kind <> tkEOF do
  begin
    var P := ParseProduction;
    Result.Prods.Add(P);
  end;
end;


function TEBNFParser.ParseProduction:TProduction;
begin
  if Cur.Kind <> tkIdent then
    raise Exception.CreateFmt('Production head must be identifier at line %d', [Cur.Line]);
  Result := TProduction.Create;
  Result.Name := Cur.Lexeme;
  Result.Line := Cur.Line;
  Next;
  Expect(tkEq, '''=''');
  Result.Expr := ParseExpr;
  Expect(tkSemi, ''';''');
end;


function TEBNFParser.ParseExpr:TNode;
var
  Choice:TChoiceNode;
  Term:TNode;
begin
  Term := ParseTerm;
  if Cur.Kind = tkBar then
  begin
    Choice := TChoiceNode.Create;
    Choice.Alts.Add(Term);
    while Accept(tkBar) do
    begin
      if Cur.Kind in [tkBar, tkSemi, tkRPar, tkRBrk, tkRBr] then
      begin
        // Empty alternative
        var Empty := TSeqNode.Create;
        Empty.Line := Cur.Line;
        Empty.Col := Cur.Col;
        Choice.Alts.Add(Empty);
      end
      else
        Choice.Alts.Add(ParseTerm);
    end;
    Result := Choice;
  end
  else
    Result := Term;
end;


function TEBNFParser.ParseTerm:TNode;
var
  Seq:TSeqNode;
  F:TNode;
begin
  Seq := TSeqNode.Create;
  while not(Cur.Kind in [tkBar, tkSemi, tkRPar, tkRBrk, tkRBr, tkEOF]) do
  begin
    F := ParseFactor;
    Seq.Items.Add(F);
  end;
  if Seq.Items.Count = 1 then
  begin
    Result := Seq.Items[0];
    Seq.Items.OwnsObjects := False;
    Seq.Free;
  end
  else
    Result := Seq;
end;


function TEBNFParser.ParseFactor:TNode;
var
  P:TNode;
  Suf:TSuffixNode;
begin
  P := ParsePrimary;
  if Cur.Kind in [tkQ, tkStar, tkPlus] then
  begin
    Suf := TSuffixNode.Create;
    Suf.Kind := nkSuffix;
    Suf.Base := P;
    Suf.Line := P.Line;
    Suf.Col := P.Col;
    case Cur.Kind of
      tkQ:
        Suf.Suffix := skOpt;
      tkStar:
        Suf.Suffix := skStar;
      tkPlus:
        Suf.Suffix := skPlus;
    end;
    Next;
    Result := Suf;
  end
  else
    Result := P;
end;


function TEBNFParser.ParsePrimary:TNode;
var
  N:TNode;
begin
  case Cur.Kind of
    tkLPar:
      begin
        Next;
        N := ParseExpr;
        Expect(tkRPar, ''')''');
        var
        G := TGroupNode.Create;
        G.Kind := nkGroup;
        G.Inner := N;
        G.Line := Cur.Line;
        G.Col := Cur.Col;
        Exit(G);
      end;
    tkLBrk:
      begin
        Next;
        N := ParseExpr;
        Expect(tkRBrk, ''']''');
        var
        O := TOptNode.Create;
        O.Kind := nkOptional;
        O.Inner := N;
        O.Line := Cur.Line;
        O.Col := Cur.Col;
        Exit(O);
      end;
    tkLBr:
      begin
        Next;
        N := ParseExpr;
        Expect(tkRBr, '''}''');
        var
        R := TRepeatNode.Create;
        R.Kind := nkRepeat;
        R.Inner := N;
        R.Line := Cur.Line;
        R.Col := Cur.Col;
        Exit(R);
      end;
    tkString:
      begin
        var
        Tm := TTerminalNode.Create;
        Tm.Kind := nkTerminal;
        Tm.Text := Cur.Lexeme;
        Tm.Line := Cur.Line;
        Tm.Col := Cur.Col;
        Next;
        Exit(Tm);
      end;
    tkIdent:
      begin
        var
        Id := TIdentRefNode.Create;
        Id.Kind := nkIdentRef;
        Id.Name := Cur.Lexeme;
        Id.Line := Cur.Line;
        Id.Col := Cur.Col;
        Next;
        Exit(Id);
      end;
  else
    raise Exception.CreateFmt('Unexpected token at line %d col %d', [Cur.Line, Cur.Col]);
  end;
end;

end.
