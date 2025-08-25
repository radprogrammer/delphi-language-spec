# Delphi Language Specification
## 09 Semantics — Attributes and Helpers

### Status
Draft v0.1.1 — 2025-08-24  
Target: RAD Studio 12 Athens (Delphi)  
Scope: This chapter defines the **semantics of attributes and helpers**. It covers declaration and use of *custom attributes* (RTTI‑based), the standard **compiler‑recognized attributes** (`[Ref]`, `[volatile]`, `[weak]`, `[unsafe]`), attribute parameter rules and run‑time retrieval, and the design and resolution rules for **class/record helpers** (including helpers for simple/intrinsic types). Grammar hooks appear in §03; lexical rules in §01.

---

### 1. Custom attributes — model and usage

1. **Definition** A *custom attribute* is any class type derived from `System.TCustomAttribute`. Attributes are applied by placing one or more bracketed items immediately before the declaration to be annotated; each item names an attribute class and optional constructor arguments. The compiler emits metadata that can be discovered through RTTI at run time.
2. **Targets** Custom attributes can annotate **types** (class, record, interface, enum, set, subrange, type alias) and **members** (fields, properties, methods, and parameters). Attributes may also appear on **variables**; unless the attribute is compiler‑recognized, such use has no semantic effect (but tools may read it via RTTI if present).
3. **Suffix elision** If an attribute class name ends with `Attribute`, that suffix may be omitted in source. If both `X` and `XAttribute` exist, `[X]` denotes `XAttribute`.
4. **Multiplicity** Multiple attributes may annotate the same entity, either as a comma‑separated list in one `[ ... ]` or as several bracketed lists. Ordering of construction at run time is **unspecified**.
5. **RTTI dependency** Attribute metadata is emitted only where **RTTI is enabled** for the annotated entity (see `{$}RTTI` in §02).

*Example*

```pascal
type
  MyNoteAttribute = class(TCustomAttribute)
  public
    Msg: string;
    constructor Create(const AMsg: string);
  end;

  [MyNote('use fast path')]
  TPoint = record
    X, Y: Integer;
  end;

  TWorker = class
  public
    [MyNote('hot path')]
    procedure Run([MyNote('milliseconds')] Timeout: Integer);
  end;

// Suffix elision
[MyNote] procedure P;
[MyNote()] procedure Q;
```

---

### 2. Attribute parameters

1. **Constant expressions.** Constructor arguments in an attribute application must be **constant expressions** evaluable at compile time.
2. **Permitted forms.** Ordinals (including enums and `Char`), strings, sets, `nil`, `True/False`, constant arithmetic, `TypeInfo(T)` (a type‑info pointer), and **class references** are permitted. Open array parameters are allowed only with **static** constant arrays.
3. **Forbidden forms.** No `var`/`out` arguments; no address‑of (`@`) or non‑constant function calls; no values that require run‑time computation.
4. **Overloads.** Attribute classes may overload constructors; normal overload resolution applies at compile time.

*Rationale (informative).* Arguments are embedded into metadata for optional construction at query time; therefore they must be representable without run‑time state.

---

### 3. Run‑time retrieval and lifetimes

1. Attribute **instances are created on demand** when queried via RTTI (e.g., `TRttiType.GetAttributes`). They are not constructed during compilation or unit initialization.
2. If multiple attributes are present, **construction order is unspecified**; do not rely on it.
3. Exceptions raised by attribute constructors propagate to the caller of the RTTI query.
4. Lifetimes follow the RTTI context; objects returned by `TRttiContext` are released with the context. User code should copy needed data before disposing the context.

*Example.*

```pascal
var Ctx: TRttiContext; T: TRttiType; A: TCustomAttribute;
begin
  T := Ctx.GetType(TypeInfo(TWorker));
  for A in T.GetAttributes do
    if A is MyNoteAttribute then
      Writeln(MyNoteAttribute(A).Msg);
end;
```

---

### 4. Compiler‑recognized attributes

These attributes directly affect code generation or semantics:

1. **`[Ref]` on `const` parameters.** Forces a `const` parameter to be passed **by reference** (no copy), even for small types that would otherwise pass by value. May be written as `[Ref] const` or `const [Ref]`.
2. **`[volatile]`.** Applied to **variables, fields, or parameters** to suppress register caching and force memory reads/writes that are visible to other threads/CPUs. Not valid on type or routine declarations.
3. **`[weak]` and `[unsafe]` (interfaces).**
   - On **interface references**, `[weak]` creates a **non‑owning, managed** reference that does not increment reference counts and is reset to `nil` if the target is destroyed (breaks cycles).
   - `[unsafe]` creates a **non‑owning, unmanaged** reference (like a raw pointer); it is **not** auto‑cleared.
   - Parameters marked `[weak]`/`[unsafe]` require actual arguments with the same modifier category; strong references do not bind to them.

