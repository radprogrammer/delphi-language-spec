# Delphi Language Specification

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Status: Draft](https://img.shields.io/badge/Status-Draft-orange.svg)](./spec/01-lexical.md#status)



## Overview

This repository provides a structured, version-controlled specification of the **Delphi programming language**. It is community-driven and unofficial, but designed to complement Embarcadero’s [official documentation](https://docwiki.embarcadero.com/RADStudio/en/Delphi_Language_Reference) with a normative, open, and maintained specification.

The specification is divided into numbered chapters, covering:

* **01 Lexical Structure** – identifiers, keywords, literals, operators, and compiler directives
* **02 Directives** – conditional compilation and compiler options
* **03 Grammar (EBNF)** – complete grammar of the Delphi language
* **04 Semantics: Types** – built-in and user-defined types
* **05 Semantics: Generics** – generic types and constraints
* **06 Semantics: Classes** – class declarations, inheritance, visibility
* **07 Semantics: Expressions** – operator precedence and evaluation
* **08 Semantics: Statements** – control flow, blocks, procedures
* **09 Attributes and Helpers** – metadata and helper types
* **10 Operator Resolution** – overload resolution rules
* **11 Managed Types and RTL Lifetimes** – memory management and finalization

## Goals

* Provide a **canonical, open reference** for the [Delphi](http://embarcadero.com/products/delphi) language.
* Capture **lexical rules, grammar, and semantics** in a structured way.
* Enable tool authors (parsers, linters, formatters, compilers) to rely on a **machine-readable spec**.
* Maintain historical versions and **track changes** across Delphi releases.

## Structure

```
├── spec/
│   ├── 01-lexical.md
│   ├── 02-directives.md
│   ├── 03-grammar-ebnf.md
│   ├── 04-semantics-types.md
│   ├── 05-semantics-generics.md
│   ├── 06-semantics-classes.md
│   ├── 07-semantics-expressions.md
│   ├── 08-semantics-statements.md
│   ├── 09-attributes-and-helpers.md
│   ├── 10-operator-resolution.md
│   └── 11-managed-types-and-rtlifetimes.md
├── data/
│   └── lexical.json   # machine-readable tables for keywords, operators, literals
├── tests/
│   └── tokenizer/     # tokenization validation examples
└── README.md
```

## Contributing

Contributions are welcome! Please:

1. Open an **issue** to discuss proposed changes (lexical rules, grammar, semantics).
2. Submit a **pull request** with edits to the relevant `spec/*.md` files.
3. Ensure any changes to keywords, operators, or literals are reflected in `data/lexical.json`.
4. Run the linter/CI checks locally (`npm run lint` or `make lint`).

### PR Template Checklist

* [ ] Mark change as **Normative** (alters language rules) or **Informative** (examples, notes).
* [ ] Update `/data/lexical.json` if tokens/keywords/literals are changed.
* [ ] Update **examples** to reflect changes.
* [ ] Add a note to the **Changelog** if normative.

## License

This project is licensed under the Apache 2.0 License — see the [LICENSE](LICENSE) file for details.

## Status

* ✅ Lexical structure in progress


---

*This project is currently not affiliated with or endorsed by Embarcadero Technologies. “Delphi” is a trademark of Embarcadero.*
