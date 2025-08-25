[![Status: Draft](https://img.shields.io/badge/Status-Draft-orange.svg)](./spec/01-lexical.md#status)

# Delphi Language Specification
## 02. Compiler Directives

*Status*: Draft v0.1  
*Scope*: This chapter defines the preprocessing model and the semantics of Delphi compiler directives, including conditional compilation, include/resource management, diagnostic controls, code-generation switches, linking flags, RTTI/method info, C++Builder interop, and package directives.

### 1. Preprocessing model

1. Directives are recognized **inside comments** only:
   - `{$ ... }` (CurlyBrace block)
   - `(*$ ... *)` (StarParen block)
2. Preprocessing runs **before** tokenization (see 01-lexical). Source excluded by false conditionals is not tokenized.
3. A directive begins with `$` after the opener and ends at the comment closer.
4. The directive processor is case-insensitive and processes the source left-to-right with a **stack of conditional states**.

#### 1.1 Recognition inside inactive regions
- Inside an inactive region, only conditional delimiters (`$IF`, `$ELSEIF`, `$ELSE`, `$IFEND`/`$ENDIF`) are recognized to properly find matching ends; other directives are ignored there.

#### 1.2 Error handling
- Unmatched `$IF*` or missing `$IFEND/$ENDIF` is a **compile-time error**.
- `$ELSE` or `$ELSEIF` without an open `$IF*` is a **compile-time error**.
- Unknown directive names are **compile-time errors** unless documented as ignored/obsolete.

### 2. Conditional compilation

#### 2.1 Directives and pairing
- Block starters: `$IF <expr>`, `$IFDEF <symbol>`, `$IFNDEF <symbol>`, `$IFOPT <switches>`
- Middles: `$ELSEIF <expr>`, `$ELSE`
- Terminators: `$IFEND` (preferred) or `$ENDIF` (accepted when `{$LEGACYIFEND ON}`)
- Symbol control: `$DEFINE <symbol>`, `$UNDEF <symbol>`
- Mode: `{$LEGACYIFEND ON|OFF}` toggles acceptance of `$ENDIF` as a terminator for `$IF`.
- Boolean functions in $IF expressions include:
  - `Defined(SYMBOL)`
  - `Declared(IDENT)`
- Expression grammar (informative sketch):
  - Expressions may use `not`, `and`, `or`, `parentheses`, and the comparison operators `=, <>, <, >, <=, >=` over integer constants and symbols. 

#### 2.2 $IF expression grammar
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

#### 2.3 Nested Example

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


### 3. Non-conditional directives (catalog)

This list mirrors data/lexical.json

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
