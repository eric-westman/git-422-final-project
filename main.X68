** -----------------------------------------------------------
* Title      : Disassembler
* Written by : 3 Cores
* Date       : Winter 2021
* Description: CSS 422 machine code disassembler
** -----------------------------------------------------------

                    ORG    $1000

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
**   A2 - Pointer to Instruction space (the contents being disassembled)
**   A3 - Pointer to Output buffer
**   A7 - Stack pointer
**
** Other data (ok to overwrite)
**   D3 - misc
**   D4 - misc
**   D5 - misc
**   D6 - misc
**   A4 - misc
**   A5 - misc
**   A6 - misc
**
** -----------------------------------------------------------
MAIN
                    MOVEA.L #$00100000,SP           * Initialize stack pointer
Fn_MAIN_Start
                    ** ***************************************
                    ** RESET: Program variables
                    ** ***************************************
                    CLR.B   D7                       * Reset line counter to zero

                    ** Note: Addresses will be set by user 'eventually'
                    **       testing start and end without the UI for now
                    **       In other words - this is where user interface will live
                    ** Note: Most likely place that UI will be called as a subroutine
                    **
                    MOVE.L  #$3000, adrValStart     * Manually setting start address until UI exists
                    LEA     adrValStart,A4
                    LEA     adrStrStart,A5
                    JSR     SR_HEX_STR              * Copy numeric start address type to string for display
                    MOVE.L  #$3050, adrValEnd       * Manually setting end address until UI exists
                    LEA     adrValEnd,A4
                    LEA     adrStrEnd,A5
                    JSR     SR_HEX_STR              * Copy numeric end address type to string for display

                    ** ***************************************
                    ** BEGIN: TESTS
                    ** Remove this and the includes when turned in!
                    ** ***************************************

                    MOVE.L  adrValStart, A2         * Mem space for tests

                    JSR     SR_TEST_ID3             * Tests MOVE, MOVEA

                    ** ***************************************
                    ** END: TESTS
                    ** ***************************************

                    LEA     Fn_MAIN_Jump,A0         * Mem space for jump table
                    MOVE.L  adrValStart,A2          * Mem space for disassembly

                    ** Clear screen
                    MOVE.B  #11,D0                  * Trap task 2 does the following:
                    MOVE.W  #$FF00,D1               * Clear the screen
                    TRAP    #15

                    ** Display header
                    JSR     SR_DSP_HEADER

fn_MAIN_Loop
                    ** Prepare loop variables
                    **
                    MOVE.L  A2,opValAdr             * Set output address as current - need for display
                    MOVE.W  (A2)+,opWord            * load first 4 bit OpCode Word, increment A2 (4 bytes)
                    MOVE.L  A2,opNxtAdr             * Save next valid word address for invalid instruction

                    ** Reset local variables
                    **

                    MOVE.B  #$00,opID               * Reset opID (first 4 bits of opcode word)
                    MOVE.B  #$01,opErr              * Reset error $01 - assume error until instruction found
                    MOVE.b  #$FF,opValSiz

                    MOVE.B  #$FF, opDstReg
                    MOVE.B  #$FF, opDstMod
                    MOVE.B  #$FF, opSrcReg
                    MOVE.B  #$FF, opSrcMod

                    MOVE.L  #$0000, opDta1
                    MOVE.B  #$FF, opDta1T
                    MOVE.L  #$0000, opDta2
                    MOVE.B  #$FF, opDta2T

                    ** Jump table
                    **
                    MOVE.W  opWord,D5               * opWord to D5 for multiplication
                    MOVE.B  #12,D6
                    LSR.W   D6,D5                   * Shift 12 bits to the right (to get first 4 bits)
                    MULU    #8,D5                   * offset is multiple of 8
                    JSR     0(A0,D5)                * Jump indirect with index

                    ** Invalid instruction
                    **
                    CMP.B   #1,opErr
                    BEQ     Fn_MAIN_ErrIns          * Instruction error, reset A2
                    BRA     Fn_MAIN_Dsp             * Instruction valid, display
Fn_MAIN_ErrIns      MOVE.L  opNxtAdr,A2             * Resetting A2 to next valid word

                    ** Display result
                    **
Fn_MAIN_Dsp         JSR     SR_DSP_DISPLAY

                    ** Max lines display stop, wait for enter
                    **
