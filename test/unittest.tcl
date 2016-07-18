source [file join [file dirname [info script]] .. Param.tcl]
source [file join [file dirname [info script]] .. .. tcl-Utils ProcAccess.tcl]
source [file join [file dirname [info script]] .. .. tcl-Utils UnitTester.tcl]

proc enumRangeErrObj { a0 obj varVar } {
  upvar $varVar var
  #puts "#### enumRangeErrObj '$a0' '$obj' '$var'"
  if { "$var" == "OBJ" } {
    return -code error "$a0-enumRangeErrObj"
  }
  return 0
}

proc enumRangeErrTypedef { a0 obj varVar } {
  upvar $varVar var
  #puts "#### enumRangeErrTypedef '$a0' '$obj' '$var'"
  if { "$var" == "TYPEDEF" } {
    return -code error "$a0-enumRangeErrTypedef"
  }
  return 0
}

proc enumRangeErrParam { a0 obj varVar } {
  upvar $varVar var
  #puts "#### enumRangeErrParam '$a0' '$obj' '$var'"
  if { "$var" == "PARAM" } {
    return -code error "$a0-enumRangeErrParam"
  }
  return 0
}


namespace eval ::Param::UnitTest {
  namespace import ::UnitTester::*

  variable rePatternParamObj_ {::Param::param_\d+}
  variable errNotInRange      {r/Value.*not in range.*/}


  public proc run {} {
    testInteger
    testDouble
    testString
    testEnum
    Summary

    Param::dump "::Param::unitTest"

    set fmt "| %-15.15s | %-60.60s |"
    set dashes [string repeat - 100]
    puts {}
    puts [format $fmt "Basetype" "Range Signature"]
    puts [format $fmt $dashes $dashes]
    foreach basetype [Param getBasetypes] {
      puts [format $fmt $basetype [Param getRangeSignature $basetype]]
    }
  }


  #========================================================================
  #                              The Tests
  #========================================================================

  private proc testInteger {} {
    doTestIntegerImpl integer
    doTestIntegerImpl int
  }


  private proc testDouble {} {
    doTestDoubleImpl double
    doTestDoubleImpl real
    doTestDoubleImpl float
  }


  private proc testString {} {
    variable errNotInRange

    H testString
    set initVal {hello world!}
    T_Param_New param string $initVal
    T_toString $param string $initVal
    T {$param = hello} hello
    T {$param += { world!}} $initVal
    unset param

    set typeName BigStrRegEx
    H "testString $typeName"
    T {Param typedef string $typeName {r/^big\S{1,4}$/it 4 7}} $typeName
    set initVal "BigStr"
    T_Param_New param $typeName $initVal
    T_toString $param $typeName $initVal
    T {$param setValue "Big1234"} "Big1234"
    T {$param setValue "big12"} "big12"
    T {$param += "AB"} "big12AB"
    E {$param += " X"} $errNotInRange
    unset param

    set typeName BigStrGlob
    H "testString $typeName"
    T {Param typedef string $typeName {g/big*/it 4 7}} $typeName
    set initVal "BigStrG"
    T_Param_New param $typeName $initVal
    T_toString $param $typeName $initVal
    T {$param setValue "Big1234"} "Big1234"
    T {$param setValue "big12"} "big12"
    T {$param += " B"} "big12 B"
    E {$param += " B"} $errNotInRange
    unset param
  }


