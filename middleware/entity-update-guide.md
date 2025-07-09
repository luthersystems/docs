---
description: This is a guide on how to add, remove fields including enum values.
---

# Entity Update Guide

### Compatibility

The general aim is that the Oracle API should not be broken by a change to existing entities, e.g. a client.

To put it another way: API clients at the latest major version should be able to work with old entities.

#### Backwards-compatible changes

* Adding a field

Adding a field to the API request and response and the corresponding entity can be non-breaking, as long as the behaviour of the API doesn't change.

* Adding a value to an enum

An enum that is only used in the request can be expanded to include new values.

* Adding an output-only field

Fields supplied in the response only may be added.

#### Backwards-incompatible (breaking) changes

* Removing or renaming a field, or enum value

This is a breaking change. This includes changing the type of a field.

### How to add / remove a field

* API endpoint (Oracle)

The API is defined using protobuf v3 and the spec is under the `api` dir.

To add a field, you need to update `./pb/oracle.proto` with the correct field type and a unique field number. Careful not to use an existing field number or one `reserved`.

To remove a field, you also need to specify the field number (and/or name) as `reserved`. This will make the protobuf compiler to complain if a developer tries to use the same numbers in the future.

* Validation

Fields with specific validation rules will have those validations implemented in the `phylum`.

By convention, the validation function, if any, is in a file with the same name as the entity being modified, e.g. for the `client` entity, the file is `client.lisp`.

Similarly, the function is by convention named according to the JSON path, e.g. for the client title, the function is named `validate-client-details-title-or-nil`.

So, to add or remove fields, you should implement or delete the corresponding validation.

* Tests

You should maintain any tests affected by the field change, e.g. the following tests:

*   Oracle (integration)

    `oracleserv/oracle/oracle`
*   Phylum (unit)

    `phylum/phylum_test.lisp`
*   Martin (e2e)

    `tests`
