if { [namespace exists string] } {
  return -code error "Duplicate basetype file."
}

namespace eval string {
  variable rangeSignature_ {?g|r<CHAR>pattern<CHAR>?i??t? ?minLen ?maxLen???}

  #namespace import ::Debug::vputs

  proc parseRange { range } {
    set re {^([gr])(.)(.+)\2([it]*)(?: +(\d+)(?: +(\d+))?)?$}
    #set re {^(Inf|[+-]?\d+)(?: +(Inf|[+-]?\d+))?$}
    set range [string trim $range]
    set ret [dict create]
    if { 0 == [llength $range] } {
      # okay
    } elseif { ![regexp $re $range -> ptype sep pattern flags minLen maxLen] } {
      variable rangeSignature_
      return -code error "Invalid range: '$range'. Should be '$rangeSignature_'"
    } elseif { [catch {regexp $pattern {xxx}} errMsg] } {
      return -code error "pattern '$pattern' / $errMsg"
    } else {
      dict set ret PTYPE $ptype
      dict set ret PATTERN $pattern
      dict set ret NOCASE [expr {-1 != [string first i $flags] ? "-nocase" : ""}]
      dict set ret DOTRIM [expr {-1 != [string first t $flags]}]
      if { "$minLen" != "" } {
        dict set ret MINLEN $minLen
      } elseif { [dict exists $ret MINLEN] } {
        dict unset ret MINLEN
      }
      if { "$maxLen" != "" } {
        dict set ret MAXLEN $maxLen
      } elseif { [dict exists $ret MAXLEN] } {
        dict unset ret MAXLEN
      }
    }
    #vputs "### VTOR::string parseRange '$range' --> [list $ret]"
    return $ret
  }

  proc validate { value limits } {
    #vputs "### [namespace current]::validate $value [list $limits]"
    set ret 1
    if { [dict exists $limits PATTERN] } {
      if { [dict get $limits DOTRIM] } {
        set value [string trim $value]
      }
      set noCase [dict get $limits NOCASE]
      set pattern [dict get $limits PATTERN]
      if { "r" == "[dict get $limits PTYPE]" } {
        set ret [regexp {*}$noCase $pattern $value]
      } else {
        set ret [string match {*}$noCase $pattern $value]
      }
      if { $ret && [dict exists $limits MINLEN] } {
        set ret [expr {[dict get $limits MINLEN] <= [string length $value]}]
      }
      if { $ret && [dict exists $limits MAXLEN] } {
        set ret [expr {[dict get $limits MAXLEN] >= [string length $value]}]
      }
    }
    return $ret
  }

  proc registerAliases { } {
    #vputs "### [namespace current]::registerAliases"
    ::Param basetype text [namespace current]
  }

  # typedef object commands
  variable objectProto_ {
    public proc += { txt } {
      variable self_
      return [$self_ setValue "[$self_ getValue]$txt"]
    }
  }
}
