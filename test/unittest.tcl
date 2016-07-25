source [file join [file dirname [info script]] .. Param.tcl]
source [file join [file dirname [info script]] .. .. tcl-Utils ProcAccess.tcl]
source [file join [file dirname [info script]] .. .. tcl-Utils UnitTester.tcl]


namespace eval ::Param::UnitTest {
  namespace import ::UnitTester::*

  variable rePatternParamObj_ {::Param::param_\d+}
  variable errNotInRange_     {r/Value.*not in range.*/}
  variable rngErrProcParam_   {::Param::notifyRangeError}
  variable rngErrProcTDef_    {::Param::ColorComponent::notifyRangeError}
  variable rngErrProcObj_     "r/${rePatternParamObj_}::notifyRangeError/"

  variable rangeErrProc_      {}


  public proc run {} {
    testInteger
    testDouble
    testString
    testEnum
    testRangeErrorCmd
    testRangeErrorCmdIgnore
    testRangeErrorCmdForce
    testRangeErrorCmdAgain
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
    T_Integer integer
    T_Integer int
  }


  private proc testDouble {} {
    T_Double double
    T_Double real
    T_Double float
  }


  private proc testString {} {
    variable errNotInRange_

    H testString
    T_Param_New defParam string
    T {$defParam getValue} {}
    T {$defParam delete} {}
    set initVal {hello world!}
    T_Param_New param string $initVal
    T_toString $param string $initVal
    T {$param = hello} hello
    T {$param += { world!}} $initVal
    T {$param delete} {}

    set typeName BigStrRegEx
    H "testString $typeName"
    T {Param typedef string $typeName {r/^big\S{1,4}$/it 4 7}} $typeName
    E_Param_New defParam $typeName $errNotInRange_
    T {Param::$typeName setDefaultValue BIGX} {}
    T_Param_New defParam $typeName
    T {$defParam getValue} BIGX
    T {$defParam delete} {}
    set initVal "BigStr"
    T_Param_New param $typeName $initVal
    T_toString $param $typeName $initVal
    T {$param setValue "Big1234"} "Big1234"
    T {$param setValue "big12"} "big12"
    T {$param += "AB"} "big12AB"
    E {$param += " X"} $errNotInRange_
    T {$param delete} {}

    set typeName BigStrGlob
    H "testString $typeName"
    T {Param typedef string $typeName {g/big*/it 4 7}} $typeName
    E_Param_New defParam $typeName $errNotInRange_
    set initVal "BigStrG"
    T_Param_New param $typeName $initVal
    T_toString $param $typeName $initVal
    T {$param setValue "Big1234"} "Big1234"
    T {$param setValue "big12"} "big12"
    T {$param += " B"} "big12 B"
    E {$param += " B"} $errNotInRange_
    T {$param delete} {}
  }


  private proc testEnum {} {
    variable errNotInRange_

    set typeName ColorComponent
    H "testEnum $typeName obj"
    T {Param typedef enum $typeName {red|green|blue=5|alpha}} $typeName
    E_Param_New defParam $typeName $errNotInRange_
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
    E {$param = yellow} $errNotInRange_
    E {$param = 3} $errNotInRange_
    T {$param delete} {}

    H "testEnum $typeName getTokenId"
    T {::Param::ColorComponent getTokenId red} 0
    T {::Param::ColorComponent getTokenId green} 1
    T {::Param::ColorComponent getTokenId blue} 5
    T {::Param::ColorComponent getTokenId alpha} 6
    E {::Param::ColorComponent getTokenId abc} {Invalid ColorComponent token 'abc'. Should be one of 'red green blue alpha'}
  }


