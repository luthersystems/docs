# Frequently Asked Questions

## 🧩 General

### What happens if a system I want to add isn’t on the connector list?

No problem! Click **"Can’t find connector"** on the Add Connector screen.
It’ll walk you through a few quick questions so we can start building the
connector you need. We’ll even give you **$500 in platform credit** for any new
connector request.

Prefer to talk it through? Book a quick call:  
[dev.luthersystems.com/tech-call](http://dev.luthersystems.com/tech-call)

---

### What if I need a backend setting that isn’t supported?

Let’s figure it out together. Message us on Discord or book a short call at  
[dev.luthersystems.com/tech-call](http://dev.luthersystems.com/tech-call)

---

### Can I contribute to building connectors?

Absolutely! We’re in the process of open-sourcing **ConnectorHub**, which
includes an SDK to help you build and contribute new connectors.

Stay tuned here:  
[github.com/luthersystems/connectorhub](https://github.com/luthersystems/connectorhub)

---

### Can Cursor suggest sample code for my application?

Yes! After onboarding, we spin up a **preconfigured repo** for you. Cursor is
fully set up to help and uses the `docs/` directory and built-in examples to
suggest relevant, modifiable code tailored to your app.

---

## 🧠 ELPS

### Is there a list of built-in ELPS functions?

Yes — check out:  
[elps/lisp/builtins.go](https://github.com/luthersystems/elps/blob/master/lisp/builtins.go)

---

### Can I require arguments when using key-argument style?

Partially — you can require arguments by specifying them first. There’s no way
to make key-arguments themselves required.

---

### What does `default` do?

It returns the second argument if the first is `nil` or `false`. Otherwise, it
returns the first argument.

---

### Can I call Go code from ELPS?

Yes — see the embedding guide:  
[elps/docs/embed.md](https://github.com/luthersystems/elps/blob/master/docs/embed.md)

---

### What’s the difference between `[` and `(`?

They are functionally equivalent — just syntactic sugar to help with readability.

---

### How does `now` work in ELPS?

`now` is an RFC3339 timestamp set by `shiroclient`. It’s consistent across all
simulations of a transaction, ensuring deterministic behavior.
