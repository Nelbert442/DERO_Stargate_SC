/*  TimeBox Payments Smart Contract in DVM-BASIC
    Send "time"-based or "block"-based transactions which can be Withdrawn within that allotted time or block count.
    However, if the 2nd party does not withdraw the sent balance, then the originating party can then re-withdraw the balance back (with slight fee based on sc_giveback for processing) at any time.

    Author: Nelbert442
    Media Handles: @Nelbert442
*/

Function Initialize() Uint64
    10 STORE("owner", SIGNER())
    20 STORE("block_between_withdraw", 100)   
    30 STORE("total_deposit_count", 0)
    40 STORE("sc_giveback", 9900)   // SC will give reward 99% of deposits, 1 % is accumulated for owner to withdraw as well as SC to keep for processing fees etc.
    50 STORE("balance", 0)
    60 STORE("total_fees_to_withdraw",0) // variable to hold amount of fees paid by users. This can be withdrawn by the owner using WithdrawFees()
    70 PRINTF "Initialize executed"
    80 RETURN 0
End Function

Function TuneTimeBoxParameters(block_between_withdraw Uint64, sc_giveback Uint64) Uint64
	10  IF ADDRESS_RAW(LOAD("owner")) == ADDRESS_RAW(SIGNER()) THEN GOTO 30 // Validate owner is one calling this function, otherwise return 1
	20  RETURN 1
	30  STORE("block_between_withdraw", block_between_withdraw) 
	40  STORE("sc_giveback", sc_giveback)   
	50  RETURN 0 
End Function

Function Error(value Uint64) Uint64
    10 DIM return_balance as Uint64
    11 DIM txid as String
    12 LET txid = TXID()
    15 LET return_balance = value
    20 IF (LOAD("balance") + return_balance) > return_balance THEN GOTO 50 // seems silly, but loads balance and if balance = 0 then + return_balance is never going to be > return_balance, so take 1% off for fee
    30 LET return_balance = 9900 * return_balance / 10000 // no need to store this fee for withdraw, it's safe to have a small amount stored in SC that is not withdrawable for tx fees later "cost of doing business"
    40 STORE("balance", value - return_balance) // should only be ran when no funds (new SC initialization etc.)

    50 PRINTF "------------------------------------------------------------------"
    55 PRINTF "Returning a balance of %d to sender." return_balance
    60 PRINTF "TXID: %s" txid
    65 PRINTF "------------------------------------------------------------------"

    100 SEND_DERO_TO_ADDRESS(SIGNER(), return_balance)

    999 RETURN 0
End Function

Function SendToAddr(destinationAddress String, value Uint64) Uint64
    // Add value to SC balance, and store values based off of destinationAddress, SIGNER() and block_between_withdraw topoheight
    // If deposit rejected, return value sent with transaction, or if not enough SC balance, then return 99% of value sent with transaction

    10 DIM new_deposit_count, balance, block_height_limit, tempcounter as Uint64
    20 DIM senderAddr,txid as String
    25 IF value == 0 THEN GOTO 240  // if value is 0, simply return
    30 IF IS_ADDRESS_VALID(destinationAddress) THEN GOTO 40 ELSE GOTO 500 // check to ensure entered destinationAddress is valid
    40 LET new_deposit_count = LOAD("total_deposit_count") + 1
    50 LET block_height_limit = BLOCK_TOPOHEIGHT() + LOAD("block_between_withdraw")
    60 LET tempcounter = new_deposit_count
    70 LET senderAddr = SIGNER() // To prevent cost of processing and load times
    80 LET txid = TXID()

    100 IF EXISTS(senderAddr + destinationAddress + tempcounter) == 1 THEN GOTO 300 ELSE GOTO 110 // if exists, go to 300 and reject deposit because deposit is already submitted for this block_height_limit [NOTE: This could pose issues if TuneTimeBoxParameters() was ran and vals are similar, possibly, though rare (need testing to see if loophole is avail)]
    110 IF tempcounter == 0 THEN GOTO 170 // extra check for == 0, just one more check to be certain
    120 LET tempcounter = tempcounter - 1
    130 PRINTF "------------------------------------------------------------------"
    140 PRINTF "Searching for duplicate Transactions at this blockheight: %d left" tempcounter
    150 PRINTF "------------------------------------------------------------------"
    160 IF tempcounter != 0 THEN GOTO 100 ELSE GOTO 170

    170 LET balance = LOAD("balance") + value
    175 STORE("balance", balance)
    180 STORE(destinationAddress + new_deposit_count, senderAddr)
    185 STORE(destinationAddress + senderAddr + new_deposit_count, value)
    190 STORE(senderAddr + destinationAddress + new_deposit_count, block_height_limit)

    200 PRINTF "------------------------------------------------------------------"
    210 PRINTF "Deposit processed - will revert if not Withdrawn at height %d" block_height_limit
    215 PRINTF "TXID: %s" txid
    220 PRINTF "------------------------------------------------------------------"
    230 STORE("total_deposit_count", new_deposit_count)
    240 RETURN 0

    300 IF LOAD(senderAddr + destinationAddress + tempcounter) == block_height_limit THEN GOTO 350 ELSE GOTO 110 // since it exists, check to see if values are equal. If not go back and keep looping down, else return rejected and 1

    350 PRINTF "------------------------------------------------------------------"
    360 PRINTF "Deposit rejected - Deposit already found that ends at %d, try again in at least 1 block (~12s)" block_height_limit
    370 PRINTF "------------------------------------------------------------------"
    380 RETURN Error(value)

    500 PRINTF "------------------------------------------------------------------"
    510 PRINTF "Deposit rejected - supplied destinationAddress is not valid. Please check parameters and try again."
    520 PRINTF "------------------------------------------------------------------"
    530 RETURN Error(value)
