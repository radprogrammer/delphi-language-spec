# Delphi Language Specification

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Status: Draft](https://img.shields.io/badge/Status-Draft-orange.svg)](./spec/01-lexical.md#status)



## Overview

This repository provides a structured, version-controlled specification of the **Delphi programming language**. It is community-driven and unofficial, but designed to complement Embarcadero’s [official documentation](https://docwiki.embarcadero.com/RADStudio/en/Delphi_Language_Reference) with a normative, open, and maintained specification.


## Goals

* Provide a **canonical, open reference** for the [Delphi](http://embarcadero.com/products/delphi) language.
* Capture **lexical rules, grammar, and semantics** in a structured way.
* Enable tool authors (parsers, linters, formatters) to rely on a **machine-readable spec**.
* Maintain historical versions and **track changes** across Delphi releases.

## Structure

```
├── spec/
│   ├── 01-lexical.md                        # identifiers, keywords, literals, operators, and compiler directives
│   ├── 02-directives.md                     # conditional compilation and compiler options
│   ├── 03-grammar-ebnf.md                   # complete grammar of the Delphi language
│   ├── 04-semantics-types.md                # built-in and user-defined types
│   ├── 05-semantics-generics.md             # generic types and constraints
│   ├── 06-semantics-classes.md              # class declarations, inheritance, visibility
│   ├── 07-semantics-expressions.md          # operator precedence and evaluation
│   ├── 08-semantics-statements.md           # control flow, blocks, procedures
│   ├── 09-attributes-and-helpers.md         # metadata and helper types
│   ├── 10-operator-resolution.md            # overload resolution rules
│   └── 11-managed-types-and-rtlifetimes.md  # memory management and finalization
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
* ✅ Directives in progress


---

*This project is currently not affiliated with or endorsed by Embarcadero Technologies. “Delphi” is a trademark of Embarcadero.*
