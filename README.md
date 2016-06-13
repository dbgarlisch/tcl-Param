# tcl-Param
This tcl library provides typed parameters.

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
