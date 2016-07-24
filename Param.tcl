if { [namespace exists ::Param] } return

source [file join [file dirname [info script]] .. tcl-Utils Debug.tcl]
source [file join [file dirname [info script]] .. tcl-Utils ProcAccess.tcl]


namespace eval ::Param {
  variable basetypes_ {}
  variable typedefs_ {}
  variable cnt_ 0
  variable rangeErrorCmd_ {}

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

    if { [namespace exists ::Param::$name] } {
      return -code error "Typedef namespace collision '$name'"
    }
    # build typedef's ensemble
    variable typedefProto_
    namespace eval ::Param::$name $typedefProto_
    set ::Param::${name}::self_ $name
    if { "" != "[info vars ${vtorNamespace}::staticProto_]" } {
      # validator wants to modify the typedef ensemble
      namespace eval ::Param::$name [set ${vtorNamespace}::staticProto_]
    }
    namespace eval ::Param::$name {
      namespace ensemble create
    }
    return $name
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


  public proc getTypedefs { } {
    variable typedefs_
    return [dict keys $typedefs_]
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


  public proc setRangeErrorCmd { cb } {
    variable rangeErrorCmd_
    set oldCB $rangeErrorCmd_
    set rangeErrorCmd_ $cb
    return $oldCB
  }


  public proc getRangeErrorCmd { } {
    variable rangeErrorCmd_
    return $rangeErrorCmd_
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


  private proc notifyRangeError { obj valVar } {
    upvar $valVar val
    variable rangeErrorCmd_
    # Give Param first dibs
    set ret [invokeRangeErrorCmd $rangeErrorCmd_ $obj val]
    if { "fatal" == "$ret" } {
      # Not handled by Param. Give the $obj's typedef namespace a chance
      set ret [::Param::[$obj getType]::notifyRangeError $obj val]
    }
    if { "fatal" == "$ret" } {
      # Not handled by Param or typedef. Give $obj a chance
      set ret [${obj}::notifyRangeError val]
    }
    return $ret ;# 0 means not handled
  }


  private proc invokeRangeErrorCmd { cb obj valVar } {
    upvar $valVar val
    set ret fatal
    if { "" != "$cb" } {
      #puts "### invokeRangeErrorCmd '$cb' '$obj' '$val'"
      set ret [{*}$cb $obj val]
    }
    return $ret
  }


  # standard typedef static commands
  variable typedefProto_ {
    variable self_ {}
    variable rangeErrorCmd_ {}

    public proc setRangeErrorCmd { cb } {
      variable rangeErrorCmd_
      set oldCB $rangeErrorCmd_
      set rangeErrorCmd_ $cb
      return $oldCB
    }

    public proc getRangeErrorCmd { } {
      variable rangeErrorCmd_
      return $rangeErrorCmd_
    }

    private proc notifyRangeError { obj valVar } {
      upvar $valVar val
      variable rangeErrorCmd_
      return [::Param::invokeRangeErrorCmd $rangeErrorCmd_ $obj val]
    }
  }

  # standard param object commands
  variable paramProto_ {
    variable self_ {}
    variable type_ {}
    variable val_ {}
    variable rangeErrorCmd_ {}

    public proc = { args } {
      variable self_
      variable type_
      variable val_
      if { 1 == [llength $args] } {
        set val [lindex $args 0]
      } else {
        set val "$args"
      }
      if { [[::Param getValidator $type_]::validate val [::Param getLimits $type_]] } {
        # val is good - use it
        return [set val_ $val]
      }
      # give any range error handlers a chance
      switch [set nre [::Param::notifyRangeError $self_ val]] {
      fatal {
        # trigger an error
      }
      again {
        # value modified - validate it again
        if { [[::Param getValidator $type_]::validate val [::Param getLimits $type_]] } {
          # A range error handler fixed val - use it
          return [set val_ $val]
        }
        # validation failed again - trigger an error
      }
      ignore {
        # Ignore error and leave val_ alone.
        return $val_
      }
      force {
        # Force assignment of val to val_. Note that val MAY have been modified
        # by notifyRangeError and could still be an invalid value.
        return [set val_ $val]
      }
      default {
        return -code error "Invalid return from notifyRangeError '$nre'"
      } }
      # invalid val
      return -code error "Value [list $val] not in range [list [::Param getRange $type_]]"
    }

    public proc setValue { args } {
      = {*}$args
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

    public proc toString {} {
      variable self_
      variable type_
      variable val_
      return "${self_}: type($type_) value($val_)"
    }

    public proc dump {} {
      variable self_
      puts [$self_ toString]
    }

    public proc setRangeErrorCmd { cb } {
      variable rangeErrorCmd_
      set oldCB $rangeErrorCmd_
      set rangeErrorCmd_ $cb
      return $oldCB
    }

    public proc getRangeErrorCmd { } {
      variable rangeErrorCmd_
      return $rangeErrorCmd_
    }

    private proc notifyRangeError { valVar } {
      upvar $valVar val
      variable self_
      variable rangeErrorCmd_
      return [::Param::invokeRangeErrorCmd $rangeErrorCmd_ $self_ val]
    }
  }

  namespace ensemble create
}
Param::init
