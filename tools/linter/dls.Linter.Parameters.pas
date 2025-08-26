unit dls.Linter.Parameters;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type

  TLinterParameters = class
  private
    FOpts:TDictionary<string, string>;
    FShowHelp:Boolean;
    FExe:string;
    function BuildHelp:string;
  public
    constructor Create(const ExePath:string; ParamCount:Integer; ParamStrFunc:TFunc<Integer, string>);

    function GetOption(const Name, DefaultValue:string):string;

    property ShowHelp:Boolean read FShowHelp;
    property HelpText:string read BuildHelp;
  end;

implementation


constructor TLinterParameters.Create(const ExePath:string; ParamCount:Integer; ParamStrFunc:TFunc<Integer, string>);
var
  i:Integer;
  k, v:string;
begin
  inherited Create;

  FExe := ExePath;
  FOpts := TDictionary<string, string>.Create;
  for i := 1 to ParamCount do
  begin
    k := ParamStrFunc(i);
    if SameText(k, '--help') or SameText(k, '-h') or SameText(k, '/?') then
    begin
      FShowHelp := True;
      Exit;
    end;
    if k.StartsWith('--') then
    begin
      if i < ParamCount then
      begin
        v := ParamStrFunc(i + 1);
        if not v.StartsWith('--') then
        begin
          FOpts.AddOrSetValue(k, v);
          Continue;
        end
        else
        begin
          // flags without value not supported; store empty
          FOpts.AddOrSetValue(k, '');
          Continue;
        end;
      end
      else
      begin
        FOpts.AddOrSetValue(k, '');
      end;
    end;
  end;
end;


function TLinterParameters.GetOption(const Name, DefaultValue:string):string;
begin
  if not FOpts.TryGetValue(Name, Result) then
  begin
    Result := DefaultValue;
  end;
end;


function TLinterParameters.BuildHelp: string;
begin
  Result :=
    'dls.Linter - Delphi EBNF Linter' + sLineBreak +
    'Usage:' + sLineBreak +
    '  dls.Linter --ebnf <file> [--lexical <file>] [--md <file>]' + sLineBreak +
    '            [--start <NonTerminal>] [--format text|json]' + sLineBreak +
    '            [--warn-as-error L001,L002,T001]' + sLineBreak +
    sLineBreak +
    'Options:' + sLineBreak +
    '  --ebnf           Path to EBNF file (default: grammar\Delphi.ebnf)' + sLineBreak +
    '  --lexical        Path to lexical.json (optional)' + sLineBreak +
    '  --md             Path to 03-grammar-ebnf.md (optional, drift check)' + sLineBreak +
    '  --start          Start symbol (default: SourceFile)' + sLineBreak +
    '  --format         Output format: text or json (default: text)' + sLineBreak +
    '  --warn-as-error  Comma-separated codes promoted to error' + sLineBreak +
    '  --help           Show this help' + sLineBreak;
end;


end.
