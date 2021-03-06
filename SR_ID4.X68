** -----------------------------------------------------------
** Subroutine: ID4
**             Covers JSR, LEA, MOVEM, NOP, NOT, RTS
**
** (This part of the code will need to be duplicated for each opcode)
**
** Input Parameters
**  opWord      OpCode (4 bits) set in main
**
** Subroutine registers
**  D3          Subroutine shifting
**  D4          Subroutine shifting
**  A3          Temp storage space for text
**
** Output Parameters
**  opErr       error flag set to 0 if instruction is valid
**              note: opErr set to 1 (error) in main to display as DATA
**                    if instruction is valid, resetting it allow display
**                    of valid instruction information
**
**  opPtrNam - instruction name pointer to string name for display
**
**  opValSiz - size of instruction: $ff default = not set, 0=Byte, 1=Word, 2=Long
**
**  opSrcMod - source mode (if it has one)
**  opSrcReg - source register (if it has one)
**  opDstMod - destination mode (if it has one)
**  opDstReg - destination register (if it has one)
**
**  opDta1   - source; extra data after instruction
**  opDta1T  - source; extra data type: $FF=not set, 0=Byte, 1=Word, 2=Long
**  opDta2   - destination; extra data after instruction
**  opDta2T  - destination; extra data type: $FF=not set, 0=Byte, 1=Word, 2=Long
**
**  opMask   - mask bits for MOVEM
**  perhaps more local vars - trying to keep it compact
**
**   This will run after the initial jump instruction
**
** -----------------------------------------------------------

SR_ID4              * This is to grab the first four that are already set, ID4
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #12,D4
                    LSR.W   D4,D3                       * Shift right 12 to get first 4 bits
                    MOVE.B  D3, opID        
                    
                    * Read next 3 bits into D3
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #4, D4
                    LSL.W   D4,D3                       * Shift left 4 to get rid of first 4 bits
                    MOVE.B  #13,D4
                    LSR.W   D4,D3                       * Shift right 13 to get next 3 bits
                    MOVE.B  D3, opDstReg
                    
                    * Read next 3 bits into D3
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #7, D4
                    LSL.W   D4,D3                       * Shift left 7 to get rid of first 7 bits
                    MOVE.B  #13,D4
                    LSR.W   D4,D3                       * Shift right 13 to get next 3 bits
                    MOVE.B  D3, opDstMod

                    ** Read next 3 bits
                    **
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #10, D4
                    LSL.W   D4, D3                      * Shift left 10 to get rid of first 10 bits
                    MOVE.B  #13,D4
                    LSR.W   D4,D3                       * Shift right 13 to get next 3 bits
                    MOVE.B  D3, opSrcMod

                    ** Read next 3 bits
                    **
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #13, D4
                    LSL.W   D4, D3                      * Shift left 10 to get rid of first 10 bits
                    MOVE.B  #13,D4
                    LSR.W   D4,D3                       * Shift right 13 to get next 3 bits
                    MOVE.B  D3, opSrcReg
                    
                    ** ***************************************
                    ** Verify instruction
                    **
                    ** JSR: If DstReg=7, DstMod=2 
                    ** LEA: If DstReg=0-7, DstMod=7
                    ** MOVEM:
                    **    RegToMem: DestReg=4, DestMod=2,3
                    **    MemToReg: DestReg=6, DestMod=2,3
                    ** NOP: If DestReg=7, DstMod=1, SrcMod=6, SrcReg=1
                    ** NOT: If DstReg=3, DstMod=0-2
                    ** RTS: If DstReg=7, DstMod=1, SrcMod=6, SrcReg=5
                    **
                    ** ***************************************
                    CMP.B   #0, DstMod
                    BEQ     Fn_ID4_NOT
                    CMP.B   #1, DstMod
                    BEQ     Fn_ID4_CheckD1
                    CMP.B   #2, DstMod
                    BEQ     Fn_ID4_CheckD2
                    CMP.B   #3, DstMod
                    BEQ     Fn_ID4_CheckD3
                    CMP.B   #7, DstMod
                    BEQ     Fn_ID4_LEA
                    BRA     Fn_ID4_Error
                    
