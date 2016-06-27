# tcl-Param
This tcl library provides typed parameters.

## Depends On

Project `tcl-Utils`


## Using The Library

To use this library to create typed parameters, you must include
`Param.tcl` in your application script.

```Tcl
  source "/some/path/to/your/copy/of/Param.tcl"
```

Declare and initialize the application's data values.

```Tcl
  set myInt [Param new integer 1]
  $myInt = 3
  $myInt = xx ;# error - Invalid

  set myDbl [Param new double 1.0]
  $myDbl = 3.5
  $myDbl = xx ;# error - Invalid

  Param typedef double Scale {>0 10.5}
  set scale [Param new Scale 1.0]
  $scale = 5.3
  $scale = 0.0 ;# error - out of range
  $scale = 10.5
  $scale = 10.50001 ;# error - out of range
```

## Base Data Types

The Param library supports the `double`, `integer`, and `string` base data
types. Base types are used to define application specific types using the
`typedef` command. A corresponding typedef is created for each basetype. Base
typedefs do not have a range and support all valid, type-specific values.

Several base type aliases are also defined.

| Base Type | Aliases         |
| --------- | --------------- |
| `double`  | `real`, `float` |
| `integer` | `int`           |
| `string`  | `text`          |

## Typedef Data Types

An application can declare its own types using the `typedef` command. A typedef
has its own type name and an optional, type-specific value range. When assigning
a parameter value, this range will be enforced. A Tcl `error` is triggered if
the assigned value violates the range.

```tcl
Param typedef { basetype name {range {}} {replace 0} }
```

### Typedef double range

Range: `?Inf|?>|=?minLimit ?Inf|?<|=?maxLimit??`

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

### Typedef integer range

Range: `?Inf|minLimit ?Inf|maxLimit??`

An `integer` value supports a `minLimit`, `maxLimit` range. Use *Inf* for an
unlimited value. If the range is empty, `{Inf Inf}` is used.

| Range     | Comparison           |
| --------- | -------------------- |
| {0 10}    | 0 <= value <= 10     |
| {0}       | 0 <= value <= Inf    |
| {0 Inf}   | 0 <= value <= Inf    |
| {}        | Inf <= value <= Inf  |

### Typedef string range

Range: `?g|r<CHAR>pattern<CHAR>?i??t? ?minLen ?maxLen???`

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
