[![Status: Draft](https://img.shields.io/badge/Status-Draft-orange.svg)](./spec/01-lexical.md#status)

# Delphi Language Specification — 01 Lexical Structure

Targets the latest Delphi compiler, Delphi 12 Athens

This chapter defines how source text is broken into tokens (identifiers, keywords, literals, operators, and punctuators). It is **normative** unless explicitly marked “informative”.

## 1. Source text and encoding

1. A *source file* is a text file encoded as **UTF-8**.
2. For backwards compatibility, source files may remain **ANSI** provided the compiler is instructed to use the correct code page, such as 1252 (Project → Options → Delphi Compiler → Compiling → Code generation → "Code page").
3. Embarcadero [officially recommends](https://docwiki.embarcadero.com/RADStudio/en/Unicode_in_RAD_Studio) using UTF-8 and writing a **UTF-8 BOM** to each source file to ensure correct encoding recognition across environments.
4. Characters outside the ASCII range may appear in comments, string literals, and identifiers as permitted below.
5. A *line terminator* is one of: CRLF (\r\n), LF (\n), or CR (\r)


## 2. Lexical phases

1. Before tokenization, *compiler directives* (\$IF, \$IFDEF, \$DEFINE, \$INCLUDE, etc.; §10) are recognized inside comments and can conditionally remove or insert source text. Regions excluded by a false conditional directive are not tokenized.
2. The source text is tokenized left‑to‑right using longest‑match ([maximal‑munch](https://www.devx.com/tip-bank/13828/)): at each position, the lexer produces the longest sequence of characters that forms a valid token. For example, :=, .., <=, and >= are each recognized as single tokens; if two dots appear in sequence they form .. (range). To avoid unintended .., insert whitespace where needed.
4. Whitespace and comments are separators and do not produce tokens.

## 3. Character classes (informative notation)

- `Letter` : any Unicode letter ([general categories](https://www.unicode.org/reports/tr44/#General_Category_Values) Lu, Ll, Lt, Lm, Lo) and the connector underscore `_`.
- `Digit` : ASCII `0`..`9`.
- `HexDigit` : `0`..`9` | `A`..`F` | `a`..`f`.
- `BinDigit` : `0` | `1`.
- `WS` : spaces (blanks), horizontal tabs, vertical tabs, and newline characters
- `Comments` : see [§4.2](#42-comments)
> Delphi documentation classifies comments as whitespace. In this specification, whitespace characters and comments are described separately for clarity, but both act as token separators and are ignored by the compiler.

## 4. Whitespace and comments

### 4.1 Whitespace

One or more whitespace characters separate tokens when needed. Whitespace has no other meaning and is discarded.

### 4.2 Comments

Delphi supports the following comment forms; comments of the same type do **not** nest.

```
Curly Brace : "{" .*? "}"
StarParen   : "(*" .*? "*)"
Line        : "//" [^\n\r]* (\r?\n|\r)?
DocComment  : "///" .*? (end of line)
DocBlock    : "{!" .*? "}"
```

- A comment may contain any characters, including quotes and operators.
- A comment may contain a *compiler directive* if the first non‑space after the opener is a `\$` ([§10](#10-compiler-directives-lexical recognition))
- **Nesting is not supported**: if a comment opener occurs inside another comment of the same style, it is treated as text. The comment ends at the first closing delimiter encountered.
- The current [official recommendation](https://docwiki.embarcadero.com/RADStudio/en/Delphi_Comments) is to use Curly Brace instead of StarParen comments

## 5. Tokens

Tokens are classified as:

- identifiers (§6)
- keywords (§7)
- literals (§8)
- operators and punctuators (§9)

## 6. Identifiers

### 6.1 Syntax

```
Identifier         : StartChar { ContChar }
StartChar          : Letter | '_'
ContChar           : Letter | Digit | '_'

EscapedIdentifier  : '&' Identifier
```

- Identifiers are case‑insensitive for purposes of declaration matching and reference, subject to implementation‑defined Unicode case folding. Note: accented letters are treated as distinct identifiers.
- The ampersand `&` forces treatment as an identifier even if the spelling is a keyword. Example: `var &type: Integer;`

### 6.2 Examples

```
Count  count  CoUnT    // same identifier
_AddRef            // leading underscore permitted
Καλημέρα           // non‑ASCII letters allowed
&object            // allowed, even though "object" is a keyword
```

## 7. Keywords

The following are **reserved words**. They cannot be used as identifiers unless escaped with `&`.

```
and array as asm begin case class const constructor destructor dispinterface
div do downto else end except exports file finalization finally for function
goto if implementation in inherited initialization inline interface is label
library mod nil not object of on or out packed procedure program property raise
record repeat resourcestring set shl shr string then threadvar to try type unit
until uses var while with xor
```

The following **directive and modifier keywords** are reserved in their grammatical positions (method, type, field, and property directives; calling conventions; visibility specifiers; etc.).

```
absolute abstract assembler automated cdecl contains requires default deprecated dispid
dynamic experimental export external far final forward helper implements index nodefault
object pascal package platform private protected public published read readonly register
reintroduce reference resources safecall sealed static stdcall strict stored unsafe varargs
virtual write writeonly
```

> Notes: The exact set of directive keywords evolves over time. Implementations may accept additional ones.

## 8. Literals

### 8.1 Integer literals

```
IntegerLiteral     : DecimalInteger | HexInteger | BinInteger
DecimalInteger     : DecDigit { DecDigit | '_' }
HexInteger         : '$' HexDigit { HexDigit | '_' }
BinInteger         : '%' BinDigit { BinDigit | '_' }
DecDigit           : '0'..'9'
```

Constraints:
- Underscores are digit separators permitted between digits only.
- The token value range is checked in later semantic phases.

Examples:
```
0   42   1_000_000
$FF $CA_FE_BA_BE
%1011_0101
```

### 8.2 Real (floating‑point) literals

```
RealLiteral  : Digits '.' [Digits] [Exponent]
             | '.' Digits [Exponent]
             | Digits Exponent
Digits       : DecDigit { DecDigit | '_' }
Exponent     : ('E' | 'e') ['+' | '-'] Digits
```

Rules:
- A `.` that would make a `..` token (range operator) is not part of a `RealLiteral`.
- At least one digit is required overall, but forms like `123.`, `.5`, `1.e10` are allowed.

Examples:
```
0.0  3.14159  6.02e23  .5  123.  1.e10
```

### 8.3 Boolean literals

```
BooleanLiteral : 'true' | 'false'   // case‑insensitive
```

### 8.4 Character code literals

```
CharCode     : '#' ( DecimalCode | '$' HexDigits | '%' BinDigits )
DecimalCode  : Digits
HexDigits    : HexDigit { HexDigit }
BinDigits    : BinDigit { BinDigit }
```

Examples:
```
#13   #10
#$0A
#%00001010
```

### 8.5 String literals and constants

#### 8.5.1 String literals

```
StringLiteral : '\'' StringChar* '\''
StringChar    : any character except '\'' and line terminators
              | "''"  // two single quotes represent one quote character
```

- Line terminators are not permitted inside a single string literal.
- To include a single quote, write two consecutive single quotes: `'Don''t'`.

#### 8.5.2 String constants

```
StringConstant : StringElem { WS* StringElem }
StringElem     : StringLiteral | CharCode
```

Examples:
```
'Hello, world'
'Line break:' #13 #10
'Path: ' 'C:\Temp'
```

### 8.6 Nil literal

```
NilLiteral : 'nil'   // case‑insensitive
```

## 9. Operators and punctuators

The following tokens are produced as single tokens under maximal munch:

```
+  -  *  /  :=  =  <>  <  <=  >  >=  @  ^  .  ..  ,  ;  :  (  )  [  ]
```

The following are formed from identifiers and act as operators/keywords:

```
and or not xor div mod shl shr in as is on
```

## 10. Compiler directives (lexical recognition)

Directives are recognized only inside comments whose first non‑space character is `$` (or `{$` / `(*$`).

```
DirectiveComment : '{' WS* '$' DirectiveBody '}'
                 | '(*' WS* '$' DirectiveBody '*)'
DirectiveBody    : { any character not closing the comment }
```

Common directive families include conditional compilation (`$IF`, `$ELSE`, `$ENDIF`, `$IFDEF`, `$DEFINE`, `$UNDEF`), code generation options (e.g., `$H+`, `$TYPEDADDRESS`), resource inclusion (`$R`, `$INCLUDE`), and others.

## 11. Ambiguities and disambiguation

- `.` vs `..`: If two dots appear in sequence, they form the `..` token (range). A real literal like `1..2` must be written `1 .. 2` or `1.0..2`.
- `<` and `>` serve both as relational operators and as generic type parameter delimiters; resolved by the grammar of §03.
- `&Identifier` is a single identifier token; the `&` does not form a separate operator token.

## 12. Examples (informative)

```
var S: string;
S := 'Line1' #13#10 'Line2';
if (A <= B) and not Done then
  Inc(Count, $10);
```

Produces:
```
[var] [Identifier] [:] [string] [;]
[Identifier] [:=] [StringConstant] [;]
[if] [(] [Identifier] [<=] [Identifier] [)] [and] [not] [Identifier] [then]
  [Identifier] [(] [Identifier] [,] [HexInteger] [)] [;]
```

## 13. Conformance

A conforming implementation must:
- Accept the token forms defined in §§6–9.
- Apply maximal‑munch tokenization after directive processing.
- Treat reserved words as non‑identifiers unless escaped with `&`.
- Enforce string and numeric literal formation rules.

---
