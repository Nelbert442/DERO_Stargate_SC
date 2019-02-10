Function Initialize() Uint64
	10 STORE("owner", SIGNER())
	40 PRINTF "Initialize executed"
	50 RETURN 0 
End Function

Function FutureLoop() Uint64
    10 LET futureBlock = BLOCK_TOPOHEIGHT() + 10
    20 DO while BLOCK_TOPOHEIGHT() < futureBlock
    30      LET n = futureBlock - BLOCK_TOPOHEIGHT()
    40      PRINTF "%d blocks to go." n
    50 LOOP
    60 PRINTF "We just looped through 10 blocks!"
    70 RETURN 0   
End Function