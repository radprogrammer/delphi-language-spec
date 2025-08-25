# Delphi Language Specification
## 07 Semantics — Expressions

### Status
Draft v0.1.0 — 2025-08-24  
Target: RAD Studio 12 Athens (Delphi)  
Scope: This chapter defines the **semantics of expressions**: constant expressions, typing and conversions, operator precedence/associativity, arithmetic and boolean rules (including short‑circuit and `{$BOOLEVAL)`, comparisons, strings and sets, pointers and references, casts (`as`, `is`, and hard casts), `in`/membership, variant semantics, and overload resolution notes. Grammar appears in 03-grammar-ebnf; this chapter is **semantic** unless stated otherwise.

---

### 1. Expressions and types

1. Every expression has a **static type** known at compile time (§04). Operators select a result type based on operand types and operator rules in this chapter.
2. **Constant expressions** are those evaluable at compile time (literals; pure arithmetic on literals; set/array constructors with constant elements; address of constants where allowed; `ord/succ/pred/low/high/length` when their arguments are constant). A constant expression used in a **typed constant**, **case label**, **set bound**, etc., must be **range‑checkable** at compile time.
3. **Side effects** in expressions occur only via function calls, dereferences/assignments in called code, and variant/property/indexer evaluation. Pure operators on value types are side‑effect free.

---

### 2. Operator precedence and associativity

Operators bind from **strongest** (top) to **weakest** (bottom). All binary operators are **left‑associative** unless noted.

```
Primary:         X.Y   X[Y]   X^   F(...)   T(X)   (X)   inherited   @X
Unary:           not   @   ^   +   -
Multiplicative:  *   /   div   mod   and   shl   shr
Additive:        +   -   or   xor
Relational:      =   <>   <   >   <=   >=   in   is
Typecast-like:   as
String concat:   +
```

Notes
- `@` (address‑of) and `^` (dereference) are also used in primary/unary positions (see §8).
- `as` binds more weakly than relational operators; parenthesize to force a cast before comparison if needed.
- Set constructor ranges use `..` inside `[...]`; `..` is **not** an expression operator (see 01‑lexical §5.3).

---

### 3. Arithmetic and numeric conversions

#### 3.1 Integer arithmetic
- The result type of `+`, `-`, `*` over two integers is at least as wide as the **wider** operand, with usual integer promotions (e.g., `SmallInt + Integer → Integer`).  
- `div` is integer division with truncation toward zero; `mod` is remainder with the sign of the **left** operand.  
- Overflow on `+`, `-`, `*`, `succ/pred`, `inc/dec` is a **run‑time error** when `{$Q+}` (overflow checks on) and **wraparound** when `Q-` (implementation‑defined two’s complement behavior).

#### 3.2 Real arithmetic
- `/` is **real division**; if both operands are integer, they are promoted to a real type.  
- Real arithmetic is performed in the platform’s floating‑point format; intermediate precision may exceed the nominal destination (see `{$EXCESSPRECISION}` in §02).

#### 3.3 Mixed integer/real
- If either operand is real (or `/` is used), the other is **converted** to real; the result is real.

#### 3.4 `Currency` and `Comp`
- `Currency` participates in `+`, `-`, `*`, `/` with scale‑aware rounding; mixing with real types converts the real to `Currency` where a `Currency` operand is present.  
- `Comp` behaves as a 64‑bit integer in arithmetic; prefer `Int64` for new code.

---

### 4. Boolean expressions

1. Boolean operators on `Boolean` are `not`, `and`, `or`, `xor`.  
2. **Short‑circuit vs complete evaluation** is controlled by `{$BOOLEVAL}`:
   - `B-` (OFF, default): **short‑circuit** — for `A and B`, `B` is evaluated only if `A` is True; for `A or B`, only if `A` is False.  
   - `B+` (ON): **complete** — both operands are always evaluated.
3. When applied to **integer** operands, `and`, `or`, `xor`, `not` perform **bitwise** operations; there is no short‑circuit on integer operands.
4. Shift operators `shl` and `shr` shift the left operand by a non‑negative integer count; shifts greater than or equal to the bit‑width yield 0 for `shr` and implementation‑defined wrap/zero for `shl`.

*Informative.* Use parentheses to avoid surprises when mixing boolean and bitwise intent with overloaded operators.

---

### 5. Comparisons and ordering

1. **Relational operators**: `=`, `<>`, `<`, `>`, `<=`, `>=`.  
2. **Numeric**: apply to integer/real types; mixed numeric operands compare after numeric promotion.  
3. **Characters and strings**:  
   - `Char` compares by code unit value.  
   - `string`/`UnicodeString` and `AnsiString` compare **lexicographically** by code units under their internal encoding; cross‑family comparisons convert as needed (may lose data).  
4. **Sets**: `=`/`<>` test equality; `<`, `>`, `<=`, `>=` are **subset/superset** comparisons.  
5. **Pointers and class references**: comparable with `=`, `<>` and ordering comparisons; ordering has no semantic meaning other than address relation.  
6. **Variants**: comparisons are performed by variant rules (§11).

---

### 6. Strings and characters

1. **Concatenation** uses `+`; mixing character and string converts the character to a 1‑length string.  
2. **Indexing** and **length** semantics are defined in §04 (code‑unit based; `{$ZEROBASEDSTRINGS}` may affect indexing base).  
3. **Conversion rules**: assigning between Unicode and Ansi strings performs conversion; conversions that cannot represent a character in the target encoding result in data loss.
4. **Appending numbers**: numeric → string conversions follow standard formatting when passed to `+` with a string operand (via implicit RTL helpers); prefer explicit conversions for clarity.

*Informative.* A `nil` `UnicodeString` behaves as empty in most operations; prefer explicit empty (`''`) for clarity.

---

### 7. Sets and membership

1. A set has type `set of TBase` (see §04).  
2. **Constructors**: `[a, b, c]` builds a set; ranges `[lo..hi]` are allowed with ordinal bounds.  
3. **Operators**: `+` union, `-` difference, `*` intersection. Membership `x in S` yields `Boolean`.  
4. The base type of operands in set operators must be **compatible** (same base or subrange of the same base).  
5. With {`$R+}` (range checks), adding an element outside the base range is a run‑time error.

---

### 8. Pointers, addresses, and dereference

1. `@X` yields the **address** of `X`. For variables/fields this is a pointer to storage; for routines, a **procedure pointer** (or method pointer when applied to an instance method).  
2. `^` dereferences a pointer: `P^` yields the value of the referenced object.  
3. Pointer **arithmetic** is not defined; you may compare pointers and compute differences only through APIs that expose them (not in the language proper).  
4. `nil` is a valid pointer/class/interface/method‑pointer value; comparing with `nil` is well‑defined for these categories.
5. `Assigned(X)` is meaningful for **pointers, procedure/method pointers, class references, and interfaces**. Use `Length(A) > 0` to test dynamic arrays, and `S <> ''` to test strings.

---

### 9. Casting and type tests

#### 9.1 Hard casts (static/unchecked)
- Syntax `T(Expr)` **reinterprets** or converts `Expr` to type `T` according to assignment‑compatibility and context. The compiler may allow **unchecked** reinterpretation (e.g., between unrelated pointers) — use with care.

#### 9.2 `as` (checked downcast)
- `Expr as TClass` evaluates `Expr` (a class‑type reference or interface) and attempts to **downcast** to `TClass`. On failure, raises a run‑time cast error.  
- `as` has **lower precedence** than relational operators (see §2). Parenthesize if combined with comparisons.

#### 9.3 `is` (type test)
- `Expr is TClass` yields `True` if `Expr` is an instance of `TClass` or its descendant; otherwise `False`. For interfaces, `is` tests support for the interface type.

*Informative.* Prefer `as` followed by a nil/try pattern for class casts when exceptions are acceptable; use `is` to guard before hard casts when you want to avoid exceptions.

---

### 10. Procedural values and anonymous methods

1. **Procedure/function pointers** are first‑class values; comparing them with `nil` is defined; equality compares code addresses (and, for method pointers, both code and instance).  
2. **Anonymous methods** (`reference to ...`) are managed closures; assignment copies references; equality compares by identity (implementation‑defined; do not rely on ordering). Captured variables follow the lifetime rules of managed types (§11).

---

### 11. Variants

1. If **either operand** of an operator is a `Variant`, the other is **promoted** to `Variant` and the operation is performed by **variant dispatch**.  
2. Supported operations include arithmetic, comparisons, string concatenation, and element access for **variant arrays**. Unsupported operations raise run‑time errors.  
3. `OleVariant` restricts the set of representable values to OLE Automation compatible types; mixed operations with non‑Automation types raise errors.

*Informative.* Prefer static types for performance and compile‑time checking; use variants at API boundaries that require them.

---

### 12. Overload resolution (expressions)

1. **Candidate set**: For an overloaded name, gather all overloads visible at the call site whose **arity** matches and whose parameter types are **potentially compatible** after considering default parameters and parameter modifiers (`var`, `out`, `const`, `constref`).  
2. **Best match**: Choose the overload requiring the **fewest and safest** implicit conversions. **Identity** beats **widening**; **widening** beats **narrowing**; **integer→real** beats other multi‑step promotions.  
3. **Ambiguity**: If two candidates are indistinguishable, the call is **ambiguous** and a compile‑time error. Supplying explicit typecasts or argument type suffixes (for generics) may disambiguate.  
4. **Generic vs non‑generic**: When otherwise indistinguishable, a **non‑generic** overload is preferred over a generic one (see §05).  
5. **Parameter modifiers** are part of the signature; an overload with `var` is not a candidate for a non‑`var` argument, etc.

*Informative.* Overloading interacts with `string` vs `AnsiString` and with `UnicodeString` conversions; explicit casts to the intended type avoid surprises.

---

### 13. Property accessors, indexers, and side effects

1. `Obj.Prop` invokes the **read accessor** (method or field access) to produce a value expression. `Obj.Prop := V` invokes the **write accessor**.  
2. **Indexed properties** evaluate index expressions left‑to‑right, then call the accessor(s).  
3. A property is **not** a variable; you cannot pass `Obj.Prop` to a `var` parameter or take `@Obj.Prop`.

---

### 14. Order of evaluation

1. In the absence of `{$BOOLEVAL ON}`, the **short‑circuit** rules define whether the right‑hand operand is evaluated for `and`/`or`.  
2. For all other binary operators and for function argument lists, evaluation order is **left‑to‑right**.  
3. The compiler may reorder **pure** subexpressions when it can prove there are no side effects; however, function calls and property/indexer access are sequenced left‑to‑right.

*Informative.* Avoid relying on incidental evaluation timing; prefer explicit temporaries if a function has side effects.

---

### 15. Exceptions arising from expressions

Expressions may raise run‑time exceptions, including:
- Overflow (`EIntOverflow`) with `{$Q+}`.
- Range error (`ERangeError`) with `{$R+}`.  
- Division by zero (`EDivByZero`) for integer/real operations.  
- Invalid cast (`EInvalidCast`) for `as` failures or unsafe casts at run time.  
- Variant operation errors (`EVariantError`).  
- Null dereference/access violations for invalid pointers.

---

### 16. Examples

```pascal
// Precedence and casts
if (Obj as TButton).Caption = 'OK' then ...;

// Short-circuit
if (P <> nil) and (P^.Next <> nil) then ...;

// Sets
type TDigits = 0..9;
var S, T: set of TDigits;
S := [1,3,5] + [7] - [3];
if 7 in S then ...;
if S <= [1,7,9] then ...;

// Strings and numbers
Writeln('Count = ' + IntToStr(N));

// Overload disambiguation
procedure F(X: Double); overload;
procedure F(X: Integer); overload;
F(1);      // Integer overload
F(1.0);    // Double overload
F(Ord(True)); // force Integer
```
