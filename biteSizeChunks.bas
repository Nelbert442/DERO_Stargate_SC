/*  biteSizeChunks.bas
    Takes a transaction, with 0.5% fee off top, and sends it to a destination address. If the value is greater than 5 DERO, then the transactions being sent
    are split into 'biteSizeChunks' of 2 DERO or less

    Author: Nelbert442
    Media Handles: @Nelbert442
*/

Function Initialize() Uint64
    10 STORE("owner", SIGNER())
    40 STORE("sc_giveback", 9950)   // SC will give reward 99.5% of deposits, 0.5 % is accumulated for owner to withdraw as well as SC to keep for processing fees etc.
    50 STORE("balance", 0)
    60 STORE("total_fees_to_withdraw",0) // variable to hold amount of fees paid by users. This can be withdrawn by the owner using WithdrawFees()
    70 PRINTF "Initialize executed"
    80 RETURN 0
End Function

Function biteSizeChunks(destinationAddress String, value Uint64) Uint64
    10 DIM tempValue,tempBalance as Uint64
    15 DIM txid as String
    16 LET txid = TXID()
    20 LET tempBalance = LOAD("balance")
    30 IF value > 5000000000000 THEN GOTO 80 // If over 5 DERO in value, then go to loop through and small chunk payments. Else send 5 or less DERO to user
    40 STORE("balance",tempBalance - value)
    50 SEND_DERO_TO_ADDRESS(destinationAddress,value)
    60 RETURN 0

    80 LET tempValue = value

    100 IF tempValue < 2000000000000 THEN GOTO 200
    130 LET tempValue = tempValue - 2000000000000
    140 SEND_DERO_TO_ADDRESS(destinationAddress, 2000000000000)
    150 IF tempValue != 2000000000000 THEN GOTO 100

    200 SEND_DERO_TO_ADDRESS(destinationAddress,tempValue)
    205 STORE("balance",tempBalance - value)
    210 RETURN 0
End Function

Function Transaction(destinationAddress String, value Uint64) Uint64
    10 DIM tempValue,total_fees_to_withdraw as Uint64
    20 LET tempValue = LOAD("sc_giveback") * value / 10000
    30 LET total_fees_to_withdraw = value - tempValue
    40 STORE("total_fees_to_withdraw",total_fees_to_withdraw)
    50 STORE("balance",value)
    60 RETURN biteSizeChunks(destinationAddress, tempValue)
End Function

Function WithdrawFees(amount Uint64) Uint64 
	10 DIM total_fees_to_withdraw, total_fees_to_withdraw_updated as Uint64
    15 IF amount == 0 THEN GOTO 80  // if amount is 0, simply return
	20 LET total_fees_to_withdraw = LOAD("total_fees_to_withdraw")
	30 IF total_fees_to_withdraw <= amount THEN GOTO 90
	40 IF ADDRESS_RAW(LOAD("owner")) != ADDRESS_RAW(SIGNER()) THEN GOTO 90 

	50 SEND_DERO_TO_ADDRESS(SIGNER(),amount)
	60 LET total_fees_to_withdraw_updated = total_fees_to_withdraw - amount
	70 STORE("total_fees_to_withdraw", total_fees_to_withdraw_updated)

	80 RETURN 0
	90 RETURN 1
End Function