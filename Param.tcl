if { [namespace exists ::Param] } return

source [file join [file dirname [info script]] .. tcl-Utils Debug.tcl]
source [file join [file dirname [info script]] .. tcl-Utils ProcAccess.tcl]


# optionlist ?valspec ?valspec?... ?default defval? ?usage text? ?
#
# where,
#
#   optionlist
#     List of option aliases. Example, {-l --long}
#
#   valspec
#     list of option argument value specs of the form:
#       valtype?*count??:range?
#
#   valtype
#     Value validation type. One of: int, real, string, file, dir, enum. You
#     can register custom value validation types using the "CLArgs vtype"
#     command.
#
#   range
#     The valid, valtype-dependent value range:
#       int    = min,max
#       float  = min,max
#       string = pattern
#       file   = absolute or relative file name.
#       dir    = absolute or relative file name.
#       enum   = delimited list of valid tokens.
#
#   count
#     The number of values expected after the option. May be a single value to
#     specify an exact count (e.g. 3), or two dash-delimited values to specify
#     a min-max count (e.g. 3-5), or a comma-delimited list of explicit or
#     min-max counts (e.g. 1,3,5-8; same as 1,3,5,6,7,8).
#
# Examples,
#
#

namespace eval ::Param {
  variable basetypes_ {}
  variable typedefs_ {}
  variable cnt_ 0

  namespace import ::Debug::vputs ::Debug::verboseDo ::Debug::dumpDict

  public proc basetype { name {vtorNamespace {}} {replace 0} } {
    if { [isBasetype $name] && !$replace} {
      return -code error "Duplicate basetype name '$name'"
    }
    if { "$vtorNamespace" == "" } {
      # Assume BUILTIN vtorNamespace
      set vtorNamespace "::Param::VTOR::$name"
    }
    if { ![namespace exists $vtorNamespace] } {
      return -code error "Validator namespace undefined '$vtorNamespace'"
    }
    variable basetypes_
    dict set basetypes_ $name $vtorNamespace

    set doTypedef 1
    if { "" != "[info vars ${vtorNamespace}::createTypedef_]" } {
      set doTypedef [set ${vtorNamespace}::createTypedef_]
    }
    if { $doTypedef } {
      # create no-range typedef with same name as basetype
      typedef $name $name
    }

    if { "" != "[info procs ${vtorNamespace}::registerAliases]" } {
      # rename so proc cannot be called again if vtorNamespace is used by a
      # basetype alias!
      rename ${vtorNamespace}::registerAliases ${vtorNamespace}::registerAliasesImpl
      # let basetype create aliases
      ${vtorNamespace}::registerAliasesImpl
    }
  }

  public proc typedef { basetype name {range {}} {replace 0} } {
    if { ![isBasetype $basetype] } {
      return -code error "Invalid typedef basetype '$name'"
    }
    if { [isTypedef $name] && !$replace} {
      return -code error "Duplicate typedef name '$name'"
    }
    if { ![isBasetype $basetype] } {
      return -code error "Invalid basetype '$basetype'"
    }
    variable basetypes_
    variable typedefs_
    set vtorNamespace [dict get $basetypes_ $basetype]
    dict set typedefs_ $name BaseType $basetype
    dict set typedefs_ $name Limits [${vtorNamespace}::parseRange $range]
    dict set typedefs_ $name Range $range

    if { "" == "[info vars ${vtorNamespace}::staticProto_]" } {
      # do nothing
    } elseif { [namespace exists ::$name] } {
      return -code error "Typedef namespace collision '$name'"
    } else {
      #vputs "${vtorNamespace}::staticProto_ =\n[set ${vtorNamespace}::staticProto_]"
      namespace eval ::$name [set ${vtorNamespace}::staticProto_]
      namespace eval ::$name {
        variable self_ {}
        namespace ensemble create
      }
      set ::${name}::self_ $name
    }
  }

  public proc new { type {val @@NULL@@} } {
    variable basetypes_
    variable typedefs_
    if { ![isTypedef $type] } {
      return -code error "Unknown Param type '$type' must be one of [dict keys $typedefs_]"
    }

    variable cnt_
    variable paramProto_
    set ret "::Param::param_[incr cnt_]"
    namespace eval $ret $paramProto_
    set ${ret}::self_ $ret
    set ${ret}::type_ $type

    set vtorNamespace [getValidator $type]
    if { "" != "[info vars ${vtorNamespace}::objectProto_]" } {
      #vputs "${vtorNamespace}::objectProto_ =\n[set ${vtorNamespace}::objectProto_]"
      namespace eval $ret [set ${vtorNamespace}::objectProto_]
    }

    # now we can create the ensemble
    namespace eval $ret {
      namespace ensemble create
    }

    # assign ctor value
    $ret = [expr {"$val" == "@@NULL@@" ? "DEF" : "$val"}]
    return $ret
  }

  public proc isBasetype { name } {
    variable basetypes_
    return [dict exists $basetypes_ $name]
  }

  public proc getBasetype { typedefName } {
    variable typedefs_
    return [dict get $typedefs_ $typedefName BaseType]
  }

  public proc getBasetypes { } {
    variable basetypes_
    return [dict keys $basetypes_]
  }

  public proc getValidator { type } {
    if { [isTypedef $type] } {
      set type [getBasetype $type]
    }
    variable basetypes_
    return [dict get $basetypes_ $type]
  }

