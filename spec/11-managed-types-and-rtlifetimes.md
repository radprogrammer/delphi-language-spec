# Delphi Language Specification
## 11 Semantics — Managed Types and RTL Lifetimes

### Status
Draft v0.1.0 — 2025-08-24  
Target: RAD Studio 12 Athens (Delphi)  
Scope: This chapter specifies **managed types** and their **lifetime semantics**: strings, dynamic arrays, interfaces, variants, and anonymous methods (method references). It also defines how the compiler initializes/finalizes locals and fields containing managed types, rules for parameter passing (`const`, `var`, `out`, `constref`) with managed values, copy‑on‑write behavior, temporary values, and **advanced/managed records** hooks. Grammar is in §03; core type categories are in §04.

---

### 1. What is a managed type?

The following are **managed** (their storage contains references whose lifetimes are tracked by the compiler and RTL):

- **Strings**: `UnicodeString` (`string`), `AnsiString` (including `UTF8String`, `RawByteString`), `WideString` (BSTR). *ShortString is **not** managed* (it is a fixed‑size value type).  
- **Dynamic arrays**: `array of T`.  
- **Interfaces**: any type deriving from `IInterface` (including custom interfaces).  
- **Variants**: `Variant`, `OleVariant`.  
- **Anonymous methods**: `reference to procedure/function …` (method references/closures).  

Fields, locals, array elements, and record/class members of these types are managed. **Records containing managed fields are themselves managed** for initialization/finalization purposes.

---

### 2. Initialization and finalization

1. **Zero‑initialization.** All managed variables (locals, fields, globals) are **zero‑initialized** upon creation. For strings and dynamic arrays, zero means *nil/empty*; for interfaces it means *nil*; for variants it means *Unassigned*; for anonymous methods it means *nil*.  
2. **Automatic finalization.** When a managed variable **goes out of scope**, the compiler inserts finalization code that **decrements reference counts** and releases resources as needed:
   - Locals: finalized on **all exits** from the routine (normal return, `Exit`, `Raise`, exceptions).  
   - Fields: finalized when the containing instance is destroyed (for classes) or when the containing record variable goes out of scope.  
   - Globals/typed constants with managed content: finalized during **unit finalization**.  
3. **Temporaries.** The compiler also finalizes **temporary** managed values it constructs (e.g., results of function calls, implicit string conversions) after the full expression is evaluated.  
4. **Definite assignment.** A managed local must be initialized (implicitly to zero or explicitly) before it is read; the compiler enforces definite‑assignment rules for `out` parameters (see §5).

*Informative.* The language provides **deterministic** release for reference‑counted entities (not tracing GC). Ordering among independent locals is unspecified; do not write code that depends on finalization order of distinct variables.

---

### 3. Strings — semantics and lifetime

#### 3.1 Representation and sharing

1. `UnicodeString` and `AnsiString` are **reference‑counted**, variable‑length, heap‑allocated strings with **copy‑on‑write (COW)** semantics. Assignment copies a **reference** and **increments** the refcount.  
2. **Mutation** (e.g., `S[i] := …`, `SetLength`, concatenation on the left) performs **COW** if the refcount > 1, creating a unique copy before mutation.  
3. `WideString` is a **BSTR** (COM) with its own allocation and ref‑count model; treat it as managed but prefer `UnicodeString` unless interop requires `BSTR`.

#### 3.2 Equality, length, and nil

1. `Length(S)` returns the number of **code units** (UTF‑16 for `UnicodeString`, bytes for `AnsiString`).  
2. A `nil` `UnicodeString` behaves as **empty** for length and comparisons.  
3. Indexing semantics follow §04 (code‑unit based; `{$}ZEROBASEDSTRINGS` may affect the index base).

#### 3.3 Interop and pointers

1. A `PChar`/`PAnsiChar` obtained from a string remains valid **until** the string variable is **modified** or goes out of scope; modifications may trigger COW and invalidate prior pointers.  
2. Assignments between `UnicodeString` and `AnsiString` perform conversions; down‑conversions may lose data. `RawByteString` preserves incoming code pages for by‑value parameters.  
3. Passing a string as `const` generally avoids refcount churn and copying (the compiler may pass by reference).

---

### 4. Dynamic arrays — semantics and lifetime

#### 4.1 Representation

1. Dynamic arrays are **reference‑counted** and **always zero‑based** (indices `0..Length(A)-1`).  
2. Assignment copies a reference; **mutation** (`A[i] := …`, `SetLength`, `Insert`, etc.) on a shared array performs **COW**.  
3. `Length(nilArray) = 0`; `High(nilArray) = -1`.

#### 4.2 Elements and nested management

1. Elements of a dynamic array that are managed types (e.g., an array of strings) are **individually** reference‑counted and finalized when the array or element slot is released/overwritten.  
2. Resizing with `SetLength` initializes new elements to default values and finalizes elements that fall out of range on shrink.

*Informative.* When holding pointers into an array, remember that `SetLength` may relocate storage.

---

### 5. Parameter passing with managed types

1. **`const`**: Read‑only. The compiler may pass by reference; no refcount modifications are required for inspection.  
2. **`var`**: By reference. Reading/writing affects the caller’s variable; assigning a new managed value to the parameter **adjusts** refcounts of both old and new values.  
3. **`out`**: By reference with **definite assignment by callee**. On entry, the parameter is **initialized to the type’s default** (strings/arrays/interfaces/anonymous methods to `nil`; variants to `Unassigned`). Any prior content in the caller is released before the call. The callee must assign before reading.  
4. **`constref`**: Read‑only **by reference** (never copied). Prefer for large records containing managed fields to avoid temporaries.