  private proc testEnum {} {
    variable errNotInRange

    set typeName ColorComponent
    H "testEnum $typeName obj"
    T {Param typedef enum $typeName {red|green|blue=5|alpha}} $typeName
    set initVal red
    T_Param_New param $typeName $initVal
    T_toString $param $typeName $initVal
    T {$param getValue} red
    T {$param getId} 0
    T {$param setValue green} green
    T {$param getValue} green
    T {$param getId} 1
    T {$param = blue} blue
    T {$param getValue} blue
    T {$param getId} 5
    T {$param = 0} red
    T {$param getValue} red
    T {$param getId} 0
    T {$param = 1} green
    T {$param getValue} green
    T {$param getId} 1
    T {$param = 5} blue
    T {$param getValue} blue
    T {$param getId} 5
    T {$param = 6} alpha
    T {$param getValue} alpha
    T {$param getId} 6
    E {$param = yellow} $errNotInRange
    E {$param = 3} $errNotInRange

    set rngErrCmdParam {::enumRangeErrParam X}
    set rngErrCmdTDef {::enumRangeErrTypedef Y}
    set rngErrCmdObj {::enumRangeErrObj Z}
    H "testEnum RangeErrorCmd"
    T {::Param setRangeErrorCmd $rngErrCmdParam} {}
    T {::Param::ColorComponent setRangeErrorCmd $rngErrCmdTDef} {}
    T {$param setRangeErrorCmd $rngErrCmdObj} {}

    E {$param = PARAM} {X-enumRangeErrParam}
    E {$param = TYPEDEF} {Y-enumRangeErrTypedef}
    E {$param = OBJ} {Z-enumRangeErrObj}
    E {$param = 33} $errNotInRange

    T {::Param setRangeErrorCmd "${rngErrCmdParam}X"} $rngErrCmdParam
    T {::Param::ColorComponent setRangeErrorCmd "${rngErrCmdTDef}Y"} $rngErrCmdTDef
    T {$param setRangeErrorCmd "${rngErrCmdObj}Z"} $rngErrCmdObj
    E {$param = PARAM} {XX-enumRangeErrParam}
    E {$param = TYPEDEF} {YY-enumRangeErrTypedef}
    E {$param = OBJ} {ZZ-enumRangeErrObj}
    E {$param = 33} $errNotInRange

    T {$param setRangeErrorCmd {}} "${rngErrCmdObj}Z"
    T {::Param::ColorComponent setRangeErrorCmd {}} "${rngErrCmdTDef}Y"
    T {::Param setRangeErrorCmd {}} "${rngErrCmdParam}X"
    E {$param = OBJ} $errNotInRange
    E {$param = TYPEDEF} $errNotInRange
    E {$param = PARAM} $errNotInRange

    H "testEnum $typeName typedef"
    T {::Param::ColorComponent getTokenId red} 0
    T {::Param::ColorComponent getTokenId green} 1
    T {::Param::ColorComponent getTokenId blue} 5
    T {::Param::ColorComponent getTokenId alpha} 6
  }


  #========================================================================
  #                              Test Helpers
  #========================================================================

  private proc T_Param_New { objVar type initVal } {
    upvar $objVar obj
    variable rePatternParamObj_
    T {set obj [Param new $type $initVal]} "r/$rePatternParamObj_/"
  }


  private proc T_toString { obj type val } {
    variable rePatternParamObj_
    T {$obj toString} "r/$rePatternParamObj_: type\\($type\\) value\\($val\\)/"
  }


  private proc doTestIntegerImpl { type } {
    variable errNotInRange

    H "testInteger $type"
    set initVal 33
    T_Param_New param $type $initVal
    T_toString $param $type $initVal
    T {$param = 77} 77
    T {$param = 99} 99
    T {$param setValue 88} 88
    T {$param += 2} 90
    T {$param -= 2} 88
    T {$param /= 2} 44
    T {$param *= 2} 88
    T {$param = 6 * 11 - 3} 63
    E {$param = XYZ} $errNotInRange
    doTestIntegerMonthImpl $type
  }


  private proc doTestIntegerMonthImpl { type } {
    variable errNotInRange

    H "testInteger [set typeName iMonth_$type]"
    T {Param typedef $type $typeName {1 12}} $typeName
    set initVal 3
    T_Param_New param $typeName $initVal
    T_toString $param $typeName $initVal
    T {$param = 7} 7
    T {$param getValue} 7
    E {$param = 13} $errNotInRange
  }


  private proc doTestDoubleImpl { type } {
    variable errNotInRange

    H "testDouble $type"
    set initVal 33.33
    T_Param_New param $type $initVal
    T_toString $param $type $initVal
    T {$param = 12.50} double(12.50)
    T {$param += 3.5} double(16.0)
    T {$param -= 3.5} double(12.5)
    T {$param /= 2} double(6.25)
    T {$param *= 2} double(12.5)
    T {$param = 2 * 12.0} double(24)
    T {$param = 3 * 12} double(36)
    E {$param = XYZ} $errNotInRange
    doTestDoubleScaleImpl $type
  }


  private proc doTestDoubleScaleImpl { type } {
    variable errNotInRange

    H "testDouble [set typeName Scale_$type]"
    T {Param typedef $type $typeName {>0 10}} $typeName
    set initVal 0.9
    T_Param_New param $typeName $initVal
    T_toString $param $typeName $initVal
    T {$param setValue .4} double(0.4)
    T {$param = 10.0000} double(10)
    E {$param = 0} $errNotInRange
    E {$param = 10.1} $errNotInRange
    E {$param = XYZ} $errNotInRange
  }

  namespace ensemble create
}
::Param::UnitTest run
