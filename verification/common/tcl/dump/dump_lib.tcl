##=============================================================================
## [Filename]       dump_lib.tcl
## [Project]        -
## [Author]         Ciro Bermudez - cirofabian.bermudezmarquez@ba.infn.it
## [Language]       Tcl (Tool Command Language)
## [Created]        2025/04/02
## [Modified]       -
## [Description]    Tcl file to run and dump signals to FSDB
## [Notes]          This file is passed to the ./simv command
##                  using the -ucli -do dump.tcl flag
##
##                  For more information refer to:
##                      Unified Command Line Interface (UCLI) User Guide W-2024.09
##                      dump - pag. 106
##
##                  The default dump is intentionally lightweight:
##                      dump -add <scope> -depth 0 -fid FSDB0
##                  If some objects are missing from the waveform, add -fsdb_opt manually:
##                      +sva         Dumps assertions
##                      +mda         Dumps memories and multidimensional arrays
##                      +packedmda   Dumps packed multidimensional arrays
##                      +struct      Dumps structs
##                      +parameter   Dumps parameters
##                      +all         Dumps memories, MDA, structs, unions, power, and packed structs
##                  Examples:
##                      dump -add tb.dut -depth 0 fid FSDB0 -fsdb_opt +mda+packedmda+struct
##                      dump -add tb.dut -depth 0 fid FSDB0 -fsdb_opt +sva
##                      dump -add tb.dut -depth 0 fid FSDB0 -fsdb_opt +all
##
##                  The -aggregates option can also be used with dump -add:
##                      dump -add / -aggregates -fid FSDB0
##                  It enables dumping of complex data stuctures such as VHDL records,
##                  arrays of records, and Verilog multidimensional arrays.
##
##                  Recommended usage:
##                      Use +sva only when debugging assertions
##                      Use +all or -aggregates only for heavy debugging
## [Status]         stable
## [Revisions]      -
##=============================================================================

proc dump_default {{dump_name novas.fsdb} {dump_scope tb.dut}} {
    puts "\[TCL-CUSTOM\]: Dumping $dump_scope signals to $dump_name"
    dump -file $dump_name -type FSDB
    dump -add $dump_scope -depth 0 -fid FSDB0
    run
    quit
}

proc dump_all {{dump_name novas.fsdb}} {
    puts "\[TCL-CUSTOM\]: Dumping all signals to $dump_name"
    dump -file $dump_name -type FSDB
    dump -add / -aggregates -fid FSDB0
    run
    quit
}

proc dump_top {{dump_name novas.fsdb}} {
    puts "\[TCL-CUSTOM\]: Dumping port signals to $dump_name"
    dump -file $dump_name -type FSDB
    dump -add tb.dut -depth 1 -ports -fid FSDB0 -aggregates
    run
    quit
}

proc dump_custom {{dump_name novas.fsdb}} {
    puts "\[TCL-CUSTOM\]: Dumping specified signals to $dump_name"
    dump -file $dump_name -type FSDB
    dump -add tb.dut.clk_i -fid FSDB0
    dump -add tb.dut.enable_i -fid FSDB0
    dump -add tb.dut.fib_out_o -fid FSDB0
    run
    quit
}

proc dump_none {} {
    puts "\[TCL-CUSTOM\]: Running without wavedorm to dumping"
    run
    quit
}
