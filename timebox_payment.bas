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
    40 STORE("scbalance", 0)
    50 PRINTF "Initialize executed"
    60 RETURN 0
End Function

Function SendToAddr(destinationAddress String, amount_transfer Uint64) Uint64
    // Add amount_transfer to SC balance, print tx fees for user?, and store with destinationAddress & block_between_withdraw topoheight
    // Also store sender addr possibly hidden, useable for when Withdraw() is called and above block_between_withdraw

    10 DIM new_deposit_count as Uint64
    20 STORE("scbalance", LOAD("scbalance") + amount_transfer)
    30 LET new_deposit_count = LOAD("total_deposit_count") + 1

    50 STORE(destinationAddress + new_deposit_count, SIGNER())
    60 STORE(destinationAddress + SIGNER(), amount_transfer)
    70 STORE(SIGNER() + destinationAddress + new_deposit_count, BLOCK_TOPOHEIGHT() + LOAD("block_between_withdraw"))

    100 PRINTF "-----------------"
    110 PRINTF "Deposit processed"
    120 PRINTF "-----------------"
    130 STORE("total_deposit_count", new_deposit_count)
    140 RETURN 0
End Function

Function CheckPendingTx(destinationAddress String) Uint64
    // Check any pending Tx being sent for withdraw, similar code to use in Withdraw and SendToAddr, however this just returns value via printF or change Function output to string and swaps if necessary
    // If not within block_between_withdraw, then change destinationAddress to Sender Addr (maybe way to store this in SendToAddr and not show in daemon out?)
    // TODO Future: loop back and get all pending Tx, not just the first one that comes up (need todo in withdraw as well)

    10 DIM tempcounter,depositAmount,block_height_limit,new_deposit_count as Uint64
    20 DIM senderAddr as String
    30 LET tempcounter = LOAD("total_deposit_count")
    40 IF tempcounter == 0 THEN GOTO 200
    50 LET new_deposit_count = tempcounter + 1

    100 IF EXISTS(destinationAddress + tempcounter) == 1 THEN GOTO 300
    110 IF tempcounter == 0 THEN GOTO 200 // extra check for == 0, shouldn't matter however since I'm GOTO this line in other places, just one more check to be certain
    120 LET tempcounter = tempcounter - 1
    130 PRINTF "Decreasing tempcounter to %d" tempcounter
    140 IF tempcounter != 0 THEN GOTO 100 ELSE GOTO 200

    190 PRINTF "--------------------------------------------------------"
    200 PRINTF "Did not find any transactions for %d" destinationAddress // doesn't know what SIGNER() is, assign to a variable and print that instead but got here . PERFECT!
    210 PRINTF "--------------------------------------------------------"
    220 RETURN 1

    300 LET senderAddr = LOAD(destinationAddress + tempcounter)
    310 IF senderAddr == "" THEN GOTO 110 // if senderAddr has been set to "", then go to 110 to decrement tempcounter and continue searching
    320 IF EXISTS(destinationAddress + senderAddr) == 1 THEN GOTO 330 ELSE GOTO 110
    330 LET depositAmount = LOAD(destinationAddress + senderAddr)
    340 IF depositAmount == 0 THEN GOTO 110 // if depositAmount has been set to 0, then go to 110 to decrement tempcounter and continue searching
    350 PRINTF "------------------"
    360 PRINTF "Transaction found!"
    370 PRINTF "------------------"
    380 IF EXISTS(senderAddr + destinationAddress + tempcounter) == 1 THEN GOTO 390 ELSE GOTO 800 // if no block_height_limit, then means transaction reverted at some point and original sender gets amount back
    390 LET block_height_limit = LOAD(senderAddr + destinationAddress + tempcounter)
    400 IF block_height_limit >= BLOCK_TOPOHEIGHT() THEN GOTO 800

    580 STORE(senderAddr + new_deposit_count, destinationAddress) // start re-assignment process. Set Withdrawer to original sender
    590 STORE(senderAddr + destinationAddress, depositAmount) // Set deposit amount variable
    // 600 STORE(destinationAddress + senderAddr + new_deposit_count, BLOCK_TOPOHEIGHT() + LOAD("block_between_withdraw")) // do not store a new block height because line 360 will then reach withdraw stage
    // clean up the other transaction information so that you cannot go withdraw after the block height has increased past allotted height
    610 STORE("total_deposit_count", new_deposit_count)
    620 PRINTF "-----------------------------------------------------------------------"
    630 PRINTF "Reached top block height for deposit, reversing deposit back to sender."
    640 PRINTF "-----------------------------------------------------------------------"
    650 STORE(destinationAddress + tempcounter, "") // set senderAddr to ""
    660 STORE(destinationAddress + senderAddr, 0) // set depositAmount to 0
    670 STORE(senderAddr + destinationAddress + tempcounter, 0) // set block_height_limit to 0
    680 PRINTF "------------------------------------------------------------------------"
    690 PRINTF "Previous Tx information has been cleaned up and reset to default values."
    700 PRINTF "------------------------------------------------------------------------"
    710 RETURN 0

    800 PRINTF "--------------------------------------------------------"
    810 PRINTF "There are pending TX available to Withdraw still, run Withdraw() to get them before they time out! For: %d" destinationAddress
    820 PRINTF "--------------------------------------------------------"
    830 RETURN 0
