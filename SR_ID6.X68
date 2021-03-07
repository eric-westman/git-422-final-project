
** -----------------------------------------------------------
** Subroutine: ID6
**             Covers BGT, BLE, BEQ, BRA
**
**   This will run after the initial jump instruction
**
** -----------------------------------------------------------

SR_ID6              * This is to grab the first four that are already set, ID6
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #12,D4
                    LSR.W   D4,D3                       * Shift right 12 to get first 4 bits
                    MOVE.B  D3, opID        
                    
                    * Read next 4 bits into D3
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #4, D4
                    LSL.W   D4,D3                       * Shift left 4 to get rid of first 4 bits
                    MOVE.B  #13,D4
                    LSR.W   D4,D3                       * Shift right 12 to get next 4 bits
                    MOVE.B  D3, opID
                    
                    * Read next 8 bits into D3
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #7, D4
                    LSL.W   D4,D3                       * Shift left 8 to get rid of first 8 bits
                    MOVE.B  #13,D4
                    LSR.W   D4,D3                       * Shift right 16 to get next 8 bits
                    MOVE.B  D3, opDstMod
					
					** Condition is stored in opID - displacement is in DstMod
					** All thats leftis to branch per condition and output name, check reg if needed more
					** BRA - opID=0
					** BEQ - opID=7
					** BGT - opID=14
					** BLE - opID=15
					CMP.B	#0,opID
					BEQ		Fn_ID6_BRA
					CMP.B   #7,opID
					BEQ		Fn_ID6_BEQ
					CMP.B   #14,opID
					BEQ		Fn_ID6_BGT
					CMP.B   #15,opID
					BEQ     Fn_ID6_BLE
					BRA     Fn_ID6_ERROR

Fn_ID6_BRA			LEA     opNam_BRA,A3
					BRA 	Fn_ID6_Displacement
					
Fn_ID6_BEQ			LEA     opNam_BEQ,A3
					BRA 	Fn_ID6_Displacement
					
Fn_ID6_BGT			LEA     opNam_BGT,A3
					BRA 	Fn_ID6_Displacement
					
Fn_ID6_BLE			LEA     opNam_BLE,A3
					
Fn_ID6_Displacement	CMP.B	#$00,opDstMod
					BEQ		Fn_ID6_Dsplcmnt16
					CMP.B	#$FF,opDstMod
					BEQ		Fn_ID6_Dsplcmnt32
					** 8 bit is good
					MOVE.W	opDstMod,opDta2
					MOVE.B 	#0,opDta2T
					BRA     Fn_ID6_Done
					
Fn_ID6_Dsplcmnt16   MOVE.W  (A2)+,opDta2
					MOVE.B	#1,opDta2T
					BRA		Fn_ID6_Done

Fn_ID6_Dsplcmnt32   MOVE.L  (A2)+,opDta2
					MOVE.B	#2,opDta2T
					BRA		Fn_ID6_Done 

** ***************************************
** GLOBALS
** ***************************************
Fn_ID6_Error                                             * Exit out if error - main subroutine will handle DATA
                    *MOVEM.L (SP)+,D0-D7/A0-A6           * Restore registers
                    RTS 

Fn_ID6_Done        RTS
