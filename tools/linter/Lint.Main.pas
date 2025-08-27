unit Lint.Main;

interface

  function RunLinter:Integer;

implementation
uses
  System.SysUtils,
  System.Generics.Collections,
  EBNF.Ast,
  EBNF.Lexer,
  EBNF.Parser,
  Grammar.LexicalInventory,
  UDiff,
  UFileUtil,
  Lint.Issues,
  Lint.Parameters,
  Lint.Report,
  Lint.RuleExec;


type
  TExitCode = (ecOK=0, ecWarn=1, ecErr=2);


function RunLinter: Integer;
var
  Params:TLinterParameters;
  EbnfPath, LexPath, MdPath, StartSymbol, FormatStr:string;
  TextFormat:Boolean;
  EbnfText, MdText, MdBlock:string;
  Lexer:TEBNFLexer;
  Parser:TEBNFParser;
  Grammar:TGrammar;
  LexInv:TLexicalInventory;
  Issues:TObjectList<TLintIssue>;
  WarnAsError:TDictionary<string, Boolean>;
  HasError, HasWarn:Boolean;
  wae:string;
  code:string;
  it:TLintIssue;
  sev:TLintSeverity;
begin
  Issues := TObjectList<TLintIssue>.Create(True);
  WarnAsError := TDictionary<string, Boolean>.Create;
  try
    Params := TLinterParameters.Create(ParamStr(0), ParamCount, ParamStr);
    try
      if Params.ShowHelp then
      begin
        Writeln(Params.HelpText);
        Exit(0);
      end;

      EbnfPath := Params.GetOption('--ebnf', 'grammar\Delphi.ebnf');
      LexPath := Params.GetOption('--lexical', 'data\lexical.json');
      MdPath := Params.GetOption('--md', '');
      //using a different start changes reachability (L002)
      StartSymbol := Params.GetOption('--start', 'SourceFile');   //SourceFile = ProgramFile | LibraryFile | PackageFile | UnitFile
      FormatStr := Params.GetOption('--format', 'text').ToLower;
      TextFormat := (FormatStr = 'text');

      wae := Params.GetOption('--warn-as-error', '');
      if wae <> '' then
      begin
        for code in wae.Split([',']) do
        begin
          if code.Trim <> '' then
          begin
            WarnAsError.AddOrSetValue(code.Trim.ToUpper, True);
          end;
        end;
      end;
    finally
      Params.Free;
    end;

    if not FileExists(EbnfPath) then
      raise Exception.Create('EBNF file not found: ' + EbnfPath);

    EbnfText := TFileUtil.ReadAllText(EbnfPath);


    Grammar := nil;
    LexInv := TLexicalInventory.Create;
    try
      Lexer := TEBNFLexer.Create(EbnfText);
      try
        Parser := TEBNFParser.Create(Lexer);
        try
          Grammar := Parser.Parse;
        finally
          Parser.Free;
        end;
      finally
        Lexer.Free;
      end;

      // Load lexical inventory if provided
      if (LexPath <> '') and FileExists(LexPath) then
      begin
        LexInv.LoadFromFile(LexPath);
      end;

      RunRules(Grammar, LexInv, StartSymbol, Issues);

      // Custom D001 drift check
      if (MdPath <> '') and FileExists(MdPath) then
      begin
        MdText := TFileUtil.ReadAllText(MdPath);
        MdBlock := ExtractAutoEbnfBlock(MdText);
        if MdBlock <> '' then
        begin
          var normE := TFileUtil.NormalizeText(EbnfText);
          var normM := TFileUtil.NormalizeText(MdBlock);
          if normE <> normM then
          begin
            var diff := UDiff.BuildSimpleDiff(normM, normE, 'md', 'ebnf');
            Issues.Add(TLintIssue.Create('D001', lsWarning,
              'Markdown drift: spec/03-grammar-ebnf.md AUTO-EBNF block differs from EBNF.',
              0, 0, diff));
          end;
        end;
      end;


      if TextFormat then
      begin
        TLintReport.OutputText(Issues);
      end
      else
      begin
        TLintReport.OutputJson(StartSymbol, Issues);
      end;

      // Determine exit code
      HasError := False;
      HasWarn := False;
      for it in Issues do
      begin
        sev := it.Severity;
        if (sev = lsWarning) and WarnAsError.ContainsKey(it.Code.ToUpper) then
          sev := lsError;
        if sev = lsError then HasError := True;
        if sev = lsWarning then HasWarn := True;
      end;
    finally
      Grammar.Free;
      LexInv.Free;
    end;


    {$IF DEFINED(MSWINDOWS)}
    {$WARN SYMBOL_PLATFORM OFF}
    if System.DebugHook > 0 then begin
      ReportMemoryLeaksOnShutdown := True;
      IsConsole := False; //allow a showmessage
      readln;
    end;
    {$WARN SYMBOL_PLATFORM ON}
    {$ENDIF}

    if HasError then
      Exit(Ord(ecErr))
    else if HasWarn then
      Exit(Ord(ecWarn))
    else
      Exit(Ord(ecOK));

  except
    on E: Exception do
    begin
      Writeln('Fatal Error: ' + E.ClassName + ': ' + E.Message);
      Result := Ord(ecErr);
    end;
  end;
end;



end.
