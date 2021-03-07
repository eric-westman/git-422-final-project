
** -----------------------------------------------------------
** Subroutine: IDD
**             Covers ADD, ADDA
**
**   This will run after the initial jump instruction
**
** -----------------------------------------------------------

SR_IDD

** ***************************************
** GLOBALS
** ***************************************
Fn_IDD_Error                                             * Exit out if error - main subroutine will handle DATA
                    *MOVEM.L (SP)+,D0-D7/A0-A6           * Restore registers
                    RTS   

Fn_IDD_Done        RTS
