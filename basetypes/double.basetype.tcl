if { [namespace exists double] } {
  return -code error "Duplicate basetype file."
}

namespace eval double {
  variable rangeSignature_ {?Inf|?>|=?minLimit ?Inf|?<|=?maxLimit??}

  #namespace import ::Debug::vputs

  proc parseRange { range } {
    set reDblMin {(Inf|[>=]?[-+]?(?:[0-9]+\.?[0-9]*|\.[0-9]+)(?:[eE][-+]?[0-9]+)?)}
    set reDblMax {(Inf|[<=]?[-+]?(?:[0-9]+\.?[0-9]*|\.[0-9]+)(?:[eE][-+]?[0-9]+)?)}
    set re "^${reDblMin}(?: +$reDblMax)?$"
    set range [string trim $range]
    #puts "###    re: $re"
    #puts "### range: $range"
    if { 0 == [llength $range] } {
      set min Inf
      set max Inf
      set minCmp Inf
      set maxCmp Inf
    } elseif { ![regexp -nocase $re $range -> min max] ||
        ![parseLimit minCmp min >] || ![parseLimit maxCmp max <] } {
      variable rangeSignature_
      return -code error "Invalid range: '$range'. Should be '$rangeSignature_'"
    } elseif { [string equal -nocase Inf $min] || [string equal -nocase Inf $max] } {
      # okay
    } elseif { $min > $max } {
      return -code error "Invalid range: '$range'. min($min) > max($max)"
    }
    set ret [dict create]
    setLimit ret MINCMP $minCmp
    setLimit ret MIN $min
    setLimit ret MAXCMP $maxCmp
    setLimit ret MAX $max
    #puts "### VTOR::double parseRange '$range' --> [list $ret]"
    return $ret
  }

  proc parseLimit { cmpVar limitVar eqOp } {
    upvar $cmpVar cmp
    upvar $limitVar limit
    set ret 1
    set cmp {}
    set limit [string trim $limit]
    #vputs "### parseLimit [list $limit]"
    if { 0 == [string length $limit] } {
      set limit Inf
    } elseif { [string equal -nocase Inf $limit] } {
      # okay
    } elseif { ![regexp {^([<>=]?)(.+)$} $limit -> cmp val] } {
      set ret 0
    } elseif { ![string is double -strict $val] } {
      set ret 0
    } else {
      set limit $val
      if { "$cmp" == "=" || "$cmp" == ""} {
        set cmp "${eqOp}="
      }
    }
    #vputs "### parseLimit [list $cmp] [list $limit] / ret=$ret"
    return $ret
  }

  proc setLimit { limitsVar key limit } {
    upvar $limitsVar limits
    if { ![string equal -nocase Inf $limit] } {
      dict set limits $key $limit
    } elseif { [dict exists $limits $key] } {
      dict unset limits $key
    }
  }

  proc validate { value limits } {
    #vputs "### [namespace current]::validate $value [list $limits]"
    set ret 1
    if { [dict exists $limits MIN] } {
      set ret [expr [list $value [dict get $limits MINCMP] [dict get $limits MIN]]]
    }
    if { $ret && [dict exists $limits MAX] } {
      set ret [expr [list $value [dict get $limits MAXCMP] [dict get $limits MAX]]]
    }
    return $ret
  }

  proc registerAliases { } {
    #vputs "### [namespace current]::registerAliases"
    ::Param basetype real [namespace current]
    ::Param basetype float [namespace current]
  }
}
