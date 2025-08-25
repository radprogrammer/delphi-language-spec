# Delphi Language Specification
## 10 Semantics — Operator Resolution

### Status
Draft v0.1.0 — 2025-08-24  
Target: RAD Studio 12 Athens (Delphi)  
Scope: This chapter specifies **how operators are resolved** in Delphi: the set of built‑in operators, user‑defined operator overloads on records/classes, implicit/explicit conversions, truthiness (`True`/`False`) operators, precedence with built‑ins (strings, sets, variants), and the **candidate/selection** process. Grammar appears in §03; basic operator meanings are in §07 (Expressions).

---

### 1. Operator kinds (inventory)

Delphi recognizes the following **operator tokens** (see §01/§07 for lexical and precedence). Some are overloadable on user types (records/classes via `class operator`), as indicated.

**Unary**
- `+` (unary plus) — *overloadable*
- `-` (unary minus) — *overloadable*
- `not` (logical/bitwise not) — *overloadable*

**Binary arithmetic/bitwise**
- `+` (addition / string concatenation) — *overloadable* (addition only; concatenation is built‑in)
- `-` (subtraction) — *overloadable*
- `*` (multiplication) — *overloadable*
- `/` (real division) — *overloadable*
- `div` (integer division) — *overloadable*
- `mod` (remainder) — *overloadable*
- `and` (bitwise/boolean and) — *overloadable*
- `or` (bitwise/boolean or) — *overloadable*
- `xor` (bitwise/boolean xor) — *overloadable*
- `shl` (left shift) — *overloadable*
- `shr` (right shift) — *overloadable*

**Relational**
- `=` `<>` `<` `<=` `>` `>=` — *overloadable*

**Other**
- `in` (membership) — **not overloadable**
- `is` (type test) — **not overloadable**
- `as` (checked cast) — **not overloadable**

**Conversion pseudo‑operators** (declared with `class operator` on a type)
- `Implicit` — defines **implicit** conversion *to or from* the declaring type — *overloadable*
- `Explicit` — defines **explicit** conversion *to or from* the declaring type — *overloadable*

**Truthiness**
- `True`, `False` — define evaluation in **Boolean contexts** (e.g., `if X then`) — *overloadable*

> *Informative.* Operator overloads are declared as **`class operator <Name>`** methods inside a record or class. Helpers cannot introduce operators (§09).

---

### 2. Declaring operator overloads

1. **Where.** Only **records and classes** may declare operators. Declarations occur inside the type body as `class operator` methods.  
2. **Arity and signatures.**
   - **Unary**: `class operator Negative(const A: T): T;` (names shown below).  
   - **Binary**: `class operator Add(const A, B: T): T;` or with mixed types: `class operator Add(const A: T; B: U): T;` (at least one operand must be the declaring type).  
   - **Relational**: result type is **Boolean**.  
   - **Conversions**: `class operator Implicit(const A: U): T;` or `class operator Explicit(const A: T): U;`.  
3. **Static binding.** Operators are **static** (`class operator` methods). They are not virtual and do not participate in dynamic dispatch.  
4. **Symmetry.** For commutative intent (`+`, `*`, `and`, `or`, `xor`), provide **both operand orderings** if you expect mixed operand types; the compiler does not auto‑swap or auto‑convert operands unless an implicit conversion makes a built‑in or other overload applicable.  
5. **Purity.** Operator bodies may have side effects, but treat them as **pure** for predictability.

---

### 3. Operator identifier names

The `class operator` **name** encodes which token it implements. The mapping is:

| Token                     | Identifier name            |
|--------------------------|----------------------------|
| `+` (binary)             | `Add`                      |
| `-` (binary)             | `Subtract`                 |
| `*`                      | `Multiply`                 |
| `/`                      | `Divide`                   |
| `div`                    | `IntDivide`                |
| `mod`                    | `Modulus`                  |
| `and`                    | `BitwiseAnd`               |
| `or`                     | `BitwiseOr`                |
| `xor`                    | `BitwiseXor`               |
| `shl`                    | `LeftShift`                |
| `shr`                    | `RightShift`               |
| `+` (unary)              | `Positive`                 |
| `-` (unary)              | `Negative`                 |
| `not`                    | `LogicalNot`               |
| `=`                      | `Equal`                    |
| `<>`                     | `NotEqual`                 |
| `<`                      | `LessThan`                 |
| `<=`                     | `LessThanOrEqual`          |
| `>`                      | `GreaterThan`              |
| `>=`                     | `GreaterThanOrEqual`       |
| **conversion**           | `Implicit`, `Explicit`     |
| **truthiness**           | `True`, `False`            |

> *Informative.* The compiler requires **exact names** above. `in`, `is`, `as` have **no** operator identifiers and cannot be overloaded.

---

### 4. Candidate set construction

Given an operator expression (token **op**, operands **L** and **R** where applicable):

1. **Built‑in candidates.** If both operands are of built‑in categories with a defined operator (e.g., integers, reals, sets, strings for `+`, pointers for comparisons), the compiler **adds** the corresponding built‑in operator to the candidate set.  
2. **User‑defined candidates from operand types.** Collect all `class operator` methods **declared on** `type(L)` and `type(R)` (if binary) whose **identifier name** matches **op** and whose **arity** matches. Include operators inherited by classes. Operators on helpers are **not** considered.  
3. **Conversion‑enabled candidates.** For each side, consider **implicit conversions** defined by `class operator Implicit` that convert an operand **to** a type that has a built‑in or user operator for **op**. At most **one** implicit conversion per operand is considered during candidate formation.  
4. **Variants.** If **either operand is `Variant`/`OleVariant`**, variant semantics take precedence (§07.11). User‑defined operators are **not** considered in that case.  
5. **Strings and sets.** If the expression is a recognized **string** concatenation (`+`) or a **set** operation (`+`, `-`, `*`), add only the **built‑in** candidate(s) for those categories. Overloads do not shadow these when operands already have string/set types.

