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
Fn_ID4_JSR

** ***************************************
** LEA
** ***************************************
Fn_ID4_LEA

** ***************************************
** MOVEM
** ***************************************
Fn_ID4_MOVEMRtoM

FN_ID4_MOVEMMtoR

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
Fn_ID4_NOT

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