Fn_ID4_CheckD1
** ***************************************
** Possibilites of DestMod=1
**
** NOT (DstMod=0-2) - If DstReg=3
** NOP (DstMod=1) - SrcReg=1
** RTS (DstMod=1) - SrcReg=5
**
** ***************************************
                    CMP.B   #3, opDstReg
                    BEQ     Fn_ID4_NOT
                    CMP.B   #1, opSrcReg
                    BEQ     Fn_ID4_NOP
                    CMP.B   #5, opSrcReg
                    BEQ     Fn_ID4_RTS
                    
Fn_ID4_CheckD2
** ***************************************
** Possibilites of DestMod=2
**
** NOT (DstMod=0-2) - If DstReg=3
** JSR (DstMod=2) - If DstReg=7
** MOVEM(RtoM) (DstMod=2,3) - If DstReg=4
** MOVEM(MtoR) (DstMod=2,3) - If DstReg=6
**
** ***************************************
                    CMP.B   #3, opDstReg
                    BEQ     Fn_ID4_NOT
                    CMP.B   #4, opDstReg
                    BEQ     Fn_ID4_MOVEMRTOM
                    CMP.B   #6, opDstReg
                    BEQ     Fn_ID4_MOVEMMTOR
                    CMP.B   #7, opDstReg
                    BEQ     Fn_ID4_JSR
Fn_ID4_CheckD3
** ***************************************
** Possibilites of DestMod=3
**
** MOVEM(RtoM) (DstMod=2,3) - If DstReg=4
** MOVEM(MtoR) (DstMod=2,3) - If DstReg=6
**
** ***************************************
                    CMP.B   #4, opDstReg
                    BEQ     Fn_ID4_MOVEMRTOM
                    CMP.B   #6, opDstReg
                    BEQ     Fn_ID4_MOVEMMTOR

** ***************************************
** JSR
** ***************************************
Fn_ID4_JSR          LEA     opNam03,A3
                    MOVE.L  A3, opPtrName
                    
Fn_ID4_VERIFY_JSR   CMP.B   #7, opDestReg
                    BNE     Fn_ID4_Error
                    CMP.B   #2, opDestMod
                    BNE     Fn_ID4_Error
                    
                    * Make sure dst reg is only 2,5,6,7 (not 0,1,3,4)
                    CMP.B   #0, opDstReg
                    BEQ     Fn_ID4_Error
                    CMP.B   #1, opDstReg
                    BEQ     Fn_ID4_Error
                    CMP.B   #3, opDstReg
                    BEQ     Fn_ID4_Error
                    CMP.B   #4, opDstReg
                    BEQ     Fn_ID4_Error
                    
                    * Make sure src mode is only 2,5,6,7 (not 0,1,3,4)
                    CMP.B   #0, opSrcMod
                    BEQ     Fn_ID4_Error
                    CMP.B   #1, opSrcMod
                    BEQ     Fn_ID4_Error
                    CMP.B   #3, opSrcMod
                    BEQ     Fn_ID4_Error
                    CMP.B   #4, opSrcMod
                    BEQ     Fn_ID4_Error
                    
                    * Make sure src reg is between 0-7
                    CMP.B   #0, opSrcReg                * Destination register >= 0
                    BLT     Fn_ID4_Error
                    CMP.B   #7, opSrcReg                * Destination register <= 7
                    BGT     Fn_ID4_Error
                    
Fn_ID4_JSR_Src      CMP.B   #7, opSrcMod
                    BEQ     Fn_ID4_Data
                    BRA     Fn_ID4_Done

** ***************************************
** LEA
** ***************************************
Fn_ID4_LEA          LEA     opNam04,A3
                    MOVE.L  A3, opPtrName
                    
