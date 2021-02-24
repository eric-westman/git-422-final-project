** -----------------------------------------------------------
* Title      : Disassembler
* Written by : 3 Cores
* Date       : Winter 2021
* Description: CSS 422 machine code disassembler
** -----------------------------------------------------------

                    ORG    $1000
START:              

** -----------------------------------------------------------
** MAIN LOGIC
**
** Program data
**   D0 - First 4 bits of instruction
**   D1 - Line Counter
**   D2 - temp storage for bit shift etc.

**   A0 - Jump Table
**   A1 - Instruction space (the contents being disassembled)
**
** -----------------------------------------------------------
Fn_MAIN_Start
                    ** ***************************************
                    ** RESET: Program variables
                    ** *************************************** 
                    CLR.B   D1                       * Reset line counter to zero
                    
                    ** Note: Addresses will be set by user 'eventually'
                    **       testing start and end without the UI for now
                    **       In other words - this is where user interface will live
                    **
                    MOVE.L  $3000, adrStart
                    MOVE.L  $3050, adrEnd
                    
                    ** ***************************************
                    ** BEGIN: TESTS
                    ** ***************************************

                    LEA     adrStart, A1            * Mem space for tests
                    
                    ** TEST MOVE
                    * MOVE.L $A0006000,$A0006010
                    * MOVE.L #255,$A0006010
                    * MOVE.L #255,D0
                    * MOVE.W #255,A0

                    **
                    ** TEST: MOVE - mem to mem
                    **
                    ** MOVE.L $FFFF6000,$FFFF6010
                    **   code: $23F9 FFFF6000 FFFF6010
                    **
                    MOVE.W  #$23F9, (A1)+
                    MOVE.L  #$A0106000, (A1)+
                    MOVE.L  #$A0106010, (A1)+

                    ** TEST: Immediate value to mem
                    **
                    ** MOVE.L #255,$FFFF6010
                    **   code: $23F9 000000FF FFFF6001
                    **
                    *MOVE.W  #$23FC, (A1)+
                    *MOVE.L  #$000000FF, (A1)+
                    *MOVE.L  #$A0106010, (A1)+
                    
                    ** ***************************************
                    ** END: TESTS
                    ** ***************************************
                             
                    LEA     Fn_MAIN_Jump, A0         * Mem space for jump table   
                    LEA     adrStart, A1             * Mem space for disassembly
                     
fn_MAIN_Loop        MOVE.W  (A1)+, opWord            * load OpCode Word from increment pointer
                    
                    ** Jump table to instruction subroutine - will return back
                    **
                    MOVE.W  opWord, D0             * opWord to D0 for multiplication
                    MOVE.B  #12, D2               
                    LSR.W   D2, D0                 * Shift 12 bits to the right (to get first 4 bits)
                    MULU    #8, D0                 * offset is multiple of 8
                    JSR     0(A0,D0)               * Jump indirect with index
                 
                    ** Display result
                    **
                    JSR     SR_DSP_DISPLAY
                   
                    ** Max lines display stop, wait for enter
                    **
Fn_MAIN_ChkLin      ADDI.B  #1, D1                  
                    CMP.B   maxLines, D1
                    BGE     Fn_MAIN_ChkPag          * Reached the maximum number of lines per page
                    BRA     Fn_MAIN_ChkEnd          * Continue to Check if at End of address space
Fn_MAIN_ChkPag      ** Logic to check ENTER key to show next page
                    
                    ** Reached end of memory @ A1 - stop main logic, ask to do it again
                    **
Fn_MAIN_ChkEnd      CMP.L   adrEnd, A1
                    BEQ     Fn_MAIN_ChkAgn          * Reached end of memory region
                    BRA     Fn_MAIN_Continue        * Continue to next loop iteration
Fn_MAIN_ChkAgn      ** Logic to check for for Y or N to check another region of memory

Fn_MAIN_Continue    BRA     Fn_MAIN_Loop            * Loop around and check another Word
                    
                    BRA     Fn_MAIN_Done            * Exit the program
                    
** -----------------------------------------------------------
** JUMP TABLE: First 4 bits of instruction
**
** Jump instruction: pointing to label (xxx).L
**  |4    E    |F    9     |00 |00 |04 |80 - Offset 6 bytes
**                          label address (Long)
**
** RTS instruction:
**  |4    E    |7    5     |               - Offset 2 bytes
**
** e.g. If looking for code0010 - 8 bytes (offset) * 4 bit code (0 to 15)
**
** Note: should find a value since 4 bits is 0 to F
** Note: There aren't any instructions that start with F
**
** -----------------------------------------------------------
Fn_MAIN_Jump        JSR     SR_IDX                  * No instructions @ ID=0
                    RTS
                    JSR     SR_ID3
                    RTS
                    JSR     SR_ID3
                    RTS
                    JSR     SR_ID3                  * Instructions @ ID=1,2,3 MOVE, MOVEA
                    RTS
                    JSR     SR_ID4
                    RTS
                    JSR     SR_ID5
                    RTS
                    JSR     SR_ID6
                    RTS
                    JSR     SR_ID7
                    RTS
                    JSR     SR_ID8
                    RTS
                    JSR     SR_ID9
                    RTS
                    JSR     SR_IDA
                    RTS
                    JSR     SR_IDB
                    RTS
                    JSR     SR_IDC
                    RTS
                    JSR     SR_IDD
                    RTS
                    JSR     SR_IDE
                    RTS
                    JSR     SR_IDX                   * No instructions @ ID=15
                    RTS

** -----------------------------------------------------------
** UI: Ask for another run or quit
** -----------------------------------------------------------
SR_UI_ANOTHER                    

** -----------------------------------------------------------
** UI: User mem input
** -----------------------------------------------------------         
SR_UI_INPUT

** -----------------------------------------------------------
** UI: Display item
** ----------------------------------------------------------- 
SR_DSP_DISPLAY
                    CMP.B   #1, opErr
                    BEQ     Fn_Dsp_Data             * Error flag - must be data
                    BRA     Fn_Dsp_Instr            * No error flag - must be instruction
Fn_Dsp_Data

Fn_Dsp_Instr

Fn_Dsp_Done
                    RTS

** -----------------------------------------------------------
** Includes: Subroutines etc.
** -----------------------------------------------------------
                    INCLUDE 'SR_IDX.X68'
                    INCLUDE 'SR_MOVE.X68'
                    INCLUDE 'SR_ID4.X68'
                    INCLUDE 'SR_ID5.X68'
                    INCLUDE 'SR_ID6.X68'
                    INCLUDE 'SR_ID7.X68'
                    INCLUDE 'SR_ID8.X68'
                    INCLUDE 'SR_ID9.X68'
                    INCLUDE 'SR_IDA.X68'
                    INCLUDE 'SR_IDB.X68'
                    INCLUDE 'SR_IDC.X68'
                    INCLUDE 'SR_IDD.X68'
                    INCLUDE 'SR_IDE.X68'

** -----------------------------------------------------------
** Variables and constants
** -----------------------------------------------------------

adrStart            DC.L     $00000000               * Starting address to check - set by user
adrEnd              DC.L     $00000000               * Ending address to check - set by user
maxLines            DC.B     $1                      * Max lines to display (30) $1E

opWord              DC.W     $0000                   * 16 bit instruction Word
opID                DC.B     $00                     * First 4 bit value ID
opErr               DC.B     $00                     * Error byte: if set to 1, the opWord is junk data; otherwise instruction
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
