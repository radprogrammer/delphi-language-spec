[![Status: Draft](https://img.shields.io/badge/Status-Draft-orange.svg)](./spec/01-lexical.md#status)

# Delphi Language Specification — 01 Lexical Structure

*Status*: Draft v0.3.2 — 2025-08-24  
*Target*: RAD Studio 12 Athens (Delphi)  
*Scope*: This chapter defines the lexical elements of the Delphi language: source text, comments, compiler directives, identifiers, literals, operators, delimiters, and tokenization rules. Grammar and semantics are specified in later chapters.

## Conventions
- The term "must" indicates a normative requirement.
- Examples are informative, not normative.
- References to data/lexical.json indicate the canonical machine-readable mapping for tools.
- data/lexical.json is the canonical machine-readable mapping for tools.


## 1. Source text and encoding

1. A *source file* is a text file that is typically encoded as **UTF-8**.
2. For backwards compatibility, source files may remain **ANSI** provided the compiler is instructed to use the correct code page, such as 1252 (Project → Options → Delphi Compiler → Compiling → Code generation → "Code page").
3. Embarcadero [officially recommends](https://docwiki.embarcadero.com/RADStudio/en/Unicode_in_RAD_Studio) using UTF-8 and writing a **UTF-8 BOM** to each source file to ensure correct encoding recognition across environments.
4. Characters outside the ASCII range may appear in comments, string literals, and identifiers as permitted below.
5. A *line terminator* is one of: CRLF (\r\n), LF (\n), or CR (\r) with the Windows-based IDE and tooling preferring CRLF.
6. Supported encodings include UTF8, ANSI (with codepage), UTF-16 BE, UTF-16 LE, UTF-32 BE, UTF-32 LE

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
> Delphi documentation can classify comments as whitespace. In this specification, whitespace characters and comments are described separately for clarity, but both act as token separators and are ignored by the compiler.

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
```

- A comment may contain any characters, including quotes and operators.
- A comment may contain a *compiler directive* if the first non‑space after the opener is a `\$` ([§10](#10-compiler-directives-lexical recognition))
- Block comments do not nest. A block comment consumes characters until its first matching closer.
- The current [official recommendation](https://docwiki.embarcadero.com/RADStudio/en/Delphi_Comments) is to use Curly Brace instead of StarParen comments
- Comments are ignored by the lexer once the directives layer has run.


## 5. Tokens

Tokens are classified as:

- identifiers (§6)
- keywords (§7)
- literals (§8)
- operators and punctuators (§9)

### 5.1 Longest-match rule

When two tokens share a prefix, the lexer must prefer the longest match. Examples:
- .. must be recognized over . when both are possible.
- := must be recognized over :.

### 5.2 Delimiters and operators

- Delimiters: , ; : . ( ) [ ]
- Operators: := + - * / div mod and or xor not shl shr = <> < > <= >= in is as @ ^ ..

Note: / is real division; div is integer division; mod is remainder. @ yields an address; ^ is pointer dereference.

### 5.3 Disambiguation: dot vs range

Because .. is a range operator, an integer followed by .. is not a real literal. Example:

```
1..5   // range; tokens: INT(1) DOTDOT INT(5)
1.5    // tokens: REAL_LITERAL(1.5)
1.     // tokens: REAL_LITERAL(1.0)
1.e3   // tokens: REAL_LITERAL(1.0e3)
```
### 5.4 Disambiguation: Relational and generic type parameter delimiters
- `<` and `>` serve both as relational operators and as generic type parameter delimiters; resolved by the grammar. See spec/03-grammar-ebnf.md (Generics).
Because Delphi allows generic methods and class/static members on generic types, a few edge cases do require symbol awareness
(the parser may need to know whether a leading `Foo` is a type or a variable/function to choose between `Foo<T>(...)` as a generic call vs `Foo < T` as a comparison).

## 6. Identifiers

### 6.1 Syntax

```
Identifier         : StartChar { ContChar }
StartChar          : Letter | '_'
ContChar           : Letter | Digit | '_'

EscapedIdentifier  : '&' Identifier
```
- Identifiers are case‑insensitive for purposes of declaration matching and reference. Note: accented letters are treated as distinct identifiers.

### 6.2 Extended Identifiers
- If `&` directly precedes an identifier, the scanner produces a single IDENTIFIER token whose lexeme is the identifier characters only; the & is consumed and not emitted as a separate token. 

- Extended Identifier Usage (Informative)
  - Declaration sites: If the name equals a keyword, you must write & in the declaration (e.g., var &begin: Integer;). 
  - Use sites: You need & only when the position would otherwise be parsed as a keyword. After a qualifier (like `Unit.TypeName` or `Obj.Member`), the grammar expects an identifier, so the & is typically optional (e.g., `TMyType.type` is OK). 
  - Token table: & is listed among Delphi's "special symbols," but in normal Delphi code its only language role is this prefix for extended identifiers (it isn’t a bitwise operator).

### 6.3 Identifier Examples

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

## 10. Compiler directives

### 10.1 Directive forms and preprocessing

- A directive is text inside one of the following comment blocks:
  - "{$" ... "}" (for example, {$R *.res}) using Curly Braces
  - "(*$" ... "*)" using StarParen
- The directives layer must run before final tokenization. Inactive regions eliminated by conditional directives are not lexed.
- Implementations should support legacy $IF pairing with $ENDIF or $IFEND. The {$LEGACYIFEND ON|OFF} switch controls acceptance of $ENDIF for $IF blocks.

```
DirectiveComment : '{' WS* '$' DirectiveBody '}'
                 | '(*' WS* '$' DirectiveBody '*)'
DirectiveBody    : { any character not closing the comment }
```

### 10.2 Conditional compilation

Supported conditional directives include (names shown without the leading $):

- IF, ELSEIF, ELSE, IFEND
- IFDEF, IFNDEF, ENDIF
- IFOPT
- DEFINE, UNDEF
- LEGACYIFEND (switch)

Boolean functions in $IF expressions include:
- Defined(SYMBOL)
- Declared(IDENT)

Expression grammar (informative sketch):
- Expressions may use not, and, or, parentheses, and the comparison operators =, <>, <, >, <=, >= over integer constants and symbols. 

### 10.3. $IF expression grammar (Normative, minimal)

````
if_expr      := or_expr ;

or_expr      := and_expr { 'or' and_expr } ;
and_expr     := not_expr { 'and' not_expr } ;
not_expr     := [ 'not' ] rel_expr ;

rel_expr     := add_expr [ rel_op add_expr ] ;
rel_op       := '=' | '<>' | '<' | '>' | '<=' | '>=' ;

add_expr     := mul_expr { add_op mul_expr } ;
add_op       := '+' | '-' ;

mul_expr     := unary { mul_op unary } ;
mul_op       := '*' | 'div' | 'mod' ;

unary        := [ '+' | '-' ] primary ;

primary      := integer_literal
              | 'True' | 'False'            # case-insensitive
              | 'Defined' '(' identifier ')'
              | 'Declared' '(' identifier ')'
              | '(' if_expr ')' ;
````


#### 10.2.1 Nested example

```
{$IF Defined(MSWINDOWS)}
  {$IFDEF WIN64}
    {$MESSAGE 'Compiling for Windows 64-bit'}
  {$ELSE}
    {$MESSAGE 'Compiling for Windows 32-bit'}
  {$ENDIF}
{$ELSEIF Defined(LINUX) and Defined(CPU64BITS)}
  {$MESSAGE 'Compiling for Linux 64-bit'}
{$ELSE}
  {$MESSAGE 'Other platform'}
{$IFEND}
```

### 10.3 Non-conditional directives (catalog)

This list mirrors data/lexical.json and is grouped for contributor convenience. Exact semantics are defined by the implementation.

- Include / resources / link:
  - INCLUDE or I
  - RESOURCE or R
  - RESOURCERESERVE
  - LINK or L

- Messages, warnings, regions:
  - MESSAGE
  - WARN
  - WARNINGS
  - HINTS
  - REGION and ENDREGION
  - TEXTBLOCK

- Code generation switches:
  - ASSERTIONS (C+ C-)
  - BOOLEVAL (B+ B-)
  - CODEALIGN
  - EXTENDEDSYNTAX (X+ X-)
  - EXCESSPRECISION
  - HIGHCHARUNICODE
  - IMPORTEDDATA (G+ G-)
  - IOCHECKS (I+ I-)
  - LOCALSYMBOLS (L+ L-)
  - LONGSTRINGS (H+ H-)
  - MINENUMSIZE (Z1 Z2 Z4)
  - OPTIMIZATION (O+ O-)
  - OVERFLOWCHECKS (Q+ Q-)
  - POINTERMATH
  - RANGECHECKS (R+ R-)
  - REALCOMPATIBILITY
  - STACKFRAMES (W+ W-)
  - STRONGLINKTYPES
  - TYPEINFO (M+ M-)
  - TYPEDADDRESS (T+ T-)
  - VARSTRINGCHECKS (V+ V-)
  - WRITEABLECONST (J+ J-)
  - ZEROBASEDSTRINGS

- Linking / binary:
  - ALIGN or A
  - APPTYPE
  - DEBUGINFO or D
  - DESCRIPTION
  - DYNAMICBASE
  - IMAGEBASE
  - IMPLICITBUILD
  - LARGEADDRESSAWARE
  - LIBPREFIX, LIBSUFFIX, LIBVERSION
  - NXCOMPAT
  - SetPEFlags, SetPEOptFlags, SETPEOSVERSION, SETPESUBSYSVERSION, SETPEUSERVERSION
  - TSAWARE
  - HIGHENTROPYVA

- RTTI and interface info:
  - RTTI
  - METHODINFO

- C++Builder interop:
  - HPPEMIT (including PUSH, POP, END forms)
  - EXTERNALSYM
  - NODEFINE
  - OBJTYPENAME

- Packages / deployment:
  - ALLOWBIND
  - ALLOWISOLATION
  - DENYPACKAGEUNIT
  - RUNONLY
  - WEAKPACKAGEUNIT

See data/lexical.json for exact shapes used by tools.


## 11. Examples (informative)

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

## 12. Conformance

A conforming implementation must:
- Accept the token forms defined in §§6–9.
- Apply maximal‑munch tokenization after directive processing.
- Treat reserved words as non‑identifiers unless escaped with `&`.
- Enforce string and numeric literal formation rules.

---
