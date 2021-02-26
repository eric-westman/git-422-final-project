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
** Program data (do not overwrite)
**   D0 - Reserved for Trap
**   D1 - Reserved for Trap
**   D2 - Reserved for Trap
**   D7 - Line Counter (do not overwrite)

**   A0 - Jump Table
**   A1 - Reserved for Trap
**   A2 - Instruction space (the contents being disassembled)
**
** Other data (ok to overwrite)
**   D3 - misc
**   D4 - misc
**   D5 - misc
**   D6 - misc
**
** -----------------------------------------------------------
Fn_MAIN_Start
                    ** ***************************************
                    ** RESET: Program variables
                    ** *************************************** 
                    CLR.B   D7                       * Reset line counter to zero
                    
                    ** Note: Addresses will be set by user 'eventually'
                    **       testing start and end without the UI for now
                    **       In other words - this is where user interface will live
                    **
                    MOVE.L  #$3000, adrStart
                    MOVE.L  #$3050, adrEnd
                    
                    ** ***************************************
                    ** BEGIN: TESTS
                    ** ***************************************

                    MOVE.L  adrStart, A2            * Mem space for tests

                    ** TEST: MOVE - mem to mem
                    **
                    ** MOVE.L $FFFF6000,$FFFF6010
                    **   code: $23F9 FFFF6000 FFFF6010
                    **
                    MOVE.W  #$23F9, (A2)+
                    MOVE.L  #$A0106000, (A2)+
                    MOVE.L  #$A0106010, (A2)+

                    ** TEST: Immediate value to mem
                    **
                    ** MOVE.L #255,$FFFF6010
                    **   code: $23F9 000000FF FFFF6001
                    **
                    MOVE.W  #$23FC, (A2)+
                    MOVE.L  #$000000FF, (A2)+
                    MOVE.L  #$A0106010, (A2)+
                    
                    ** ***************************************
                    ** END: TESTS
                    ** ***************************************
                             
                    LEA     Fn_MAIN_Jump, A0        * Mem space for jump table   
                    MOVE.L  adrStart, A2            * Mem space for disassembly
                     
fn_MAIN_Loop        
                    ** Set opWord (OpCode Word) and opValAdr (OpCode Address)
                    MOVE.W  (A2),opWord             * load OpCode Word from increment pointer (by instruction size)
                    MOVE.L  A2,opValAdr             * Set output address as current - need for display
                    
                    ** Reset local variables
                    **
                    MOVE.B  #$01,opID               * Reset opID (first 4 bits of opWord)
                    MOVE.B  #$00,opErr              * Reset error $00 (means no error)
                    MOVE.B  #$FF,opValSiz           * Reset size $FF (means not set)
                    
                    MOVE.B  $00, opDstReg
                    MOVE.B  $00, opDstMod
                    MOVE.B  $00, opSrcReg
                    MOVE.B  $00, opSrcMod
                    
                    MOVE.L  $0000, opDta1
                    MOVE.B  $FF, opDta1T
                    MOVE.L  $0000, opDta2
                    MOVE.B  $FF, opDta2T
                    
                    ** Jump table to instruction disassembler
                    **
                    MOVE.W  opWord, D5              * opWord to D5 for multiplication
                    MOVE.B  #12, D6               
                    LSR.W   D6, D5                  * Shift 12 bits to the right (to get first 4 bits)
                    MULU    #8, D5                  * offset is multiple of 8
                    JSR     0(A0,D5)                * Jump indirect with index
                 
                    ** Increment address for DATA if opErr still set
                    **    When instruction is error, increment 4 bytes for DATA
                    **    When instruction is valid, the jump subroutine will handle the increment
                    **
                    CMP.B   #1,opErr
                    BEQ     Fn_MAIN_IncDATA
                    BRA     Fn_MAIN_IncSkip
Fn_MAIN_IncDATA

