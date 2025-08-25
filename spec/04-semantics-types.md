[![Status: Draft](https://img.shields.io/badge/Status-Draft-orange.svg)](./04-semantics-types.md#status)

# Delphi Language Specification 

## 04 Type System and Semantics

*Status*: Draft v0.1.0 — 2025-08-24  
*Target*: RAD Studio 12 Athens (Delphi)  
*Scope*: This chapter defines the **types** of Delphi and their **semantic** properties: identity vs. compatibility, value ranges, representation notes, operations and promotion rules, and platform‑dependent behaviors. Detailed grammar appears in §03; class/interface/generics semantics are expanded in §§06–07. Managed type lifetimes are in §11.

---

### 1. Overview of the type system

1. **Categories.** Types are grouped as follows:
   - **Simple**: ordinal (integer, character, Boolean, enumerated, subrange), real (floating‑point), `Currency`, `Comp`.
   - **Strings**: `UnicodeString` (`string`), `AnsiString` (including code‑paged variants such as `UTF8String`, `RawByteString`), `ShortString`, `WideString`.
   - **Structured**: sets, arrays (static & dynamic), records (traditional, variant, advanced), files.
   - **Pointer and reference**: typed pointers `^T`, untyped `Pointer`, PChar family.
   - **Procedural**: procedure/function pointers, **method pointers** (`of object`), **method references** (`reference to` for anonymous methods).
   - **Class, class‑reference, interface** (see §§06,09).
   - **Variant** and `OleVariant`.
2. **Static typing.** Every expression has a **static type** known at compile time; implicit conversions are permitted only where **assignment‑compatibility** or **operator‑specific promotions** allow it (§2).
3. **Platform dependence.** Some predefined types have **target‑dependent size/format** (e.g., `NativeInt`, `Extended`, pointers). Where relevant, both Win32 and Win64 behavior are stated (§3.3, §3.5).  
4. **Managed types.** `UnicodeString`, `AnsiString` family, dynamic arrays, interfaces, and `Variant`/`OleVariant` are reference‑counted and participate in automatic initialization/finalization. Their detailed lifetime rules are in §11.

---

### 2. Type identity and compatibility

#### 2.1 Identity (nominal typing)

- Two type identifiers denote the **same type** if one is declared directly as the other without the `type` keyword repetition (alias):  
  ```pascal
  type T1 = Integer; T2 = T1;  // T1, T2, and Integer are identical
  ```
- Repeating `type` creates a **distinct** type with its own identity:  
  ```pascal
  type TMyInt = type Integer; // distinct from Integer
  ```
- Each occurrence of a type constructor (e.g., `set of Char`, `string[10]`) denotes a **fresh type**. Declaring two variables with separate `string[10]` constructions yields **different** types; use a named type to share identity.

#### 2.2 Assignment‑compatibility summary

An expression of type `T2` is assignable to a variable of type `T1` if the value fits the destination range and one of these holds (selected highlights; see §03 for grammar and §07 for expression‑specific promotions):

- Both are **real types**; or both **integer types** (with range check at run time if enabled).  
- One is a **subrange** of the other, or both are subranges of the same base.  
- Both are **set types** with compatible base types.  
- One is **string** and the other is **string, packed‑string (short string), or `Char`**.  
- PChar compatibility: `PAnsiChar`/`PWideChar` with zero‑based character arrays (`array[0..n] of AnsiChar/WideChar`).  
- `Variant` with integer/real/string/character/Boolean; `OleVariant` is limited to Automation‑compatible types.  
- Pointers: `Pointer` is compatible with any pointer; typed pointers require `{$T+}` for assignment between equal pointed‑to types.

*Informative.* Identity implies assignment‑compatibility; the converse is not generally true.

---

### 3. Simple and ordinal types

#### 3.1 Integer family

- **Signed**: `ShortInt` (8b), `SmallInt` (16b), `Integer` (32b), `Int64` (64b), `NativeInt` (target pointer size).
- **Unsigned**: `Byte` (8b), `Word` (16b), `Cardinal` (32b), `UInt64` (64b), `NativeUInt` (target pointer size).
- `Integer = LongInt` (32b). `LongWord = Cardinal` (32b).  
- `NativeInt/NativeUInt` are 32‑bit on Win32, 64‑bit on Win64.  
- Arithmetic on mixed integer sizes follows usual integer promotions; overflow behavior is subject to `{$Q+/-}` overflow checks.

#### 3.2 Boolean family

- `Boolean` (1 byte) uses logical **True/False** with compiler‑generated 0/1 values.
- `ByteBool` (1 byte), `WordBool` (2 bytes), `LongBool` (4 bytes) are provided for OS/COM interop; any **non‑zero** value is True, zero is False. Prefer `Boolean` for pure Delphi code.

#### 3.3 Character types

- Since Delphi 2009+, `Char = WideChar` (UTF‑16 *code unit*). `AnsiChar` is 8‑bit. 
- `PChar = PWideChar`; `PAnsiChar` refers to 8‑bit (code‑paged) char sequences. Indexing a `UnicodeString` exposes **code units**; surrogate pairs count as two code units (see §4.2).

#### 3.4 Enumerated and subrange types

- Enumerations define ordered sets; first element has ordinality 0 unless overridden.  
- Subranges `L..H` constrain an ordinal base type; assignment must satisfy range.  

#### 3.5 Real types, `Currency`, `Comp`

- **Floating‑point**: `Single` (32b), `Double` (64b), `Extended` (80‑bit on Win32; 64‑bit on Win64 where it aliases `Double`), `Real` (aliases `Double` by default; with `{$REALCOMPATIBILITY ON}` it maps to legacy `Real48`).  
- **`Currency`** is a 64‑bit scaled integer with four decimal places; decimal arithmetic suitable for money.  
- **`Comp`** is a signed 64‑bit integer (legacy); prefer `Int64` unless binary‑compatibility is required.  
- Floating‑point intermediate precision is platform/setting dependent (e.g., implicit Extended on x86; `{$EXCESSPRECISION}` affects x64).

---

### 4. String types

#### 4.1 Kinds and defaults

- `string` is an alias for `UnicodeString` (UTF‑16 reference‑counted).  
- `AnsiString` is reference‑counted byte string; it may carry a **code page** (e.g., `UTF8String` is an `AnsiString` with UTF‑8 code page; `RawByteString` is code‑page‑agnostic and intended for by‑value parameters).  
- `WideString` (COM **BSTR**) is unmanaged and primarily for COM interop; prefer `UnicodeString` elsewhere.  
- `ShortString` (0..255) is legacy; length is stored in `S[0]`.

#### 4.2 Indexing and element type

- `UnicodeString`/`AnsiString` indexing is **1‑based** by default. The local directive `{$ZEROBASEDSTRINGS ON|OFF}` controls the **index base** within its scope (default **OFF** ⇒ 1‑based). `ShortString` is always 1‑based for content (`S[0]` stores length).  
- Indexing returns a **code unit**: `Char` for `UnicodeString` (UTF‑16 unit), `AnsiChar` for `AnsiString`. Characters outside the BMP occupy two `Char` values (a surrogate pair).  
- Length/SetLength operate on **code units**, not Unicode scalar values.

#### 4.3 Conversions and interop

- Assignments between `UnicodeString` and `AnsiString` perform necessary conversions; down‑conversion may lose data.  
- `PChar`/`PWideChar` interoperate with null‑terminated arrays; casting a string to a pointer yields a pointer that remains valid until the string is modified or goes out of scope (copy‑on‑write applies).  
- Mixing `string` and `PChar` in expressions converts the `PChar` operand to `UnicodeString`.

*Informative.* Use `RawByteString` only for by‑value parameters to *preserve* an incoming code page without conversion.

---

### 5. Sets

1. A set is `set of BaseType` where `BaseType` is an ordinal type whose **cardinality ≤ 256** and whose ordinal values lie in **0..255** (commonly a subrange).  
2. The empty set is `[]`. Set constructors use brackets: `[a, b, c]`.  
3. Operators on sets (defined only for sets of **compatible** base type):  
   - `+` union, `*` intersection, `-` difference, `<=` subset, `>=` superset, `=` equality, `<>` inequality.  
   - Membership: `x in S` for element `x`.  
   - Intrinsics `Include(S, x)` and `Exclude(S, x)` are equivalent to `S := S + [x]` and `S := S - [x]`, but may generate better code.  
4. Sets of `WideChar` are reduced to byte char in set expressions; use subrange/`AnsiChar` where appropriate.

---

### 6. Arrays

#### 6.1 Static arrays

- `array[indexType1, …, indexTypeN] of T` with ordinal index types (each range ≤ 2GB). `Low(A)`/`High(A)` return the first dimension bounds; `Length(A)` returns the first dimension length.

#### 6.2 Dynamic arrays (managed)

- Declared `array of T`; use `SetLength` to allocate/resize.  
- **Always zero‑based**: indices run from `0` to `Length(A)-1`.  
- Reference‑counted; assignment is O(1) (copy reference), copy‑on‑write on mutation.

#### 6.3 Array constants

- For dynamic arrays, `[e1, e2, …]` constructs a new array; for other arrays, the same syntax denotes a **set** unless explicitly typed.

---

### 7. Records

- Traditional records are value types; copied on assignment.  
- Variant records provide a `case` section with overlapping variants; tag field (if present) is not enforced by the compiler.  
- `packed` affects alignment/layout; prefer default alignment for performance/ABI compatibility. Advanced/custom managed records are covered in §11.

---

### 8. Pointer and reference types

- `^T` is a typed pointer; `Pointer` is untyped. Pointer size equals the **native pointer size** (4 bytes Win32, 8 bytes Win64).  
- `@X` yields the address. With `{$T+}` type‑checked pointers, `@X` is of type `^T` (where `T` is `TypeOf(X)`); otherwise it is `Pointer`. `@Proc` is always `Pointer`.  
- Dereference with `P^`. Take care with alignment and lifetime of referenced data.

---

### 9. Procedural types

Delphi distinguishes three families (not mutually assignment‑compatible unless explicitly stated by the language version; events use method pointers):

1. **Procedure/function pointers** (standalone routines):  
   `type TProc = procedure(X: Integer);`
2. **Method pointers** (instance methods) — carry both code *and* instance pointer:  
   `type TNotify = procedure(Sender: TObject) of object;`
3. **Method references** (anonymous methods) — managed closures capturing context:  
   `type TThunk = reference to function(X: Integer): Integer;`

Calling conventions and parameter modifiers (`var`, `out`, `const`, `constref`) are part of the type and must match for assignment compatibility.

*Informative.* Anonymous method types are distinct from method pointers and plain procedure types; use the correct form required by an API (e.g., events typically require `of object`).

---

### 10. Variant types

- `Variant` holds values whose *runtime* type can change, supporting arithmetic, comparisons, strings, arrays, etc.  
- `OleVariant` is restricted to **OLE Automation** compatible types (e.g., `WideString`, numeric types) for cross‑process/COM interop.  
- Operations on variants incur runtime dispatch and may raise runtime errors for invalid operations. Prefer static types where possible.

---

### 11. Promotions, conversions, and operators — **Normative summary**

- **Integer ↔ real.** In mixed arithmetic, integers are promoted to real where a real operator is selected; `/` is real division, `div` integer division, `mod` remainder.  
- **Char/string.** `'A'` is assignment‑compatible with `string`/`ShortString`/`AnsiString`/`UnicodeString`; concatenation `+` follows string semantics.  
- **Set operators** only defined for sets of compatible base type (§5).  
- **Pointer arithmetic** is not defined (no `+`/`-` on typed pointers except comparisons).  
- Over/underflow and range checks are controlled by `{$Q}` and `{$R}` switches respectively.

---

### 12. Platform‑dependent notes

- **Pointer size** and `NativeInt/NativeUInt` size track the target (32 vs 64 bit).  
- **`Extended`** is 80‑bit on Win32; **64‑bit (alias of `Double`) on Win64**. For portable persistence, prefer `Double` or serialize `TExtended80Rec`.  
- **Procedure of object** layout differs between 32/64‑bit (alignment/size differences); use it opaquely.

---

### 13. Examples

#### 13.1 Identity vs aliasing

```pascal
type
  T1 = Integer;
  T2 = T1;           // same identity as Integer
  TId = type Integer; // distinct type
var
  X: Integer;
  A: T1;
  B: TId;
begin
  A := X;   // OK
  // B := X; // Error without explicit cast; distinct identity
end;
```

#### 13.2 Sets and operators

```pascal
type TDigits = 0..9;
var
  S, T: set of TDigits;
begin
  S := [1,3,5];          // constructor
  Include(S, 7);         // S := S + [7]
  T := [0,2,4,6,8];
  if 3 in S then …;
  S := S * T;            // intersection → [ ]
end;
```

#### 13.3 Dynamic arrays and strings

```pascal
var
  A: array of Integer;
  S: string;
begin
  SetLength(A, 3);       // A[0..2]
  A := [10, 20, 30];     // array constant
  S := 'Hi';
  {$ZEROBASEDSTRINGS OFF} // default
  S[1] := 'h';
end;
```

