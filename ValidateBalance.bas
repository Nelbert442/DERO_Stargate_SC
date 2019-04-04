/*
    SC to allow for an owner (defined at time of SC initialization or when TransferOwnership() & ClaimOwnership() is ran) to deposit/withdraw funds from the SC
    Any user is able to view the current balance available in the SC with a provided SCID via rpc call
*/

Function Initialize() Uint64
	10 STORE("owner", SIGNER())
	20 STORE("balance", 0) 
    30 STORE("TXIDCount", 0)
    35 PRINTF "-------------------------------------------------------------"
	40 PRINTF "Initialize executed, you can now Deposit() funds for tracking"
    45 PRINTF "-------------------------------------------------------------"
	50 RETURN 0 
End Function

// this function is used to change owner 
// owner is an string form of address 
Function TransferOwnership(newowner String) Uint64 
    10  IF ADDRESS_RAW(LOAD("owner")) == ADDRESS_RAW(SIGNER()) THEN GOTO 30 
    20  RETURN 1
    30  STORE("tmpowner",newowner)
    40  RETURN 0
End Function

// until the new owner claims ownership, existing owner remains owner
Function ClaimOwnership() Uint64 
    10  IF ADDRESS_RAW(LOAD("tmpowner")) == ADDRESS_RAW(SIGNER()) THEN GOTO 30 
    20  RETURN 1
    30  STORE("owner",SIGNER()) // ownership claim successful
    40  RETURN 0
End Function

Function Deposit(value Uint64) Uint64
	10 DIM balance, tempcounter as Uint64
    11 DIM txid as String
    15 IF value == 0 THEN GOTO 110  // if value is 0, simply return
    20 IF ADDRESS_RAW(LOAD("owner")) == ADDRESS_RAW(SIGNER()) THEN GOTO 50
    25 PRINTF "----------------------------------------------------------------------"
    30 PRINTF "You are not the owner of this SCID and therefore cannot deposit funds."
    35 PRINTF "----------------------------------------------------------------------"
    40 RETURN 1

	50 LET balance = LOAD("balance") + value
	60 STORE("balance", balance)
    70 LET tempcounter = LOAD("TXIDCount") + 1
    75 LET txid = TXID()
    80 STORE("txid_" + tempcounter, txid + " (deposit)")
    90 STORE("TXIDCount", tempcounter)
    95 PRINTF "----------------------------------------------------------------------"
	100 PRINTF "Deposit executed. TXID: %s" txid
    105 PRINTF "----------------------------------------------------------------------"
	110 RETURN 0
End Function

Function Withdraw(amount Uint64) Uint64
    10 DIM balance, balance_updated, tempcounter as Uint64
    11 DIM txid as String
    15 IF amount == 0 THEN GOTO 170  // if amount is 0, simply return
    20 IF ADDRESS_RAW(LOAD("owner")) == ADDRESS_RAW(SIGNER()) THEN GOTO 50
    25 PRINTF "-----------------------------------------------------------------------"
    30 PRINTF "You are not the owner of this SCID and therefore cannot withdraw funds."
    35 PRINTF "-----------------------------------------------------------------------"
    40 RETURN 1

    50 LET balance = LOAD("balance")
    60 IF balance > amount THEN GOTO 100
    65 PRINTF "-----------------------------------------------------------------------"
    70 PRINTF "Insufficient balance available for withdraw (%d). You attempted to withdraw %d" balance amount
    75 PRINTF "-----------------------------------------------------------------------"
    80 RETURN 1

    100 SEND_DERO_TO_ADDRESS(SIGNER(), amount)
    110 LET balance_updated = balance - amount
    120 STORE("balance", balance_updated)
    130 LET tempcounter = LOAD("TXIDCount") + 1
    135 LET txid = TXID()
    140 STORE("txid_" + tempcounter, txid + " (withdraw)")
    145 STORE("TXIDCount", tempcounter)
    150 PRINTF "-----------------------------------------------------------------------"
    155 PRINTF "Withdrew %d. There is a total of %d remaining in this SC." amount balance_updated
    160 PRINTF "TXID: %s" txid
    165 PRINTF "-----------------------------------------------------------------------"
    170 RETURN 0
End Function

Function ListTXIDs() Uint64
    10 DIM tempcounter as Uint64
    11 DIM txid as String
    20 LET tempcounter = LOAD("TXIDCount")
    30 PRINTF "-----------------------------------"
    35 PRINTF "There are %d TXIDs to print." tempcounter
    40 PRINTF "-----------------------------------"
    45 PRINTF "-----------------------------------"

    50 IF EXISTS("txid_" + tempcounter) == 1 THEN GOTO 60 ELSE GOTO 800
    60 IF tempcounter == 0 THEN GOTO 200
    70 LET txid = LOAD("txid_" + tempcounter)
    75 PRINTF "| -- TXID: %s" txid
    90 LET tempcounter = tempcounter - 1
    100 IF tempcounter != 0 THEN GOTO 50 ELSE GOTO 200

    200 PRINTF "-----------------------------------"
    210 RETURN 0

    800 IF tempcounter == 0 THEN GOTO 200 ELSE GOTO 90 // Rarely should come here, but if you get here, check to ensure tempcounter == 0 or not, if so go to 200 and return; else go to 90 and decrease tempcounter
End Function

Function ViewBalance() Uint64
    10 DIM balance as Uint64
    20 LET balance = LOAD("balance")
    25 PRINTF "-----------------------------------"
    30 PRINTF "SC Balance (in Uint64): %d" balance
    35 PRINTF "-----------------------------------"
    40 RETURN 0
End Function