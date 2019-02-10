Function Initialize() Uint64
	10 STORE("owner", SIGNER())
	40 PRINTF "Initialize executed"
	50 RETURN 0 
End Function

Function FutureLoop() Uint64
    10 DIM futureBlock,n as Uint64
    20 LET futureBlock = BLOCK_TOPOHEIGHT() + 10
    30 LET n = futureBlock - BLOCK_TOPOHEIGHT()
    40 PRINTF "%d blocks to go." n
    50 IF BLOCK_TOPOHEIGHT() < futureBlock THEN GOTO 30
    60 PRINTF "We just looped through 10 blocks!"
    70 RETURN 0   
End Function

//IF EXISTS(futureBlock) THEN LOAD(futureBlock) ELSE LET futureBlock = BLOCK_TOPOHEIGHT() + 10 // If futureBlock was stored, reload it and test to see if needs to be updated
//IF BLOCK_TOPOHEIGHT() > futureBlock THEN LET futureBlock = BLOCK_TOPOHEIGHT() + 10 // Meaning futureBlock needs to be updated as time has passed since last run
//Need to store vars so can re-call maybe? seems like the infinite loop above bc getting evaluated at the current block and never exits out
//TODO: maybe can re-call SC from within? Not sure, reading up on chat to see, can try again later