Fn_MAIN_ChkLin      ADDI.B  #1,D7                   * Increment line counter

                    CLR.L D6                        * Modulo on maxLines and line counter
                    MOVE.L D7,D6                    * Line counter to D6 for division
                    DIVU #10,D6                     * Set line count max here - 10 lines per page (test)
                    SWAP D6                         * Swap for remainder (the modulo part)

                    CMP.B   #0,D6
                    BEQ     Fn_MAIN_ChkPag          * Reached the maximum number of lines per page
                    BRA     Fn_MAIN_ChkEnd          * Continue to Check if at End of address space

                    ** Logic to check ENTER key to show next page
                    **
Fn_MAIN_ChkPag      LEA     msgPage,A1              * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen
                    MOVE.B  #5,D0                   * Trap task 2 does the following:
                    TRAP    #15                     * Read single char into D1.B - repurposed for ENTER key

                    ** Clear screen
                    MOVE.B  #11,D0                  * Trap task 2 does the following:
                    MOVE.W  #$FF00,D1               * Clear the screen
                    TRAP    #15

                    ** Display header
                    JSR     SR_DSP_HEADER

                    ** Reached end of memory @ A2 - stop main logic, ask to do it again
                    **
Fn_MAIN_ChkEnd      CMP.L   adrValEnd, A2
                    BEQ     Fn_MAIN_ChkAgn          * Reached end of memory region
                    BRA     Fn_MAIN_Continue        * Continue to next loop iteration

                    ** Logic to check for for Y or N to check another region of memory
                    **
Fn_MAIN_ChkAgn      LEA     msgEndMem01,A1          * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen
                    LEA     msgEndMem02,A1          * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    LEA     msgEndMemAns,A1         * Loads MESSAGE into A1
                    MOVE.B  #2,D0                   * Trap task 2 does the following:
                    TRAP    #15                     * Read string to (A1), length in D1.W
                    CMP.B   #$59,(A1)               * Checking for 'Y' - otherwise Nope
                    BEQ     Fn_MAIN_Start           * Restart program
                    CMP.B   #$79,(A1)               * Checking for 'y' - otherwise Nope
                    BEQ     Fn_MAIN_Start           * Restart program
                    BRA     Fn_Main_Done            * Exit program

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
** UI: Display Header
** -----------------------------------------------------------
SR_DSP_HEADER

                    ** Header line 03
                    LEA     msgTop03,A1             * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    ** Header line 01
                    LEA     msgTop01,A1             * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    ** Header line 02
                    LEA     msgTop02a,A1            * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    LEA     adrStrStart,A1          * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    LEA     msgTop02b,A1            * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15

                    LEA     adrStrEnd,A1          * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    LEA     msgNewLine,A1           * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    ** Header line 03
                    LEA     msgTop03,A1             * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    RTS

** -----------------------------------------------------------
** UI: Display item
** -----------------------------------------------------------
SR_DSP_DISPLAY
                    ** Output buffer
                    **   Need buffer for spacing issues
                    **
                    LEA     opOutBuf,A3             * Reset pointer to output buffer
                    MOVE.B  #$00,(A3)               * Insert NULL

                    ** Push opValAdr to opStrAdr
                    LEA     opValAdr,A4             * input hex
                    LEA     opStrAdr,A5             * output string
                    JSR     SR_HEX_STR              * Hex to ASCII input @A4, output @A5
                    LEA     opStrAdr,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3

                    ** Instruction or DATA redirector
                    **
                    CMP.B   #1, opErr               * Check instruction type
                    BEQ     Fn_Dsp_Data             * Error flag - must be data
                    BRA     Fn_Dsp_Instr            * No error flag - must be instruction

Fn_Dsp_Data         ** Process invalid instruction (DATA)
                    **

                    ** Space
                    LEA     opSpace,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3

                    ** Instruction name
                    LEA     opNam00,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3

                    BRA     Fn_Dsp_Done

Fn_Dsp_Instr        ** Process instruction
                    **

                    ** Space
                    LEA     opSpace,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3

                    ** Instruction name
                    MOVE.L  opPtrNam,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3

                    ** Instruciton size
                    **
                    CMP.B   #0,opValSiz
                    BEQ     Fn_DSP_Siz00            * Size is Byte
                    CMP.B   #1,opValSiz
                    BEQ     Fn_DSP_Siz01            * Size is Word
                    CMP.B   #2,opValSiz
                    BEQ     Fn_DSP_Siz02            * Size is Long
                    BRA     Fn_DSP_DTA1             * Size not set, go to check Data 1

