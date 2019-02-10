Function Initialize() Uint64
	10 STORE("owner", SIGNER())
	40 PRINTF "Initialize executed"
	50 RETURN 0 
End Function

Function IsAddressValid(address String) Uint64
    10 IF IS_ADDRESS_VALID(address) THEN GOTO 40
    20 PRINTF "Address %d is NOT valid." address
    30 RETURN 1
    40 PRINTF "Address %d is valid." address
    50 RETURN 0    
End Function