Fn_MAIN_IncSkip
                    
                    ** Display result
                    **
                    JSR     SR_DSP_DISPLAY
                   
                    ** Max lines display stop, wait for enter
                    **
Fn_MAIN_ChkLin      ADDI.B  #1,D7                   * Increment line counter

                    CLR.L D6                        * Modulo on maxLines and line counter
                    MOVE.L D7,D6                    * Line counter to D6 for division
                    DIVU #5,D6                      * Set line count max here - 5 lines per page (test)
                    SWAP D6                         * Swap for remainder (the modulo part)
    
                    CMP.B   #0,D6
                    BEQ     Fn_MAIN_ChkPag          * Reached the maximum number of lines per page
                    BRA     Fn_MAIN_ChkEnd          * Continue to Check if at End of address space
                    
Fn_MAIN_ChkPag      ** Logic to check ENTER key to show next page
                    LEA     msgPage,A1              * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen
                    MOVE.B  #5,D0                   * Trap task 2 does the following:
                    TRAP    #15                     * Read single char into D1.B - repurposed for ENTER key
                    
                    MOVE.B  #11,D0                  * Trap task 2 does the following:
                    MOVE.W  #$FF00,D1               * Clear the screen
                    TRAP    #15
                    
                    ** Reached end of memory @ A2 - stop main logic, ask to do it again
                    **
Fn_MAIN_ChkEnd      CMP.L   adrEnd, A2
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
** UI: User mem input
** -----------------------------------------------------------         
SR_UI_INPUT

** -----------------------------------------------------------
** UI: Display item
** ----------------------------------------------------------- 
SR_DSP_DISPLAY
                    ** Push opValAdr to opDspAdr
                    LEA     opValAdr,A3
                    LEA     opDspAdr,A4
                    JSR     SR_HEX_STR
                    
                    CMP.B   #1, opErr               * Check instruction type
                    BEQ     Fn_Dsp_Data             * Error flag - must be data
                    BRA     Fn_Dsp_Instr            * No error flag - must be instruction
                    
Fn_Dsp_Data                                         * Instruction is DATA
                    ** Instruction address
                    LEA     opDspAdr,A1             * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen
                    
                    ** Space
                    LEA     opSpace,A1              * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15
                    
                    ** Instruction name
                    LEA     opNam00,A1              * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen
                    
                    BRA     Fn_Dsp_Done
                    
Fn_Dsp_Instr                                        * Instruction is valid
                    ** Instruction address
                    LEA     opDspAdr,A1             * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen
                    
                    ** Space
                    LEA     opSpace,A1              * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15
                    
                    ** Instruction name
                    ** Note: MOVE.L because opDspNam is a pointer
                    MOVE.L  opDspNam,A1             * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen
          
Fn_Dsp_Done                                         * Done with instruction display
                    ** End of line
                    LEA     msgNewLine,A1           * Load result message "CR,LF"
                    MOVE.B  #14,D0                  * Trap task 14 - use (A1)
                    TRAP    #15                     * I/O Trap - write message to screen
                    
                    RTS                             * Return back to caller
   
** -----------------------------------------------------------
** UI: Convert Long Hexadecimal value to a string
** -----------------------------------------------------------              
SR_LNG_STR

** -----------------------------------------------------------
** UI: Convert Word Hexadecimal value to a string
** -----------------------------------------------------------
SR_WRD_STR

** -----------------------------------------------------------
** Convert single hexadecimal value to a string value
**
** Parameters
**   D5 - Hex value to assess. Converted value returned in D5
** -----------------------------------------------------------
SR_HEX_ASCII
                    CMP.B   #9, D5
                    BGT     Fn_HEX_Ltr
Fn_HEX_Num          ADDI.B  #$30, D5                 * If Hex is anumber, add $30
                    RTS
Fn_HEX_Ltr          ADDI.B  #$37, D5                 * If Hex is A-F, Add $37
                    RTS