Fn_DSP_Siz00        LEA     opSiz00,A4              * '.B' string
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3
                    BRA     Fn_DSP_OPR1

Fn_DSP_Siz01        LEA     opSiz01,A4              * '.W' string
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3
                    BRA     Fn_DSP_OPR1

Fn_DSP_Siz02        LEA     opSiz02,A4              * '.L' string
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3
                    BRA     Fn_DSP_OPR1

Fn_DSP_OPR1                                         * Display First Operand
                    LEA     opTab,A4                * Tab (or calculated spaces)
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3

Fn_DSP_DTA1         ** Data 1 (source)
                    **

                    ** Check if source mode set (may not have a source)
                    CMP.B   #$FF,opDta1
                    BEQ     Fn_DSP_DTA2             * No source data, goto check Dta2

                    ** Check source mode
                    **
                    CMP.B   #0,opSrcMod
                    BEQ     Fn_DSP_DTA1_00          * Handle Reg Mode 0 Dn
                    CMP.B   #1,opSrcMod
                    BEQ     Fn_DSP_DTA1_01          * Handle Reg Mode 1 An
                    CMP.B   #2,opSrcMod
                    BEQ     Fn_DSP_DTA1_02          * Handle Reg Mode 2 (An)
                    CMP.B   #3,opSrcMod
                    BEQ     Fn_DSP_DTA1_03          * Handle Reg Mode 3 (An)+
                    CMP.B   #4,opSrcMod
                    BEQ     Fn_DSP_DTA1_04          * Handle Reg Mode 4 -(An)
                    CMP.B   #7,opSrcMod
                    BEQ     Fn_DSP_DTA1_07          * Handle Reg Mode 7 (xxx).W, (xxx).L, #<data>
                    BRA     Fn_DSP_OPR2             * Check data 2 (destination)

Fn_DSP_DTA1_00
                    MOVE.B  #$44,(A3)+              * Insert 'D' character
                    MOVE.B  opSrcReg,D3             * Move Register value to D3 for ASCII conversion
                    ADDI.B  #$30,D3                 * Add 30 to convert number to ASCII
                    MOVE.B  D3,(A3)+                * Insert Register value
                    BRA     Fn_DSP_OPR2             * Display data 2
Fn_DSP_DTA1_01
                    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  opSrcReg,D3             * Move Register value to D3 for ASCII conversion
                    ADDI.B  #$30,D3                 * Add 30 to convert number to ASCII
                    MOVE.B  D3,(A3)+                * Insert Register value
                    BRA     Fn_DSP_OPR2             * Display data 2
Fn_DSP_DTA1_02
                    MOVE.B  #$28,(A3)+              * Insert '(' character
                    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  opSrcReg,D3             * Move Register value to D3 for ASCII conversion
                    ADDI.B  #$30,D3                 * Add 30 to convert number to ASCII
                    MOVE.B  D3,(A3)+                * Insert Register value
                    MOVE.B  #$29,(A3)+              * Insert ')' character
                    BRA     Fn_DSP_OPR2             * Display data 2
Fn_DSP_DTA1_03
                    MOVE.B  #$28,(A3)+              * Insert '(' character
                    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  opSrcReg,D3             * Move Register value to D3 for ASCII conversion
                    ADDI.B  #$30,D3                 * Add 30 to convert number to ASCII
                    MOVE.B  D3,(A3)+                * Insert Register value
                    MOVE.B  #$29,(A3)+              * Insert ')' character
                    MOVE.B  #$2B,(A3)+              * Insert '+' character
                    BRA     Fn_DSP_OPR2             * Display data 2
Fn_DSP_DTA1_04
                    MOVE.B  #$2D,(A3)+              * Insert '-' character
                    MOVE.B  #$28,(A3)+              * Insert '(' character
                    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  opSrcReg,D3             * Move Register value to D3 for ASCII conversion
                    ADDI.B  #$30,D3                 * Add 30 to convert number to ASCII
                    MOVE.B  D3,(A3)+                * Insert Register value
                    MOVE.B  #$29,(A3)+              * Insert ')' character
                    BRA     Fn_DSP_OPR2             * Display data 2
Fn_DSP_DTA1_07
                    CMP.B   #0,opDta1T
                    BEQ     Fn_DSP_DTA1_BYT         * Display data as byte
                    CMP.B   #1,opDta1T
                    BEQ     Fn_DSP_DTA1_WRD         * Display data as word
                    CMP.B   #2,opDta1T
                    BEQ     Fn_DSP_DTA1_LNG         * Display data as long
                    BRA     Fn_DSP_DTA1_ERR
