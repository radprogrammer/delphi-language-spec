# Delphi Language Specification
## 03 Grammar — EBNF

### Status
Draft v0.1.0 — 2025-08-24  
Target: RAD Studio 12 Athens (Delphi)  
Scope: This chapter gives a **complete EBNF grammar** for Delphi source files (programs, libraries, packages, and units), declarations (types, variables, constants, resourcestrings), **classes/records/interfaces**, **generics** (types and methods), **procedural types** (including anonymous-method and method-pointer forms), **attributes**, **helpers**, **statements**, and **expressions** with precedence.  
Lexical rules (identifiers, literals, operators, comments, directives) are defined in **01‑lexical.md**; semantic rules appear in chapters 04–11.

> **Preprocessing layer.** Compiler directives (e.g., `{$IF}`, `{$DEFINE}`, `{$INCLUDE}`) are recognized **inside comments** and processed **before** tokenization (§02). Inactive regions removed by conditionals are **not** parsed.

---

### EBNF notation (legend)

We use a conventional EBNF close to ISO/IEC 14977:

```
A          := B | C         // choice
X?         := [ X ]         // optional
X*         := { X }         // zero or more
X+         := X { X }       // one or more
a..b       := range in set constructors (not an operator in expressions)
'KW'       := literal keyword token (case-insensitive)
ID         := identifier token (see 01-lexical)
INT, REAL  := numeric literal tokens (see 01-lexical)
STR        := StringConstant (01-lexical)
```

Terminals are in single quotes; nonterminals are CapitalizedIdentifiers. Punctuation and operators are terminals as in 01‑lexical.

---

### 1. Compilation units

```
SourceFile        := ProgramFile | LibraryFile | PackageFile | UnitFile ;

ProgramFile       := 'program' ProgHeading ';'
                     UsesClause?
                     Block '.' ;

LibraryFile       := 'library' ProgHeading ';'
                     UsesClause?
                     Block '.' ;

PackageFile       := 'package' ProgHeading ';'
                     RequiresClause? ContainsClause?
                     '.' ;

UnitFile          := 'unit' UnitId ';'
                     InterfaceSection
                     ImplementationSection
                     InitializationSection? '.' ;

ProgHeading       := QualifiedIdent ;
UnitId            := QualifiedIdent ;

RequiresClause    := 'requires' UnitRefList ';' ;
ContainsClause    := 'contains' UnitAliasList ';' ;

UnitRefList       := UnitRef { ',' UnitRef } ;
UnitAliasList     := UnitAlias { ',' UnitAlias } ;
UnitRef           := QualifiedIdent ;
UnitAlias         := QualifiedIdent 'in' STR?  // file path string optional
                   | QualifiedIdent ;          // pure name
```

---

### 2. Sections and blocks

```
InterfaceSection  := 'interface'
                     UsesClause?
                     InterfaceDecls* ;

ImplementationSection
                   := 'implementation'
                      UsesClause?
                      ImplementationDecls* ;

InitializationSection
                   := 'initialization' StatementList
                      ( 'finalization' StatementList )? ;

UsesClause         := 'uses' UsesList ';' ;
UsesList           := UsesItem { ',' UsesItem } ;
UsesItem           := QualifiedIdent ( 'in' STR )? ;

Block              := DeclarationPart* 'begin' StatementList 'end' ;
DeclarationPart    := ConstSection
                    | TypeSection
                    | VarSection
                    | ThreadVarSection
                    | ResourceStringSection
                    | RoutineDecl ;
InterfaceDecls     := DeclarationPart ;
ImplementationDecls:= DeclarationPart ;
```

---

### 3. Declarations (const, type, var, resourcestring, threadvar)

```
ConstSection      := 'const' ConstDecl+ ;
ConstDecl         := Attributes? ID (':' TypeRef)? '=' ConstExpr ';' ;

ResourceStringSection
                   := 'resourcestring' ResourceStringDecl+ ;
ResourceStringDecl := Attributes? ID '=' STR ';' ;

TypeSection       := 'type' TypeDecl+ ;
TypeDecl          := Attributes? ID '=' TypeDef ';' ;

VarSection        := 'var' VarDecl+ ;
ThreadVarSection  := 'threadvar' VarDecl+ ;

VarDecl           := Attributes? IdentList ':' TypeRef ( '=' ConstExpr )? ';' ;
IdentList         := ID { ',' ID } ;
```

