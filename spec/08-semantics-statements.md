# Delphi Language Specification
## 08 Semantics — Statements

### Status
Draft v0.1.0 — 2025-08-24  
Target: RAD Studio 12 Athens (Delphi)  
Scope: This chapter defines the **semantics of statements**: blocks and sequencing; assignments and calls; conditionals (`if`, `case`); iteration (`while`, `repeat`, `for`, **for‑in**); `with`; exception handling (`try..except`, `try..finally`, `raise`); flow‑control (`exit`, `break`, `continue`, `goto`/labels); `inherited`; and brief notes on `asm`. Grammar appears in §03; types and expressions are covered in §§04–07.

---

### 1. Statement categories

A *statement* is one of the following:
- **Empty** (`;`), **compound** (`begin S1; …; Sn; end`), or **labelled** (`LabelId: Statement`).
- **Assignment** (`VarRef := Expr`), **call** (`Proc(…)`), or **inherited** call.
- **Conditional** (`if … then … [else …]`, `case … of … end`).
- **Iteration** (`while … do …`, `repeat … until …`, `for … do …`, **`for … in … do …`**).
- **With** (`with ExprList do Statement`).
- **Exception** (`try … except … end`, `try … finally … end`, `raise`).
- **Flow‑control** (`exit [Value]`, `break`, `continue`, `goto LabelId`).
- **Asm** (`asm … end`).

A *block* is `begin` *StatementList* `end`. A semicolon is a **separator** between statements; a semicolon before `end` is optional.

---

### 2. Assignments and calls

1. **Assignment** `L := R` evaluates `R` then assigns to `L`. `L` must denote a writable variable, field, array element, dereferenced pointer, or **property**.  
   - For **properties**, `L := R` invokes the *write accessor*; the read accessor is **not** evaluated unless the accessor requires it.  
   - Assignment to **managed types** (strings, dynamic arrays, interfaces, variants, anonymous methods) updates reference counts per §11.
2. **Procedure/function calls** evaluate arguments left‑to‑right and pass by the declared modifier:  
   - `value` (default): by value;  
   - `var`: by reference; actual must be an assignable variable;  
   - `out`: by reference with **definite assignment by callee**; the actual is initialized to the type’s default on entry;  
   - `const`: read‑only; may be passed by reference;  
   - `constref`: read‑only by reference (never copied).
3. The **result** of a function can be assigned via `Result := Expr` inside the function body, or by `Exit(Expr)`. Outside, assign to a function call is illegal.

*Informative.* `Exit` in a procedure may be written with no value; in a function, `Exit(Value)` assigns `Result` then leaves.

---

### 3. Conditional statements

#### 3.1 `if … then … [else …]`
- The condition is a `Boolean`.  
- The `else` (if present) is associated with the **nearest** preceding unmatched `if` (standard *dangling‑else* rule).  
- Both branches are statements; use `begin … end` to group multiple statements.

#### 3.2 `case … of`
- The selector expression must be **ordinal** (integer, character, Boolean, enumerated, or subrange). `string` is **not** permitted.  
- Each case label is a **constant expression** of the selector’s type; ranges `lo..hi` are allowed. Duplicate coverage is illegal.  
- An optional `else` handles all values not matched by labels.  
- Execution selects the first matching label; if none and `else` is absent, control proceeds after the `case` with no action.

*Informative.* Use `case Ord(SomeEnum)` or mapping tables if you need non‑ordinal dispatch (e.g., strings).

---

### 4. Iteration statements

#### 4.1 `while … do`
- Evaluate the condition (Boolean); if True, execute the body, then repeat; otherwise exit. The body may execute **zero or more** times.

#### 4.2 `repeat … until`
- Execute the body, then evaluate the condition; if True, exit; otherwise repeat. The body executes **one or more** times. The condition is a Boolean.

#### 4.3 `for … do` (numeric)
- Syntax forms:  
  - `for Variable := Expr1 to   Expr2 do Statement`  
  - `for Variable := Expr1 downto Expr2 do Statement`
- `Variable` must be an **ordinal** variable (or `for var X` declaration with an ordinal type).  
- The bounds `Expr1`, `Expr2` are evaluated **once**, before iteration begins, and converted to the control variable’s type.  
- For `to`: iteration proceeds by **successive `Succ`**; terminates after assigning `Expr2`. For `downto`: by **`Pred`**; terminates at `Expr2`.  
- The control variable is **assigned** at each step and is **read‑only** within the loop with respect to reassignment via the loop control; explicit writes are allowed but **undefined** with respect to iteration (do not modify it).  
- If the initial comparison (`Expr1` > `Expr2` for `to`; `<` for `downto`) is false, the body does not execute.

*Informative.* Avoid writing to the control variable inside the body; behavior can be surprising and is non‑portable.

#### 4.4 `for … in … do` (enumeration)
- Iterates over a **sequence** determined by the *enumerable expression* after `in`. Supported categories:
  1. **Arrays and strings** — built‑in enumeration over elements/characters.  
  2. **Types that expose an enumerator** via either:
     - `function GetEnumerator: TEnum;` where `TEnum` has  
       `function MoveNext: Boolean;` and either `function GetCurrent: T;` or `property Current: T read GetCurrent;`, or
     - A compatible *record/class* enumerator with the same members.  
