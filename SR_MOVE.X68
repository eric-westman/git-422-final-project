
** ********************************************************************************
** Subroutine: ID3
**             Covers ID's 1,2,3. MOVE, MOVEA
**
** (This part of the code will need to be duplicated for each opcode)
**
** Input Parameters
**  opWord      OpCode (4 bits) set in main
**
** Subroutine registers
**  D3          Subroutine shifting
**  D4          Subroutine shifting
**  D5          Address increment count
**  A3          Temp storage space for text
**
** Output Parameters
**  opErr       Error flag set to 0 if instruction is valid
**  opDspNam    Instruction name pointer to string name for display
**
** ********************************************************************************

SR_ID3

** ********************************************************************************
** edit below
** ********************************************************************************
                    
                    ** ***************************************
                    ** Read first 4 bits 
                    ** need to know if 0(byte), 1(word), 2(long) - only for MOVE, MOVEA
                    ** Note: most instructions will be in this format 3,3,3,3 
                    **    I think there is only one instrction that is 4,8
                    **
                    ** ***************************************
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #12,D4
                    LSR.W   D4,D3                       * Shift right 12 to get first 4 bits
                    MOVE.B  D3, opID

                    ** Read next 3 bits
                    **
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #4, D4
                    LSL.W   D4, D3                      * Shift left 4 to get rid of first 4 bits
                    MOVE.B  #13,D4
                    LSR.W   D4,D3                       * Shift right 13 to get next 3 bits
                    MOVE.B  D3, opDstReg

                    ** Read next 3 bits
                    **
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #7, D4
                    LSL.W   D4, D3                      * Shift left 7 to get rid of first 7 bits
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
                    ** Verify this is MOVE or MOVEA
                    **
                    ** MOVE:  If opID = 1,2,3 & DstMod = 0,2-7
                    ** MOVEA: If opID =   2,3 & DstMod = 1
                    **
                    ** Size: opID = 1: Byte; opID = 2: Long; opID = 3: Word
                    **
                    ** ***************************************
                    CMP.B   #1, opDstMod                * Destination mode is 1 - must be MOVEA
                    BEQ     Fn_MOVE_Ins02               * Set as instruction 0 MOVEA
                    BRA     Fn_MOVE_Ins01               * Set as instruction 1 MOVE
                    
Fn_MOVE_Ins01       LEA     opNam01,A3                  
                    MOVE.L  A3,opDspNam                 * Display name points to name                   
                    BRA     Fn_MOVE_Verify            
                    
Fn_MOVE_Ins02       CMP.B   #1, opID
                    BEQ     Fn_MOVE_Error               * MOVEA cannot have opID = 1 (byte)
                    LEA     opNam02,A3
                    MOVE.L  A3,opDspNam                 * Display name points to name

                    ** ***************************************
                    ** Verify other instruction parameters are correct
                    **
                    **    DstMod = 0, 2 to 6
                    **    DstReg = 0 to 7
                    **    SrcMod = 0 to 7
                    **    SrcReg = 0 to 7
                    **
                    ** ***************************************
Fn_MOVE_Verify      CMP.B   #0, opDstMod                * Destination mode is >= 0
                    BLT     Fn_MOVE_Error
                    CMP.B   #2, opDstMod                * Destination mode is >= 2
                    BLT     Fn_MOVE_Error
                    CMP.B   #7, opDstMod                * Destination mode is <= 7
                    BGT     Fn_MOVE_Error
                    CMP.B   #0, opDstReg                * Destination register >= 0
                    BLT     Fn_MOVE_Error
                    CMP.B   #7, opDstReg                * Destination register <= 7
                    BGT     Fn_MOVE_Error
                    
                    CMP.B   #0, opSrcMod                * Destination mode is 0
                    BLT     Fn_MOVE_Error
                    CMP.B   #7, opSrcMod                * Destination mode is <= 7
                    BGT     Fn_MOVE_Error
                    CMP.B   #0, opSrcReg                * Destination register >= 0
                    BLT     Fn_MOVE_Error
                    CMP.B   #7, opSrcReg                * Destination register <= 7
                    BGT     Fn_MOVE_Error
                    
                    ** ***************************************
                    ** Set instruction size - the .B,.W,.L part
                    ** Note: size set by opID only for MOVE, MOVEA
                    **       other instructions use 3 bits for size
                    ** ***************************************
                    CMP.B   #1, opID                    * Instruction size is Byte
                    BEQ     Fn_MOVE_Siz00
                    CMP.B   #3, opID                    * Instruction size is Word (Note sizes reversed for MOVE)
                    BEQ     Fn_MOVE_Siz01
                    CMP.B   #2, opID                    * Instruction size is Long
                    BEQ     Fn_MOVE_Siz02
Fn_MOVE_Siz00       MOVE.B  #$00,opValSiz               * Set size as byte
                    BRA     Fn_MOVE_SrcMod                
Fn_MOVE_Siz01       MOVE.B  #$01,opValSiz               * Display size is word
                    BRA     Fn_MOVE_SrcMod                    
