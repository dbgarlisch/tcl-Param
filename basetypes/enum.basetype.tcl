if { [namespace exists enum] } return

namespace eval enum {
  variable rangeSignature_ {?|<CHAR>?token?=integer? ?|token?=integer??...}
  variable createTypedef_  0

  #namespace import ::Debug::vputs

  proc parseRange { range } {
    variable rangeSignature_

    set range [string trim $range]
    if { [set delim "|"] != [string index $range 0] } {
      # nothing to do
    } elseif { 3 > [string length $range] } {
      return -code error "Invalid range '$range'. Should be '$rangeSignature_'"
    } else {
      set delim [string index $range 1]
      set range [string range $range 2 end]
    }

    if { "" == "[set range [string trim $range]]" } {
      return -code error "Empty range. Should be '$rangeSignature_'"
    }
    set ret [dict create]
    set prevId -1
    foreach pair [split $range $delim] {
      set extra [lassign [split $pair "="] token id]
      if { "" != "$extra" } {
        return -code error "Invalid token value pair '$pair'. Should be '$rangeSignature_'"
      }
      if { [dict exists $ret $token] } {
        return -code error "Duplicate token '$pair'. Should be '$rangeSignature_'"
      }
      if { "" == "$id" } {
        set id [incr prevId]
      } elseif { ![string is integer -strict $id] } {
        return -code error "Invalid enum value '$id'. Should be '$rangeSignature_'"
      } else {
        set prevId $id
      }
      dict set ret $token $id
    }
    #vputs "### VTOR::enum parseRange '$range' --> [list $ret]"
    return $ret
  }

  proc validate { valueVar limits } {
    upvar $valueVar value
    set ret [dict exists $limits [string trim $value]]
    if { !$ret && [string is integer -strict $value]} {
      # get sub dict that has matching value(s)
      set m [dict filter $limits value $value]
      if { 0 != [dict size $m] } {
        # found at least one {key val} pair, use key from first entry to
        # change value being assigned
        set value [lindex $m 0]
        set ret 1
      }
    }
    #vputs "### [namespace current]::validate $value [list $limits]"
    return $ret
  }

  proc registerAliases { } {
    #vputs "### [namespace current]::registerAliases"
    #::Param basetype int [namespace current]
  }

  # typedef object commands
  variable objectProto_ {
    public proc getId { } {
      variable self_
      return [dict get [${self_} getLimits] [${self_} getValue]]
    }
  }

  # typedef static commands
  variable staticProto_ {
    public proc getTokenId { token } {
      variable self_
      set limits [::Param getLimits $self_]
      if { ![dict exists $limits $token] } {
        return -code error "Invalid $self_ token '$token'. Should be one of '[dict keys $limits]'"
      }
      return [dict get $limits $token]
    }
  }
}