---

### 4. Type definitions

```
TypeDef           := AliasType
                   | SubrangeType
                   | EnumType
                   | SetType
                   | ArrayType
                   | FileType
                   | RecordType
                   | ClassType
                   | InterfaceType
                   | PointerType
                   | ProcType
                   | HelperType ;

AliasType         := 'type'? TypeRef ;   // 'type' forces identity, see §04

SubrangeType      := ConstExpr '..' ConstExpr ;

EnumType          := '(' EnumList ')' ;
EnumList          := EnumItem { ',' EnumItem } ;
EnumItem          := ID ( '=' ConstExpr )? ;

SetType           := 'set' 'of' OrdinalType ;
OrdinalType       := TypeRef ; // must denote ordinal type

ArrayType         := 'array' ( '[' ArrayIndexList ']' )? 'of' TypeRef ;
ArrayIndexList    := ArrayIndex { ',' ArrayIndex } ;
ArrayIndex        := SubrangeType | TypeRef ; // static array; absent => dynamic array

FileType          := 'file' ('of' TypeRef)? ;

PointerType       := '^' TypeRef ;

ProcType          := 'procedure' ParamList? MethodSpec?
                   | 'function'  ParamList? ':' TypeRef MethodSpec?
                   | 'reference' 'to' ( 'procedure' ParamList?
                                        | 'function'  ParamList? ':' TypeRef ) ;

MethodSpec        := ('of' 'object')? ; // method pointer if present

HelperType        := ClassHelperType | RecordHelperType ;

ClassHelperType   := 'class' 'helper' 'for' TypeRef
                     ClassHelperBody 'end' ;

RecordHelperType  := 'record' 'helper' 'for' TypeRef
                     RecordHelperBody 'end' ;
```

**Notes**  
- `AliasType` with the `type` keyword (e.g., `type T = type U;`) preserves **identity** (§04).  
- `ArrayType` without brackets is a **dynamic array**; with brackets is **static**.  
- `reference to` denotes an **anonymous‑method** type; `of object` denotes a **method pointer** type.

---

### 5. Type references and generics

```
TypeRef           := QualifiedIdent GenericArgs? TypeSuffix* ;

QualifiedIdent    := ID { '.' ID } ;

GenericArgs       := '<' TypeArgList '>' ;
TypeArgList       := TypeRef { ',' TypeRef } ;

TypeSuffix        := '^'              // pointer deref in types like ^T
                   | 'class'          // class reference: class of T
                   | 'of' TypeRef     // class of T (combined form)
                   ;

TypeParamClause   := '<' TypeParamList '>' ;
TypeParamList     := TypeParam { ',' TypeParam } ;
TypeParam         := ID ( ':' TypeConstraints )? ;

TypeConstraints   := TypeConstraint { ',' TypeConstraint } ;
TypeConstraint    := 'constructor'
                   | 'class'
                   | 'record'
                   | TypeRef ;    // interface or specific class

GenericTypeDecl   := ID TypeParamClause ;   // used in ClassType, RecordType, etc.
```

**Disambiguation note.** The `<` following a **type identifier** begins `GenericArgs`; `<` in expressions is a relational operator. Parsing contexts (TypeRef vs Expression) resolve the ambiguity (§05).

---

### 6. Classes, records, interfaces

