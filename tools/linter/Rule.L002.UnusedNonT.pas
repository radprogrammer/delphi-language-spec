unit Rule.L002.UnusedNonT;

interface

uses
  System.Generics.Collections,
  EBNF.Ast,
  Grammar.Symbols,
  Lint.Issues;

// unused / unreachable
procedure RunL002_UnusedNonTerminal(const G:TGrammar; const S:TSymbolTables; const TokenNames:TDictionary<string, Boolean>; const Start:string; const Issues:TObjectList<TLintIssue>);


implementation


procedure RunL002_UnusedNonTerminal(const G:TGrammar; const S:TSymbolTables; const TokenNames:TDictionary<string, Boolean>; const Start:string; const Issues:TObjectList<TLintIssue>);
var
  Reach:TDictionary<string, Boolean>;
begin
  Reach := ComputeReachable(G, Start, TokenNames);
  try
    for var def in S.DefinedNT do
    begin
      if not Reach.ContainsKey(def.Key) then
      begin
        Issues.Add(TLintIssue.Create('L002', lsWarning, 'Unused/unreachable nonterminal: ' + def.Key, def.Value, 0));
      end;
    end;
  finally
    Reach.Free;
  end;
end;


end.