Fn_DSP_DTA1_BYT
                    LEA     opDta1,A4               * input hex
                    LEA     opStrDtaWrd,A5          * output string
                    JSR     SR_HEX_STR              * Hex to ASCII input @A4, output @A5
                    LEA     opStrDtaWrd,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3
                    BRA     Fn_DSP_OPR2             * Display data 2
Fn_DSP_DTA1_WRD
                    LEA     opDta1,A4               * input hex
                    LEA     opStrDtaWrd,A5          * output string
                    JSR     SR_HEX_STR              * Hex to ASCII input @A4, output @A5
                    LEA     opStrDtaWrd,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3
                    BRA     Fn_DSP_OPR2             * Display data 2
Fn_DSP_DTA1_LNG
                    LEA     opDta1,A4               * input hex
                    LEA     opStrDtaLng,A5          * output string
                    JSR     SR_HEX_STR              * Hex to ASCII input @A4, output @A5
                    LEA     opStrDtaLng,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3
                    BRA     Fn_DSP_OPR2             * Display data 2
Fn_DSP_DTA1_ERR
                    LEA     msgErr,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3
                    BRA     Fn_DSP_OPR2             * Display data 2

Fn_DSP_OPR2                                         * Display Second Operand
                    LEA     opComma,A4              * Comma
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3

Fn_DSP_DTA2         ** Data 2 (destination)
                    **

                    ** Check if destination mode set (may not have a destination)
                    CMP.B   #$FF,opDstMod
                    BEQ     Fn_DSP_DONE             * No source data, goto check Dta2

                    CMP.B   #0,opDstMod
                    BEQ     Fn_DSP_DTA2_00          * Handle Reg mode 0 (Dn)
                    CMP.B   #1,opDstMod
                    BEQ     Fn_DSP_DTA2_01          * Handle Reg Mode 1 An
                    CMP.B   #2,opDstMod
                    BEQ     Fn_DSP_DTA2_02          * Handle Reg Mode 2 (An)
                    CMP.B   #3,opDstMod
                    BEQ     Fn_DSP_DTA2_03          * Handle Reg Mode 3 (An)+
                    CMP.B   #4,opDstMod
                    BEQ     Fn_DSP_DTA2_04          * Handle Reg Mode 4 -(An)
                    CMP.B   #7,opDstMod
                    BEQ     Fn_DSP_DTA2_07          * Handle Reg Mode 7 (xxx).W, (xxx).L, #<data>

                    BRA     Fn_DSP_Done             * Done with data
Fn_DSP_DTA2_00
                    MOVE.B  #$44,(A3)+              * Insert 'D' character
                    MOVE.B  opDstReg,D3             * Move Register value to D3 for ASCII conversion
                    ADDI.B  #$30,D3                 * Add 30 to convert number to ASCII
                    MOVE.B  D3,(A3)+                * Insert Register value
                    BRA     Fn_DSP_DONE             * Done with display
Fn_DSP_DTA2_01
                    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  opDstReg,D3             * Move Register value to D3 for ASCII conversion
                    ADDI.B  #$30,D3                 * Add 30 to convert number to ASCII
                    MOVE.B  D3,(A3)+                * Insert Register value
                    BRA     Fn_DSP_DONE             * Done with display
Fn_DSP_DTA2_02
                    MOVE.B  #$28,(A3)+              * Insert '(' character
                    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  opDSTReg,D3             * Move Register value to D3 for ASCII conversion
                    ADDI.B  #$30,D3                 * Add 30 to convert number to ASCII
                    MOVE.B  D3,(A3)+                * Insert Register value
                    MOVE.B  #$29,(A3)+              * Insert ')' character
                    BRA     Fn_DSP_DONE             * Done with display
Fn_DSP_DTA2_03
                    MOVE.B  #$28,(A3)+              * Insert '(' character
                    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  opDstReg,D3             * Move Register value to D3 for ASCII conversion
                    ADDI.B  #$30,D3                 * Add 30 to convert number to ASCII
                    MOVE.B  D3,(A3)+                * Insert Register value
                    MOVE.B  #$29,(A3)+              * Insert ')' character
                    MOVE.B  #$2B,(A3)+              * Insert '+' character
                    BRA     Fn_DSP_DONE             * Done with display
