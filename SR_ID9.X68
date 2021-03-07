
** -----------------------------------------------------------
** Subroutine: ID9
**             Covers SUB
**
**   This will run after the initial jump instruction
**
** -----------------------------------------------------------

SR_ID9

** ***************************************
** GLOBALS
** ***************************************
Fn_ID9_Error                                             * Exit out if error - main subroutine will handle DATA
                    *MOVEM.L (SP)+,D0-D7/A0-A6           * Restore registers
                    RTS   

Fn_ID9_Done        RTS