*Informative.* Marking string/array parameters as `const` can significantly reduce refcount churn and COW.

---

### 6. Interfaces — semantics and lifetime

#### 6.1 Reference counting

1. An interface variable holds a reference to an object that implements `IInterface`; **assigning** an interface increments the object’s **interface refcount**; setting the last reference to `nil` **destroys** the object (calls its destructor).  
2. Classes deriving from `TInterfacedObject` provide the standard `QueryInterface/AddRef/Release` implementation. Other classes implementing interfaces must supply it manually.  
3. Interface reference counting is **separate** from object references. **Mixing object variables and interface variables** referencing the same instance can lead to **dangling object references** when the interface count drops to zero. Avoid storing raw object references to `TInterfacedObject` instances unless you control all reference paths.

#### 6.2 Weak and unsafe interface refs

- `[weak]` creates a **non‑owning, managed** interface reference that is set to `nil` when the target is destroyed (break cycles).  
- `[unsafe]` creates a **non‑owning, unmanaged** interface reference (like a raw pointer). See §09 for details.

#### 6.3 Threading and atomicity note

- Interface AddRef/Release operations are **atomic**; avoid manual sharing of non‑thread‑safe object state across threads merely because the references are refcounted.

---

### 7. Variants — semantics and lifetime

1. `Variant` is a discriminated union with **reference‑counted** payloads for strings, arrays, etc.; copying a variant adjusts counts of any referenced sub‑objects.  
2. `OleVariant` is restricted to Automation‑compatible types. Conversions outside that set raise run‑time errors.  
3. **Variant arrays** (`VarArrayCreate`) are managed independently of dynamic arrays; releasing the variant that owns the array releases the array.

*Informative.* Prefer `Variant` only where required; variant dispatch adds overhead and defers errors to run time.

---

### 8. Anonymous methods (method references) — semantics and lifetime

1. A `reference to` type denotes a **managed closure** capturing variables from its defining scope. The compiler **lifts** captured variables to heap‑allocated, reference‑counted cells so that they remain valid as long as **any** closure referencing them remains alive.  
2. Assigning or passing an anonymous method **increments** its reference count; when the last reference is released, captured context is finalized.  
3. Captures are by **reference**: updates through the closure are reflected in the original variable and in other closures sharing the capture.  
4. Avoid capturing `Self` or UI controls into long‑lived closures without breaking cycles or carefully controlling lifetimes.

*Informative.* Anonymous methods are distinct from **method pointers** (`of object`), which carry only code+instance and are *not* closures.

---

### 9. Advanced (managed) records

Records can customize their lifetime and copying through **special class operators**:

```pascal
type
  TMyRec = record
    S: string; // managed field
    class operator Initialize (out   Dest: TMyRec);
    class operator Finalize   (var   Dest: TMyRec);
    class operator Assign     (var   Dest: TMyRec; const [ref] Src: TMyRec);
  end;
```

Semantics:

1. **Initialize(out Dest)** — called when a variable of the record type comes into scope (locals), is default‑constructed, or a new array element is created. It runs **after** zero‑init. Use to set invariants.  
2. **Finalize(var Dest)** — called when the variable goes out of scope or is destroyed. Use to release resources; finalize contained managed fields as needed (the compiler finalizes fields **after** this hook).  
3. **Assign(var Dest; constref Src)** — called on *assignment to an existing* destination (e.g., `Dest := Src`). Implement **self‑assignment** safety and preserve invariants. Adjust refcounts of managed fields appropriately.  

*Informative.* Use `const ref` to avoid copying large records during hooks.  
*Informative.* Delphi uses Assign for both assignment and construction scenarios (e.g., pass-by-value, function return).  FPC adds support for class operator Copy.

---

### 10. Temporaries and expression lifetimes

1. The compiler may materialize **hidden temporaries** to hold intermediate results (e.g., string concatenation, implicit conversions). Those temporaries are finalized **after** the full expression completes and **before** proceeding to the next statement sequence point.  
2. In a `with` or short‑circuit boolean expression, temporaries for subexpressions follow **left‑to‑right** evaluation (see §07) and are finalized as soon as they go dead.  
3. When passing managed results to procedures, the temporary remains alive **through** the call and is finalized afterwards.

---

### 11. Global data and unit initialization order

1. Managed **global variables** and **typed constants** are zero‑initialized before a unit’s `initialization` section runs and are finalized during the unit’s `finalization` section.  
2. Initialization/finalization run in **reverse** unit dependency order across the program. Inter‑unit references to managed globals must tolerate the other unit being already finalized.  
3. To ensure controlled release order, explicitly set global interfaces/strings/arrays to `nil` in the owning unit’s `finalization` section.

---

### 12. Diagnostics and common pitfall notes

- **Dangling object refs with interfaces.** Holding a raw object reference to a `TInterfacedObject` while interfaces release it to zero causes a **dangling pointer**. Prefer interface references consistently.  
- **Pointer stability with strings/arrays.** Do not keep `PChar`/element pointers across operations that may trigger COW/reallocation.  
- **Accidental copies of large records.** Prefer `constref` for parameters and consider **managed record hooks** to control copying.  
- **Cycles (interfaces/closures).** Use `[weak]` on interface members that back‑reference their owners; break or design around cycles for closures.  
- **`out` parameters.** Remember that `out` **clears** the actual on entry; save prior content if you need it.
