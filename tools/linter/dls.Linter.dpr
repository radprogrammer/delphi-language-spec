program dls.Linter;

{$APPTYPE CONSOLE}

uses
  EBNF.Ast in 'EBNF.Ast.pas',
  EBNF.Lexer in 'EBNF.Lexer.pas',
  EBNF.Parser in 'EBNF.Parser.pas',
  Grammar.LexicalInventory in 'Grammar.LexicalInventory.pas',
  Grammar.Symbols in 'Grammar.Symbols.pas',
  UDiff in 'UDiff.pas',
  UFileUtil in 'UFileUtil.pas',
  dls.Linter.RuleExec in 'dls.Linter.RuleExec.pas',
  dls.Linter.Parameters in 'dls.Linter.Parameters.pas',
  dls.Linter.Report in 'dls.Linter.Report.pas',
  dls.Linter.Main in 'dls.Linter.Main.pas',
  Rule.L001.UndefinedNonT in 'Rule.L001.UndefinedNonT.pas',
  Linter.Issues in 'Linter.Issues.pas',
  Rule.L002.UnusedNonT in 'Rule.L002.UnusedNonT.pas',
  Rule.T002.UnknownTokenRef in 'Rule.T002.UnknownTokenRef.pas',
  Rule.L003.DupeNonT in 'Rule.L003.DupeNonT.pas',
  Rule.L004.EmptyAlternative in 'Rule.L004.EmptyAlternative.pas',
  Rule.T004.TokenCollisionWithNonT in 'Rule.T004.TokenCollisionWithNonT.pas';

begin
  Halt(RunLinter);
end.
