---
description: >-
  Functions for manipulating decimal values with proper rounding. This should be
  used for modeling math on money amounts.
---

# Copy of Decimals

```
(use-package 'decimal)
```

You must convert your numbers into decimal types using the helpers, and then use the decimal functions on these decimal types.

It makes heavy usage of the `github.com/shopspring/decimal` go package.

## to-decimal

Coerce a decimal in string, number, or decimal format into a decimal type.

```
(to-decimal "1.22")
#<native value: decimal.Decimal>
```

## decimal-string

Convert a decimal type into a string.

```
shiro> (decimal-string (to-decimal 1.22))
"1.22"
```

## decimal-float

Convert a decimal type into a float.

```
shiro> (decimal-float (to-decimal "1.22"))
1.22
```

## decimal+

Add var arg decimals. Arguments are coerced into a decimal type.

```
  (assert-string= "6.79" (decimal-string (decimal+ 1 4.56 1.23)))
```

## decimal-

Subtract var arg decimals. Arguments are coerced into a decimal type.

```
  (assert-string= "3.33" (decimal-string (decimal- 4.56 1.23)))
```

## decimal\*

Multiply var arg decimals. Arguments are coerced into a decimal type.

```
  (assert-string= "24" (decimal-string (decimal* 2 3 4)))
```

## decimal/

Divide var arg decimals. Arguments are coerced into a decimal type.

```
  (assert-string= "1" (decimal-string (decimal/ 4 2 2)))
```

## decimal=

Check equality of two decimals. Arguments are coerced into a decimal type.

```
  (assert (decimal= 2 (decimal- 5.00 3)))
```

## decimal<

Check less than of two decimals. Arguments are coerced into a decimal type.

```
  (assert (decimal< 2 5))
```

## decimal<=

Check less than or equal of two decimals. Arguments are coerced into a decimal type.

```
  (assert (decimal<= 2 5))
```

## decimal>

Check greater than of two decimals. Arguments are coerced into a decimal type.

```
  (assert (decimal> 5 2))
```

## decimal>=

Check greater than or equal of two decimals. Arguments are coerced into a decimal type.

```
  (assert (decimal>= 5 2))
```

## decimal-pow

Raise a decimal to a power. Arguments are coerced into a decimal type.

```
  (assert-string= "25" (decimal-string (decimal-pow 5 2))))
```

## decimal-floor

Compute the floor of a decimal. Arguments are coerced into a decimal type.

```
  (assert-string= "2" (decimal-string (decimal-floor 2.99))))
```

## decimal-ceil

Compute the ceiling of a decimal. Arguments are coerced into a decimal type.

```
  (assert-string= "3" (decimal-string (decimal-ceil 2.99))))
```

## decimal-abs

Compute the absolute value of a decimal. Arguments are coerced into a decimal type.

```
  (assert-string= "2.99" (decimal-string (decimal-abs -2.99)))
```

## decimal-sign

Get the sign (-1, 0, 1) of a decimal. Arguments are coerced into a decimal type.

```
  (assert (= -1 (decimal-sign -2)))
```

## decimal-round

Round a decimal. Several rounding modes are supported (see shopspring repo for more details). Arguments are coerced into a decimal type.

```
  (assert-string= "1.23" (decimal-string "1.23"))
  (assert-string= "1.3" (decimal-string "1.29" :places 1))
  (assert-string= "1.3" (decimal-string "1.29" :places 1 :rounding 'fixed))
  (assert-string= "1.29" (decimal-string "1.299" :places 2 :rounding 'truncate))
  (assert-string= "1.2" (decimal-string "1.23" :places 1 :rounding 'bank))
```