  private proc testRangeErrorCmd {} {
    variable errNotInRange_
    variable rangeErrProc_
    variable rePatternParamObj_
    variable rngErrProcParam_
    variable rngErrProcTDef_
    variable rngErrProcObj_

    set rngErrCmdParam {UnitTest::enumRangeErrParam X}
    set rngErrCmdTDef {UnitTest::enumRangeErrTypedef Y}
    set rngErrCmdObj {UnitTest::enumRangeErrObj Z}

    set typeName ColorComponent
    set initVal red
    T_Param_New param $typeName $initVal
    T_toString $param $typeName $initVal

    H "testRangeErrorCmd X Y Z"
    T {::Param setRangeErrorCmd $rngErrCmdParam} [::Param getRangeErrorCmd]
    T {::Param::ColorComponent setRangeErrorCmd $rngErrCmdTDef} [::Param::ColorComponent getRangeErrorCmd]
    T {$param setRangeErrorCmd $rngErrCmdObj} [$param getRangeErrorCmd]
    E {$param = PARAM} {X-enumRangeErrParam}
    T {set rangeErrProc_} $rngErrProcParam_
    E {$param = TYPEDEF} {Y-enumRangeErrTypedef}
    T {set rangeErrProc_} $rngErrProcTDef_
    E {$param = OBJ} {Z-enumRangeErrObj}
    T {set rangeErrProc_} $rngErrProcObj_
    E {$param = 33} $errNotInRange_

    H "testRangeErrorCmd XX YY ZZ"
    T {::Param setRangeErrorCmd "${rngErrCmdParam}X"} [::Param getRangeErrorCmd]
    T {::Param::ColorComponent setRangeErrorCmd "${rngErrCmdTDef}Y"} [::Param::ColorComponent getRangeErrorCmd]
    T {$param setRangeErrorCmd "${rngErrCmdObj}Z"} [$param getRangeErrorCmd]
    E {$param = PARAM} {XX-enumRangeErrParam}
    T {set rangeErrProc_} $rngErrProcParam_
    E {$param = TYPEDEF} {YY-enumRangeErrTypedef}
    T {set rangeErrProc_} $rngErrProcTDef_
    E {$param = OBJ} {ZZ-enumRangeErrObj}
    T {set rangeErrProc_} $rngErrProcObj_
    E {$param = 33} $errNotInRange_

    H "testRangeErrorCmd Defaulted"
    T {::Param setRangeErrorCmd {}} [::Param getRangeErrorCmd]
    T {::Param::ColorComponent setRangeErrorCmd {}} [::Param::ColorComponent getRangeErrorCmd]
    T {$param setRangeErrorCmd {}} [$param getRangeErrorCmd]
    set rangeErrProc_ null
    E {$param = PARAM} $errNotInRange_
    T {set rangeErrProc_} null
    E {$param = TYPEDEF} $errNotInRange_
    T {set rangeErrProc_} null
    E {$param = OBJ} $errNotInRange_
    T {set rangeErrProc_} null

    T {$param delete} {}
  }


  private proc testRangeErrorCmdIgnore {} {
    variable rngErrProcParam_
    variable rngErrProcTDef_
    variable rngErrProcObj_

    set typeName ColorComponent
    set initVal green
    T_Param_New param $typeName $initVal
    T_toString $param $typeName $initVal

    set expectedVals [dict create \
      PARAM   $initVal \
      TYPEDEF $initVal \
      OBJ     $initVal \
    ]
    T_RangeErrorCmd $param Ignore ::Param                 $expectedVals $rngErrProcParam_
    T_RangeErrorCmd $param Ignore ::Param::ColorComponent $expectedVals $rngErrProcTDef_
    T_RangeErrorCmd $param Ignore $param                  $expectedVals $rngErrProcObj_

    T {$param delete} {}
  }


  private proc testRangeErrorCmdForce {} {
    variable rngErrProcParam_
    variable rngErrProcTDef_
    variable rngErrProcObj_

    set typeName ColorComponent
    set initVal red
    T_Param_New param $typeName $initVal
    T_toString $param $typeName $initVal

    set expectedVals [dict create \
      PARAM   PARAM   \
      TYPEDEF TYPEDEF \
      OBJ     OBJ     \
    ]
    T_RangeErrorCmd $param Force ::Param                 $expectedVals $rngErrProcParam_
    T_RangeErrorCmd $param Force ::Param::ColorComponent $expectedVals $rngErrProcTDef_
    T_RangeErrorCmd $param Force $param                  $expectedVals $rngErrProcObj_

    T {$param delete} {}
  }


  private proc testRangeErrorCmdAgain {} {
    variable rngErrProcParam_
    variable rngErrProcTDef_
    variable rngErrProcObj_

    set typeName ColorComponent
    set initVal red
    T_Param_New param $typeName $initVal
    T_toString $param $typeName $initVal

    foreach newVal {red green blue alpha} {
      set expectedVals [dict create \
        PARAM   $newVal \
        TYPEDEF $newVal \
        OBJ     $newVal \
      ]
      T_RangeErrorCmd $param "Again $newVal" ::Param                 $expectedVals $rngErrProcParam_
      T_RangeErrorCmd $param "Again $newVal" ::Param::ColorComponent $expectedVals $rngErrProcTDef_
      T_RangeErrorCmd $param "Again $newVal" $param                  $expectedVals $rngErrProcObj_
    }

    T {$param delete} {}
  }


  #========================================================================
  #                              Test Helpers
  #========================================================================