```
ClassType         := 'class' ClassHead? ClassBody 'end' ;
ClassHead         := ClassModifiers? AncestorList? ;
ClassModifiers    := ( 'sealed' | 'abstract' )+ ;
AncestorList      := '(' AncestorType { ',' InterfaceTypeRef } ')' ;
AncestorType      := TypeRef ;
InterfaceTypeRef  := TypeRef ;

ClassBody         := ClassMemberSection* ;
ClassMemberSection:= Visibility? ClassMemberList ;
Visibility        := 'strict' 'private'
                   | 'strict' 'protected'
                   | 'private'
                   | 'protected'
                   | 'public'
                   | 'published' ;

ClassMemberList   := { ClassMember } ;

ClassMember       := FieldDecl
                   | MethodDecl
                   | PropertyDecl
                   | ClassVarDecl
                   | NestedTypeDecl
                   | ConstDecl ;

ClassVarDecl      := 'class' 'var' VarDecl+ ;
NestedTypeDecl    := 'type' TypeDecl+ ;

RecordType        := 'record' RecordBody 'end' ;
RecordBody        := RecordFieldSection* VariantPart? ;
RecordFieldSection:= (FieldDecl | MethodDecl | PropertyDecl | NestedTypeDecl) ;

VariantPart       := 'case' (ID ':' TypeRef | TypeRef)? 'of'
                     VariantSelectorList ';'? ;

VariantSelectorList
                   := VariantSelector { ';' VariantSelector } ;
VariantSelector   := ConstExprList ':' '(' RecordFieldSection* ')' ;
ConstExprList     := ConstExpr { ',' ConstExpr } ;

InterfaceType     := 'interface' InterfaceHead? InterfaceBody 'end' ;
InterfaceHead     := '(' InterfaceTypeRefList ')' ;
InterfaceTypeRefList := InterfaceTypeRef { ',' InterfaceTypeRef } ;
InterfaceBody     := InterfaceMember* ;
InterfaceMember   := MethodHeading ';'  // no implementation
                   | PropertyDecl ;

FieldDecl         := Attributes? IdentList ':' TypeRef ('=' ConstExpr)? ';' ;
```

---

### 7. Methods and routines

```
RoutineDecl       := Attributes? RoutineHeading (';' Directive* ';')? RoutineBlock? ;

RoutineHeading    := 'procedure' RoutineName GenericParams? ParamList?
                   | 'function'  RoutineName GenericParams? ParamList? ':' TypeRef
                   | 'constructor' RoutineName ParamList?
                   | 'destructor'  RoutineName ParamList? ;

RoutineName       := QualifiedIdent ;

GenericParams     := TypeParamClause ;

ParamList         := '(' ParamGroup { ';' ParamGroup } ')' ;
ParamGroup        := ParamModifier? IdentList ':' TypeRef ( '=' ConstExpr )? ;
ParamModifier     := 'const' | 'var' | 'out' ;

Directive         := 'overload' | 'override' | 'virtual' | 'dynamic'
                   | 'reintroduce' | 'abstract' | 'final' | 'inline'
                   | 'deprecated' ( '(' STR ')' )?
                   | 'experimental'
                   | 'static'     // for class methods
                   | 'message' INT
                   | CallingConv
                   ;

CallingConv       := 'register' | 'cdecl' | 'pascal' | 'safecall'
                   | 'stdcall' | 'winapi' | 'inline' ;

RoutineBlock      := Block ;

MethodDecl        := ClassMethod? RoutineDecl ;
ClassMethod       := 'class' ;

MethodHeading     := (ClassMethod? 'procedure' ID GenericParams? ParamList?)
                   | (ClassMethod? 'function'  ID GenericParams? ParamList? ':' TypeRef)
                   | (ClassMethod? 'operator' OperatorId ParamList ':' TypeRef)
                   | (ClassMethod? 'operator' OperatorId ParamList) // procedures
                   | ('constructor' ID ParamList?)
                   | ('destructor'  ID ParamList?) ;

OperatorId        := 'Add' | 'Subtract' | 'Multiply' | 'Divide'
                   | 'IntDivide' | 'Modulus'
                   | 'BitwiseAnd' | 'BitwiseOr' | 'BitwiseXor'
                   | 'LeftShift' | 'RightShift'
                   | 'Positive' | 'Negative' | 'LogicalNot'
                   | 'Equal' | 'NotEqual' | 'LessThan' | 'LessThanOrEqual'
                   | 'GreaterThan' | 'GreaterThanOrEqual'
                   | 'Implicit' | 'Explicit'
                   | 'True' | 'False' ;
```

**Notes.**  
- Method headings inside **interfaces** are declarations only (no `RoutineBlock`).  
- `operator` methods are `class operator` in implementation; the `class` keyword is captured by `ClassMethod`.  
- Constructors and destructors cannot be generic (§05).

---

### 8. Properties

