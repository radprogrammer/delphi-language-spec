# Delphi Language Specification
## 06 Semantics — Classes

### Status
Draft v0.1.0 — 2025-08-24  
Target: RAD Studio 12 Athens (Delphi)  
Scope: This chapter specifies **class semantics**: declaration and inheritance; visibility and scope; fields and class variables; methods (static/virtual/dynamic, abstract/final, class methods); constructors/destructors and class constructors/destructors; properties (including `stored`, `default`, `nodefault`, `implements`); interface implementation and delegation; class references; and key RTTI/streaming aspects. Grammar hooks appear in §03; generics in §05; interfaces and helpers are cross‑referenced where relevant.

---

### 1. Overview (model)

1. **Reference type.** A class is a heap‑allocated reference type with **single inheritance** and support for implementing multiple interfaces.
2. **Members.** A class may declare **fields, methods, properties, class variables (`class var`), class methods (`class procedure`/`class function`),** and **nested types**.
3. **Visibility sections.** Member visibility is governed by `private`, `protected`, `public`, `published`, and (Delphi 2005+) `strict private`, `strict protected`. See §2.3.

---

### 2. Declaration, inheritance, visibility

#### 2.1 Declaration & inheritance

- A class optionally derives from a single base class; otherwise it implicitly derives from `TObject`. It may list zero or more **implemented interfaces** after the base class (see §8).  
- The `sealed` modifier **forbids subclassing**; `abstract` forbids direct instantiation and allows abstract methods. A class cannot be both `abstract` and `sealed`. citeturn2search0

#### 2.2 Forward declarations note

- Mutually dependent classes can be forward‑declared; full member lists must appear in a non‑forward declaration (§03).

#### 2.3 Visibility & scope

- **private**: visible **only within the declaring unit**.  
- **protected**: visible within the declaring unit **and** to **all descendants**, regardless of unit.  
- **public**: visible everywhere.  
- **published**: like `public` **and** participates in **design‑time streaming/RTTI** (see §7.5).  
- **strict private**: visible **only inside the declaring class** (not even other classes in the same unit).  
- **strict protected**: visible **inside the declaring class and all descendants**, regardless of unit; not visible to other code in the same unit.  
These rules follow Embarcadero’s definitions. citeturn0search4turn0search0

---

### 3. Fields and class variables

1. **Fields** are storage members; **class variables** (`class var`) are storage shared by the **type** rather than instances. Both obey visibility.
2. **Initialization.** Storage is **zero‑initialized** when an instance is created; managed fields (strings, dynamic arrays, interfaces, variants) receive default empty values and are finalized when the instance is destroyed (§11).
3. **Generics.** In a generic class, each **closed constructed type** has its own copy of any `class var` (see §05).

---

### 4. Methods (instance and class)

#### 4.1 Binding kinds

- **Static** (default): resolved at compile time.  
- **Virtual**: dispatched through the virtual method table; **overridable**.  
- **Dynamic**: like virtual but with a different dispatch table; trades memory for slightly slower dispatch.  
Only virtual and dynamic methods can be overridden; all methods can be **overloaded**. citeturn4search0turn2search2

#### 4.2 Class methods

- Declared with the `class` keyword; callable on the class identifier or an instance.  
- A **class method** may itself be `virtual`/`override` to support polymorphism on **class references** (§9).  
- A **`static` class method** has **no implicit `Self` (metaclass) parameter** and is always **statically bound**; it cannot exhibit virtual dispatch. citeturn4search1turn4search11

*Informative.* Calling a virtual class method **from** a `static` class method resolves against the **declaring** class, not an override, because no metaclass `Self` is available for dispatch.

#### 4.3 Abstract, override, final

- **abstract** marks a method with no implementation; the class becomes abstract unless it inherits an implementation.  
- **override** replaces a virtual/dynamic ancestor method with the **same signature**.  
- **final** prevents further overriding; `virtual|dynamic` precedes `final` in the declaration. citeturn2search19

#### 4.4 Hiding and `reintroduce`

- Declaring a **non‑virtual/dynamic** member with the **same name** as an inherited one **hides** it and produces warning **W1010**. Use `reintroduce` to acknowledge intentional hiding. citeturn2search5

#### 4.5 Message and dispatch methods notes

- **message** methods handle Windows/VCL messages (e.g., `procedure WndProc(var Msg: TMessage); message WM_…;`).  
- Use `virtual` for frequently invoked handlers; `dynamic` when many overridables exist but few are overridden (§4.1). citeturn2search2turn2search9

---

### 5. Constructors and destructors

#### 5.1 Instance constructors

