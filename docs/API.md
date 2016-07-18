# tcl-Param

Provides the *Param* command ensemble.

### Table of Contents
* [Param Commands](#param-commands)
  * [basetype](#param-basetype)
  * [getBasetype](#param-getbasetype)
  * [getBasetypes](#param-getbasetypes)
  * [getLimits](#param-getlimits)
  * [getRange](#param-getrange)
  * [getRangeErrorCmd](#param-getrangeerrorcmd)
  * [getRangeSignature](#param-getrangesignature)
  * [getTypedefs](#param-gettypedefs)
  * [getValidator](#param-getvalidator)
  * [isBasetype](#param-isbasetype)
  * [isTypedef](#param-istypedef)
  * [new](#param-new)
  * [typedef](#param-typedef)
  * [setRangeErrorCmd](#param-setrangeerrorcmd)
* [Parameter Objects](#parameter-objects)
  * [Parameter Object Variables](#parameter-object-variables)
    * [$self_](#objself_)
    * [$type_](#objtype_)
    * [$val_](#objval_)
  * [Parameter Object Commands](#parameter-object-commands)
    * [=](#obj-)
    * [dump](#obj-dump)
    * [getLimits](#obj-getlimits)
    * [getRange](#obj-getrange)
    * [getRangeErrorCmd](#obj-getrangeerrorcmd)
    * [getType](#obj-gettype)
    * [getValue](#obj-getvalue)
    * [setRangeErrorCmd](#obj-setrangeerrorcmd)
    * [setValue](#obj-setvalue)
* [Range Error Commands](#range-error-commands)
* [Usage Examples](#usage-examples)
  * [Base Type Params](#base-type-params)
  * [Typedef Params](#typedef-params)


## Param Commands

Commands in this ensemble are accessed as:

```Tcl
Param <cmd> <options>
```
Where,

`cmd` - Is one of the Param command names listed below.

`options` - The cmd dependent options.

See also [BuiltIn Base Types](BuiltInBaseTypes.md) and [Custom Base Types](CustomBaseTypes.md).


### Param basetype
```Tcl
Param basetype name ?vtorNamespace? ?replace?
```
Creates an application defined basetype. Returns nothing. See [Custom Base Types](CustomBaseTypes.md).

where,

`name` - The name of the base type being created. An error is triggered if `name` is not unique unless `replace` is set to 1.

`vtorNamespace` - The optional validator namespace. See [Validators](CustomBaseTypes.md#validators). (default `name`)

`replace` - If 1, any existing base type definition will be replaced with this one. (default 0)

### Param getBasetype
```tcl
Param getBasetype typedefName
```
Returns the base type of a type definition.

where,

`typedefName` - The type definition name.

### Param getBasetypes
```tcl
Param getBasetypes
```
Returns a list of all base type names.


### Param getLimits
```tcl
Param getLimits type
```
Returns the limits for a given type.

where,

`type` - Is a type definition or base type name.

### Param getRange
```tcl
Param getRange type
```
Returns the range for a given type.

where,

`type` - Is a type definition or base type name.

### Param getRangeErrorCmd
```tcl
Param getRangeErrorCmd
```
Gets the current range error command.

### Param getRangeSignature
```tcl
Param getRangeSignature type
```
Returns the human readable range signature for a given type.

where,

`type` - Is a type definition or base type name.

### Param getTypedefs
```tcl
Param getTypedefs
```
Returns a list of all type definition names.

### Param getValidator
```tcl
Param getValidator type
```
Returns the validator namespace name for a given type.

where,

`type` - Is a type definition or base type name.

### Param isBasetype
```tcl
Param isBasetype name
```
Returns 1 if `name` is a valid base type name.

where,

`name` - The name being tested.

### Param isTypedef
```tcl
Param isTypedef name
```
Returns 1 if `name` is a valid type definition name.

where,

`name` - The name being tested.

### Param new
```tcl
Param new type ?val?
```
Creates a parameter object. Returns the parameter object.

where,

`type` - An existing type definition name.

`val` - The optional, initial parameter value. The default is type dependent.

### Param setRangeErrorCmd
```tcl
Param setRangeErrorCmd cmd
```
Sets the command to be invoked when an assignment violates a parameter's range.
See also [Range Error Commands](#range-error-commands). Returns the previous command.

where,

`cmd` - The command to invoke as [{*}$cmd $obj valueVarName].

### Param typedef
```tcl
Param typedef basetype name ?range? ?replace?
```
Creates an application defined parameter data type. A typedef has its own type name and an optional,
basetype-specific value range. When assigning a parameter value, this range will be enforced. A Tcl
`error` is triggered if the assigned value violates the range. The `basetype` must be one of the
[built-in](BuiltInBaseTypes.md) or [user defined](CustomBaseTypes.md) base types. Returns nothing.

where,

`basetype` - One of the [built in](BuiltInBaseTypes.md) or [user defined](CustomBaseTypes.md)
             base types. See the [basetype](#param-basetype) command.

`name` - The name of the type being created. An error is triggered if `name` is not unique
         unless `replace` is set to 1.

`range` - The optional, base type specific range. See ranges for the
          [BuiltIn Base Types](BuiltInBaseTypes.md). (default {})

`replace` - If 1, any existing type definition will be replaced with this one. (default 0)


## Parameter Objects
All parameter objects support the following variables and commands. Additional variables and
commands may be added by a base type validator.
See also [BuiltIn Base Types](BuiltInBaseTypes.md) and [VTOR::objectProto_](CustomBaseTypes.md#validator-variables).

## Parameter Object Variables
These variables are managed by the parameter object. A typical application should not access these values directly. However, these values will often be directly accessed by [validators](CustomBaseTypes.md#validators).

### $obj::self_
The object's namespace name. The same value returned by [Param new](API.md#param-new).
That is, ($obj == $obj::self_) is true.

### $obj::type_
The object's type name as passed to [Param new](API.md#param-new).

### $obj::val_
The object's current value as set by [$obj =](#obj-) or [$obj setValue](#obj-setvalue).

## Parameter Object Commands

### $obj =
```tcl
$obj = val
```
Assignes a new value to the parameter. An error is triggered if the value
violates the parameter type range. Same as the [setValue](#obj-setvalue) command.
Returns the assigned value.

where,

`val` - The value being assigned.

### $obj dump
```tcl
$obj dump
```
Returns a text representation of the parameter as
```
"${self_}: type($type_) value($val_)".
```

### $obj getLimits
```tcl
$obj getLimits
```
Returns the parsed `range` value as returned by [VTOR::parseRange](CustomBaseTypes.md#parseRange).
The exact structure of this value is base type dependent and is typically not
used or needed by an application except for debugging.

### $obj getRange
```tcl
$obj getRange
```
Returns the unparsed `range` value passed to [Param typedef](#param-typedef).

### $obj getRangeErrorCmd
```tcl
$obj getRangeErrorCmd
```
Gets the current range error command.

### $obj getType
```tcl
$obj getType
```
Returns the paramter type as passed to [Param new](#param-new).

### $obj getValue
```tcl
$obj getValue
```
Returns the current parameter value.

### $obj setRangeErrorCmd
```tcl
$obj setRangeErrorCmd cmd
```
Sets the command to be invoked when an assignment violates this parameter's range.
See also [Range Error Commands](#range-error-commands). Returns the previous command.

where,

`cmd` - The command to invoke as [{*}$cmd $obj valueVarName].

### $obj setValue
```tcl
$obj setValue val
```
Assignes a new value to the parameter. An error is triggered if the value
violates the associated range. Returns the assigned value.

where,

`val` - The value being assigned.

## Range Error Commands
When an assignment violates a parameter's range. A series of commands are attempted.
* The command set by [::Param setRangeErrorCmd](#param-setrangeerrorcmd)
* The command set by [::Param::TYPEDEFNAME setRangeErrorCmd](#param-setrangeerrorcmd)
* The command set by [$obj setRangeErrorCmd](#param-setrangeerrorcmd)

## Usage Examples

### Base Type Params
Base types that support typedefs (see [VTOR::createTypedef_](CustomBaseTypes.md#validator-variables)) can be used
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

Output:
```
::Param::param_11 id(5)
ColorComponent getTokenId(alpha=6)

| Basetype        | Range Signature                                              |
| --------------- | ------------------------------------------------------------ |
| double          | ?Inf|?>|=?minLimit ?Inf|?<|=?maxLimit??                      |
| real            | ?Inf|?>|=?minLimit ?Inf|?<|=?maxLimit??                      |
| float           | ?Inf|?>|=?minLimit ?Inf|?<|=?maxLimit??                      |
| enum            | ?|<CHAR>?token?=integer? ?|token?=integer??...               |
| integer         | ?Inf|minLimit ?Inf|maxLimit??                                |
| int             | ?Inf|minLimit ?Inf|maxLimit??                                |
| string          | ?g|r<CHAR>pattern<CHAR>?i??t? ?minLen ?maxLen???             |
| text            | ?g|r<CHAR>pattern<CHAR>?i??t? ?minLen ?maxLen???             |
```
