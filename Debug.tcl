if { [namespace exists ::Debug] } {
  return
}

namespace eval ::Debug {
  variable verbose_ 0

  namespace export verboseDo
  proc verboseDo { script } {
    variable verbose_
    if { $verbose_ } {
      uplevel $script
    }
  }

  namespace export vputs
  proc vputs { msg } {
    verboseDo {
      puts $msg
    }
  }

  namespace export dumpDict
  proc dumpDict { title dict {indent 0} } {
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

  namespace ensemble create
}
