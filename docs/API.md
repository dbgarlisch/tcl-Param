# tcl-Param

Provides the *Param* command ensemble.

### Table of Contents
* [Param Commands](#param-commands)
  * [basetype](#basetype)
  * [getBasetype](#getbasetype)
  * [getBasetypes](#getbasetypes)
  * [getLimits](#getlimits)
  * [getRange](#getrange)
  * [getRangeSignature](#getrangesignature)
  * [getTypedefs](#gettypedefs)
  * [getValidator](#getvalidator)
  * [isBasetype](#isbasetype)
  * [isTypedef](#istypedef)
  * [new](#new)
  * [typedef](#typedef)
* [Usage Examples](#usage-examples)
  * [Base Type Params](#base-type-params)
  * [Typedef Params](#typedef-params)
* [Builtin Base Types](#builtin-base-types)
  * [double range](#double)
  * [integer range](#integer)
  * [string range](#string)
  * [enum range](#enum)
* [Custom Base Types](#custom-base-types)
  * [Base Type Definition File](#base-type-definition-file)
  * [Validators](#validators)
    * [Validator Variables](#validator-variables)
    * [Validator Commands](#validator-commands)


## Param Commands

Commands in this ensemble are accessed as:

```Tcl
Param <cmd> <options>
```
Where,

`cmd` - Is one of the Param command names listed below.

`options` - The cmd dependent options.

### basetype
```Tcl
Param basetype name ?vtorNamespace? ?replace?
```
Creates an application defined basetype. Returns nothing. See [Custom Base Types](#custom-base-types).

where,

`name` - The name of the base type being created. An error is triggered if `name` is not unique unless `replace` is set to 1.

`vtorNamespace` - The optional validator namespace. See [Validators](#validators). (default `name`)

`replace` - If 1, any existing base type definition will be replaced with this one. (default 0)

### getBasetype
```tcl
Param getBasetype typedefName
```
Returns the base type of a type definition.

where,

`typedefName` - The type definition name.

### getBasetypes
```tcl
Param getBasetypes
```
Returns a list of all base type names.


### getLimits
```tcl
Param getLimits type
```
Returns the limits for a given type.

where,

`type` - Is a type definition or base type name.

### getRange
```tcl
Param getRange type
```
Returns the range for a given type.

where,

`type` - Is a type definition or base type name.

### getRangeSignature
```tcl
Param getRangeSignature type
```
Returns the human readable range signature for a given type.

where,

`type` - Is a type definition or base type name.

### getTypedefs
```tcl
Param getTypedefs
```
Returns a list of all type definition names.

### getValidator
```tcl
Param getValidator type
```
Returns the validator namespace name for a given type.

where,

`type` - Is a type definition or base type name.

### isBasetype
```tcl
Param isBasetype name
```
Returns 1 if `name` is a valid base type name.

where,

`name` - The name being tested.

### isTypedef
```tcl
Param isTypedef name
```
Returns 1 if `name` is a valid type definition name.

where,

`name` - The name being tested.

### new
```tcl
Param new type ?val?
```
Creates a parameter object. Returns the parameter object.

where,

`type` - An existing type definition name.

`val` - The optional, initial parameter value. The default is type dependent.

### typedef
```tcl
Param typedef basetype name ?range? ?replace?
```
Creates an application defined parameter data type. A typedef has its own type name and an optional,
basetype-specific value range. When assigning a parameter value, this range will be enforced. A Tcl
`error` is triggered if the assigned value violates the range. The `basetype` must be one of the
[built-in](#base-data-types) or [user defined](#custom-base-types) base types. Returns nothing.

where,

`basetype` - One of the [built in](#builtin-base-types) or [user defined](#custom-base-types) base types. See the [basetype](#basetype) command.

`name` - The name of the type being created. An error is triggered if `name` is not unique unless `replace` is set to 1.

`range` - The optional, base type specific range. See [Ranges](#ranges). (default {})

`replace` - If 1, any existing type definition will be replaced with this one. (default 0)

## Parameter Object Commands
All parameter objects support the following commands. Additional commands may be added by a
particular base type (see [VVTOR::objectProto_](#validator-variables)).

### =
```tcl
$param = val
```
Assignes a new value to the parameter. An error is triggered if the value
violates the parameter type range. Returns the assigned value.

where,

`val` - The value being assigned.

### setValue
```tcl
$param setValue val
```
Assignes a new value to the parameter. An error is triggered if the value
violates the associated range. Returns the assigned value.

where,

`val` - The value being assigned.

### getValue
```tcl
$param getValue
```
Returns the current parameter value.

### getType
```tcl
$param getType
```
Returns the paramter type as passed to [Param new](#new).

### getLimits
```tcl
$param getLimits
```
Returns the parsed `range` value as returned by [VTOR::parseRange](#parseRange).
The exact structure of this value is base type dependent and is typically not
used or needed by an application except for debugging.

### getRange
```tcl
$param getRange
```
Returns the unparsed `range` value passed to [Param typedef](#typedef).

### dump
```tcl
$param dump
```
Returns a text representation of the parameter as
```
"${self_}: type($type_) value($val_)".
```

## Usage Examples

### Base Type Params
Base types that support typedefs (see [VTOR::createTypedef_](#validator-variables)) can be used
for parameters. These parameters will have an unlimited range.
```
set poi [Param new integer 33]
$poi = 77

set pod [Param new double 33.33]
$pod = 77.77

# real is an alias of double
set por [Param new real 44.55]
$por = 66.88

set pos [Param new string {hello}]
$pos = {world!}

# enum requires a range! It must be typedef'ed.
set enum [Param new enum] ;# ERROR
```


### Typedef Params
Typedefs can be used to define ranges for base types.
```
Param typedef integer iMonth {1 12}
set imon [Param new iMonth 3]
$imon = 7
$imon setValue 8
$imon = 13 ;# ERROR

Param typedef double Scale {>0 10}
set scale [Param new Scale 0.9]
$scale = 0.4
$scale setValue 5.5
$scale = 0 ;# ERROR

# regex string typedef
Param typedef string BigStrR {r/^big\S{1,4}$/it}
set bigStr [Param new BigStrR "BigStr"]
$bigStr = "Big1234"
$bigStr = "big" ;# ERROR
$bigStr setValue "Big12345" ;# ERROR

Param typedef string BigStrG {g/big*/it 4 7}
set bigStrg [Param new BigStrR "BigStr"]
$bigStrg = "Big1234"
$bigStrg = "big" ;# ERROR
$bigStrg setValue "Big12345" ;# ERROR

Param typedef enum ColorComponent {red|green|blue=5|alpha}
set ccomp [Param new ColorComponent "red"]
$ccomp setValue "green"
$ccomp = "blue"
# Call enum-defined getId object command
puts "$ccomp id([$ccomp getId])" ;# id is 5 for "blue"
# Call enum-defined getTokenId typedef command
puts "ColorComponent getTokenId(alpha=[ColorComponent getTokenId alpha])"

# print a table of base type range signatures
set fmt "| %-15.15s | %-60.60s |"
set dashes [string repeat - 100]
puts {}
puts [format $fmt "Basetype" "Range Signature"]
puts [format $fmt $dashes $dashes]
foreach basetype [Param getBasetypes] {
 puts [format $fmt $basetype [Param getRangeSignature $basetype]]
}
```


## Builtin Base Types

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

### Ranges

#### double

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

#### integer

Range: `?Inf|minLimit ?Inf|maxLimit??`

An `integer` value supports a `minLimit`, `maxLimit` range. Use *Inf* for an
unlimited value. If the range is empty, `{Inf Inf}` is used.

| Range     | Comparison           |
| --------- | -------------------- |
| {0 10}    | 0 <= value <= 10     |
| {0}       | 0 <= value <= Inf    |
| {0 Inf}   | 0 <= value <= Inf    |
| {}        | Inf <= value <= Inf  |

#### string

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

#### enum

Range: `?|<CHAR>?token?=integer? ?|token?=integer??...`

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


## Custom Base Types

New base types can be added to the Param library. A new base type can be
explicitly added by an application using the [basetype](#basetype) command
or automatically added by creating a
[Base Type Definition File](#base-type-definition-file).

Each base type uses a validator to implement its behavior.
See [Validators](#validators).

### Base Type Definition File

The Param library auto loads all base type definition files found in the `basetypes`
subdirectory. A base type definition file contains the named validator's implementation.
Base type definition files require a naming convention.
```
NAME?-VTOR?.basetype.tcl
```
where,

`NAME` - The base type's name.

`VTOR` - The validator's name. If not provided, `VTOR` defaults to `NAME`.

For example, a base type definition file named:
* *real.basetype.tcl*
  * Defines a base type named *real*
  * Implements a validator named *real*
* *real-vtor.basetype.tcl*
  * Defines a base type named *real*
  * Implements a validator named *vtor*

### Validators

A validator is a Tcl namespace that provides one or more procs and variables used by the
Param library. The validator namespace must be unique and must exist before the call
to `Param basetype`.

A validator implements the following variable and procs. In the following sections, VTOR
is a place holder for the actual validator namespace name.
```tcl
namespace eval VTOR {
  variable rangeSignature_ {signature-pattern}                          ;# REQUIRED
  variable createTypedef_ 1                                             ;# OPTIONAL
  variable objectProto_ {commands added to objects of basetype}         ;# OPTIONAL
  variable staticProto_ {static commands added to typedefs of basetype} ;# OPTIONAL
  proc parseRange { range }                                             ;# REQUIRED
  proc validate { value limits }                                        ;# REQUIRED
  proc registerAliases { }                                              ;# OPTIONAL
}
```

#### Validator Variables

`VTOR::rangeSignature_` - Provides the base type's human readable range signature
pattern string. This should describe the range value expected by the validator's
parseRange proc. This string is primarily used for error reporting. REQUIRED.

`VTOR::createTypedef_` - If 1, a typedef is created with the same name as the base
type. If 0, a typedef is not created. OPTIONAL (default 1).

`VTOR::objectProto_` - Defines one or more base type specific variables or procs
that are added to all Param instances of this base type. See [Param new](#new).
These variables and procs extend a Param instance beyond its base procs and
variables. See XXXX. OPTIONAL (default {}).

`VTOR::staticProto_` - Defines one or more typedef specific variables or procs
that are added to all typedefs of this base type. See [Param typedef](#typedef).
These variables and procs extend a typedef beyond its base procs and
variables. See XXXX. OPTIONAL (default {}).

#### Validator Commands

##### parseRange
```Tcl
VTOR::parseRange { range }
```
Parses the range value passed to a typedef that uses this base type. Invoked by
[Param typedef](#typedef). Returns a parsed representation of `range`. If `range`
is invalid, a Tcl error should be triggered. REQUIRED.

The returned value is never used outside of the validator. It is stored as-is and
later passed in the `limits` argument of [VTOR::validate](#validate). Since `parseRange`
is only called once per typedef, it is more efficient to do all heavy processing
here so that the more frequent calls to [VTOR::validate](#validate) will be as fast as
possible.

where,

`range` - A range value passed to [Param typedef](#typedef).

example,
```
namespace eval integer {
  variable rangeSignature_ {?Inf|minLimit ?Inf|maxLimit??}
  
  proc parseRange { range } {
    set re {^(Inf|[+-]?\d+)(?: +(Inf|[+-]?\d+))?$}
    set range [string trim $range]
    if { 0 == [llength $range] } {
      set min Inf
      set max Inf
    } elseif { ![regexp -nocase $re $range -> min max] ||
        ![parseLimit min] || ![parseLimit max] } {
      variable rangeSignature_
      return -code error "Invalid range: '$range'. Should be '$rangeSignature_'"
    }
    set ret [dict create]
    setLimit ret MIN $min
    setLimit ret MAX $max
    return $ret
  }
}
```


##### validate
```
VTOR::validate { value limits }
```
Validates a value assigned to a parameter instance that uses this base type.
Invoked by `$param = value`. Returns 1 if `value` is valid or 0 if invalid.
REQUIRED.

where,

`value` - The value being assigned to a paramter instance.

`limits` - The parsed representation of `range` returned by
[VTOR::parseRange](#parseRange).

example,
```
namespace eval integer {
  proc validate { value limits } {
    set ret 1
    if { [dict exists $limits MIN] && $value < [dict get $limits MIN]} {
      set ret 0
    } elseif { [dict exists $limits MAX] && $value > [dict get $limits MAX]} {
      set ret 0
    }
    return $ret
  }
}
```

##### registerAliases
```
VTOR::registerAliases { }
```
Creates one or more aliases for a base type. Invoked once by
[Param basetype](#basetype). Returns nothing. OPTIONAL.

example,
```
namespace eval integer {
  proc registerAliases { } {
    ::Param basetype int [namespace current]
  }
}
```
