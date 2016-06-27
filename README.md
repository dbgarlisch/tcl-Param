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
types. Base types are used to define aplication specific types using the
`typedef` command. A corresponding typedef is created for each basetype. Base
typedefs do not have a range and support all valid, type-specific values.

Several base type aliases are also defined. The `real` and `float` base types
are aliases for `double`, `int` is an alias for `integer`, and `text` is an
alias for `string`.

## Typedef Data Types

An application can declare its own types using the `typedef` command. A typedef
has its own type name and an optional, type-specific value range.

### Typedef double range

### Typedef integer range

### Typedef string range
