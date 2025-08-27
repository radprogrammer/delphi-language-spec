program DLS.Lint;

{$APPTYPE CONSOLE}

uses
  EBNF.Ast in '..\shared\EBNF.Ast.pas',
  EBNF.Lexer in '..\shared\EBNF.Lexer.pas',
  EBNF.Parser in '..\shared\EBNF.Parser.pas',
  Grammar.LexicalInventory in '..\shared\Grammar.LexicalInventory.pas',
  Grammar.Symbols in '..\shared\Grammar.Symbols.pas',
  UDiff in '..\shared\UDiff.pas',
  UFileUtil in '..\shared\UFileUtil.pas',
  Lint.RuleExec in 'Lint.RuleExec.pas',
  Lint.Parameters in 'Lint.Parameters.pas',
  Lint.Report in 'Lint.Report.pas',
  Lint.Main in 'Lint.Main.pas',
  Rule.L001.UndefinedNonT in 'Rule.L001.UndefinedNonT.pas',
  Lint.Issues in 'Lint.Issues.pas',
  Rule.L002.UnusedNonT in 'Rule.L002.UnusedNonT.pas',
  Rule.T002.UnknownTokenRef in 'Rule.T002.UnknownTokenRef.pas',
  Rule.L003.DupeNonT in 'Rule.L003.DupeNonT.pas',
  Rule.L004.EmptyAlternative in 'Rule.L004.EmptyAlternative.pas',
  Rule.T004.TokenCollisionWithNonT in 'Rule.T004.TokenCollisionWithNonT.pas';

begin
  Halt(RunLinter);
end.
