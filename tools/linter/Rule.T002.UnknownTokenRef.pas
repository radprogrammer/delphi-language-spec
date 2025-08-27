unit Rule.T002.UnknownTokenRef;

interface

uses
  System.Generics.Collections,
  EBNF.Ast,
  Grammar.LexicalInventory,
  Lint.Issues;

procedure RunT002_UnknownTokenRef(const G:TGrammar; const Inv:TLexicalInventory; const Issues:TObjectList<TLintIssue>);

implementation


// unknown token ref
procedure RunT002_UnknownTokenRef(const G:TGrammar; const Inv:TLexicalInventory; const Issues:TObjectList<TLintIssue>);

  function LooksLikeToken(const Name:string):Boolean;
  var
    i:Integer;
    c:Char;
    hasAlpha:Boolean;
  begin
    // Heuristic: ALLCAPS + underscores/digits, at least 2 chars, with at least one A..Z
    hasAlpha := False;
    for i := 1 to Length(name) do
    begin
      c := name[i];
      if (c >= 'A') and (c <= 'Z') then
      begin
        hasAlpha := True
      end
      else if (c = '_') or ((c >= '0') and (c <= '9')) then
      begin
        { ok }
      end
      else
      begin
        Exit(False);
      end;
    end;
    Result := hasAlpha and (Length(name) >= 2);
  end;

  procedure Walk(N:TNode);
  var
    Name:string;
    i:Integer;
  begin
    if N = nil then Exit;

    case N.Kind of
      nkIdentRef:
        begin
          name := TIdentRefNode(N).Name;
          if Inv.HasToken(name) then
          begin
            Exit // known token
          end
          else if LooksLikeToken(name) then
          begin
            Issues.Add(TLintIssue.Create('T002', lsError, 'Unknown token reference: ' + name, N.Line, N.Col));
          end;
        end;

      nkSeq:
        for i := 0 to TSeqNode(N).Items.Count - 1 do
        begin
          Walk(TSeqNode(N).Items[i]);
        end;

      nkChoice:
        for i := 0 to TChoiceNode(N).Alts.Count - 1 do
        begin
          Walk(TChoiceNode(N).Alts[i]);
        end;

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


var
  P:TProduction;
begin
  if Inv = nil then Exit;

  for P in G.Prods do
  begin
    Walk(P.Expr);
  end;
end;


end.
