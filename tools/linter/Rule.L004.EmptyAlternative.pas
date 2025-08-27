unit Rule.L004.EmptyAlternative;

interface

uses
  System.Generics.Collections,
  EBNF.Ast,
  Lint.Issues;


procedure RunL004_EmptyAlternatives(const G:TGrammar; const Issues:TObjectList<TLintIssue>);


implementation
uses
  System.Math;


// to test failure, add to EBNF:
// LintEmptyAlt1 = 'a' | ;

procedure RunL004_EmptyAlternatives(const G:TGrammar; const Issues:TObjectList<TLintIssue>);
  procedure Walk(N:TNode);
  var
    i:Integer;
    alt:TNode;
  begin
    if N = nil then
      Exit;
    case N.Kind of
      nkChoice:
        begin
          for i := 0 to TChoiceNode(N).Alts.Count - 1 do
          begin
            alt := TChoiceNode(N).Alts[i];
            if (alt is TSeqNode) and (TSeqNode(alt).Items.Count = 0) then
            begin
              Issues.Add(TLintIssue.Create('L004', lsWarning, 'Empty alternative', Max(1, alt.Line), Max(1, alt.Col)));
            end;
            Walk(alt);
          end;
        end;
      nkSeq:
        for i := 0 to TSeqNode(N).Items.Count - 1 do
        begin
          Walk(TSeqNode(N).Items[i]);
        end;
      nkSuffix:
        Walk(TSuffixNode(N).Base);
      nkGroup:
        Walk(TGroupNode(N).Inner);
      nkOptional:
        Walk(TOptNode(N).Inner);
      nkRepeat:
        Walk(TRepeatNode(N).Inner);
      nkIdentRef, nkTerminal:
        ; // leaf
    end;
  end;


var
  P:TProduction;
begin
  for P in G.Prods do
  begin
    Walk(P.Expr);
  end;
end;


end.