Fn_MOVE_Siz02       MOVE.B  #$02,opValSiz               * Display size is long
                    BRA     Fn_MOVE_SrcMod
                    
                    ** ***************************************
                    ** Grab extra DATA if needed
                    **
                    **    If DstMod = 7
                    **       DstReg = 0 (get Word)
                    **       DstReg = 1 (get Long)
                    **
                    **    If SrcMod = 7
                    **       SrcReg = 0 (get Word)
                    **       SrcReg = 1 (get Long)
                    **       SrcReg = 4
                    **          MOVE.B, MOVE.W (get Word)
                    **          MOVE.L         (get Long)
                    **
                    ** SOURCE
                    **
                    ** ***************************************
Fn_MOVE_SrcMod      CMP.B   #7, opSrcMod                * Check if source mode is 7
                    BEQ     Fn_MOVE_ChkSrcReg           * Check source register
                    BRA     Fn_MOVE_ChkDstMod           * Source not 7, now check destination Mod                    
Fn_MOVE_ChkSrcReg   CMP.B   #0, opSrcReg                * Check is source register is 0
                    BEQ     Fn_MOVE_DtaSrcWrd           * Load next word
                    CMP.B   #1, opSrcReg                * Check is source register is 1
                    BEQ     Fn_MOVE_DtaSrcLng           * Load next long                    
                    CMP.B   #4, opSrcReg                * Check is source register is 4 (immediate value)
                    BEQ     Fn_MOVE_DtaSrcImd           * Load first word into word one
                    BRA     FN_MOVE_Error               * Invalid register value
                    
                    ** Note: Checking immediate value
                    **       opID as size is specific to MOVE, MOVEA
                    **       other instructions will use 3 bits to set size, not part of ID
                    **
Fn_MOVE_DtaSrcImd   CMP.B   #1, opID                    * opID = 0 - size is byte
                    BEQ     Fn_MOVE_DtaSrcByt           * Load next byte
                    CMP.B   #3, opID                    * opID = 3 - size is word
                    BEQ     Fn_MOVE_DtaSrcWrd           * Load next word
                    CMP.B   #2, opID                    * opID = 0 - size is long
                    BEQ     Fn_MOVE_DtaSrcLng           * Load next long
                    BRA     Fn_MOVE_Error               * Invalid opID (this should never happen)
                    
Fn_MOVE_DtaSrcByt   MOVE.W  (A2)+, opDta1               * Load byte and increment address count (note .W for byte)
                    MOVE.B  #0, opDta1T                 * Set Data 1 type as 0=Byte
                    *ADDI.B  #1,D5                       * Increment address count 1 byte
                    BRA     Fn_MOVE_ChkDstMod           * Check destination mode
Fn_MOVE_DtaSrcWrd   MOVE.W  (A2)+, opDta1               * Load word and increment address count
                    MOVE.B  #1, opDta1T                 * Set Data 1 type as 1=Word
                    *ADDI.B  #2,D5                       * Increment address count 2 bytes
                    BRA     Fn_MOVE_ChkDstMod           * Check destination mode
Fn_MOVE_DtaSrcLng   MOVE.L  (A2)+, opDta1               * Load long and increment address count
                    MOVE.B  #2, opDta1T                 * Set Data 1 type as 2=Long
                    *ADDI.B  #4,D5                       * Increment address count 4 bytes
                    BRA     Fn_MOVE_ChkDstMod           * Check destination mode

                    ** DESTINATION
                    **
Fn_MOVE_ChkDstMod   CMP.B   #7, opDstMod                * Check if destination mode is 7
                    BEQ     Fn_MOVE_ChkDstReg           * Check destination register
                    BRA     Fn_MOVE_Done                * Destination not 7, done with data
Fn_MOVE_ChkDstReg   CMP.B   #0, opDstReg                * Check if destination register is 0
                    BEQ     Fn_MOVE_DtaDstWrd           * Load next word
                    CMP.B   #1, opDstReg                * Check if destination register is 1
                    BEQ     Fn_MOVE_DtaDstLng           * Load next long
                    BRA     fn_MOVE_Error               * Invalid registration Mode
                    
Fn_MOVE_DtaDstWrd   MOVE.W  (A2)+, opDta2               * Load word and increment address count
                    MOVE.B  #1, opDta2T                 * Set Data2 type as 1=Word
                    BRA     Fn_MOVE_Done
Fn_MOVE_DtaDstLng   MOVE.L  (A2)+, opDta2               * Load long and increment address count
                    MOVE.B  #2, opDta2T                 * Set Data2 type as 2=Long
                    BRA     Fn_MOVE_Done
                    
** ********************************************************************************
** do not edit below
** ********************************************************************************                   
Fn_MOVE_Done        MOVE.B  #0, opErr                   * Clear error flag so this will display instruction info
                    
Fn_MOVE_Error                                           * Exit out if error - main subroutine will handle DATA
                    *MOVEA D0-D7/A0-A6                  * Reset registers
                    RTS                                 * Return to main































*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
