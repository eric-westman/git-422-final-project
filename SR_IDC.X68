
** -----------------------------------------------------------
** Subroutine: IDC
**             Covers AND
**
**   This will run after the initial jump instruction
**
** -----------------------------------------------------------

SR_IDC

** ***************************************
** GLOBALS
** ***************************************
Fn_IDC_Error                                             * Exit out if error - main subroutine will handle DATA
                    *MOVEM.L (SP)+,D0-D7/A0-A6           * Restore registers
                    RTS   

Fn_IDC_Done        RTS
