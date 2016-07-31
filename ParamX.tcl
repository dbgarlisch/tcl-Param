if { [namespace exists ::ParamX] } return

source [file join [file dirname [info script]] .. tcl-Utils Debug.tcl]
source [file join [file dirname [info script]] .. tcl-Utils ProcAccess.tcl]

#
# EXPERIMENTAL STUFF
#

# The thought is to attach validators to normal tcl vars and have type and
# ranges enforced. This is doable with the limitation of not being able to have
# type-specific object commands. For example,
#
# From:
# https://github.com/dbgarlisch/tcl-Param/blob/master/docs/BuiltInBaseTypes.md#builtin-base-types
#
#   set poi [Param new integer 33]
#   $poi = 77
#   $poi += 23
#   $poi /= 2
#
# If there was a way to determine the context of a tcl var read from within a
# trace callback, we could support object commands. For example,
#
#   # init a tcl var to 77 and attach an integer validator
#   ParamX new integer x 77
#   puts "x = $x" ;# in this context, we want the value of x
#   $x += 7       ;# in this context, we want x to be an object
#
# The current ParamX impl does NOT support validators yet. Just testing out some
# tracing logic.
#
# The trace callbacks do not get invoked until AFTER the var's value has been
# updated. So, to restore the previous value if validation fails, we must cache
# var values. Information about a traced var including its cached value are
# stored in the ::ParamX::$keyName namespace variables val_, name_, and type_.
#
namespace eval ParamX {

  namespace import ::Debug::vputs ::Debug::verboseDo

  public proc new { typedef varname args } {
    uplevel set $varname @@@ ;# should init to typedef default here
    uplevel ::ParamX::attach $typedef $varname {*}$args
  }


