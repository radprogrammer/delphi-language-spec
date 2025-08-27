unit Rule.T004.TokenCollisionWithNonT;

interface

uses
  System.Generics.Collections,
  EBNF.Ast,
  Grammar.LexicalInventory,
  Lint.Issues;


procedure RunT004_NTTokenCollision(const G:TGrammar; const Inv:TLexicalInventory; const Issues:TObjectList<TLintIssue>);


implementation


// to test failure, add to EBNF:
// INT = 'zero' ;
procedure RunT004_NTTokenCollision(const G:TGrammar; const Inv:TLexicalInventory; const Issues:TObjectList<TLintIssue>);
var
  P:TProduction;
begin
  if not Assigned(Inv) then Exit;

  for P in G.Prods do
  begin
    if Inv.HasToken(P.Name) then
    begin
      Issues.Add(TLintIssue.Create('T004', lsError, 'Nonterminal name collides with token: ' + P.Name, P.Line, 0));
    end;
  end;
end;


end.
