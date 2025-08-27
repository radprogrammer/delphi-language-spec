unit Rule.L003.DupeNonT;

interface

uses
  System.Generics.Collections,
  EBNF.Ast,
  Lint.Issues;

procedure RunL003_Duplicates(const G:TGrammar; const Issues:TObjectList<TLintIssue>);


implementation

uses
  System.SysUtils;


procedure RunL003_Duplicates(const G:TGrammar; const Issues:TObjectList<TLintIssue>);
var
  seen:TDictionary<string, Integer>;
  firstLine:TDictionary<string, Integer>;
  P:TProduction;
  prev:Integer;
begin
  seen := TDictionary<string, Integer>.Create;
  firstLine := TDictionary<string, Integer>.Create;
  try
    for P in G.Prods do
    begin
      if seen.TryGetValue(P.Name, prev) then
      begin
        Issues.Add(TLintIssue.Create('L003', lsError, 'Duplicate non terminal definition: ' + P.Name + ' (first defined at line ' + firstLine[P.Name].ToString + ')', P.Line, 0));
        seen[P.Name] := prev + 1;
      end
      else
      begin
        seen.Add(P.Name, 1);
        firstLine.Add(P.Name, P.Line);
      end;
    end;
  finally
    seen.Free;
    firstLine.Free;
  end;
end;

end.
