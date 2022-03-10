---
description: >-
  This page lists the recommended guidelines for developers building
  applications on the Luther platform
---

# Copy of Development Guidelines

1. Dates should be represented as `YYYY-MM-DD`
2. Money should be represented as `decimal-string` and use the `decimal` library
3. Calculations in the Oracle with large numbers should use `maths.Big`&#x20;
4. Use the `svcerr` package to return proper error codes in the Oracle
5. Follow the testing guidelines
6. The whole stack should run locally on your laptop at all times
7. Run all tests for every PR against the master branch
8. Run end-to-end Martin tests upon every successful deployment to integration
9. Avoid making breaking (backwards incompatible) data model changes
10. Use `lutherauth` for user authentication only, and enforce authorisation at application layer