End Function

Function CheckPendingTx(destinationAddress String) Uint64
    // Check any pending Tx being sent for withdraw, similar code to use in Withdraw and SendToAddr, however this just returns value via printF or change Function output to string and swaps if necessary
    // If not within block_between_withdraw, then change destinationAddress to Sender Addr

    10 DIM tempcounter,depositAmount,block_height_limit,new_deposit_count,pending_action as Uint64
    20 DIM senderAddr as String
    30 IF IS_ADDRESS_VALID(destinationAddress) THEN GOTO 40 ELSE GOTO 900 // check to ensure entered destinationAddress is valid
    40 LET tempcounter = LOAD("total_deposit_count")
    50 IF tempcounter == 0 THEN GOTO 200
    60 LET new_deposit_count = tempcounter + 1
    70 LET pending_action = 0 // initialize pending_action at 0. If no withdraws take place, it won't be incremented [line 710 & 830] and will continue on to 210 after going to line 200

    100 IF EXISTS(destinationAddress + tempcounter) == 1 THEN GOTO 300
    110 IF tempcounter == 0 THEN GOTO 200 // extra check for == 0, just one more check to be certain
    120 LET tempcounter = tempcounter - 1
    130 PRINTF "Decreasing tempcounter to %d" tempcounter
    140 IF tempcounter != 0 THEN GOTO 100 ELSE GOTO 200

    200 IF pending_action > 0 THEN GOTO 850 ELSE GOTO 210
    210 PRINTF "--------------------------------------------------------"
    220 PRINTF "Did not find any additional transactions for %d" destinationAddress
    230 PRINTF "--------------------------------------------------------"
    240 RETURN 1

    300 LET senderAddr = LOAD(destinationAddress + tempcounter)
    310 IF senderAddr == "" THEN GOTO 110 // if senderAddr has been set to "", then go to 110 to decrement tempcounter and continue searching
    320 IF EXISTS(destinationAddress + senderAddr + tempcounter) == 1 THEN GOTO 330 ELSE GOTO 110
    330 LET depositAmount = LOAD(destinationAddress + senderAddr + tempcounter)
    340 IF depositAmount == 0 THEN GOTO 110 // if depositAmount has been set to 0, then go to 110 to decrement tempcounter and continue searching
    350 PRINTF "------------------"
    360 PRINTF "Transaction found!"
    370 PRINTF "------------------"
    380 IF EXISTS(senderAddr + destinationAddress + tempcounter) == 1 THEN GOTO 390 ELSE GOTO 800 // if no block_height_limit, then means transaction reverted at some point and original sender gets amount back
    390 LET block_height_limit = LOAD(senderAddr + destinationAddress + tempcounter)
    400 IF block_height_limit >= BLOCK_TOPOHEIGHT() THEN GOTO 800

    580 STORE(senderAddr + new_deposit_count, destinationAddress) // start re-assignment process. Set Withdrawer to original sender
    590 STORE(senderAddr + destinationAddress + new_deposit_count, depositAmount) // Set deposit amount variable
    // 600 STORE(destinationAddress + senderAddr + new_deposit_count, BLOCK_TOPOHEIGHT() + LOAD("block_between_withdraw")) // do not store a new block height because line 360 will then reach withdraw stage
    // clean up the other transaction information so that you cannot go withdraw after the block height has increased past allotted height
    610 LET new_deposit_count = new_deposit_count + 1
    620 PRINTF "-----------------------------------------------------------------------"
    630 PRINTF "Reached top block height for deposit, reversing deposit back to sender."
    640 PRINTF "-----------------------------------------------------------------------"
    650 STORE(destinationAddress + tempcounter, "") // set senderAddr to ""
    660 STORE(destinationAddress + senderAddr + tempcounter, 0) // set depositAmount to 0
    670 STORE(senderAddr + destinationAddress + tempcounter, 0) // set block_height_limit to 0
    680 PRINTF "------------------------------------------------------------------------"
    690 PRINTF "Previous Tx information has been cleaned up and reset to default values."
    700 PRINTF "------------------------------------------------------------------------"
    710 LET pending_action = pending_action + 1
    720 GOTO 110 // Go back to loop through finding if any more pending actions are available. Will come back to 850 if tempcounter reaches 0 and pending_action is > 0 [which it will be if pending tx / reversals have taken place]
    // 730 RETURN 0 // not need anymore since we will be going back to 110 then down to 850 for Return 0, keeping commented for few commits

    800 PRINTF "--------------------------------------------------------"
    810 PRINTF "There is one or more pending TX available to Withdraw still, run Withdraw() to get them before they expire!"
    820 PRINTF "--------------------------------------------------------"
    830 LET pending_action = pending_action + 1
    840 GOTO 110 // Go back to loop through finding if any more pending actions are available. Will come back to 850 if tempcounter reaches 0 and pending_action is > 0 [which it will be if pending tx / reversals have taken place]

    850 STORE("total_deposit_count", new_deposit_count - 1) // new_deposit_count incremented initially from total_deposit_count, so storing over itself if it never incremented from re-address. If re-address happens, by time exits it'll be 1 more than actual top count so - 1 still works
    860 RETURN 0

    900 PRINTF "------------------------------------------------------------------"
    910 PRINTF "Function rejected - supplied destinationAddress is not valid. Please check parameters and try again."
    920 PRINTF "------------------------------------------------------------------"
    930 RETURN 1