Fn_ID4_VERIFY_LEA   CMP.B   #7, opDestMod
                    BNE     Fn_ID4_Error
                    
                    * Make sure src mode is only 2,5,6,7 (not 0,1,3,4)
                    CMP.B   #0, opSrcMod
                    BEQ     Fn_ID4_Error
                    CMP.B   #1, opSrcMod
                    BEQ     Fn_ID4_Error
                    CMP.B   #3, opSrcMod
                    BEQ     Fn_ID4_Error
                    CMP.B   #4, opSrcMod
                    BEQ     Fn_ID4_Error
                    
                    * Make sure src reg is between 0-7
                    CMP.B   #0, opSrcReg                * Destination register >= 0
                    BLT     Fn_ID4VE_Error
                    CMP.B   #7, opSrcReg                * Destination register <= 7
                    BGT     Fn_ID4_Error
                    
Fn_ID4_LEA_Src      CMP.B   #7, opSrcMod
                    BEQ     Fn_ID4_Data
                    BRA     Fn_ID4_Done

** ***************************************
** MOVEM
** ***************************************
Fn_ID4_MOVEMRtoM    LEA     opNam05,A3
                    MOVE.L  A3, opPtrName
                    
Fn_ID4_VERIFY_MRM   CMP.B   #4, opDestReg
                    BNE     Fn_ID4_Error
                    
                    * Make sure dest mode is only 2 or 3
                    CMP.B   #3, opSrcReg                * Destination register > 2
                    BLT     Fn_ID4VE_Error
                    CMP.B   #3, opSrcReg                * Destination register < 3
                    BGT     Fn_ID4_Error
                    
                    * Make sure src mode is only 2,4,5,6,7 (not 0,1,3)
                    CMP.B   #0, opSrcMod
                    BEQ     Fn_ID4_Error
                    CMP.B   #1, opSrcMod
                    BEQ     Fn_ID4_Error
                    CMP.B   #3, opSrcMod
                    BEQ     Fn_ID4_Error
                    
                    * Make sure src reg is between 0-7
                    CMP.B   #0, opSrcReg                * Destination register >= 0
                    BLT     Fn_ID4VE_Error
                    CMP.B   #7, opSrcReg                * Destination register <= 7
                    BGT     Fn_ID4_Error
                    BRA Fn_ID4_MOVEM_Src

FN_ID4_MOVEMMtoR    LEA     opNam05,A3
                    MOVE.L  A3, opPtrName
                    
Fn_ID4_VERIFY_MRM   CMP.B   #6, opDestReg
                    BNE     Fn_ID4_Error
                    
                    * Make sure dest mode is only 2 or 3
                    CMP.B   #3, opSrcReg                * Destination register > 2
                    BLT     Fn_ID4VE_Error
                    CMP.B   #3, opSrcReg                * Destination register < 3
                    BGT     Fn_ID4_Error
                    
                    * Make sure src mode is only 2,4,5,6,7 (not 0,1,3)
                    CMP.B   #0, opSrcMod
                    BEQ     Fn_ID4_Error
                    CMP.B   #1, opSrcMod
                    BEQ     Fn_ID4_Error
                    CMP.B   #3, opSrcMod
                    BEQ     Fn_ID4_Error
                    
                    * Make sure src reg is between 0-7
                    CMP.B   #0, opSrcReg                * Destination register >= 0
                    BLT     Fn_ID4VE_Error
                    CMP.B   #7, opSrcReg                * Destination register <= 7
                    BGT     Fn_ID4_Error
                    
Fn_ID4_MOVEM_Src    CMP.B   #7, opSrcMod
                    BEQ     Fn_ID4_Data
                    BRA     Fn_ID4_Done

** ***************************************
** NOP
** ***************************************
Fn_ID4_NOP          LEA     opNam06,A3
                    MOVE.L  A3, opPtrName

Fn_ID4_VERIFY_NOP   CMP.B   #7,DestReg
                    BNE     Fn_ID4_Error
                    CMP.B   #1, DestMod
                    BNE     Fn_ID4_Error
                    CMP.B   #6, SrcMod
                    BNE     Fn_ID4_Error
                    CMP.B   #1, SrcReg
                    BNE     Fn_ID4_Error
                    BRA     Fn_ID4_Done


