---
description: Path queries over ellipse objects.
---

# Ellipse Path

Inspired by jq simple selectors, but over elps objects! This library allows concise and easy manipulation of elps data. `parse_tests.go` has a comprehensive set of tests to demonstrate typical queries. You can readily compare these results against jq using the jq playground: [https://jqplay.org](https://jqplay.org/).

We only support simple selectors that output a single value. All paths are strings that must begin with `.`. A path consists of a series of selectors, and performs operations (both mutating and non-mutating versions): 1) Get, 2) Set, 3) Delete, 4) Nil. These operations take ELPS LVals as input, and return an elps LVal.

In the below examples we use JSON to represent elps data structures.

## Index & Dot Selectors

Index and dot examples: `.regularKey`, `["$special key"]`, `[0]`

***Object:*** `{"hello":"world"}`

***Path:*** `.hello`

***Output:*** `"world"`

## Range Selectors

Range examples: `[1:2]`, `[:2]`, `[1:]`, `[:]`

***Object:*** `["a","b","c"]`

***Get Path:*** `.[1:]`

***Output:*** `["b","c"]`

## Iterator Selectors

Iterator selectors execute a path selector on each element of an array.

***Object:*** `{"a":[ { "b": 2 }, 0, {"b": 3 } ] }`

***Get Path:*** `.a[].b`

***Output:*** `[2,null,3]`

*Note*: jq would throw an error since `.b` on `0` is an error, however elpspath iterators returns `null` when the selector throws an error.

Like in jq, nested iterators are collapsed in the return results:

***Object:*** `[ {"a":[ { "b": 2 }, {"b": 3 } ] }, {"a":[ { "b": 4 } ]} ]`

***Get Path:*** `.[].a[].b` ***Output:*** \[2,3,4\]

---

## Differences from jq

-   Range selectors such as `[:2]` is treated as a query of two paths: `[0]`, `[1]`, where the query results are wrapped in array `[...]`
-   elpspath supports `[:]` notation which is equivalent to `[0:]`.
-   Iterator notation `[]` will skip over some errors that jq will throw an error.
-   jq iterators have a notation of "multiple outputs" where each output of an iterator is printed on a new line. elpspath iterators return multiple outputs wrapped in an array, as jq would if there was an outer braces `[a[].b]` array constructor surrounding the iterator query.

---
