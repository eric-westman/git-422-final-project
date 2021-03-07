
** -----------------------------------------------------------
** Subroutine: ID5
**             Covers ADDQ
**
**   This will run after the initial jump instruction
**
** -----------------------------------------------------------

SR_ID5              * This is to grab the first four that are already set, ID4
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
                    MOVE.B  D3, opSrcMod
                    
                    * Read next 3 bits into D3
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #7, D4
                    LSL.W   D4,D3                       * Shift left 7 to get rid of first 7 bits
                    MOVE.B  #13,D4
                    LSR.W   D4,D3                       * Shift right 13 to get next 3 bits
                    MOVE.B  D3, opID

                    ** Read next 3 bits
                    **
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #10, D4
                    LSL.W   D4, D3                      * Shift left 10 to get rid of first 10 bits
                    MOVE.B  #13,D4
                    LSR.W   D4,D3                       * Shift right 13 to get next 3 bits
                    MOVE.B  D3, opDstMod

                    ** Read next 3 bits
                    **
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #13, D4
                    LSL.W   D4, D3                      * Shift left 10 to get rid of first 10 bits
                    MOVE.B  #13,D4
                    LSR.W   D4,D3                       * Shift right 13 to get next 3 bits
                    MOVE.B  D3, opDstReg
					
Fn_ID5_VERIFY		* Make sure src mod is between 0-7
                    CMP.B   #0, opSrcMod                * Destination register >= 0
                    BLT     Fn_ID5_Error
                    CMP.B   #7, opDstReg                * Destination register <= 7
                    BGT     Fn_ID5_Error
					
					* Make sure opId  is between 0-2
                    CMP.B   #0, opID                    * Destination register >= 0
                    BLT     Fn_ID5_Error
                    CMP.B   #2, opID                    * Destination register <= 2
                    BGT     Fn_ID5_Error
					
					* Move data to  appropriate places for printing
					MOVE.B  #7,opSrcMod
					MOVE.B  #4,opSrcReg

                    ** Note: Checking immediate value
                    **       opID as size is specific to MOVE, MOVEA
                    **       other instructions will use 3 bits to set size, not part of ID
                    **
Fn_ID5_DtaSrcImd    CMP.B   #1, opID                    * opID = 0 - size is byte
                    BEQ     Fn_ID5_DtaSrcByt           * Load next byte
                    CMP.B   #3, opID                    * opID = 3 - size is word
                    BEQ     Fn_ID5_DtaSrcWrd           * Load next word
                    CMP.B   #2, opID                    * opID = 0 - size is long
                    BEQ     Fn_ID5_DtaSrcLng           * Load next long
                    BRA     Fn_ID5_Error               * Invalid opID (this should never happen)

Fn_ID5_DtaSrcByt    MOVE.W  (A2)+, opDta1               * Load byte and increment address count (note .W for byte)
                    MOVE.B  #0, opDta1T                 * Set Data 1 type as 0=Byte
                    BRA     Fn_ID5_ChkDstMod            * Check destination mode
Fn_ID5_DtaSrcWrd    MOVE.W  (A2)+, opDta1               * Load word and increment address count
                    MOVE.B  #1, opDta1T                 * Set Data 1 type as 1=Word
                    BRA     Fn_ID5_ChkDstMod            * Check destination mode
Fn_ID5_DtaSrcLng    MOVE.L  (A2)+, opDta1               * Load long and increment address count
                    MOVE.B  #2, opDta1T                 * Set Data 1 type as 2=Long
                    BRA     Fn_ID5_ChkDstMod            * Check destination mode
					
Fn_ID5_ChkDstMod    CMP.B   #7, opDstMod                * Check if destination mode is 7
                    BEQ     Fn_ID5_ChkDstReg            * Check destination register
                    BRA     Fn_ID5_Done                 * Destination not 7, done with data
Fn_ID5_ChkDstReg    CMP.B   #0, opDstReg                * Check if destination register is 0
                    BEQ     Fn_ID5_DtaDstWrd            * Load next word
                    CMP.B   #1, opDstReg                * Check if destination register is 1
                    BEQ     Fn_ID5_DtaDstLng            * Load next long
                    BRA     Fn_ID5_Error                * Invalid registration Mode

Fn_ID5_DtaDstWrd    MOVE.W  (A2)+, opDta2               * Load word and increment address count
                    MOVE.B  #1, opDta2T                 * Set Data2 type as 1=Word
                    BRA     Fn_ID5_Done
Fn_ID5_DtaDstLng    MOVE.L  (A2)+, opDta2               * Load long and increment address count
                    MOVE.B  #2, opDta2T                 * Set Data2 type as 2=Long
                    BRA     Fn_ID5_Done

** ***************************************
** GLOBALS
** ***************************************
Fn_ID5_Error                                             * Exit out if error - main subroutine will handle DATA
                    *MOVEM.L (SP)+,D0-D7/A0-A6           * Restore registers
                    RTS   
					
Fn_ID5_Done        RTS