```
PropertyDecl      := Attributes? 'property' PropertyName PropertyIndex? ':' TypeRef
                     PropertySpecifiers ';' ;

PropertyName      := ID ;

PropertyIndex     := '[' PropertyParamList ']' ;
PropertyParamList := PropertyParam { ';' PropertyParam } ;
PropertyParam     := ('const')? IdentList ':' TypeRef ;

PropertySpecifiers:= ( 'read'  Accessor )
                     ( 'write' Accessor )?
                     ( 'stored' (ID | 'True' | 'False') )?
                     ( 'default' ConstExpr | 'nodefault' )?
                     ( 'implements' TypeRef (',' TypeRef)* )?
                     ( 'index' ConstExpr )?
                     ( 'dispID' ConstExpr )? ;

Accessor          := ID | QualifiedIdent ;  // method or field
```

---

### 9. Attributes (syntactic placement)

```
Attributes        := '[' AttrList ']' ;
AttrList          := Attribute { ',' Attribute } ;
Attribute         := AttrType AttrArgs? ;
AttrType          := QualifiedIdent ; // 'Attribute' suffix may be omitted
AttrArgs          := '(' AttrArgList? ')' ;
AttrArgList       := ConstExpr { ',' ConstExpr } ;
```

Attributes may precede **type, routine, field, property, parameter** declarations. Variable‑level attributes have effect only if compiler‑recognized (§09).

---

### 10. Statements

```
StatementList     := { Statement ';'? } ;

Statement         := LabeledStatement
                   | SimpleStatement
                   | StructuredStatement
                   | Empty ;

LabeledStatement  := LabelId ':' Statement ;
LabelId           := INT | ID ;

Empty             := /* nothing */ ;

SimpleStatement   := AssignOrCall
                   | 'inherited' ( QualifiedIdent? ActualParams? )?
                   | 'goto' LabelId ;

AssignOrCall      := Designator ':=' Expression
                   | Designator ActualParams? ;

Designator        := QualIdOrPrimary Selector* ;

QualIdOrPrimary   := QualifiedIdent | Primary ;

Selector          := '.' ID
                   | '[' ArgList ']'
                   | '^' ;

ActualParams      := '(' ArgList? ')' ;
ArgList           := Arg { ',' Arg } ;
Arg               := Expression | ID ':' Expression ;

StructuredStatement
                   := CompoundStmt
                    | ConditionalStmt
                    | CaseStmt
                    | WhileStmt
                    | RepeatStmt
                    | ForStmt
                    | ForInStmt
                    | WithStmt
                    | TryStmt
                    | RaiseStmt ;

CompoundStmt      := 'begin' StatementList 'end' ;

ConditionalStmt   := 'if' Expression 'then' Statement ('else' Statement)? ;

CaseStmt          := 'case' Expression 'of' CaseSelectorList CaseElse? 'end' ;
CaseSelectorList  := CaseSelector { ';' CaseSelector } ;
CaseSelector      := ConstExprList ':' Statement ;
CaseElse          := ';' 'else' Statement ;

WhileStmt         := 'while' Expression 'do' Statement ;
RepeatStmt        := 'repeat' StatementList 'until' Expression ;

ForStmt           := 'for' Designator ':=' Expression ('to' | 'downto') Expression 'do' Statement ;

ForInStmt         := 'for' ('var' ID ':' TypeRef 'in' Expression
                      | ID 'in' Expression) 'do' Statement ;

WithStmt          := 'with' ExprList 'do' Statement ;
ExprList          := Expression { ',' Expression } ;

TryStmt           := 'try' StatementList ( ExceptPart | FinallyPart ) 'end' ;
ExceptPart        := 'except' HandlerList 'end' ;
HandlerList       := ( Handler ';' )* ( 'else' StatementList )? ;
Handler           := 'on' (ID ':')? TypeRef 'do' StatementList ;
FinallyPart       := 'finally' StatementList 'end' ;

RaiseStmt         := 'raise' ( Expression ( 'at' Expression )? )? ;
```

---

### 11. Expressions (precedence form)

We present expressions by precedence (highest first). Parenthesized expressions and primary forms appear at the bottom.

