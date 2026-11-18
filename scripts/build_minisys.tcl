if {$argc < 1 || $argc > 2} {
    puts stderr "Usage: vivado -mode batch -source scripts/build_minisys.tcl -tclargs <top> ?output_directory?"
    exit 2
}

set root [file normalize [file join [file dirname [info script]] ..]]
set top [lindex $argv 0]
set constraints [file join $root constraints minisys "$top.xdc"]
if {![regexp {^[a-z][a-z0-9_]*$} $top] || ![file isfile $constraints]} {
    puts stderr "Unknown board top: $top. See constraints/minisys."
    exit 2
}

set output [file join $root build vivado $top]
if {$argc == 2} {
    set output [file normalize [lindex $argv 1]]
}
file mkdir $output

read_verilog [lsort [glob -directory [file join $root rtl] */*.v]]
read_xdc $constraints
synth_design -top $top -part xc7a100tfgg484-1
opt_design
place_design
route_design
report_utilization -file [file join $output utilization.rpt]
report_timing_summary -file [file join $output timing.rpt]
write_bitstream -force [file join $output "$top.bit"]