Fn_DSP_DTA2_04
                    MOVE.B  #$2D,(A3)+              * Insert '-' character
                    MOVE.B  #$28,(A3)+              * Insert '(' character
                    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  opSrcReg,D3             * Move Register value to D3 for ASCII conversion
                    ADDI.B  #$30,D3                 * Add 30 to convert number to ASCII
                    MOVE.B  D3,(A3)+                * Insert Register value
                    MOVE.B  #$29,(A3)+              * Insert ')' character
                    BRA     Fn_DSP_DONE             * Done with display
Fn_DSP_DTA2_07
                    CMP.B   #0,opDta2T
                    BEQ     Fn_DSP_DTA2_BYT         * Display data as byte
                    CMP.B   #1,opDta2T
                    BEQ     Fn_DSP_DTA2_WRD         * Display data as word
                    CMP.B   #2,opDta2T
                    BEQ     Fn_DSP_DTA2_LNG         * Display data as long
                    BRA     Fn_DSP_DTA2_ERR
Fn_DSP_DTA2_BYT
                    LEA     opDta2,A4               * input hex
                    LEA     opStrDtaWrd,A5          * output string
                    JSR     SR_HEX_STR              * Hex to ASCII input @A4, output @A5
                    LEA     opStrDtaWrd,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3
                    BRA     Fn_DSP_DONE             * Display data 2
Fn_DSP_DTA2_WRD
                    LEA     opDta2,A4               * input hex
                    LEA     opStrDtaWrd,A5          * output string
                    JSR     SR_HEX_STR              * Hex to ASCII input @A4, output @A5
                    LEA     opStrDtaWrd,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3
                    BRA     Fn_DSP_DONE             * Display data 2
Fn_DSP_DTA2_LNG
                    LEA     opDta2,A4               * input hex
                    LEA     opStrDtaLng,A5          * output string
                    JSR     SR_HEX_STR              * Hex to ASCII input @A4, output @A5
                    LEA     opStrDtaLng,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3
                    BRA     Fn_DSP_DONE             * Display data 2
Fn_DSP_DTA2_ERR
                    LEA     msgErr,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3
                    BRA     Fn_DSP_DONE             * Display data 2

Fn_Dsp_Done                                         * Done with instruction display
                    MOVE.B  #$00,(A3)               * Insert NULL to end string
                    LEA     opOutBuf,A1             * Loads MESSAGE into A1
                    MOVE.B  #13,D0                  * Use (A1) with CR/LF
                    TRAP    #15

                    RTS                             * Return back to caller

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
**   A4 - Pointer to string copying from
**   A5 - Pointer to defined constant
**
** Data registers
**   D4 - Current byte      (hex value A4)
**   D5 - Temp byte         (hex value or string)
**   D6 - Number to shift
** -----------------------------------------------------------
SR_HEX_STR

Fn_Hex_Str_Loop     MOVE.B  (A4)+,D4

                    MOVE.B  (A5),D5
                    CMP.B   #$00,D5                  * Looking for NULL hex value $00
                    BEQ     Fn_Hex_Str_Done          * NULL value found - exit SR

                    ** First Hex value (high order value)
                    MOVE.B  D4,D5                    * Copy current value to temp byte holder
                    MOVE.B  #4,D6
                    LSR.B   D6,D5                    * Shift right to get high order hex value
                    JSR     SR_HEX_ASCII             * Hex to ASCII conversion
                    MOVE.B  D5,(A5)+                 * Move ASCII value to constant

                    ** Second Hex value (low order value)
                    MOVE.B  D4,D5                    * Copy current vaue to temp byte holder
                    MOVE.B  #4,D6
                    LSL.B   D6,D5
                    LSR.B   D6,D5                    * Shift left, right to get low order hex value
                    JSR     SR_HEX_ASCII             * Hex to ASCII conversion
                    MOVE.B  D5,(A5)+                 * Move ASCII value to constant

                    BRA     Fn_Hex_Str_Loop
Fn_Hex_Str_Done
                    MOVE.B  #$00,(A5)+               * Insert NULL value (required to print string)

                    RTS

** -----------------------------------------------------------
** Copy string to output buffer @ A3
**
** Parameters
**   A4 - Pointer to string copying from
**
** Data registers
**   D5 - Temp byte         (hex value or string)
** -----------------------------------------------------------
SR_CPY_STR_BUF

