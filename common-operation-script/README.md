# Common Operation Script Documentation

Welcome to the documentation for the **Common Operation Script** system! This section of the docs provides everything you need to develop, test, and extend process logic on the Luther Platform using our unified scripting and process automation toolkit.

This documentation is organized into several subdirectories, each focused on a core area of development:

---

## Quickstart

- **Location:** [`quickstart/`](quickstart/)
- **Purpose:** Get up and running quickly! Learn local system requirements, how to launch your first network, add endpoints, update data models, and write your first unit test.
- **Key docs:**

  - [quickstart/README.md](quickstart/README.md) — Intro to the quickstart series
  - [quickstart/local-system-requirements.md](quickstart/local-system-requirements.md) — Required tools/software
  - [quickstart/run-your-first-network.md](quickstart/run-your-first-network.md) — Step-by-step network setup
  - [quickstart/add-your-first-endpoint.md](quickstart/add-your-first-endpoint.md), [quickstart/update-your-data-model.md](quickstart/update-your-data-model.md) — Extending your app
  - [quickstart/write-your-first-unit-test.md](quickstart/write-your-first-unit-test.md) — Unit testing basics

## Ellipse Development Language

- **Location:** [`ellipse-dev-language/`](ellipse-dev-language/)
- **Purpose:** Deep dive into the Ellipse (ELPS) scripting language for building process logic scripts.
- **Key docs:**

  - [ellipse-dev-language/README.md](ellipse-dev-language/README.md) — Ellipse language overview
  - [ellipse-dev-language/language-guide.md](ellipse-dev-language/language-guide.md) — Syntax, structure, and idioms
  - [ellipse-dev-language/standard-library.md](ellipse-dev-language/standard-library.md) — Available functions/utilities
  - [ellipse-dev-language/advanced.md](ellipse-dev-language/advanced.md) — Advanced topics
  - [ellipse-dev-language/ellipse-testing.md](ellipse-dev-language/ellipse-testing.md) — Testing scripts
  - [ellipse-dev-language/automated-migrations.md](ellipse-dev-language/automated-migrations.md) — Library for running very large migrations of data in your common operations script.

## Substrate Engine

- **Location:** [`substrate/`](substrate/)
- **Purpose:** Documentation for the low-level Substrate engine that executes process scripts and manages data.
- **Key docs:**

  - [substrate/README.md](substrate/README.md) — Substrate architecture
  - [substrate/decimals.md](substrate/decimals.md), [substrate/elpspath.md](substrate/elpspath.md), [substrate/substrate-indexes.md](substrate/substrate-indexes.md), [substrate/substrate-utilities.md](substrate/substrate-utilities.md), [substrate/templates.md](substrate/templates.md) — Specialized guides and APIs

## Development Guidelines

- **Location:** [`development-guidelines/`](development-guidelines/)
- **Purpose:** Best practices for development and contributing to process scripts and related components.
- **Key docs:**

  - [development-guidelines/guidelines.md](development-guidelines/guidelines.md) — Coding and contribution standards
  - [development-guidelines/phylum-best-practices.md](development-guidelines/phylum-best-practices.md) — Best practices for business logic (phylum)

## Testing Guidelines

- **Location:** [`testing-guidelines.md`](testing-guidelines.md)
- **Purpose:** General recommendations and requirements for testing your scripts and logic.

---

### How to Use This Section

- **Start with the [Quickstart](quickstart/)** if you are new to the Luther Platform or common operation scripts.
- **Consult the [Ellipse Development Language](ellipse-dev-language/)** section to write or extend your own scripts.
- **Review the [Substrate Engine docs](substrate/)** for detailed platform integration or when working close to the data layer.
- **Follow the [Development and Testing Guidelines](development-guidelines/guidelines.md)** to ensure code quality and maintainability.
