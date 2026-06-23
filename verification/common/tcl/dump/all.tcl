##==============================================================================
## [Filename]       all.tcl
## [Project]        -
## [Author]         Ciro Bermudez - cirofabian.bermudezmarquez@ba.infn.it
## [Language]       Tcl (Tool Command Language)
## [Created]        -
## [Modified]       -
## [Description]    Tcl file to run and dump signals to FSDB
## [Notes]          This file is passed to the ./simv command
##                  using the -ucli -do dump.tcl flag
##
##                  For more information refer to:
##                    Unified Command Line Interface (UCLI) User Guide W-2024.09
##                    dump - pag. 106
## [Status]         stable
## [Revisions]      -
##==============================================================================

# Load library
source $::env(DUMP_LIB_TCL)

# Call function
dump_all "novas.fsdb"
