# Custom Base Types

New base types can be added to the Param library. A new base type can be
explicitly added by an application using the [Param basetype](API.md#param-basetype)
command or automatically added by creating a
[Base Type Definition File](#base-type-definition-file).

Each base type uses a validator to implement its behavior.
See [Validators](#validators).

### Table of Contents
* [Base Type Definition File](#base-type-definition-file)
* [Validators](#validators)
  * [Validator Variables](#validator-variables)
  * [Validator Commands](#validator-commands)
    * [parseRange](#parserange)
    * [validate](#validate)
    * [registerAliases](#registeraliases)

## Base Type Definition File

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

## Validators

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

### Validator Variables

`VTOR::rangeSignature_` - Provides the base type's human readable range signature
pattern string. This should describe the range value expected by the validator's
parseRange proc. This string is primarily used for error reporting. REQUIRED.

`VTOR::createTypedef_` - If 1, a typedef is created with the same name as the base
type. If 0, a typedef is not created. OPTIONAL (default 1).

`VTOR::objectProto_` - Defines one or more base type specific variables or procs
that are added to all Param instances of this base type. See [Param new](API.md#param-new).
These variables and procs extend a Param instance beyond its base procs and
variables. See XXXX. OPTIONAL (default {}).

`VTOR::staticProto_` - Defines one or more typedef specific variables or procs
that are added to all typedefs of this base type. See [Param typedef](API.md#param-typedef).
These variables and procs extend a typedef beyond its base procs and
variables. See XXXX. OPTIONAL (default {}).

### Validator Commands

#### parseRange
```Tcl
VTOR::parseRange { range }
```
Parses the range value passed to a typedef that uses this base type. Invoked by
[Param typedef](API.md#param-typedef). Returns a parsed representation of `range`. If `range`
is invalid, a Tcl error should be triggered. REQUIRED.

The returned value is never used outside of the validator. It is stored as-is and
later passed in the `limits` argument of [VTOR::validate](#validate). Since `parseRange`
is only called once per typedef, it is more efficient to do all heavy processing
here so that the more frequent calls to [VTOR::validate](#validate) will be as fast as
possible.

where,

`range` - A range value passed to [Param typedef](API.md#param-typedef).

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


#### validate
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

#### registerAliases
```
VTOR::registerAliases { }
```
Creates one or more aliases for a base type. Invoked once by
[Param basetype](API.md#param-basetype). Returns nothing. OPTIONAL.

example,
```
namespace eval integer {
  proc registerAliases { } {
    ::Param basetype int [namespace current]
  }
}
```
