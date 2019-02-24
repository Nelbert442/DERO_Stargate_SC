/* General Idea
    Address 1 --> SC --> Address 2
    When address 1 sends to SC, place hold on amount for Address 2 and X number of blocks that it will hold withdrawable balance until the address gets flipped back to address 1
    Addresses can request status, maybe 'pending' transactions from x address? should sender address be shown? Idk, kinda defeats purpose, maybe just simple response but SC knows sender/receiver somehow?
    When address requests to withdraw, check to ensure within block holding limit, some stored value upon deposit, and then send to address (maybe withhold 1% for tx fee on SC side? or just send it for now and figure out fees later, prob easiest)
*/

Function Initialize() Uint64
    10 STORE("owner", SIGNER())
    20 STORE("block_between_withdraw", 10)   
    30 STORE("total_deposit_count", 0)
    40 STORE("sc_giveback", 9500)   // SC will give reward 95% of deposits, 1 % is accumulated for owner to withdraw
    50 STORE("balance", 0)
    60 PRINTF "Initialize executed"
    70 RETURN 0
End Function

Function TuneTimeBoxParameters(block_between_withdraw Uint64, sc_giveback Uint64) Uint64
	10  IF ADDRESS_RAW(LOAD("owner")) == ADDRESS_RAW(SIGNER()) THEN GOTO 30 
	20  RETURN 1
	30  STORE("block_between_withdraw", block_between_withdraw) 
	40  STORE("sc_giveback", sc_giveback)   
	50  RETURN 0 
End Function

Function SendToAddr(destinationAddress String, value Uint64) Uint64
    // Add value to SC balance, print tx fees for user?, and store with destinationAddress & block_between_withdraw topoheight
    // Also store sender addr possibly hidden, useable for when Withdraw() is called and above block_between_withdraw

    10 DIM new_deposit_count, balance, block_height_limit as Uint64
    20 LET balance = LOAD("balance") + value
    30 STORE("balance", balance)
    40 LET new_deposit_count = LOAD("total_deposit_count") + 1
    50 LET block_height_limit = BLOCK_TOPOHEIGHT() + LOAD("block_between_withdraw")

    60 STORE(destinationAddress + new_deposit_count, SIGNER())
    70 STORE(destinationAddress + SIGNER() + new_deposit_count, value)
    80 STORE(SIGNER() + destinationAddress + new_deposit_count, block_height_limit)

    100 PRINTF "------------------------------------------------------------------"
    110 PRINTF "Deposit processed - will revert if not Withdrawn at height %d" block_height_limit
    120 PRINTF "------------------------------------------------------------------"
    130 STORE("total_deposit_count", new_deposit_count)
    140 RETURN 0
End Function

Function CheckPendingTx(destinationAddress String) Uint64
    // Check any pending Tx being sent for withdraw, similar code to use in Withdraw and SendToAddr, however this just returns value via printF or change Function output to string and swaps if necessary
    // If not within block_between_withdraw, then change destinationAddress to Sender Addr (maybe way to store this in SendToAddr and not show in daemon out?)
    // TODO Future: loop back and get all pending Tx, not just the first one that comes up (need todo in withdraw as well)

    10 DIM tempcounter,depositAmount,block_height_limit,new_deposit_count,pending_action as Uint64
    20 DIM senderAddr as String
    30 LET tempcounter = LOAD("total_deposit_count")
    40 IF tempcounter == 0 THEN GOTO 200
    50 LET new_deposit_count = tempcounter + 1
    60 LET pending_action = 0 // initialize pending_action at 0. If no withdraws take place, it won't be incremented [line 730 & 920] and will continue on to 210 after going to line 200

    100 IF EXISTS(destinationAddress + tempcounter) == 1 THEN GOTO 300
    110 IF tempcounter == 0 THEN GOTO 200 // extra check for == 0, shouldn't matter however since I'm GOTO this line in other places, just one more check to be certain
    120 LET tempcounter = tempcounter - 1
    130 PRINTF "Decreasing tempcounter to %d" tempcounter
    140 IF tempcounter != 0 THEN GOTO 100 ELSE GOTO 200

    200 IF pending_action > 0 THEN GOTO 850 ELSE GOTO 210
    210 PRINTF "--------------------------------------------------------"
    220 PRINTF "Did not find any additional transactions for %d" destinationAddress // doesn't know what SIGNER() is, assign to a variable and print that instead but got here . PERFECT!
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
End Function

