
** -----------------------------------------------------------
** Subroutine: IDX
**             INVALID OPCODE ID
**
**   This will run after the initial jump instruction
**   Invalid OpCode is a placeholder for instruction codes
**      that don't exist or that are not assigned as
**      required in the assignment
**
**   This subroutine only returns back to the caller,
**      no errors or other tracking
**
** -----------------------------------------------------------

SR_IDX
                   move.b   #1,d2

Fn_IDX_Done        RTS

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
