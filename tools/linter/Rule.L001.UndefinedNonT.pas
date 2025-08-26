unit Rule.L001.UndefinedNonT;

interface

uses
  System.Generics.Collections,
  EBNF.Ast,
  Grammar.Symbols,
  Linter.Issues;

procedure RunL001_UndefinedNonTerminal(const G:TGrammar; const S:TSymbolTables; const TokenNames:TDictionary<string, Boolean>; const Start:string; const Issues:TObjectList<TLintIssue>);


implementation


procedure RunL001_UndefinedNonTerminal(const G:TGrammar; const S:TSymbolTables; const TokenNames:TDictionary<string, Boolean>; const Start:string; const Issues:TObjectList<TLintIssue>);
begin
  for var kv in S.RefsNT do
  begin
    if not S.DefinedNT.ContainsKey(kv.Key) then
    begin
      Issues.Add(TLintIssue.Create('L001', lsError, 'Undefined nonterminal: ' + kv.Key, kv.Value, 0));
    end;
  end;
end;


end.