  private proc T_Param_New { objVar type args } {
    upvar $objVar obj
    variable rePatternParamObj_
    T {set obj [Param new $type {*}$args]} "r/$rePatternParamObj_/"
  }


  private proc E_Param_New { objVar type errPattern args } {
    upvar $objVar obj
    variable rePatternParamObj_
    E {set obj [Param new $type {*}$args]} $errPattern
  }


  private proc T_toString { obj type val } {
    variable rePatternParamObj_
    T {$obj toString} "r/$rePatternParamObj_: type\\($type\\) value\\($val\\)/"
  }


  private proc T_Integer { type } {
    variable errNotInRange_

    H "testInteger $type"
    T_Param_New defParam $type
    T {$defParam getValue} 0
    T {$defParam delete} {}
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
    E {$param = XYZ} $errNotInRange_
    T {$param delete} {}
    T_IntegerMonth $type
  }


  private proc T_IntegerMonth { type } {
    variable errNotInRange_

    H "testInteger [set typeName iMonth_$type]"
    T {Param typedef $type $typeName {1 12}} $typeName
    set initVal 3
    T_Param_New param $typeName $initVal
    T_toString $param $typeName $initVal
    T {$param = 7} 7
    T {$param getValue} 7
    E {$param = 13} $errNotInRange_
    T {$param delete} {}
  }


  private proc T_Double { type } {
    variable errNotInRange_

    H "testDouble $type"
    T_Param_New defParam $type
    T {$defParam getValue} double(0.0)
    T {$defParam delete} {}
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
    E {$param = XYZ} $errNotInRange_
    T {$param delete} {}
    T_DoubleScale $type
  }


  private proc T_DoubleScale { type } {
    variable errNotInRange_

    H "testDouble [set typeName Scale_$type]"
    T {Param typedef $type $typeName {>0 10}} $typeName
    set initVal 0.9
    T_Param_New param $typeName $initVal
    T_toString $param $typeName $initVal
    T {$param setValue .4} double(0.4)
    T {$param = 10.0000} double(10)
    E {$param = 0} $errNotInRange_
    E {$param = 10.1} $errNotInRange_
    E {$param = XYZ} $errNotInRange_
    T {$param delete} {}
  }


  private proc T_RangeErrorCmd { param rngErrCmdSfx blob expectedVals rngProc } {
    variable errNotInRange_
    variable rangeErrProc_

    H "testRangeErrorCmd$rngErrCmdSfx $blob"
    T {$blob setRangeErrorCmd "UnitTest::rangeErr$rngErrCmdSfx"} [$blob getRangeErrorCmd]
    dict for {key val} $expectedVals {
      T {$param = $key} $val
      T {set rangeErrProc_} $rngProc
    }
    T {$blob setRangeErrorCmd {}} [$blob getRangeErrorCmd]
    set rangeErrProc_ null
    dict for {key val} $expectedVals {
      E {$param = $key} $errNotInRange_
      T {set rangeErrProc_} null
    }
  }

  proc enumRangeErrObj { a0 obj valVar } {
    variable rangeErrProc_ [dict get [info frame -2] proc]
    upvar $valVar val
    #puts "#### enumRangeErrObj '$a0' '$obj' '$val'"
    if { "$val" == "OBJ" } {
      return -code error "$a0-enumRangeErrObj"
    }
    return fatal
  }

  proc enumRangeErrTypedef { a0 obj valVar } {
    variable rangeErrProc_ [dict get [info frame -2] proc]
    upvar $valVar val
    #puts "#### enumRangeErrTypedef '$a0' '$obj' '$val'"
    if { "$val" == "TYPEDEF" } {
      return -code error "$a0-enumRangeErrTypedef"
    }
    return fatal
  }

  proc enumRangeErrParam { a0 obj valVar } {
    variable rangeErrProc_ [dict get [info frame -2] proc]
    upvar $valVar val
    #puts "#### enumRangeErrParam '$a0' '$obj' '$val'"
    if { "$val" == "PARAM" } {
      return -code error "$a0-enumRangeErrParam"
    }
    return fatal
  }

  proc rangeErrIgnore { obj valVar } {
    variable rangeErrProc_ [dict get [info frame -2] proc]
    upvar $valVar val
    return ignore
  }

  proc rangeErrForce { obj valVar } {
    variable rangeErrProc_ [dict get [info frame -2] proc]
    upvar $valVar val
    return force
  }

  proc rangeErrAgain { newVal obj valVar } {
    variable rangeErrProc_ [dict get [info frame -2] proc]
    upvar $valVar val
    set val $newVal
    return again
  }


  namespace ensemble create
}
::Param::UnitTest run

puts [namespace children ::Param]
