if { [namespace exists integer] } {
  return -code error "Duplicate basetype file."
}

namespace eval integer {
  variable rangeSignature_ {?Inf|minLimit ?Inf|maxLimit??}

  #namespace import ::Debug::vputs

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
    #vputs "### VTOR::integer parseRange '$range' --> [list $ret]"
    return $ret
  }

  proc parseLimit { limitVar } {
    upvar $limitVar limit
    set ret 1
    set limit [string trim $limit]
    #vputs "### parseLimit $limit"
    if { 0 == [string length $limit] } {
      set limit Inf
    } elseif { ![string equal -nocase Inf $limit] && \
      ![string is integer -strict $limit] } {
      set ret 0
    }
    #vputs "### parseLimit $limit / ret=$ret"
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

  proc validate { valueVar limits } {
    upvar $valueVar value
    #vputs "### [namespace current]::validate $value [list $limits]"
    set ret 1
    if { [string is integer -strict $value] } {
      # all good
    } elseif { [catch {expr $value} result] } {
      # value was NOT a valid expression
      set ret 0
    } elseif { ![string is integer -strict $result] } {
      # $result is NOT a integer value
      set ret 0
    } else {
      # value WAS a valid integer expression. use it.
      set value $result
    }
    if { $ret && [dict exists $limits MIN] && $value < [dict get $limits MIN] } {
      set ret 0
    }
    if { $ret && [dict exists $limits MAX] && $value > [dict get $limits MAX] } {
      set ret 0
    }
    return $ret
  }

  proc registerAliases { } {
    #vputs "### [namespace current]::registerAliases"
    ::Param basetype int [namespace current]
  }

  # typedef object commands
  variable objectProto_ {
    public proc += { val } {
      variable self_
      return [$self_ setValue [expr {[$self_ getValue] + $val}]]
    }
    public proc -= { val } {
      variable self_
      return [$self_ setValue [expr {[$self_ getValue] - $val}]]
    }
    public proc *= { val } {
      variable self_
      return [$self_ setValue [expr {[$self_ getValue] * $val}]]
    }
    public proc /= { val } {
      variable self_
      return [$self_ setValue [expr {[$self_ getValue] / $val}]]
    }
  }
}