** -----------------------------------------------------------
** Copy hexadecimal value to defined constant
**
** Parameters
**   A3 - Pointer to string copying from
**   A4 - Pointer to defined constant
**
** Data registers
**   D4 - Current byte      (hex value A3)
**   D5 - Temp byte         (hex value or string)
**   D6 - Number to shift
** -----------------------------------------------------------
SR_HEX_STR

Fn_Hex_Str_Loop     MOVE.B  (A3)+,D4

                    MOVE.B  (A4),D5
                    CMP.B   #$00,D5                  * Looking for NULL value $00
                    BEQ     Fn_Hex_Str_Done          * NULL value found - exit SR
                    
                    ** First Hex value (high order value)
                    MOVE.B  D4,D5                    * Copy current value to temp byte holder
                    MOVE.B  #4,D6
                    LSR.B   D6,D5                    * Shift right to get high order hex value
                    JSR     SR_HEX_ASCII             * Hex to ASCII conversion
                    MOVE.B  D5,(A4)+                 * Move ASCII value to constant                    
                    
                    ** Second Hex value (low order value)
                    MOVE.B  D4,D5                    * Copy current vaue to temp byte holder
                    MOVE.B  #4,D6
                    LSL.B   D6,D5                    
                    LSR.B   D6,D5                    * Shift left, right to get low order hex value
                    JSR     SR_HEX_ASCII             * Hex to ASCII conversion
                    MOVE.B  D5,(A4)+                 * Move ASCII value to constant
                    
                    BRA     Fn_Hex_Str_Loop
                    
Fn_Hex_Str_Done
                    MOVE.B  #$00,(A4)+               * Insert NULL value (required to print string)                 
                    
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
maxLines            DC.B     $5                      * Max lines to display (30) $1E, test (5) $5

opWord              DC.W     $0000                   * 16 bit instruction Word
opID                DC.B     $00                     * First 4 bit value ID
opErr               DC.B     $01                     * Error byte: If set to 1 then is DATA. default is error

opValAdr            DC.L     $00000000               * Instruction address - used for calculation
opDspAdr            DC.B     '89ABCDEF',0            * String hex value display for address
opDspNam            DC.L     $00000000               * Pointer to full text name e.g. 'MOVE'
opValSiz            DC.B     $FF                     * Data value size ($FF not set, 0=byte, 1=word, 2=long)

** XXXXXXXX
opDspSiz            DC.L     $00000000               * Pointer to full text size e.g. 'B','W','L' - need to REMOVE THIS

opDstReg            DC.B     $00                     * Destination Register Value
opDstMod            DC.B     $00                     * Destination Mode Value
opSrcReg            DC.B     $00                     * Source Register Value
opSrcMod            DC.B     $00                     * Source Register Mode

opDta1              DC.L     $00000000               * Data value one (most likely source)
opDta1T             DC.B     $FF                     * Data value one type ($FF not set, 0=byte, 1=word, 2=long)
opDta2              DC.L     $00000000               * Data value two (most likely destination)
opDta2T             DC.B     $FF                     * Data value two type ($FF not set, 0=byte, 1=word, 2=long)

CR                  EQU      $0D                     * ASCII code for Carriage Return
LF                  EQU      $0A                     * ASCII code for Line Feed

opNam00             DC.B     'DATA',0
opNam01             DC.B     'MOVE',0                * String value for instrution 'MOVE'
opNam02             DC.B     'MOVEA',0               * String value for instrution 'MOVEA'

opSiz00             DC.B     'B',0                   * String value for instrution size 'B'
opSiz01             DC.B     'W',0                   * String value for instrution size 'W'
opSiz02             DC.B     'L',0                   * String value for instrution size 'L'

msgPage             DC.B     'Hit Enter to go to the next page',0
msgNewLine          DC.B     CR,LF,0
opComma             DC.B     ',',0
opPeriod            DC.B     '.',0
opSpace             DC.B     ' ',0


Fn_MAIN_Done        
                    END      START






















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
