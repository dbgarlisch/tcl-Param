# Builtin Base Types

The Param library supports the `double`, `integer`, `string`, and `enum` base data
types. Base types are used to define application specific types using the `typedef`
command. If appropriate, a corresponding typedef is created for each basetype. Base
typedefs do not have a range and support all valid, type-specific values.

Several base type aliases are also defined.

| Base Type | Aliases         |
| --------- | --------------- |
| `double`  | `real`, `float` |
| `integer` | `int`           |
| `string`  | `text`          |

### Table of Contents
* [double](#double)
  * [Double Range](#double-range)
  * [Double Object Commands](#double-object-commands)
* [integer](#integer)
  * [Integer Range](#integer-range)
  * [Integer Object Commands](#integer-object-commands)
* [string](#string)
  * [String Range](#string-range)
  * [String Object Commands](#string-object-commands)
* [enum](#enum)
  * [Enum Range](#enum-range)
  * [Enum Object Commands](#enum-object-commands)
  * [Enum Typedef Commands](#enum-typedef-commands)

## double
### Double Range
```
?Inf|?>|=?minLimit ?Inf|?<|=?maxLimit??
```
A `double` value supports a `minLimit`, `maxLimit` range. You can control the
value comparison with an optional prefix. The `minLimit` value supports the
*=* (value >= `minLimit`) and *>* (value > `minLimit`) prefixes. The `maxLimit` value
supports the *=* (value <= `maxLimit`) and *<* (value < `maxLimit`) prefixes. If no
prefix is given, *=* is used. Use *Inf* for an unlimited value. If the range is
empty, `{Inf Inf}` is used.

| Range     | Comparison           |
| --------- | -------------------- |
| {0 10}    | 0.0 <= value <= 10.0 |
| {>0 <10}  | 0.0 < value < 10.0   |
| {0}       | 0.0 <= value <= Inf  |
| {0 Inf}   | 0.0 <= value <= Inf  |
| {}        | Inf <= value <= Inf  |

### Double Object Commands

#### $obj +=
```Tcl
$obj += val
```
Increments parameter by val.

where,

`val` - The increment.

#### $obj -=
```Tcl
$obj -= val
```
Decrements parameter by val.

where,

`val` - The decrement.

#### $obj *=
```Tcl
$obj *= val
```
Multiply parameter by val.

where,

`val` - The multiplier.

#### $obj /=
```Tcl
$obj /= val
```
Divide parameter by val.

where,

`val` - The divisor.


## integer
### Integer Range
```
?Inf|minLimit ?Inf|maxLimit??
```
An `integer` value supports a `minLimit`, `maxLimit` range. Use *Inf* for an
unlimited value. If the range is empty, `{Inf Inf}` is used.

| Range     | Comparison           |
| --------- | -------------------- |
| {0 10}    | 0 <= value <= 10     |
| {0}       | 0 <= value <= Inf    |
| {0 Inf}   | 0 <= value <= Inf    |
| {}        | Inf <= value <= Inf  |

### Integer Object Commands

#### $obj +=
```Tcl
$obj += val
```
Increments parameter by val.

where,

`val` - The increment.

#### $obj -=
```Tcl
$obj -= val
```
Decrements parameter by val.

where,

`val` - The decrement.

#### $obj *=
```Tcl
$obj *= val
```
Multiply parameter by val.

where,

`val` - The multiplier.

#### $obj /=
```Tcl
$obj /= val
```
Divide parameter by val.

where,

`val` - The divisor.


## string
### String Range
```
?g|r<CHAR>pattern<CHAR>?i??t? ?minLen ?maxLen???
```
A `string` value supports a `pattern` match and `minLen`, `maxLen` range.

The `g` prefix specifies a Tcl *glob* comparison.
The `r` prefix specifies a Tcl *regexp* comparison.

The `pattern` is delimted by a matching `<CHAR>` pair. It can be any character
not used in `pattern`.

The `i` suffix specifies a case-insensitive comparison.
The `t` suffix specifies the value should have leading and trailing whitespace
trimmed before the comparison is performed.

If `minLen` is specified, the value length must be >= `minLen`.
If `maxLen` is specified, the value length must be <= `maxLen`.


| Range              | Comparison                          |
| ------------------ | ----------------------------------- |
| {r/^big.*$/it 4 7} | regexp, nocase, trim, length 4 to 7 |
| {g/big*/it 4 7}    | glob, nocase, trim, length 4 to 7   |

### String Object Commands

#### $obj +=
```Tcl
$obj += val
```
Appends val to the string.

where,

`val` - The appendage.

## enum
### Enum Range
```
?|<CHAR>?token?=integer? ?|token?=integer??...
```

An `enum` value supports a fixed list of token values. Each token has an
asociated integer id. The valid tokens are defined by a delimited list of
`token=integer` pairs. If an integer id is not provided, it will be
assigned the previous token's id value plus one. If there is no previous
token, the id is set to zero.

The default delimiter is the vbar '|' character. The delimiter can be changed
by prefixing the list with a 2-character `|<CHAR>` sequence where `CHAR` is
the new delimiter.

Because all enum typedefs must have a non-empty range, an `enum` typedef is
**not** created.

All `enum` parameters support the `$param getId` command. This returns the
integer id associated with the currently assigned enum token.

| Range                       | Same as                           |
| --------------------------- | --------------------------------- |
| {red\|green\|blue\|alpha}   | {red=0\|green=1\|blue=2\|alpha=3} |
| {red\|green\|blue\|alpha}   | {\|,red,green,blue,alpha}         |
| {top=4\|bot\|left=8\|right} | {top=4\|bot=5\|left=8\|right=9}   |

### Enum Object Commands

#### $obj getId
```Tcl
$obj getId
```
Returns the enum's current id value.

### Enum Typedef Commands

#### $obj getTokenId token
```Tcl
$obj getId
```
Returns the token's associated id value.

where,

`token` - The enum token string.