End Function

Function Withdraw() Uint64
    // Withdraw all available, as long as within block_between_withdraw blocks from SendToAddr
    // If not within block_between_withdraw, then change destinationAddress to Sender Addr

    10 DIM tempcounter,depositAmount,block_height_limit,new_deposit_count,withdraw_action,tempFeeAmt as Uint64
    20 DIM senderAddr,tempSigner,txid as String
    30 LET tempcounter = LOAD("total_deposit_count")
    40 LET tempSigner = SIGNER() // used to clean-up calling SIGNER() over and over and over again [evals limit etc.]
    50 IF tempcounter == 0 THEN GOTO 200
    60 LET new_deposit_count = tempcounter + 1
    70 LET withdraw_action = 0 // initialize withdraw_action at 0. If no withdraws take place, it won't be incremented [line 730 & 920] and will continue on to 210 after going to line 200
    80 LET txid = TXID()

    100 IF EXISTS(tempSigner + tempcounter) == 1 THEN GOTO 300
    110 IF tempcounter == 0 THEN GOTO 200 // extra check for == 0, just one more check to be certain
    120 LET tempcounter = tempcounter - 1
    130 PRINTF "Decreasing tempcounter to %d" tempcounter
    140 IF tempcounter != 0 THEN GOTO 100 ELSE GOTO 200

    200 IF withdraw_action > 0 THEN GOTO 940 ELSE GOTO 210
    210 PRINTF "--------------------------------------------------------"
    220 PRINTF "Did not find any additional transactions for %d" tempSigner // doesn't know what SIGNER() is, assign to a variable and print that instead, helps with processing times / loads as well
    230 PRINTF "--------------------------------------------------------"
    240 RETURN 1

    300 LET senderAddr = LOAD(tempSigner + tempcounter)
    310 IF senderAddr == "" THEN GOTO 110 // if senderAddr has been set to "", then go to 110 to decrement tempcounter and continue searching
    320 IF EXISTS(tempSigner + senderAddr + tempcounter) == 1 THEN GOTO 330 ELSE GOTO 200
    330 LET depositAmount = LOAD(tempSigner + senderAddr + tempcounter)
    340 IF depositAmount == 0 THEN GOTO 110 // if depositAmount has been set to 0, then go to 110 to decrement tempcounter and continue searching
    350 PRINTF "------------------"
    360 PRINTF "Transaction found!"
    370 PRINTF "------------------"
    380 IF EXISTS(senderAddr + tempSigner + tempcounter) == 1 THEN GOTO 390 ELSE GOTO 800 // if no block_height_limit, then means transaction reverted at some point and original sender gets amount back
    390 LET block_height_limit = LOAD(senderAddr + tempSigner + tempcounter)
    400 IF block_height_limit >= BLOCK_TOPOHEIGHT() THEN GOTO 800

    600 STORE(senderAddr + new_deposit_count, tempSigner) // start re-assignment process. Set Withdrawer to original sender
    610 STORE(senderAddr + tempSigner + new_deposit_count, depositAmount) // Set deposit amount variable
    // 620 STORE(tempSigner + senderAddr + new_deposit_count, BLOCK_TOPOHEIGHT() + LOAD("block_between_withdraw")) // do not store a new block height because line 360 will then reach withdraw stage
    // clean up the other transaction information so that you cannot go withdraw after the block height has increased past allotted height
    630 LET new_deposit_count = new_deposit_count + 1
    640 PRINTF "-----------------------------------------------------------------------"
    650 PRINTF "Reached top block height for deposit, reversing deposit back to sender."
    660 PRINTF "-----------------------------------------------------------------------"
    670 STORE(tempSigner + tempcounter, "") // set senderAddr to ""
    680 STORE(tempSigner + senderAddr + new_deposit_count, 0) // set depositAmount to 0
    690 STORE(senderAddr + tempSigner + tempcounter, 0) // set block_height_limit to 0
    700 PRINTF "------------------------------------------------------------------------"
    710 PRINTF "Previous Tx information has been cleaned up and reset to default values."
    720 PRINTF "------------------------------------------------------------------------"
    730 LET withdraw_action = withdraw_action + 1
    740 GOTO 110 // Go back to loop through finding if any more withdraws are available to perform. Will go to 940 if tempcounter reaches 0 and withdraw_action is > 0 [which it will be if withdraws / reversals have taken place]
    // 750 RETURN 0 // not need anymore since we will be going back to 110 then down to 940 for Return 0, keeping commented for few commits

    800 PRINTF "--------------------------------------------------------"
    810 PRINTF "Reached withdraw stage for: %d" tempSigner // TODO: Start withdraw process, make sure to set values to 0 afterwards (or remove variables from memory if possible?)
    820 PRINTF "--------------------------------------------------------"
    825 LET tempFeeAmt = depositAmount // set tempFeeAmt to depositAmount to later use in subtract to find fee [this prevent multiple loads of a stored variable sc_giveback]
    830 LET depositAmount = LOAD("sc_giveback") * depositAmount / 10000
    835 LET tempFeeAmt = tempFeeAmt - depositAmount
    836 STORE("total_fees_to_withdraw",LOAD("total_fees_to_withdraw") + tempFeeAmt)
    840 PRINTF "--------------------------------------------------------"
    850 PRINTF "Withdrawing DERO of amount: %d" depositAmount
    855 PRINTF "TXID: %s" txid
    860 PRINTF "--------------------------------------------------------"
    870 SEND_DERO_TO_ADDRESS(tempSigner, depositAmount) // SIGNER() is withdrawing; send them amount of stored depositAmount * stored sc_giveback / 10000 [taken from lottery.bas example]
    880 STORE(tempSigner + tempcounter, "") // reset values after withdraw (senderAddr to "")
    890 STORE(tempSigner + senderAddr + tempcounter, 0) // rest values after withdraw (depositAmount to 0)
    900 IF EXISTS(senderAddr + tempSigner + tempcounter) THEN GOTO 910 ELSE GOTO 920 // not every instance will there be a block_height_limit, say for example when sender gets tx back
    910 STORE(senderAddr + tempSigner + tempcounter, 0) // reset values after withdraw (block_height_limit to 0)
    915 STORE("balance",LOAD("balance") - depositAmount)
    920 LET withdraw_action = withdraw_action + 1
    930 GOTO 110 // Go back to loop through finding if any more withdraws are available to perform. Will come back to 940 if tempcounter reaches 0 and withdraw_action is > 0 [which it will be if withdraws / reversals have taken place]

    940 STORE("total_deposit_count", new_deposit_count - 1) // new_deposit_count incremented initially from total_deposit_count, so storing over itself if it never incremented from re-address. If re-address happens, by time exits it'll be 1 more than actual top count so - 1 still works
    950 RETURN 0 // exit out location for when a withdraw is performed or when a re-address is performed, withdraw_action is incremented then when tempcounter reaches 0 it'll come down here to exit out and store any values to be stored
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