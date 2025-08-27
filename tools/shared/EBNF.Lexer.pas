unit EBNF.Lexer;

interface

uses System.SysUtils;

type
  TTokenKind = (tkEOF, tkIdent, tkString, tkEq, tkBar, tkSemi, tkLPar, tkRPar, tkLBrk, tkRBrk, tkLBr, tkRBr, tkQ, tkStar, tkPlus);


  TToken = record
    Kind:TTokenKind;
    Lexeme:string;
    Line:Integer;
    Col:Integer;
  end;


  TEBNFLexer = class
  private
    FText:string;
    FPos:Integer;
    FLine:Integer;
    FCol:Integer;
    function Peek:Char; inline;
    function NextChar:Char; inline;
    procedure SkipWSAndComments;
    function ReadIdent:string;
    function ReadString:string;
  public
    constructor Create(const Text:string);

    function NextToken:TToken;
  end;

implementation

uses
  System.Character;


constructor TEBNFLexer.Create(const Text:string);
begin
  FText := Text;
  FPos := 1;
  FLine := 1;
  FCol := 1;
end;


function TEBNFLexer.Peek:Char;
begin
  if FPos <= Length(FText) then
    Result := FText[FPos]
  else
    Result := #0;
end;


function TEBNFLexer.NextChar:Char;
begin
  if FPos <= Length(FText) then
  begin
    Result := FText[FPos];
    Inc(FPos);
    if Result = #10 then
    begin
      Inc(FLine);
      FCol := 1;
    end
    else
      Inc(FCol);
  end
  else
    Result := #0;
end;


procedure TEBNFLexer.SkipWSAndComments;
begin
  while True do
  begin
    while CharInSet(Peek, [#9, #10, #13, ' ']) do
      NextChar;

    // Comments: ISO style (* ... *)
    if (Peek = '(') and (FPos + 1 <= Length(FText)) and (FText[FPos + 1] = '*') then
    begin
      NextChar;
      NextChar; // consume "(*"
      while True do
      begin
        if (Peek = #0) then
          Exit;
        if (Peek = '*') and (FPos + 1 <= Length(FText)) and (FText[FPos + 1] = ')') then
        begin
          NextChar;
          NextChar; // consume "*)"
          Break;
        end;
        NextChar;
      end;
      Continue;
    end;

    // Existing ISO style "(* ... *)" is supported.
    if (Peek = '/') and (FPos + 1 <= Length(FText)) and (FText[FPos + 1] = '*') then
    begin
      NextChar;
      NextChar; // consume /*
      while True do
      begin
        if Peek = #0 then
          Exit;
        if (Peek = '*') and (FPos + 1 <= Length(FText)) and (FText[FPos + 1] = '/') then
        begin
          NextChar;
          NextChar; // consume */
          Break;
        end;
        NextChar;
      end;
      Continue;
    end;


    // Line comments: // ...
    if (Peek = '/') and (FPos + 1 <= Length(FText)) and (FText[FPos + 1] = '/') then
    begin
      while (Peek <> #0) and (Peek <> #10) do
        NextChar;
      Continue;
    end;

    Break;
  end;
end;


function TEBNFLexer.ReadIdent:string;
begin
  Result := '';
  if not(Peek.IsLetter or (Peek = '_')) then
    Exit;
  while (Peek.IsLetterOrDigit or (Peek = '_')) do
    Result := Result + NextChar;
end;


function TEBNFLexer.ReadString:string;
var
  ch:Char;
begin
  Result := '';
  ch := NextChar; // opening quote '
  while True do
  begin
    if Peek = #0 then
      raise Exception.Create('Unterminated string literal');
    if Peek = '''' then
    begin
      // doubled quote '' escapes a single quote inside
      if (FPos + 1 <= Length(FText)) and (FText[FPos + 1] = '''') then
      begin
        NextChar; // first '
        NextChar; // second '
        Result := Result + '''';
        Continue;
      end;
      NextChar; // closing '
      Break;
    end;
    Result := Result + NextChar;
  end;
end;


function TEBNFLexer.NextToken: TToken;
begin
  SkipWSAndComments;
  Result.Lexeme := '';
  Result.Line := FLine;
  Result.Col := FCol;

  case Peek of
    #0: begin Result.Kind := tkEOF; Exit; end;
    '=': begin NextChar; Result.Kind := tkEq; Exit; end;
    '|': begin NextChar; Result.Kind := tkBar; Exit; end;
    ';': begin NextChar; Result.Kind := tkSemi; Exit; end;
    '(': begin NextChar; Result.Kind := tkLPar; Exit; end;
    ')': begin NextChar; Result.Kind := tkRPar; Exit; end;
    '[': begin NextChar; Result.Kind := tkLBrk; Exit; end;
    ']': begin NextChar; Result.Kind := tkRBrk; Exit; end;
    '{': begin NextChar; Result.Kind := tkLBr; Exit; end;
    '}': begin NextChar; Result.Kind := tkRBr; Exit; end;
    '?': begin NextChar; Result.Kind := tkQ; Exit; end;
    '*': begin NextChar; Result.Kind := tkStar; Exit; end;
    '+': begin NextChar; Result.Kind := tkPlus; Exit; end;
    '''': begin
      Result.Kind := tkString;
      Result.Lexeme := ReadString; // content without quotes
      Exit;
    end;
  end;

  if Peek.IsLetter or (Peek = '_') then
  begin
    Result.Kind := tkIdent;
    Result.Lexeme := ReadIdent;
    Exit;
  end;

  // Unknown char -> skip
  NextChar;
  Exit(NextToken);
end;

end.