*Informative.* ARC for classes is no longer used on current desktop/mobile targets; `[weak]/[unsafe]` remain relevant for **interface** references.

---

### 5. Helpers — model and intent

Helpers extend an existing type with additional methods/properties **without** altering the type’s identity or introducing inheritance relationships.

- **Kinds**
  - **Class helpers**: `class helper for TClass`. May specify an *ancestor helper* (helper‑to‑helper inheritance).
  - **Record helpers**: `record helper for TRecord` and for **intrinsic/simple types** (e.g., `string`, `Integer`, enums). Record helpers have **no** helper inheritance.
- **Capabilities**
  - No per‑instance fields (no instance data). **Class fields** are allowed.
  - Methods (including `class`/`static`), properties, and nested types are permitted.
  - Helpers do **not** change visibility, vtables, RTTI shape, or assignment compatibility of the extended type.

*Informative.* Prefer helpers for convenience APIs and migration paths. For primary design, favor normal inheritance and interfaces.

---

### 6. Helper binding and name resolution

1. **Active helper — exactly one.** Many helpers may exist for the same extended type, but at any point **zero or one** helper is *active* for lookup.
2. **Nearest scope wins.** The active helper is the one closest in scope by normal unit resolution (notably, the `uses` clause is searched **right‑to‑left**).
3. **Member precedence.** When a member exists **both** on the extended type **and** on the active helper with the same name/signature, the **extended type’s own member takes precedence**. A helper member is considered only if the extended type (and its ancestors) don’t already provide a matching member.
4. **Static binding.** Helper members are **statically bound**; helpers do not introduce virtual dispatch.
5. **`Self` meaning.** Inside a helper method, `Self` denotes the **extended type instance**, not the helper object.

*Example* If units `U1` and `U2` both bring a `string` helper into scope and the `implementation uses` clause reads `uses ..., U2, U1;` then `U1`’s helper is active in that implementation section.

---

### 7. Helper visibility and access

1. Helpers **do not** gain access to `private` or `strict private` members of the extended type.
2. Helpers are **not descendants** of the extended class; they receive **no `protected` access**.
3. A helper’s own members may use standard visibility sections; `published` in a helper does not make members design‑time visible on the extended type.

---

### 8. Helper limitations

- Helpers cannot define **operator overloads** for the extended type.
- Record helpers cannot declare an ancestor helper; only **class helpers** support helper‑to‑helper inheritance.
- Helpers cannot add **instance fields** to the extended type.
- Helpers do not alter **type identity**, **assignment compatibility**, or **RTTI** of the extended type.

---

### 9. Examples

**9.1 Class helper**

```pascal
type
  TStreamHelper = class helper for TStream
    function ReadAllText: string;
  end;

function TStreamHelper.ReadAllText: string;
var SS: TStringStream;
begin
  SS := TStringStream.Create('');
  try
    SS.CopyFrom(Self, 0);
    Result := SS.DataString;
  finally
    SS.Free;
  end;
end;
```

**9.2 Record helper for an intrinsic type**

```pascal
type
  TStringAddons = record helper for string
    function IsBlank: Boolean;
    class function Join(const Parts: array of string; const Sep: string): string; static;
  end;

function TStringAddons.IsBlank: Boolean;
begin
  Result := Trim(Self) = '';
end;

class function TStringAddons.Join(const Parts: array of string; const Sep: string): string;
var I: Integer;
begin
  Result := '';
  for I := Low(Parts) to High(Parts) do
  begin
    if I > Low(Parts) then
      Result := Result + Sep;
    Result := Result + Parts[I];
  end;
end;
```

**9.3 Custom attribute with parameters and RTTI use**

```pascal
type
  RangeAttribute = class(TCustomAttribute)
  public
    Low, High: Integer;
    constructor Create(ALow, AHigh: Integer);
  end;

  TConfig = class
  public
    [Range(1, 10)]
    Retries: Integer;
  end;

procedure Validate(const Obj: TObject);
var Ctx: TRttiContext; T: TRttiType; F: TRttiField; A: TCustomAttribute;
begin
  T := Ctx.GetType(Obj.ClassType);
  for F in T.GetFields do
    for A in F.GetAttributes do
      if A is RangeAttribute then
        if (F.GetValue(Obj).AsInteger < RangeAttribute(A).Low) or
           (F.GetValue(Obj).AsInteger > RangeAttribute(A).High) then
          raise ERangeError.CreateFmt('%s out of range', [F.Name]);
end;
```
