---
description: >-
  Martin is an integration testing tool based on Postman/Newman. Tests are
  defined in one or more yaml files. The martin CLI generates a single postman
  collection file by combining these tests. It is al
---

# Copy of Martin: End-to-end Testing

{% hint style="info" %}
This is a copy of [https://bitbucket.org/luthersystems/hyphae/src/master/martin/README.md](https://bitbucket.org/luthersystems/hyphae/src/master/martin/README.md)
{% endhint %}

## Building

```
go install
martin -h
```

## General workflow

Collate test case files into single Postman collection. Note the file name postfix: `.postman_collection.json`

```
martin -n "Basic" cat examples/*{json,yaml} > examples/basic.postman_collection.json
```

Run newman on temporary collated collection

```
martin run -e ../../scaffold/tests/LocalDev.postman_environment.json examples/*{json,yaml}
```

## Test cases

Test cases usually consist of multiple steps, and are defined in the format described below, one per yaml file. They may contain placeholders that are resolved upon execution.

## Environment

Placeholder values for each environment are held in individual JSON files. These can be specified to the CLI when running a collection.

Example:

```javascript
{
    "id": "8b7b1d43-0e23-4c8b-817a-f391b973acf7",
    "name": "Local Dev",
    "values": [
        {
            "key": "SCHEME",
            "value": "http",
            "description": "",
            "enabled": true
        }
    ]
}
```

## Format

Supported fields:

`name` - Name of the test case. This is the name of the Postman folder.

`headers` - Headers to be included in every request/test step.

* `key`: Header name.
* `value`: Header value. Placeholders are resolved from the environment variables JSON.

`tests` - List of test steps. Translated to requests in the Postman collection.

* `name`: Name of test step.
* `path`: Request path. URL will be assembled from protocol and server + path automatically when running.
* `method`: HTTP method.
* `body`: Request body, verbatim.
* `test_script`: Test assertions in JavaScript. Translated to Postman tests.