- At each step: call `MoveNext`; if True, fetch the current element; assign it to the iteration variable; execute the body. Stops when `MoveNext` returns False.  
- The **iteration variable** may be declared inline: `for var X: T in Expr do …` or predeclared and type‑compatible. It is read‑only with respect to enumeration (do not assign to it to affect the sequence).  
- The compiler may allocate **temporaries** to hold the enumerator; their lifetime is the duration of the statement.

*Informative.* Sets are **not** directly enumerable; define a helper that exposes an enumerator if needed.

#### 4.5 `break` and `continue`
- `break` exits the **innermost** loop statement (`for`, `while`, `repeat`, or `for‑in`).  
- `continue` skips to the next iteration of the **innermost** loop.

---

### 5. `with` statement

#### 5.1 Semantics
- `with E1, E2, …, En do S`: evaluate each `Ei` **left‑to‑right** to an object/record reference; then execute `S` with a **qualifier search list** `[En, …, E1]` from **right to left** (the last expression has the **highest** priority).  
- An **unqualified** member reference in `S` resolves to the **first** member found in that search list; otherwise to outer scopes.  
- The expressions are **evaluated once**; if an expression constructs a temporary value, its lifetime extends through `S` (implementation‑generated temps).

#### 5.2 Cautions
- `with` can obscure bindings and accidentally target unexpected members; prefer explicit qualifiers in new code.  
- `with TStringList.Create do …` does **not** auto‑free; pair with `try..finally Free`.

---

### 6. Exceptions

#### 6.1 `try … finally … end`
- Always executes the `finally` block **exactly once** after the `try` block finishes, whether normally, via `exit/break/continue/goto`, or by exception.  
- If both the `try` block and the `finally` block raise exceptions, the `finally` exception **replaces** the earlier one (the earlier exception is discarded).

#### 6.2 `try … except … end`
- Catches exceptions raised in the `try` block. The handler list consists of zero or more `on E: EClass do Handler;` clauses followed by an optional `else Handler`.  
- The first matching `on` clause (by class **or subclass**) handles the exception; if none matches and `else` is present, it executes; otherwise the exception **propagates**.  
- The exception variable `E` (if named) is scoped to its handler and is **read‑only**.

#### 6.3 `raise`
- `raise;` inside an `except` handler **re‑raises** the current exception and **preserves** its original raise location.  
- `raise E;` raises a new exception object `E` (class derived from `Exception`); the raise location is the current point.  
- `raise E at Addr;` sets the reported address to `Addr` (legacy form).

*Informative.* Use `try..finally` for resource management; use `try..except` for recovery and translation to domain errors.

---

### 7. Flow‑control statements

1. **`exit [Value]` ** Exits the current routine. In a **function**, `exit(V)` is equivalent to `Result := V; exit;`.  
2. **`break` / `continue`** See §4.5.  
3. **`goto LabelId`** Transfers control to a **declared label** within the **same routine** subject to restrictions (§8).  
4. **Process termination note.** `Halt(Code)` terminates the process; avoid in libraries.

---

### 8. Labels and `goto`

1. A label must be declared in the routine’s `label` section. Labels are local to the routine.  
2. `goto` may **not** jump **into** a block that creates an execution context requiring setup: `try`, `finally`, `except`, `for`, `while`, `repeat`, or `with`. Jumps **out of** such blocks are permitted (the runtime still executes pending `finally` blocks).  
3. Jumps **into** a nested scope that would skip variable initialization are illegal.  
4. Labels inside `try`/`finally`/`except` are permitted as **targets** only for jumps that originate **within** the same protected block.

---

### 9. `inherited` statement

1. `inherited;` inside an overriding method invokes the **ancestor** method of the **same name and signature**.  
2. `inherited Identifier(…)` calls a **specific** ancestor method by name.  
3. `inherited` is only valid inside methods of a class (or record) with an ancestor that defines a callable member of the same name/signature.

*Informative.* Use `inherited` at the **start** or **end** of overrides to maintain ancestor invariants.

---

### 10. `asm` statement note

- Inline assembly `asm … end` inserts target‑specific instructions. Availability and syntax are **platform dependent** (e.g., supported on Win32, restricted/unsupported on Win64 for inline asm). Use only in performance‑critical or low‑level code.

---

### 11. Examples

```pascal
// 1) Resource management
var F: TFileStream;
begin
  F := TFileStream.Create('data.bin', fmOpenRead);
  try
    // use F
  finally
    F.Free;
  end;
end;

// 2) for-in over a custom enumerable
type
  TMyList = class
  type
    TEnum = record
      Index: Integer;
      Data: TArray<Integer>;
      function MoveNext: Boolean;
      function GetCurrent: Integer;
      property Current: Integer read GetCurrent;
    end;
  public
    Items: TArray<Integer>;
    function GetEnumerator: TEnum;
  end;

var X: Integer; L: TMyList;
for X in L do
  Writeln(X);

// 3) case on an enumeration
type TKind = (kA, kB, kC);
var K: TKind;
case K of
  kA, kB: Writeln('A or B');
  kC:     Writeln('C');
else
  Writeln('Other');
end;

// 4) inherited call in an override
type
  TBase = class
    procedure DoIt; virtual;
  end;
  TSub = class(TBase)
    procedure DoIt; override;
  end;

procedure TSub.DoIt;
begin
  inherited; // call TBase.DoIt
  // then extend
end;
```
