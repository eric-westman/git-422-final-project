
** -----------------------------------------------------------
** Subroutine: IDC
**             Covers AND
**
**   This will run after the initial jump instruction
**
** -----------------------------------------------------------

SR_IDC				* This is to grab the first four that are already set, ID4
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
					
					** Find out if its Dn, ea or ea, Dn
					** ea, Dn - 0,1,2
					** Dn, ea - 4,5,6
					LEA     opNam_AND,A3
					CMP.B	#3,opDstMod
					BLT		Fn_IDC_Case1
					CMP.B   #7,opDstMod
					BLT     Fn_IDC_Case2
					BRA     Fn_IDC_Error

Fn_IDC_Case1		MOVE.B  opDstMod,opID
					MOVE.B  opSrcMod,opDstMod
					MOVE.B  opDstReg,D6
					MOVE.B  opSrcReg,opDstReg
					MOVE.B  D6,opSrcReg
					MOVE.B  #0,opSrcMod
					** Immediate data?
					CMP.B   #7, opDstMod
                    BEQ     Fn_IDC_DataDst
                    BRA     Fn_IDC_Done

Fn_IDC_Case2		MOVE.B  opDstMod,opID
					SUB.B   #4,opID
					MOVE.B  #0,opDstMod
					** Immediate data?
					CMP.B   #7, opSrcMod
                    BEQ     Fn_IDC_DataSrc
                    BRA     Fn_IDC_Done
					
Fn_IDC_DataDst      CMP.B   #0, opDstReg                * Check is source register is 0
                    BEQ     Fn_IDC_DtaDstWrd            * Load next word
                    CMP.B   #1, opDstReg                * Check if source register is 1
                    BEQ     Fn_IDC_DtaDstLng            * Load next long
                    CMP.B   #4, opDstReg                * Check if source register is 4 (immediate value)
                    BEQ     Fn_IDC_DtaDstImd            * Load first word into word one
                    BRA     FN_IDC_Error                * Invalid register value
                    
Fn_IDC_DtaDstImd    CMP.B   #1, opID                    * opID = 0 - size is byte
                    BEQ     Fn_IDC_DtaDstByt            * Load next byte
                    CMP.B   #3, opID                    * opID = 3 - size is word
                    BEQ     Fn_IDC_DtaDstWrd            * Load next word
                    CMP.B   #2, opID                    * opID = 0 - size is long
                    BEQ     Fn_IDC_DtaDstLng            * Load next
                    BRA     Fn_IDC_Error                * Invalid opID (this should never happen) long

Fn_IDC_DtaDstByt    MOVE.W  (A2)+, opDta1               * Load byte and increment address count (note .W for byte)
                    MOVE.B  #0, opDta1T                 * Set Data 1 type as 0=Byte
                    BRA     Fn_IDC_Done
Fn_IDC_DtaDstWrd    MOVE.W  (A2)+, opDta1               * Load word and increment address count
                    MOVE.B  #1, opDta1T                 * Set Data 1 type as 1=Word
                    BRA     Fn_IDC_Done
Fn_IDC_DtaDstLng    MOVE.L  (A2)+, opDta1               * Load long and increment address count
                    MOVE.B  #2, opDta1T                 * Set Data 1 type as 2=Long
                    BRA     Fn_IDC_Done
					
Fn_IDC_DataSrc      CMP.B   #0, opSrcReg                * Check is source register is 0
                    BEQ     Fn_IDC_DtaSrcWrd            * Load next word
                    CMP.B   #1, opSrcReg                * Check if source register is 1
                    BEQ     Fn_IDC_DtaSrcLng            * Load next long
                    CMP.B   #4, opSrcReg                * Check if source register is 4 (immediate value)
                    BEQ     Fn_IDC_DtaSrcImd            * Load first word into word one
                    BRA     FN_IDC_Error                * Invalid register value
                    
Fn_IDC_DtaSrcImd    CMP.B   #1, opID                    * opID = 0 - size is byte
                    BEQ     Fn_IDC_DtaSrcByt            * Load next byte
                    CMP.B   #3, opID                    * opID = 3 - size is word
                    BEQ     Fn_IDC_DtaSrcWrd            * Load next word
                    CMP.B   #2, opID                    * opID = 0 - size is long
                    BEQ     Fn_IDC_DtaSrcLng            * Load next
                    BRA     Fn_IDC_Error                * Invalid opID (this should never happen) long

Fn_IDC_DtaSrcByt    MOVE.W  (A2)+, opDta2               * Load byte and increment address count (note .W for byte)
                    MOVE.B  #0, opDta2T                 * Set Data 1 type as 0=Byte
                    BRA     Fn_IDC_Done
Fn_IDC_DtaSrcWrd    MOVE.W  (A2)+, opDta2               * Load word and increment address count
                    MOVE.B  #1, opDta2T                 * Set Data 1 type as 1=Word
                    BRA     Fn_IDC_Done
Fn_IDC_DtaSrcLng    MOVE.L  (A2)+, opDta2               * Load long and increment address count
                    MOVE.B  #2, opDta2T                 * Set Data 1 type as 2=Long
                    BRA     Fn_IDC_Done

** ***************************************
** GLOBALS
** ***************************************
Fn_IDC_Error                                             * Exit out if error - main subroutine will handle DATA
                    *MOVEM.L (SP)+,D0-D7/A0-A6           * Restore registers
                    RTS   

Fn_IDC_Done        RTS