  public proc getLimits { type } {
    if { ![isTypedef $type] } {
      return -code error "Unknown Param type '$type' must be one of [dict keys $typedefs_]"
    }
    variable typedefs_
    return [dict get $typedefs_ $type Limits]
  }

  public proc getRange { type } {
    if { ![isTypedef $type] } {
      return -code error "Unknown Param type '$type' must be one of [dict keys $typedefs_]"
    }
    variable typedefs_
    return [dict get $typedefs_ $type Range]
  }

  public proc getRangeSignature { type } {
    return [set [getValidator $type]::rangeSignature_]
  }

  public proc isTypedef { name } {
    variable typedefs_
    return [dict exists $typedefs_ $name]
  }

  # namespace for BUILTIN validators
  namespace eval VTOR {
  }

  # ================================= PRIVATE =================================

  private proc init {} {
    #basetype enum
    #basetype boolean
    set scriptDir [file dirname [info script]]
    set basetypesDir [file join $scriptDir basetypes]
    foreach basetypeFile [glob -directory $basetypesDir -type f *.basetype.tcl] {
      # Capture "name?-namespace?" from "/path/to/name?-namespace?.basetype.tcl"
      lassign [split [file tail $basetypeFile] "."] name
      # Capture "name" and "namespace" from "name?-namespace?"
      lassign [split $name "-"] name nspace
      if { "" != "$nspace" } {
        # Make validator namespace a child of the ::Param::VTOR namespace
        set nspace "::Param::VTOR::$nspace"
      }
      if { [namespace exists $nspace] } {
        return -code error "Duplicate validator '$nspace' in '$basetypeFile'."
      }
      # load validator
      namespace eval VTOR [list source "$basetypeFile"]
      # register new basetype with ::Param
      basetype $name $nspace
    }
    verboseDo {
      Param::dump "[namespace current]::init"
    }
  }

  private proc dump { title } {
    variable basetypes_
    variable typedefs_
    puts {}
    puts "$title \{"
    dumpDict "::Param::basetypes_|Base Type|Validator Namespace" $basetypes_ 1
    dumpDict "::Param::typedefs_|Type Name|Limits" $typedefs_ 1
    puts "\}"
  }

  variable paramProto_ {
    variable self_ {}
    variable type_ {}
    variable val_ {}

    public proc = { val } {
      variable type_
      if { [[::Param getValidator $type_]::validate $val [::Param getLimits $type_]] } {
        variable val_
        set val_ $val
      } else {
        return -code error "Value [list $val] not in range [list [::Param getRange $type_]]"
      }
    }

    public proc setValue { val } {
      = $val
    }

    public proc getValue { } {
      variable val_
      return $val_
    }

    public proc getType { } {
      variable type_
      return $type_
    }

    public proc getLimits { } {
      variable type_
      return [::Param getLimits $type_]
    }

    public proc getRange { } {
      variable type_
      return [::Param getRange $type_]
    }

    public proc dump {} {
      variable self_
      variable type_
      variable val_
      puts "${self_}: type($type_) value($val_)"
    }

    namespace ensemble create
  }

  namespace ensemble create
}
Param::init


proc ::Param::unitTest {} {
  Param typedef integer iMonth {1 12}
  Param typedef double Scale {>0 10}
  Param typedef real ScaleReal {>1 10}
  Param typedef float ScaleFloat {>2 10}
  Param typedef string BigStrR {r/^big\S{1,4}$/it 4 7}
  Param typedef string BigStrG {g/big*/it 4 7}
  #Param typedef boolean Switched {on=1|off=0}
  Param::dump "::Param::unitTest"

  puts {}
  set poi [Param new integer 33]
  $poi dump
  $poi = 77
  $poi dump

  puts {}
  set pod [Param new double 33.33]
  $pod dump
  $pod = 77.77
  $pod dump

  puts {}
  set pod [Param new real 44.55]
  $pod dump
  $pod = 66.88
  $pod dump

  puts {}
  set pos [Param new string {string 33}]
  $pos dump
  $pos = {string 77}
  $pos dump

  puts {}
  set imon [Param new iMonth 3]
  $imon dump
  $imon = 7
  $imon dump

  puts {}
  set scale [Param new Scale 0.9]
  $scale dump
  $scale setValue .4
  $scale dump
  $scale = 10.0000
  $scale dump

  puts {}
  set scale [Param new ScaleReal 1.1]
  $scale dump
  $scale setValue 1.4
  $scale dump
  $scale = 10.0000
  $scale dump

  puts {}
  set scale [Param new ScaleFloat 2.1]
  $scale dump
  $scale setValue 2.4
  $scale dump
  $scale = 10.0000
  $scale dump

  puts {}
  set bigStr [Param new BigStrR "BigStr"]
  $bigStr dump
  $bigStr setValue "Big1234"
  $bigStr dump
  $bigStr setValue "big12"
  $bigStr dump

  puts {}
  set bigStr [Param new BigStrG "BigStrG"]
  $bigStr dump
  $bigStr setValue "Big1234"
  $bigStr dump
  $bigStr setValue "Big12"
  $bigStr dump
  $bigStr setValue "Big123"
  $bigStr dump

  set fmt "| %-15.15s | %-60.60s |"
  set dashes [string repeat - 100]
  puts [format $fmt "Basetype" "Range Signature"]
  puts [format $fmt $dashes $dashes]
  foreach basetype [Param getBasetypes] {
    puts [format $fmt $basetype [Param getRangeSignature $basetype]]
  }
}
::Param::unitTest
