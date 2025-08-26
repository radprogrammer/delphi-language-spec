unit dls.Linter.RuleExec;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  EBNF.Ast,
  Grammar.LexicalInventory,
  Grammar.Symbols,
  Linter.Issues;


procedure RunRules(const G:TGrammar; const Inv:TLexicalInventory; const Start:string; const Issues:TObjectList<TLintIssue>);
function ExtractAutoEbnfBlock(const Md:string):string;


implementation

uses
  UFileUtil,
  Rule.L001.UndefinedNonT,
  Rule.L002.UnusedNonT,
  Rule.L003.DupeNonT,
  Rule.L004.EmptyAlternative,
  Rule.T002.UnknownTokenRef,
  Rule.T004.TokenCollisionWithNonT;





(*
Rule names
  Lxxx = grammar/Language checks (structure + reachability).
  Txxx = token/lexical cross-checks against lexical.json.
  Dxxx = doc/drift checks (e.g., MD vs EBNF).
  Sxxx = style advisories.  (TODO)

  Numbered bucket groupings
  L000–L099 = core structural invariants (must be sane before anything else).
  L100+ = deeper analyses (FIRST/FOLLOW, left-recursion heuristics, etc.).
*)

procedure RunRules(const G:TGrammar; const Inv:TLexicalInventory; const Start:string; const Issues:TObjectList<TLintIssue>);
var
  UpperAsTokens:TDictionary<string, Boolean>;
  P:TProduction;
  S:TSymbolTables;

  procedure Walk(N:TNode);
  var
    i:Integer;
    Name:string;
  begin
    if N = nil then
      Exit;
    case N.Kind of
      nkIdentRef:
        begin
          name := TIdentRefNode(N).Name;
          // Heuristic: ALLCAPS (len > 1) are treated as token names for reachability
          if ((name = name.ToUpper) and (Length(name) > 1)) or ((Inv <> nil) and Inv.HasToken(name)) then
            UpperAsTokens.AddOrSetValue(name, True);
        end;

      nkSeq:
        for i := 0 to TSeqNode(N).Items.Count - 1 do
          Walk(TSeqNode(N).Items[i]);

      nkChoice:
        for i := 0 to TChoiceNode(N).Alts.Count - 1 do
          Walk(TChoiceNode(N).Alts[i]);

      nkSuffix:
        Walk(TSuffixNode(N).Base);

      nkGroup:
        Walk(TGroupNode(N).Inner);

      nkOptional:
        Walk(TOptNode(N).Inner);

      nkRepeat:
        Walk(TRepeatNode(N).Inner);
    end;
  end;


begin
  // Build heuristic token set for reachability (L001/L002)
  UpperAsTokens := TDictionary<string, Boolean>.Create;
  try
    for P in G.Prods do
      Walk(P.Expr);

    RunL003_Duplicates(G, Issues);

    CollectSymbols(G, UpperAsTokens, S);
    try
      RunL001_UndefinedNonTerminal(G, S, UpperAsTokens, Start, Issues);
      RunL002_UnusedNonTerminal(G, S, UpperAsTokens, Start, Issues);
    finally
      S.Free;
    end;

    RunL004_EmptyAlternatives(G, Issues);

    if Inv <> nil then // lexical.json inventory provided
    begin
      RunT004_NTTokenCollision(G, Inv, Issues);
      RunT002_UnknownTokenRef(G, Inv, Issues);
    end;
  finally
    UpperAsTokens.Free;
  end;
end;


function ExtractAutoEbnfBlock(const Md:string):string;
var
  S, e:Integer;
  startMarker, endMarker:string;
  block:string;
  codeStart, codeEnd:Integer;
begin
  Result := '';
  startMarker := '<!-- AUTO-EBNF START -->';
  endMarker := '<!-- AUTO-EBNF END -->';
  S := Md.IndexOf(startMarker);
  if S < 0 then
    Exit;
  e := Md.IndexOf(endMarker, S + Length(startMarker));
  if e < 0 then
    Exit;
  block := Md.Substring(S + Length(startMarker), e - (S + Length(startMarker)));
  // find ```ebnf ... ```
  codeStart := block.IndexOf('```ebnf');
  if codeStart < 0 then
    Exit;
  codeStart := codeStart + Length('```ebnf');
  codeEnd := block.IndexOf('```', codeStart);
  if codeEnd < 0 then
    Exit;
  Result := block.Substring(codeStart, codeEnd - codeStart);
  Result := Result.Replace(#13#10, #10).Replace(#13, #10);
  if (Result <> '') and (Result[1] = #10) then
    Result := Result.Substring(1);
end;

end.
