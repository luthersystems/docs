# Luther Middleware Docs

This repository contains documentation and guides for building, updating, and testing middleware within the [Luther Platform](https://github.com/luthersystems) ecosystem.

---

## 📚 Documentation

- **[Entity Update Guide](./entity-update-guide.md)**
  Learn how to safely add, remove, or modify entity fields and enum values in a backwards-compatible way, with conventions for API and phylum validation, and best practices for testing.

- **Martin: End-to-end Testing**

  - [martin/README.md](./martin/README.md): Introduction and usage of the `martin` integration test tool (YAML-to-Postman workflow).
  - [martin/proxy.md](./martin/proxy.md): How to run martin tests through a local proxy, both with Docker and directly on your machine.

All documentation is maintained in Markdown and intended to provide practical guidance for engineers working on process logic and middleware for Luther-connected services.

---

## 🏗️ Related Repositories

- **[`svc`](https://github.com/luthersystems/svc): Building Blocks for Middleware**
  The [`luthersystems/svc`](https://github.com/luthersystems/svc) package provides the foundational building blocks for writing middleware, connectors, and integrations in the Luther Platform. It includes modules for gRPC and HTTP middleware, observability, document storage, error handling, and more.
  _See the [`svc` README](https://github.com/luthersystems/svc/blob/main/README.md) for architecture, usage, and integration patterns._

- **[`lutherauth-sdk-go`](https://github.com/luthersystems/lutherauth-sdk-go): Authentication & Claims Handling**
  [`lutherauth-sdk-go`](https://github.com/luthersystems/lutherauth-sdk-go) provides Go utilities for extracting and validating JWT claims issued by [LutherAuth](https://github.com/luthersystems/lutherauth), the centralized authentication service for the Luther Platform.
  This SDK enables secure user authentication, CSRF protection, and seamless integration with OIDC-compliant identity providers such as Cognito and AzureAD.
  _Use this SDK to authenticate users, validate JWTs, and enforce access control in your middleware and services.
  See the [`lutherauth-sdk-go` documentation](https://github.com/luthersystems/lutherauth-sdk-go) for details and code samples._

- **[`shiroclient-sdk-go`](https://github.com/luthersystems/shiroclient-sdk-go): JSON-RPC Client for Distributed Logic**
  [`shiroclient-sdk-go`](https://github.com/luthersystems/shiroclient-sdk-go) is a Go-based JSON-RPC client for interacting with the **shiroclient gateway**, a Luther Platform component that mediates access to distributed _common operations scripts_ (phylum) running on substrate/fabric.
  With this SDK, you can execute requests and receive responses from ELPS logic, schedule batch jobs, manage private data, perform health checks, and manage phylum versions across distributed networks.
  _See the [`shiroclient-sdk-go` GoDoc](https://pkg.go.dev/github.com/luthersystems/shiroclient-sdk-go/shiroclient) for full usage and transaction flow details._
