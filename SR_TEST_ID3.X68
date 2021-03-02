SR_TEST_ID3
                    ** TEST: MOVE - reg to reg
                    **
                    ** MOVE.W (A1),(A1)
                    **   code: $3491
                    **
                    MOVE.W  #$3491, (A2)+
                    
                    ** TEST: MOVE - reg to reg
                    **
                    ** MOVE.W A1,D2
                    **   code: $3409
                    **
                    MOVE.W  #$3409, (A2)+
                    
                    ** TEST: MOVE - reg to reg
                    **
                    ** MOVE.W A1,A2
                    **   code: $3449
                    **
                    MOVE.W  #$3449, (A2)+
                    
                    ** TEST: MOVE - reg to reg
                    **
                    ** MOVE.W D1,A2
                    **   code: $3441
                    **
                    MOVE.W  #$3441, (A2)+
                    
                    ** TEST: MOVE - reg to reg
                    **
                    ** MOVE.W D1,D2
                    **   code: $3401
                    **
                    MOVE.W  #$3401, (A2)+                  
                    
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
                    
                    RTS
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