** ***************************************
** NOT
** ***************************************
Fn_ID4_NOT          LEA     opNam07,A3
                    MOVE.L  A3, opPtrName
                    
Fn_ID4_VERIFY_NOT   CMP.B   #3, opDestReg
                    BNE     Fn_ID4_Error
                    
                    * Make sure src mode is not 1
                    CMP.B   #1, opSrcMod
                    BEQ     Fn_ID4_Error
                    
                    * Make sure src reg is between 0-7
                    CMP.B   #0, opSrcReg                * Destination register >= 0
                    BLT     Fn_ID4_Error
                    CMP.B   #7, opSrcReg                * Destination register <= 7
                    BGT     Fn_ID4_Error
                    
Fn_ID4_NOT_Src      MOVE.W  opDestMod,opID              * Dest mod holds the size (move it)
                    CMP.B   #7, opSrcMod
                    BEQ     Fn_ID4_Data
                    BRA     Fn_ID4_Done

** ***************************************
** RTS
** ***************************************
Fn_ID4_RTS          LEA    opNam08,A3
                    MOVE.L A3, opPtrName
                    
Fn_ID4_VERIFY_RTS   CMP.B   #7,DestReg
                    BNE     Fn_ID4_Error
                    CMP.B   #1, DestMod
                    BNE     Fn_ID4_Error
                    CMP.B   #6, SrcMod
                    BNE     Fn_ID4_Error
                    CMP.B   #5, SrcReg
                    BNE     Fn_ID4_Error
                    BRA     Fn_ID4_Done

** ***************************************
** Global Addressing
** ***************************************
Fn_ID4_Data         CMP.B   #0, opSrcReg                * Check is source register is 0
                    BEQ     Fn_ID4_DtaWrd               * Load next word
                    CMP.B   #1, opSrcReg                * Check if source register is 1
                    BEQ     Fn_ID4_DtaLng               * Load next long
                    CMP.B   #4, opSrcReg                * Check if source register is 4 (immediate value)
                    BEQ     Fn_ID4_DtaImd               * Load first word into word one
                    BRA     FN_ID4_Error                * Invalid register value
                    
Fn_ID4_DtaImd       CMP.B   #1, opID                    * opID = 0 - size is byte
                    BEQ     Fn_ID4_DtaByt               * Load next byte
                    CMP.B   #3, opID                    * opID = 3 - size is word
                    BEQ     Fn_ID4_DtaWrd               * Load next word
                    CMP.B   #2, opID                    * opID = 0 - size is long
                    BEQ          Fn_ID4_DtaLng               * Load next
                    BRA     Fn_ID4_Error                * Invalid opID (this should never happen) long

Fn_ID4_DtaByt       MOVE.W  (A2)+, opDta2               * Load byte and increment address count (note .W for byte)
                    MOVE.B  #0, opDta1T                 * Set Data 1 type as 0=Byte
                    BRA     Fn_ID4_Done
Fn_ID4_DtaWrd       MOVE.W  (A2)+, opDta2               * Load word and increment address count
                    MOVE.B  #1, opDta1T                 * Set Data 1 type as 1=Word
                    BRA     Fn_ID4_Done
Fn_ID4_DtaLng       MOVE.L  (A2)+, opDta2               * Load long and increment address count
                    MOVE.B  #2, opDta1T                 * Set Data 1 type as 2=Long
                    BRA     Fn_ID4_Done

** ***************************************
** GLOBALS
** ***************************************
Fn_ID4_Error                                             * Exit out if error - main subroutine will handle DATA
                    *MOVEM.L (SP)+,D0-D7/A0-A6           * Restore registers
                    RTS                                  * Return to main

Fn_ID4_Done         RTS


*~Font name~Courier New~
*~Font size~10~
*~Tab type~0~
*~Tab size~4~
