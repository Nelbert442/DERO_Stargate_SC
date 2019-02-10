Function Initialize() Uint64
	10 STORE("owner", SIGNER())
	40 PRINTF "Initialize executed"
	50 RETURN 0 
End Function

// Returns a 0 or 1 (Uint64) if address is valid or not
Function IsAddressValid(address String) Uint64
    10 IF IS_ADDRESS_VALID(address) THEN GOTO 40
    20 PRINTF "Address %d is NOT valid." address
    30 RETURN 1
    40 PRINTF "Address %d is valid." address
    50 RETURN 0    
End Function

/* Returns String output (String) stating if address is valid or not
*Function IsAddressValid(address String) String
*    10 IF IS_ADDRESS_VALID(address) THEN GOTO 40 // Could have else here, however easy to read that it is not valid otherwise
*    20 RETURN "Address ("+address+") is NOT valid"
*    40 RETURN "Address ("+address+") is valid."
*End Function
*/