```
Expression        := OrElseExpr ;

OrElseExpr        := AndAlsoExpr { 'or' AndAlsoExpr } ;
AndAlsoExpr       := NotExpr     { 'and' NotExpr } ;
NotExpr           := [ 'not' ] XorExpr ;
XorExpr           := RelExpr     { 'xor' RelExpr } ;

RelExpr           := AddExpr ( RelOp AddExpr )? ;
RelOp             := '=' | '<>' | '<' | '>' | '<=' | '>=' | 'in' | 'is' | 'as' ;

AddExpr           := MulExpr { AddOp MulExpr } ;
AddOp             := '+' | '-' | 'or' | 'xor' ;

MulExpr           := UnaryExpr { MulOp UnaryExpr } ;
MulOp             := '*' | '/' | 'div' | 'mod' | 'and' | 'shl' | 'shr' ;

UnaryExpr         := [ '+' | '-' | 'not' | '@' | '^' ] Primary ;

Primary           := Literal
                   | 'nil'
                   | SetConstructor
                   | '(' Expression ')'
                   | QualifiedIdent GenericArgs? Selector*
                   | AnonymousMethod ;

Selector          := '.' ID
                   | '[' ArgList ']'
                   | '^'
                   | '(' ArgList? ')' ;   // call

Literal           := INT | REAL | STR | CharCode | 'True' | 'False' ;

SetConstructor    := '[' SetElemList? ']' ;
SetElemList       := SetElem { ',' SetElem } ;
SetElem           := Expression ( '..' Expression )? ;

AnonymousMethod   := 'function' ParamList? ( ':' TypeRef )? '=>' Statement
                   | 'procedure' ParamList? '=>' Statement ;
```

**Notes.**  
- `QualifiedIdent GenericArgs?` allows `TypeName<T>` in **type** or **constructor** contexts; in pure **expression** contexts, the parser must ensure this form is only accepted where a **type** is expected (§05).  
- `@` and `^` appear here in unary form; `^` is also used in selectors to dereference after a primary.  
- `is`/`as` are included in `RelOp` per Delphi’s precedence.

---

### 12. Constant expressions

```
ConstExpr         := ConstRelExpr ;

ConstRelExpr      := ConstAddExpr ( RelOp ConstAddExpr )? ;
ConstAddExpr      := ConstMulExpr { AddOp ConstMulExpr } ;
ConstMulExpr      := ConstUnaryExpr { MulOp ConstUnaryExpr } ;
ConstUnaryExpr    := [ '+' | '-' | 'not' ] ConstPrimary ;
ConstPrimary      := Literal
                   | 'nil'
                   | '(' ConstExpr ')'
                   | QualifiedIdent           // consts, enum items
                   | 'TypeInfo' '(' TypeRef ')' ;
```

Only a subset is valid based on context (case labels, set bounds, etc., see §04/§08).

---

### 13. Packages: `requires` and `contains` (syntactic)

Already covered in §1; semantics (design/package system) are out of scope for the grammar.

---

### 14. Helpers (syntactic)

Helpers are declared via **HelperType** in §4. The bodies use the same **ClassMemberSection** / **RecordFieldSection** forms as classes/records, except that helpers cannot declare instance fields (enforced semantically).

---

### 15. Generics (summary of placements)

- **Type parameter clauses** are allowed on: `class`, `record`, `interface`, **procedural types** (by wrapping in a generic type), and **methods** (`procedure`/`function` headings).  
- **Type argument lists** (`<...>`) are allowed after **type identifiers** in **type/constructor** contexts and after **class identifiers** when denoting nested types (`TFoo<Integer>.TBar`). Disambiguation from `<`/`>` relational operators is per syntactic context (§05).

---

### 16. Lexical tokens (reference)

Terminals such as `'+'`, `'..'`, `'('`, `')'`, `'['`, `']'`, `','`, `';'`, `':'`, `':='`, `'@'`, `'^'`, relational operators, and keywords are defined in **01‑lexical.md**. The **longest‑match** rule applies (§01 §5.1/5.3).

---

### 17. Conformance notes

- The grammar aims to be **LALR(1)** friendly. A production split across **type vs expression** contexts avoids the classic `< >` ambiguity for generics.  
- Some restrictions (e.g., what qualifies as an **ordinal** type, property specifier restrictions, helper limitations, operator availability) are **semantic** and enforced in chapters 04–11.  
- Compiler directives in comments may elide whole subtrees before parsing; ensure your preprocessor honors §02.

