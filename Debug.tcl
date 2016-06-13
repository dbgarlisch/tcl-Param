if { [namespace exists Debug] } return
source [file join [file dirname [info script]] ProcAccess.tcl]


#============================================================================
#============================================================================
#============================================================================

namespace eval Debug {
  variable verbose_       0

  public proc setVerbose { {onOff 1} } {
    variable verbose_
    set verbose_ $onOff
  }

  public proc dumpDict { title dict {indent 0} } {
    lassign [split "$title|Key|Value" |] title lbl1 lbl2
    set maxKeyWd [string length $lbl1]
    set maxValWd [string length $lbl2]
    dict for {key val} $dict {
      if { [set wd [string length $key]] > $maxKeyWd } {
        set maxKeyWd $wd
      }
      if { [set wd [string length $val]] > $maxValWd } {
        set maxValWd $wd
      }
    }
    set pfx [string repeat "  " $indent]
    set dashes [string repeat "-" [expr {$maxKeyWd > $maxValWd ? $maxKeyWd : $maxValWd}]]
    set fmt "${pfx}${pfx}| %-${maxKeyWd}.${maxKeyWd}s | %-${maxValWd}.${maxValWd}s |"
    puts "${pfx}$title \{"
    puts [format $fmt $lbl1 $lbl2]
    puts [format $fmt $dashes $dashes]
    dict for {key val} $dict {
      puts [format $fmt $key $val]
    }
    puts "${pfx}\}"
  }

  private proc verboseDo__ { body } {
    variable verbose_
    if { $verbose_ } {
      uplevel $body
    }
  }

  private proc vputs__ { args } {
    verboseDo {
      puts {*}$args
    }
  }

  namespace ensemble create
}

# alias the global keywords to the appropriate namespaced proc
interp alias {} vputs      {} ::Debug::vputs__
interp alias {} verboseDo  {} ::Debug::verboseDo__