- A **constructor** allocates and initializes a new instance. Constructors may be `virtual`/`override`/`overload` and can be **inherited**.  
- A constructor invoked on a **class‑type identifier** behaves like a static constructor; when combined with **class‑reference variables**, a **virtual** constructor enables **polymorphic construction** (see §9). citeturn0search1

#### 5.2 Destructors and `Free`

- Destructors are typically declared `destructor Destroy; override;`. Always call `inherited` in overrides to release ancestor resources.  
- Call `Obj.Free` to destroy an instance; `Free` is **nil‑safe** and invokes the destructor if the reference is non‑nil. citeturn5search0

*Informative.* GUI classes often use delayed destruction (`Release`) rather than immediate `Free` to avoid re‑entrancy during message handling.

#### 5.3 Class constructors and class destructors

- Declared as `class constructor` / `class destructor`; executed **once** per type. They run **with** unit initialization/finalization: class constructors before the unit’s `initialization`, class destructors after its `finalization` (subject to link‑in and dependency order). citeturn5search3turn4search6

---

### 6. Properties

#### 6.1 Semantics and specifiers

A property pairs a **name and type** with **access specifiers**. Minimal form requires `read` or `write`. Legal specifiers include: `read`, `write`, `stored`, `default` / `nodefault`, and `implements` (see §8.2). citeturn0search6turn3search1

- Properties may be **indexed**; a class can declare a **default property** to enable indexer‑like syntax.  
- Properties are not variables: they cannot be passed as `var` parameters and you cannot take their address with `@`. citeturn0search19

#### 6.2 Storage and streaming note

- `stored` controls whether a property participates in **component streaming** (design‑time persistence). `nodefault` suppresses default‑value optimization. Published properties appear in the Object Inspector. citeturn0search11

#### 6.3 Overriding and visibility

- A derived class may **redeclare** an inherited property to adjust accessors or **increase** visibility; it cannot **decrease** visibility. An override may include `implements` to add delegated interfaces. citeturn3search12

#### 6.4 Class properties

- A property can be declared on the **class** (using `class` on its accessors) and typically accesses `class var` state.

---

### 7. RTTI and published members

1. **Published visibility** marks members for design‑time tools and enables classic RTTI; **extended RTTI** is controlled by the `{$}RTTI` directive. citeturn1search5  
2. **Events** are properties of **method‑pointer** types (e.g., `TNotifyEvent = procedure(Sender: TObject) of object;`) usually placed in `published` to allow designer binding. *Informative.*

---

### 8. Interfaces and implementation in classes

#### 8.1 Direct implementation

- A class lists interfaces in its ancestor list; it must implement all required methods (directly or inherited). Querying through `IInterface` follows standard COM‑style reference counting when the class derives from `TInterfacedObject`; otherwise, implement `QueryInterface/AddRef/Release` yourself. *Informative.*

#### 8.2 Delegation with `implements`

- A property can **delegate** implementation of one or more interfaces using the `implements` specifier; the specifier is written **last** in the property declaration. Constraints apply (e.g., the property must have a `read` specifier; getter cannot be `dynamic` or `message`). citeturn3search0

---

### 9. Class references (metaclasses)

- `class of TBase` denotes a **class‑reference (metaclass) type**. Variables of this type can hold a descendant class and are used to invoke **class methods** and **virtual constructors** when the actual class is not known at compile time. citeturn0search3

---

### 10. Examples

#### 10.1 Virtual constructor and class reference

```pascal
type
  TAnimal = class
  public
    constructor Create; virtual;
    class function Kind: string; virtual;
  end;

  TDog = class(TAnimal)
  public
    constructor Create; override;
    class function Kind: string; override;
  end;

  TAnimalClass = class of TAnimal;

constructor TAnimal.Create;
begin
  Writeln('Animal created');
end;

constructor TDog.Create;
begin
  inherited;
  Writeln('Dog created');
end;

class function TAnimal.Kind: string;
begin
  Result := 'Animal';
end;

class function TDog.Kind: string;
begin
  Result := 'Dog';
end;

// Factory using a class reference (metaclass)
function MakeAnimal(C: TAnimalClass): TAnimal;
begin
  Result := C.Create;          // virtual constructor dispatch
  Writeln('Kind = ', C.Kind);  // class method dispatch
end;
```

#### 10.2 Property with streaming and delegation

```pascal
type
  ILog = interface
    ['{499A99B1-2C16-4BBA-A3B7-2DFAE3B2C0E7}']
    procedure Write(const S: string);
  end;

  TConsoleLog = class(TInterfacedObject, ILog)
  public
    procedure Write(const S: string);
  end;

  TFormLike = class
  private
    FCaption: string;
    FLogger: ILog;
  published
    property Caption: string read FCaption write FCaption stored True;
  public
    property Logger: ILog read FLogger implements ILog;
  end;
```
