---
description: Frequently asked questions
---

# FAQ

{% tabs %}
{% tab title="Elps" %}
## Is there a list of builtin elps functions?

github.com/luthersystems/elps/lisp/builtins.go

## Is there a version of the key-argument approach of function definition where all arguments are required?

You can combine key-argument with required fields, if you specify the required fields first. There is not a way to make key-arg fields required.

## What does \`default\` do?

If the first argument is nil or false it will return the second argument, otherwise it will return the first.

## Can you call go code from elps?

https://github.com/luthersystems/elps/blob/master/docs/embed.md discusses how to call Go from elps.

## What is the difference between \`\[\` and \`(\` ?

They are equivalent, and only cosmetic to make reading clearer.

## How does \`now\` work in elps?

`now` is an RFC3339 timestamp that is set by shiroclient, and is common across multiple simulations of a transaction.
{% endtab %}
{% endtabs %}

##
