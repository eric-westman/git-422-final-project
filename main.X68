*-----------------------------------------------------------
* Title      : Disassembler
* Written by : 3 Cores
* Date       : Feb-Mar 2021
* Description: Machine code disassembler
*-----------------------------------------------------------

                    ORG    $1000
START:              

                    ** TEST instructions
                    MOVE.L $A0006000,$A0006010
                    MOVE.L #255,$A0006010
                    MOVE.L #255,D0
                    MOVE.W #255,A0

                    **
                    ** TEST: MOVE - mem to mem
                    **
                    ** MOVE.L $FFFF6000,$FFFF6010
                    **   code: $23F9 FFFF6000 FFFF6010
                    **
                    LEA     $1000, A0
                    MOVE.W  #$23F9, (A0)+
                    MOVE.L  #$A0106000, (A0)+
                    MOVE.L  #$A0106010, (A0)+

                    ** TEST: Immediate value to mem
                    **
                    ** MOVE.L #255,$FFFF6010
                    **   code: $23F9 000000FF FFFF6001
                    **
                    LEA     $1000, A0
                    MOVE.W  #$23FC, (A0)+
                    MOVE.L  #$000000FF, (A0)+
                    MOVE.L  #$A0106010, (A0)+

                    LEA     $1000, A0
                    ** Store instruction into wordID for processing
                    **   This could be part of a loop that loads the ID,
                    **   then runs the decipher algorithm
                    MOVE.W  (A0)+, opWord            * load OpCode Word and increment pointer
                    

                    BRA     Fn_MAIN_Done             * Exit the program

                    INCLUDE 'SR_MOVE.X68'

** ********************************************************************************
** Variables and constants
** ********************************************************************************

opWord              DC.W     $0000                   * 16 bit instruction Word
opID                DC.B     $00                     * First 4 bit value ID
opErr               DC.B     $00                     * Error byte: if set to 1, the opWord is junk data; if = opWord is instruction
opDspNam            DC.L     $0000                   * Placeholder for full text name e.g. 'MOVE'
opDspSiz            DC.L     $0000                   * Placeholder for full text size e.g. 'B','W','L'

opDstReg            DC.B     $00                     * Destination Register Value
opDstMod            DC.B     $00                     * Destination Mode Value
opSrcReg            DC.B     $00                     * Source Register Value
opSrcMod            DC.B     $00                     * Source Register Mode

opDta1              DC.L     $0000                   * Data value one (most likely source)
opDta1T             DC.B     $FF                     * Data value one type ($FF not set, 0=byte, 1=word, 2=long)
opDta2              DC.L     $0000                   * Data value two (most likely destination)
opDta2T             DC.B     $FF                     * Data value two type ($FF not set, 0=byte, 1=word, 2=long)

opNam01             DC.B     'MOVE',0                * String value for instrution 'MOVE'
opNam02             DC.B     'MOVEA',0               * String value for instrution 'MOVEA'

opSiz00             DC.B     'B',0                   * String value for instrution size 'B'
opSiz01             DC.B     'W',0                   * String value for instrution size 'W'
opSiz02             DC.B     'L',0                   * String value for instrution size 'L'
opStrComma          DC.B     ',',0                   * Comma, comma; comma.


Fn_MAIN_Done        
                    END      START


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
