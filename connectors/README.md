# Connectors Documentation

This directory provides documentation and references for building and configuring **connectors** in the Luther Platform ecosystem.

## ConnectorHub Overview

ConnectorHub is the central component that enables seamless, event-driven integration between enterprise systems and Luther’s Common Operations Script (_phylum_). It manages all cross-system requests, routes events to external services via connectors, and ensures secure, auditable process automation across organizational boundaries.

- For a detailed introduction, see [connectorhub.md](./connectorhub.md).

A connector is a reusable integration to a third-party system (e.g., Equifax, Postgres, Stripe, Camunda, AWS SES, Invoice Ninja, GoCardless, etc.). The platform supports a growing catalog of connectors, which can be enabled, mocked, or configured in your project’s `fabric/connectorhub.yml` file.

---

## Full Connector Reference & Catalog

A full and continually updated list of supported and upcoming connectors, including setup and configuration guides, can be found at:

👉 **[Luther Connectors Catalog](https://dev.luthersystems.com/connectors)**

---

## What’s in this directory?

- [connectorhub.md](./connectorhub.md):

  - Overview of the ConnectorHub architecture, event functions, ELPS helper functions, connector factory patterns, and phylum unit testing for connectors.
  - Step-by-step configuration guides and examples for each major connector (AWS SES, Camunda, Equifax, GoCardless, Invoice Ninja, PDF Service, Postgres, Stripe, etc.)

Use these docs to implement, configure, and test connectors for new or existing business processes in the Luther Platform.
