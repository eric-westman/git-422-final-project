
** -----------------------------------------------------------
** Subroutine: ID7
**             Covers MOVEQ
**
**   This will run after the initial jump instruction
**
** -----------------------------------------------------------

SR_ID7              * This is to grab the first four that are already set, ID7
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
                    MOVE.B  D3, opDta1			
					
					* Read next 1 bits into D3
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #7, D4
                    LSL.W   D4,D3                       * Shift left 7 to get rid of first 7 bits
                    MOVE.B  #15,D4
                    LSR.W   D4,D3                       * Shift right 15 to get next 1 bits
                    MOVE.B  D3, opDstMod		
					CMP.B	#0,opDstMod
					BNE     Fn_ID7_Error
					
					* Read next 8 bits into D3
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #8, D4
                    LSL.W   D4,D3                       * Shift left 7 to get rid of first 7 bits
                    MOVE.B  #8,D4
                    LSR.W   D4,D3                       * Shift right 8 to get next 8 bits
                    MOVE.B  D3, opDta2

					LEA     opNam_MOVEQ,A3
					* Set appropriate data
					MOVE.B	#1, opDta2T
					MOVE.B  #7, opSrcMod
					MOVE.B  #0, opSrcReg

** ***************************************
** GLOBALS
** ***************************************
Fn_ID7_Error                                             * Exit out if error - main subroutine will handle DATA
                    *MOVEM.L (SP)+,D0-D7/A0-A6           * Restore registers
                    RTS                                  * Return to main
					
Fn_ID7_Done        RTS