  public proc attach { typedef varname args } {
    set fullName [uplevel namespace which -variable $varname]
    if { "" != "$fullName" } {
      # Attaching to a global or namespace variable
      set keyName [string map {: _} $fullName]
      uplevel trace add variable $fullName write "\{::ParamX::traceWriteNs $fullName $keyName $typedef\}"
      uplevel trace add variable $fullName unset "\{::ParamX::traceUnsetNs $fullName $keyName $typedef\}"
    } elseif { -1 == [lsearch -sorted [lsort [uplevel info locals]] $varname] } {
      return -code error "Unknown variable '$varname'"
    } else {
      # Attaching to a proc local variable
      set fullName $varname
      set lvl [uplevel {info level}]
      set keyName [format "${varname}.%04d" $lvl]
      uplevel trace add variable $fullName write "\{::ParamX::traceWriteLvl $lvl $fullName $keyName $typedef\}"
      uplevel trace add variable $fullName unset "\{::ParamX::traceUnsetLvl $lvl $fullName $keyName $typedef\}"
    }

    upvar $varname var
    namespace eval $keyName "variable val_ $var"
    namespace eval $keyName "variable name_ $fullName"
    namespace eval $keyName "variable type_ $typedef"

    verboseDo {
      puts {#------------------------------------------}
      puts "# attach varname=$varname args=\{$args\}"
      puts "#   keyName  = '$keyName'"
      puts "#   fullName = '$fullName'"
      puts "#   typedef  = '$typedef'"
      puts {#------------------------------------------}
    }
    uplevel set $varname $args
    return $varname
  }


  private proc maxLen { maxVar str } {
    upvar $maxVar max
    if { [set wd [string length $str]] > $max } {
      set max $wd
    }
  }


  public proc dump { {title {ParamX dump}} } {
    set max0 10 ;# init with min width values
    set max1  7
    set max2 10
    set max3 25
    foreach v [namespace children] {
      maxLen max0 [namespace tail $v]
      maxLen max1 [set ${v}::type_]
      maxLen max2 [set ${v}::name_]
      maxLen max3 [set ${v}::val_]
    }
    set totWd [expr {$max0 + 3 + $max1 + 3 + $max2 + 3 + $max3}]
    set dashes [string repeat - 100]
    set fmt "| %-${totWd}.${totWd}s |"
    puts [format $fmt $dashes]
    puts [format $fmt $title]
    set fmt "| %-${max0}.${max0}s | %-${max1}.${max1}s | %-${max2}.${max2}s | %-${max3}.${max3}s |"
    puts [format $fmt $dashes $dashes $dashes $dashes]
    puts [format $fmt KeyName VarType VarName VarValue]
    puts [format $fmt $dashes $dashes $dashes $dashes]
    foreach v [namespace children] {
      puts [format $fmt [namespace tail $v] [set ${v}::type_] [set ${v}::name_] [set ${v}::val_]]
    }
    puts [format $fmt $dashes $dashes $dashes $dashes]
  }

  #==========================================================================
  #                              Private procs
  #==========================================================================

  private proc traceWriteNs { fullName keyName typedef locName key op args } {
    set val [set $fullName]
    # This is where the validator would get invoked. Dummy one here for testing.
    if { "$val" == "BAD" } {
      return -code error "Invalid value '$val' assigned to '$locName'"
    }
    # sync cached value with user var
    namespace eval $keyName "variable val_ $val"
    verboseDo {
      puts {-------------------------------------------}
      puts "# traceWriteNs fullName=$fullName keyName=$keyName typedef=$typedef locName=$locName key=$key op=$op args=[list $args]"
      puts "#   $fullName set to '$val'"
      puts {-------------------------------------------}
    }
  }


  private proc traceUnsetNs { fullName keyName typedef locName key op args } {
    namespace delete $keyName
    verboseDo {
      puts {-------------------------------------------}
      puts "# traceUnsetNs fullName=$fullName keyName=$keyName typedef=$typedef locName=$locName key=$key op=$op args=[list $args]"
      puts {-------------------------------------------}
    }
  }


  private proc traceWriteLvl { lvl fullName keyName typedef locName key op args } {
    set val [uplevel #$lvl set $fullName]
    # This is where the validator would get invoked. Dummy one here for testing.
    if { "$val" == "BAD" } {
      return -code error "Invalid value '$val' assigned to '$locName'"
    }
    # sync cached value with user var
    namespace eval $keyName "variable val_ $val"
    verboseDo {
      puts {-------------------------------------------}
      puts "# traceWriteLvl lvl=$lvl fullName=$fullName keyName=$keyName typedef=$typedef locName=$locName key=$key op=$op args=[list $args]"
      puts "#   $fullName set to '$val'"
      puts {-------------------------------------------}
    }
  }


  private proc traceUnsetLvl { lvl fullName keyName typedef locName key op args } {
    namespace delete $keyName
    verboseDo {
      puts {-------------------------------------------}
      puts "# traceUnsetNs fullName=$fullName keyName=$keyName typedef=$typedef locName=$locName key=$key op=$op args=[list $args]"
      puts {-------------------------------------------}
    }
  }

  namespace ensemble create
}


proc local1 {} {
  set dummy1 0
  puts ">>>"
  puts ">>> local1"
  puts ">>>"
  set x 1
  ParamX attach integer x
  set x XLocal1
  ParamX new string z Zlocal1
  set z Zlocal1B
  local2 x
  ParamX dump {Proc local1 dump}
  puts "<<<"
  puts "<<< local1"
  puts "<<<"
}

proc local2 { xVar } {
  upvar $xVar upX
  puts ">>>"
  puts ">>> local2"
  puts ">>>"
  set dummy2 0
  set upX "${upX}-upXin2"
  set x 2
  ParamX attach string x
  set x XLocal2
  ParamX new string z Zlocal2
  local3 upX
  ParamX dump {Proc local2 dump}
  puts "<<<"
  puts "<<< local2"
  puts "<<<"
}

proc local3 { xVar } {
  upvar $xVar upX
  puts ">>>"
  puts ">>> local3"
  puts ">>>"
  set dummy3 0
  set upX "${upX}-upXin3"
  set x 3
  ParamX attach string x
  set x XLocal3
  ParamX new string z Zlocal3
  ParamX dump {Proc local3 dump}
  puts "<<<"
  puts "<<< local3"
  puts "<<<"
}

proc testOneTiming { varVar } {
  upvar $varVar var
  set start [clock milliseconds]
  for {set ii 0} {$ii < 100000} {incr ii} {
    set var $ii
  }
  set delta [expr {[clock milliseconds] - $start}]
  puts "$varVar Delta $delta ms"
  return $delta
}

proc testTimings {} {
  set d1 [testOneTiming dummy]
  ParamX attach integer dummy
  set d2 [testOneTiming dummy]
  puts [expr {1.0 * $d2 / $d1}]
}

#==========================================================================
#==========================================================================
#==========================================================================

proc main {} {
  ParamX dump {main BEFORE local1}
  local1
  ParamX dump {main AFTER local1}

  set x 1
  ParamX attach integer x 11

  set y hello
  ParamX attach string y

  ParamX new integer z 33
  catch {set z BAD} msg ; puts "#   ERROR: $msg"

  puts {}
  ParamX dump {main BEFORE unset}
  unset x y z
  puts {}
  ParamX dump {main AFTER unset}
}

#Debug setVerbose

main

puts {}
ParamX new integer zGlobal 77
set zGlobal 88
puts "zGlobal=$zGlobal"

puts {}
ParamX dump {global BEFORE unset}

unset zGlobal

puts {}
ParamX dump {global AFTER unset}

if { ![Debug isVerbose] } {
  #testTimings
} else {
  puts "\nskipping testTimings - verbose is ON\n"
}