Function Withdraw() Uint64
    // Withdraw all available (maybe one per Withdraw() call at first then future TODO?), as long as within block_between_withdraw blocks from SendToAddr
    // If not within block_between_withdraw, then change destinationAddress to Sender Addr (maybe way to store this in SendToAddr and not show in daemon out?)

    10 DIM tempcounter,depositAmount,block_height_limit,new_deposit_count,withdraw_action as Uint64
    20 DIM senderAddr,tempSigner as String
    30 LET tempcounter = LOAD("total_deposit_count")
    40 LET tempSigner = SIGNER() // used to clean-up calling SIGNER() over and over and over again [evals limit etc.]
    50 IF tempcounter == 0 THEN GOTO 200
    60 LET new_deposit_count = tempcounter + 1
    70 LET withdraw_action = 0 // initialize withdraw_action at 0. If no withdraws take place, it won't be incremented [line 730 & 920] and will continue on to 210 after going to line 200

    100 IF EXISTS(tempSigner + tempcounter) == 1 THEN GOTO 300
    110 IF tempcounter == 0 THEN GOTO 200 // extra check for == 0, shouldn't matter however since I'm GOTO this line in other places, just one more check to be certain
    120 LET tempcounter = tempcounter - 1
    130 PRINTF "Decreasing tempcounter to %d" tempcounter
    140 IF tempcounter != 0 THEN GOTO 100 ELSE GOTO 200

    200 IF withdraw_action > 0 THEN GOTO 940 ELSE GOTO 210
    210 PRINTF "--------------------------------------------------------"
    220 PRINTF "Did not find any additional transactions for %d" tempSigner // doesn't know what SIGNER() is, assign to a variable and print that instead but got here . PERFECT!
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
    830 LET depositAmount = LOAD("sc_giveback") * depositAmount / 10000
    840 PRINTF "--------------------------------------------------------"
    850 PRINTF "Withdrawing DERO of amount: %d" depositAmount
    860 PRINTF "--------------------------------------------------------"
    870 SEND_DERO_TO_ADDRESS(tempSigner, depositAmount) // SIGNER() is withdrawing; send them amount of stored depositAmount * stored sc_giveback / 10000 [taken from lottery.bas example]
    880 STORE(tempSigner + tempcounter, "") // reset values after withdraw (senderAddr to "")
    890 STORE(tempSigner + senderAddr + tempcounter, 0) // rest values after withdraw (depositAmount to 0)
    900 IF EXISTS(senderAddr + tempSigner + tempcounter) THEN GOTO 910 ELSE GOTO 920 // not every instance will there be a block_height_limit, say for example when sender gets tx back
    910 STORE(senderAddr + tempSigner + tempcounter, 0) // reset values after withdraw (block_height_limit to 0)
    920 LET withdraw_action = withdraw_action + 1
    930 GOTO 110 // Go back to loop through finding if any more withdraws are available to perform. Will come back to 940 if tempcounter reaches 0 and withdraw_action is > 0 [which it will be if withdraws / reversals have taken place]

    940 STORE("total_deposit_count", new_deposit_count - 1) // new_deposit_count incremented initially from total_deposit_count, so storing over itself if it never incremented from re-address. If re-address happens, by time exits it'll be 1 more than actual top count so - 1 still works
    950 RETURN 0 // exit out location for when a withdraw is performed or when a re-address is performed, withdraw_action is incremented then when tempcounter reaches 0 it'll come down here to exit out and store any values to be stored
End Function