End Function

Function Withdraw() Uint64
    // Withdraw all available (maybe one per Withdraw() call at first then future TODO?), as long as within block_between_withdraw blocks from SendToAddr
    // If not within block_between_withdraw, then change destinationAddress to Sender Addr (maybe way to store this in SendToAddr and not show in daemon out?)
    // TODO Future: Save ~1% or less for tx fees outside of chain txfees into SC balance
    // TODO Future: loop back and get all pending Tx, not just the first one that comes up (need todo in CheckPendingTx as well)

    10 DIM tempcounter,depositAmount,block_height_limit,new_deposit_count as Uint64
    20 DIM senderAddr,tempSigner as String
    30 LET tempcounter = LOAD("total_deposit_count")
    40 LET tempSigner = SIGNER() // just used for Line 200 output
    50 IF tempcounter == 0 THEN GOTO 200
    60 LET new_deposit_count = tempcounter + 1

    100 IF EXISTS(SIGNER() + tempcounter) == 1 THEN GOTO 300
    110 IF tempcounter == 0 THEN GOTO 200 // extra check for == 0, shouldn't matter however since I'm GOTO this line in other places, just one more check to be certain
    120 LET tempcounter = tempcounter - 1
    130 PRINTF "Decreasing tempcounter to %d" tempcounter
    140 IF tempcounter != 0 THEN GOTO 100 ELSE GOTO 200

    190 PRINTF "--------------------------------------------------------"
    200 PRINTF "Did not find any transactions for %d" tempSigner // doesn't know what SIGNER() is, assign to a variable and print that instead but got here . PERFECT!
    210 PRINTF "--------------------------------------------------------"
    220 RETURN 1

    300 LET senderAddr = LOAD(SIGNER() + tempcounter)
    310 IF senderAddr == "" THEN GOTO 110 // if senderAddr has been set to "", then go to 110 to decrement tempcounter and continue searching
    320 IF EXISTS(SIGNER() + senderAddr) == 1 THEN GOTO 330 ELSE GOTO 200
    330 LET depositAmount = LOAD(SIGNER() + senderAddr)
    340 IF depositAmount == 0 THEN GOTO 110 // if depositAmount has been set to 0, then go to 110 to decrement tempcounter and continue searching
    350 PRINTF "------------------"
    360 PRINTF "Transaction found!"
    370 PRINTF "------------------"
    380 IF EXISTS(senderAddr + SIGNER() + tempcounter) == 1 THEN GOTO 390 ELSE GOTO 800 // if no block_height_limit, then means transaction reverted at some point and original sender gets amount back
    390 LET block_height_limit = LOAD(senderAddr + SIGNER() + tempcounter)
    400 IF block_height_limit >= BLOCK_TOPOHEIGHT() THEN GOTO 800

    600 STORE(senderAddr + new_deposit_count, SIGNER()) // start re-assignment process. Set Withdrawer to original sender
    610 STORE(senderAddr + SIGNER(), depositAmount) // Set deposit amount variable
    // 620 STORE(SIGNER() + senderAddr + new_deposit_count, BLOCK_TOPOHEIGHT() + LOAD("block_between_withdraw")) // do not store a new block height because line 360 will then reach withdraw stage
    // clean up the other transaction information so that you cannot go withdraw after the block height has increased past allotted height
    630 STORE("total_deposit_count", new_deposit_count)
    640 PRINTF "-----------------------------------------------------------------------"
    650 PRINTF "Reached top block height for deposit, reversing deposit back to sender."
    660 PRINTF "-----------------------------------------------------------------------"
    670 STORE(destinationAddress + tempcounter, "") // set senderAddr to ""
    680 STORE(destinationAddress + senderAddr, 0) // set depositAmount to 0
    690 STORE(senderAddr + destinationAddress + tempcounter, 0) // set block_height_limit to 0
    700 PRINTF "------------------------------------------------------------------------"
    710 PRINTF "Previous Tx information has been cleaned up and reset to default values."
    720 PRINTF "------------------------------------------------------------------------"
    730 RETURN 0

    800 PRINTF "--------------------------------------------------------"
    810 PRINTF "Reached withdraw stage for: %d" tempSigner // TODO: Start withdraw process, make sure to set values to 0 afterwards (or remove variables from memory if possible?)
    820 PRINTF "--------------------------------------------------------"
    830 RETURN 0
End Function