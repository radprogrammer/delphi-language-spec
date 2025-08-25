[![Status: Draft](https://img.shields.io/badge/Status-Draft-orange.svg)](./04-semantics-types.md#status)


# Delphi Language Specification
## 05 Semantics — Generics

### Status
Draft v0.1.0 — 2025-08-24  
Target: RAD Studio 12 Athens (Delphi)  
Scope: This chapter defines **generic types** (classes, records, interfaces, arrays, procedural types) and **generic methods** in Delphi, including parameter lists, type argument admissibility, constraints, identity/compatibility, scoping, instantiation timing, RTTI visibility, overload resolution, and platform notes. Grammar appears in 03-grammar-ebnf; this chapter is **semantic** unless otherwise stated.

---

### 1. Model and terminology (overview)

1. **Generic type.** A *generic* is a type declaration with one or more **type parameters**, written in angle brackets after the type name: `TFoo<T>`, `TPair<TKey,TValue>`. *Instantiation* replaces type parameters by **type arguments**, producing a **constructed type** such as `TFoo<Integer>` (a *closed constructed type*).  
   - An *open constructed type* mentions one or more still‑open parameters, e.g., `TFoo<T>` inside a generic scope. (variables, fields, parameters, or properties may not have an *open* constructed type outside a generic declaration body.)
2. **Generic method.** A method with its own type parameter list: `procedure M<T>(X: T)`. Constructors, destructors, and virtual/dynamic/message methods **cannot** be generic.
3. **Where generics apply.** **Classes, interfaces, records, arrays, and procedural types** can be generic. 
4. **Static typing.** Every instantiation yields a distinct, statically known type; there is no run‑time reification for open generics. Dynamic (late) instantiation is **not supported**.

*Informative.* This chapter uses **open**/**closed** and **instantiation** consistently with the grammar in §03 and the collections library usage (`System.Generics.Collections`).

---

### 2. Syntax hooks (summary)

- **Type parameters (declaration):** `type TFoo<T1, T2> = class …;`  
- **Constraints (optional):** `type TFoo<T: IInterface, constructor>;`  
- **Instantiation:** `var F: TFoo<Integer>;`  
- **Generic method:** `procedure P<T>(X: T);`  
(Exact grammar in §03; examples here are illustrative.)

---

### 3. Identity, equality, and assignment compatibility 

1. **Type identity.** `TFoo<T>` and `TFoo<U>` are the *same generic*, but **constructed types are distinct by arguments**: `TFoo<Integer>` ≠ `TFoo<String>`. Aliases preserve identity.  
2. **Open generics.** Two *non‑instantiated* generics/parameterized types are assignment‑compatible **only if identical** (or aliases to a common type).  
3. **Closed generics.** Two *instantiated* generics are assignment‑compatible **iff** their base generic is identical and **all type arguments are identical** (after alias resolution).  
4. **Variance.** Delphi treats parameterized types as **invariant** with respect to their type arguments. There is no declaration‑site or use‑site variance.  
5. **Overload preference.** If overload resolution is otherwise ambiguous between a generic and a non‑generic routine, the compiler **selects the non‑generic**.  
6. **Collections note.** `TList<TPerson>` is not assignment‑compatible with `TList<TEntity>` even if `TPerson < TEntity`.

---

### 4. Type arguments (admissibility) 

You can use **any type** as a type argument **except**:
- a **static array** type;
- a **short string** type;
- a **record type that (recursively) contains** either of the above.

These restrictions apply recursively through fields of record arguments.

---

### 5. Constraints 

A type parameter may declare a **constraint list** after `:`. The list contains **zero or more interface types**, **zero or one class type**, and **at most one** of the reserved constraints `constructor`, `class`, `record`.

1. **Interface type constraints.** One or more interfaces (comma‑separated): `T: ICloneable, ISerializable`. The argument type must implement **all** listed interfaces.  
2. **Class type constraint (specific class).** At most one concrete **class type** may appear (e.g., `T: TComponent`). The argument must be assignment‑compatible with that class (usual OOP subtyping rules).  
3. **Reserved constraint — `constructor`.** Argument type must be a **class** that declares a **public, parameterless** constructor; code may invoke `T.Create`. (`constructor` may be combined with interface or specific class constraints.)  
4. **Reserved constraint — `class`.** Argument must be a **class type** (of any ancestry). May be combined with `constructor`.  
5. **Reserved constraint — `record`.** Argument must be a **value type** (not a reference type). **May not** be combined with `class` or `constructor`.  
6. **Multiple constraints.** Combined with commas; semantics are **conjunctive** (“AND”).  
7. **Compile‑time checking.** Constraint satisfaction is checked at **instantiation** points. Failure is a compile‑time error.

*Informative.* Within a generic body, members available through constraints participate in *name‑based lookup*: the compiler resolves a call on `T` against the **union** of members promised by the constraints and requires an unambiguous match.

---

### 6. Scope of type parameters 

1. A type parameter is **in scope** throughout its declaring type (including all member bodies).  
2. The scope **does not extend** to descendant types: a subclass that introduces its own type parameters does **not** see those of its ancestors by name.  
3. Nested types declared **inside** a generic are themselves **generic**; to reference a nested type you must qualify it with a **constructed** outer type: `TFoo<Integer>.TBar`.

---

### 7. Base classes and implemented interfaces 

1. A parameterized class or interface may derive from or implement an **actual type**, an **open constructed type**, or a **closed constructed type**.  
2. If the base uses parameters, **instantiating** the derived type **induces** instantiation of the base with corresponding arguments.  
3. Circularities are prohibited; usual inheritance rules apply.

---

### 8. Generic methods 

1. **Where allowed.** Methods may declare their own type parameters. **Not allowed:** constructors, destructors, or methods marked `virtual`, `dynamic`, or `message`.  
2. **Instantiation.** A generic method can be instantiated:
   - **Explicitly**: `M<Integer>(42)`  
   - **By inference**: `M(42)` (the compiler infers `<Integer>` from actuals when possible).  
3. **Overloading.** Generic methods can overload with non‑generic ones; if a non‑generic provides an equally good match, it is **chosen**.  
4. **Signature matching.** Calling convention and parameter modifiers (`var`, `out`, `const`, `constref`) are part of a method type.  
5. **Interfaces.** Parameterized **methods cannot be declared in interfaces.**

*Informative.* Inference interacts with overloading; explicit type arguments can disambiguate calls.

---

### 9. Runtime model, RTTI, and GUIDs 

1. **Instantiation timing.** Generic types are **instantiated at compile time** and emitted into units/objects. For **generic classes**, instance variables are created at run time; for **generic records**, code/data are realized at compile time.  
2. **RTTI.** Instantiated **types** (e.g., `TFoo<Integer>`) have RTTI like their non‑generic counterparts. **Generic methods** themselves do **not** have RTTI.  
3. **Interfaces.** On Win32, an instantiated **interface** type does **not** receive a distinct interface **GUID**.  
4. **Dynamic instantiation.** Constructing new specializations at run time is **not supported**.

---

### 10. Class variables (per‑specialization) 

A `class var` declared in a generic type is **replicated per closed constructed type**. For example, `TFoo<Integer>.FCount` and `TFoo<String>.FCount` are **distinct** storage locations.

---

### 11. Parsing note (generics vs relational `< >`) 

The tokens `<` and `>` serve as **operators** *and* as generic delimiters. Disambiguation is syntactic (see 03-grammar-ebnf). Heuristics such as no whitespace between the identifier and `<` are not required by the language but are common style.

---

### 12. Examples

#### 12.1 Constraints and construction example
```pascal
type
  TFactory<T: class, constructor> = class
  public
    class function Make: T;
  end;

class function TFactory<T>.Make: T;
begin
  Result := T.Create;
end;

var C: TFactory<TStringList>;
begin
  C := TFactory<TStringList>.Create;
  Writeln(C.Make.ClassName);
end;
```

#### 12.2 Inference and overloads example
```pascal
type
  TFoo = class
    procedure Proc<T>(A: T); overload;
    procedure Proc(A: string); overload;
  end;

procedure TFoo.Proc<T>(A: T);
begin
  Writeln('generic: ', SizeOf(A));
end;

procedure TFoo.Proc(A: string);
begin
  Writeln('non-generic: ', A);
end;

var F: TFoo;
begin
  F := TFoo.Create;
  F.Proc('Hi');            // calls non-generic
  F.Proc<string>('Hi');    // calls generic
  F.Free;
end;
```

#### 12.3 Nested, open and closed constructed types example
```pascal
type
  TFoo<T> = class
  type
    TBar = class
    end;
  end;

var
  N: TFoo<Integer>.TBar;   // legal: closed outer type
```


#### 12.4 Generic procedural types example
Three flavors of generic procedural types—plain function pointer, method pointer, and anonymous-method (closure)

````
program GenericProcTypeDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils;

type
  // 1) Plain function pointer (no instance)
  TConverter<TIn, TOut> = function(const Value: TIn): TOut;

  // 2) Method pointer (instance method: carries code + Self)
  TConsumer<T> = procedure(const Value: T) of object;

  // 3) Anonymous method (closure that can capture variables)
  TSelector<TSource, TResult> = reference to function(const Src: TSource): TResult;

function IntToStrConv(const Value: Integer): string;
begin
  Result := IntToStr(Value);
end;

type
  THost = class
  public
    procedure PrintInt(const Value: Integer);
  end;

procedure THost.PrintInt(const Value: Integer);
begin
  Writeln('Value = ', Value);
end;

var
  Convert : TConverter<Integer, string>;
  Consume : TConsumer<Integer>;
  Select  : TSelector<Integer, Integer>;
  Host    : THost;
  Factor  : Integer;
begin
  // Use the generic function-pointer type
  Convert := IntToStrConv;
  Writeln('Convert(123) = ', Convert(123));

  // Use the generic method-pointer type
  Host := THost.Create;
  try
    Consume := Host.PrintInt;
    Consume(42);
  finally
    Host.Free;
  end;

  // Use the generic anonymous-method type (captures Factor)
  Factor := 3;
  Select :=
    function(const Src: Integer): Integer
    begin
      Result := Src * Factor;   // closure captures Factor
    end;
  Writeln('Select(10) = ', Select(10));  // prints 30
end.

````
- TConverter<TIn, TOut> shows a generic function pointer.
- TConsumer<T> shows a generic method pointer (of object).
- TSelector<TSource, TResult> shows a generic anonymous-method type (reference to function), which can close over variables.