---

### 5. Candidate filtering (applicability)

A candidate is **applicable** if:
- Its parameter types are **identical** to the operand types, or
- Each operand can be obtained from the actual via **identity** or **implicit** conversion (including conversions declared via `Implicit`).  
A candidate requiring **explicit** conversions is **not applicable**.

---

### 6. Best‑candidate selection

From the applicable candidates, select the **best** using these rules (in order):

1. **Fewer conversions** are preferred (0 over 1 over 2).  
2. **Narrower conversions** are preferred: identity > widening within a numeric family > user‑defined implicit > numeric + user‑defined chains.  
3. **Built‑in vs user‑defined.** If two candidates remain indistinguishable, prefer the **built‑in** operator over a user‑defined overload.  
4. **Left‑type bias (tie‑break).** If one user‑defined candidate comes from the **left operand’s** type and another equally good one from the right’s type, prefer the **left**.  
5. **Ambiguity.** If none is better, the expression is **ambiguous** (compile‑time error). Use casts to disambiguate.

---

### 7. Conversions

1. **Implicit (`Implicit` operator).** Permits use of a value in any context where the **target type** is expected, including as an operand if doing so enables a better candidate.  
2. **Explicit (`Explicit` operator).** Only applied when the programmer writes an **explicit cast** `T(X)` (or helper factory code); never inserted by the compiler during operator resolution.  
3. **Direction.** Conversions may be declared **to** or **from** the declaring type. Overlapping implicit conversions can cause ambiguities; prefer **Explicit** for lossy or potentially surprising mappings.
4. **Boolean contexts.** Do not rely on `Implicit` to convert to `Boolean` for `if/while` conditions; use **`True`/`False` operators** instead (see §8).

---

### 8. Truthiness and short‑circuit

1. A user type can participate in `if`, `while`, `until`, and **short‑circuit** operations by declaring **both** `class operator True` and `class operator False` returning **Boolean**.  
2. In a conditional, the compiler evaluates **`True`** to test the condition; in short‑circuit boolean expressions it may use both `True` and `False` to determine evaluation. **Both must be present**; having only one is an error.  
3. These operators do **not** define `=`/`<>`; provide comparison overloads separately if needed.

---

### 9. Interactions with built‑in categories

1. **Strings.** `+` as concatenation is **built‑in**. If either operand is a `string` (UnicodeString/AnsiString/ShortString), the built‑in concatenation applies. A user‑defined `Add` on a custom type will not intercept concatenation unless you **explicitly convert** operands.  
2. **Sets.** `+`, `-`, `*` on sets are built‑in; overloading these for set types is not supported.  
3. **Pointers and class references.** Comparisons (`=`, `<>`, `<`, `>`, `<=`, `>=`) between pointers/class refs use built‑in semantics; overloads on unrelated types do not apply.  
4. **Variants.** See §4. Variants suppress user‑defined overloads.  
5. **`in`, `is`, `as`.** Never overloadable; always built‑in semantics.

---

### 10. Examples

#### 10.1 Complex numbers with arithmetic, comparison, and conversions

```pascal
type
  TComplex = record
    R, I: Double;
    class operator Add    (const A, B: TComplex): TComplex;
    class operator Subtract(const A, B: TComplex): TComplex;
    class operator Multiply(const A, B: TComplex): TComplex;
    class operator Divide (const A, B: TComplex): TComplex;
    class operator Negative(const A: TComplex): TComplex;
    class operator Equal  (const A, B: TComplex): Boolean;
    class operator NotEqual(const A, B: TComplex): Boolean;
    class operator Implicit(const A: Double): TComplex;
    class operator Explicit(const A: TComplex): Double;
  end;
```

Usage:

```pascal
var Z: TComplex;
Z := 1.0 + TComplex(R:2, I:3); // implicit Double→TComplex applies to left '1.0'
if Z = 0.0 then ...            // implicit Double→TComplex, then Equal
Writeln(Double(Z));            // explicit cast required (Explicit)
```

#### 10.2 Truthiness for a handle wrapper

```pascal
type
  THandleRef = record
    Value: NativeUInt;
    class operator True (const H: THandleRef): Boolean;
    class operator False(const H: THandleRef): Boolean;
  end;

if H then                       // uses True/False operators
  DoSomething;
```

#### 10.3 Left/right bias and ambiguity

```pascal
type
  TLeft = record
    class operator Add(const A: TLeft; const B: Integer): TLeft;
  end;
  TRight = record
    class operator Add(const A: Integer; const B: TRight): TRight;
  end;

var L: TLeft; R: TRight;
// L + R  // ambiguous: no candidate directly matches; add an Implicit on one side or cast
```

#### 10.4 Built‑in wins over overload

```pascal
type
  TStringy = record
    S: string;
    class operator Add(const A, B: TStringy): TStringy;
  end;

var A, B: TStringy; S: string;
S := 'x' + 'y';     // built‑in concatenation
A := A + B;         // user‑defined Add
S := S + A.S;       // still built‑in; Add on TStringy never intercepts string + string
```

---

### 11. Diagnostics and common error notes

- **E2015 Operator not applicable to this operand type**: no applicable candidates were found.  
- **E2250 Ambiguous overloaded call to 'operator'**: more than one equally good candidate; disambiguate with casts.  
- **E2019 Invalid typecast**: attempting to use `Explicit` implicitly or performing invalid hard casts.  
- **E2089 Invalid type of expression**: using a type without `True`/`False` in a boolean context.