Fn_CPY_STR_Loop     MOVE.B  (A4),D5
                    CMP.B   #$00,D5                  * Looking for NULL hex value $00
                    BEQ     Fn_CPY_STR_Done          * NULL value found - exit SR

                    MOVE.B  (A4)+,(A3)+
                    BRA     Fn_CPY_STR_Loop

Fn_CPY_STR_Done     RTS

** -----------------------------------------------------------
** Length of string output buffer
** -----------------------------------------------------------
SR_CNT_STR_BUF

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
                    INCLUDE 'SR_TEST_ID3.X68'

** -----------------------------------------------------------
** Variables and constants
** -----------------------------------------------------------

adrValStart         DC.L     $00000000               * Starting address to check - set by user
adrStrStart         DC.B     '89ABCDEF',0            * String hex value display for start address
adrValEnd           DC.L     $00000000               * Ending address to check - set by user
adrStrEnd           DC.B     '89ABCDEF',0            * String hex value display for end address
maxLines            DC.B     $5                      * Max lines to display (30) $1E, test (5) $5

opWord              DC.W     $0000                   * 16 bit instruction Word
opID                DC.B     $00                     * First 4 bit value ID
opErr               DC.B     $01                     * Error byte: If set to 1 then is DATA. default is error

opValAdr            DC.L     $00000000               * Instruction address - used for calculation
opStrAdr            DC.B     '89ABCDEF',0            * String address
opNxtAdr            DC.L     $00000000               * Store next valid word in case instruction returns error

opOutBuf            DC.B     'Placeholder 80 cols wide output buffer                                          '
opPtrNam            DC.L     $00000000               * Pointer to full text name e.g. 'MOVE'

opValSiz            DC.B     $FF                     * Instruction size value $FF=Not set, 1=Byte, 2=Word, 3=Long

opDstReg            DC.B     $FF                     * Destination Register Value
opDstMod            DC.B     $FF                     * Destination Mode Value
opSrcReg            DC.B     $FF                     * Source Register Value
opSrcMod            DC.B     $FF                     * Source Register Mode

opDta1              DC.L     $00000000               * Data value one (most likely source)
opDta1T             DC.B     $FF                     * Data value one type ($FF not set, 0=byte, 1=word, 2=long)
opDta2              DC.L     $00000000               * Data value two (most likely destination)
opDta2T             DC.B     $FF                     * Data value two type ($FF not set, 0=byte, 1=word, 2=long)
opStrDtaWrd         DC.B     '0000',0                * Data value string placeholder - dynamically built
opStrDtaLng         DC.B     '00000000',0            * Data value string placeholder - dynamically built

CR                  EQU      $0D                     * ASCII code for Carriage Return
LF                  EQU      $0A                     * ASCII code for Line Feed

opNam00             DC.B     'DATA',0
opNam01             DC.B     'MOVE',0                * String value for instrution 'MOVE'
opNam02             DC.B     'MOVEA',0               * String value for instrution 'MOVEA'

opSiz00             DC.B     '.B',0                  * String value for instrution size 'B'
opSiz01             DC.B     '.W',0                  * String value for instrution size 'W'
opSiz02             DC.B     '.L',0                  * String value for instrution size 'L'

msgErr              DC.B     'Error',0               * Debug message

msgPage             DC.B     'Hit Enter to go to the next page',CR,LF,0
msgEndMem01         DC.B     'You have reached the end of the memory sequence.',CR,LF,0
msgEndMem02         DC.B     '         Y to continue or any other key to quit: ',0
msgEndMemAns        DC.B     'Placeholder for user input',0
msgDone             DC.B     'Thank you for using 3 Cores disassembler!',0
msgTop01            DC.B     '3 Cores disassembler',CR,LF,0
msgTop02a           DC.B     'Memory range:',0
msgTop02b           DC.B     ' to ',0
msgTop03            DC.B     '**************************************************',CR,LF,0
msgNewLine          DC.B     CR,LF,0

opComma             DC.B     ',',0
opPeriod            DC.B     '.',0
opSpace             DC.B     ' ',0
opTab               DC.W     $0900                  * Tab - doesn't work as expected
opBlank             DC.B     '',0

Fn_MAIN_Done        ** Clear screen
                    MOVE.B  #11,D0                  * Trap task 2 does the following:
                    MOVE.W  #$FF00,D1               * Clear the screen
                    TRAP    #15

                    ** Thank you message
                    LEA     msgDone,A1              * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    END      $1000

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
