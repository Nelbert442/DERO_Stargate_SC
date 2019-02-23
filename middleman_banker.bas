/* General Idea
    Address 1 --> SC --> Address 2
    When address 1 sends to SC, place hold on amount for Address 2 and X number of blocks that it will hold withdrawable balance until the address gets flipped back to address 1
    Addresses can request status, maybe 'pending' transactions from x address? should sender address be shown? Idk, kinda defeats purpose, maybe just simple response but SC knows sender/receiver somehow?
    When address requests to withdraw, check to ensure within block holding limit, some stored value upon deposit, and then send to address (maybe withhold 1% for tx fee on SC side? or just send it for now and figure out fees later, prob easiest)
*/

Function Initialize() Uint64
	10 STORE("owner", SIGNER())
	20 STORE("block_between_withdraw", 10)   
	30 STORE("scbalance", 0)
    40 STORE("total_deposit_count", 0)
	50 PRINTF "Initialize executed"
	60 RETURN 0
End Function

Function SendToAddr(destinationAddress String, amount_transfer Uint64) Uint64
    // Add amount_transfer to SC balance, print tx fees for user, and store with destinationAddress & block_between_withdraw topoheight
    // Also store sender addr possibly hidden, useable for when Withdraw() is called and above block_between_withdraw

    20 STORE("scbalance", LOAD("scbalance") + amount_transfer)

    50 STORE(destinationAddress + (LOAD("total_deposit_count") + 1), SIGNER())
    60 STORE(destinationAddress + SIGNER(), amount_transfer)
    70 STORE(SIGNER() + (LOAD("total_deposit_count") + 1), BLOCK_TOPOHEIGHT() + LOAD("block_between_withdraw"))

    100 PRINTF "Deposit processed" //TODO start withdraw and store process
    110 STORE("total_deposit_count", LOAD("total_deposit_count") + 1)
    120 RETURN 0
End Function

Function CheckPendingTx(destinationAddress String) Uint64
    // Check any pending Tx being sent for withdraw, similar code to use in Withdraw and SendToAddr, however this just returns value via printF or change Function output to string and swaps if necessary
    // If not within block_between_withdraw, then change destinationAddress to Sender Addr (maybe way to store this in SendToAddr and not show in daemon out?)
    // TODO Future: loop back and get all pending Tx, not just the first one that comes up (need todo in withdraw as well)

    10 DIM tempcounter,depositAmount,block_height_limit as Uint64
    20 DIM senderAddr as String
    30 LET tempcounter = LOAD("total_deposit_count")

    100 IF EXISTS(destinationAddress + tempcounter) == 1 THEN GOTO 500    
    110 LET tempcounter = tempcounter - 1
    120 PRINTF "Decreasing tempcounter to %d" tempcounter
    130 IF tempcounter != 0 THEN GOTO 100 ELSE GOTO 200

    200 PRINTF "Did not find any transactions for %d" destinationAddress // doesn't know what SIGNER() is, assign to a variable and print that instead but got here . PERFECT!
    210 RETURN 1

    500 PRINTF "Transaction found!" // value of destinationAddress + tempcounter is the first step to receiving the amount
    510 IF EXISTS(destinationAddress + tempcounter) THEN GOTO 520 ELSE GOTO 980
    520 LET senderAddr = LOAD(destinationAddress + tempcounter) // need to check if exists

    530 IF EXISTS(destinationAddress + senderAddr) THEN GOTO 540 ELSE GOTO 980
    540 LET depositAmount = LOAD(destinationAddress + senderAddr) // need to check if exists

    550 IF EXISTS(senderAddr + tempcounter) THEN GOTO 560 ELSE GOTO 700 // if no block_height_limit, then means transaction reverted at some point and original sender gets amount back
    560 LET block_height_limit = LOAD(senderAddr + tempcounter) // need to check if exists
    570 IF block_height_limit >= BLOCK_TOPOHEIGHT() THEN GOTO 700

    560 STORE(senderAddr + (LOAD("total_deposit_count") + 1), destinationAddress) // start re-assignment process. Set Withdrawer to original sender
    570 STORE(senderAddr + destinationAddress, depositAmount) // Set deposit amount variable
    580 STORE(destinationAddress + (LOAD("total_deposit_count") + 1), BLOCK_TOPOHEIGHT() + LOAD("block_between_withdraw"))
    590 PRINTF "Reached top block height for deposit, reversing deposit back to sender."
    600 RETURN 0

    700 PRINTF "There are pending TX available to Withdraw still from %d" destinationAddress
    710 RETURN 0

    980 PRINTF "There are no pending TX available to Withdraw from %d" destinationAddress
    990 RETURN 1
End Function

Function Withdraw() Uint64
    // Withdraw all available (maybe one per Withdraw() call at first then future TODO?), as long as within block_between_withdraw blocks from SendToAddr
    // If not within block_between_withdraw, then change destinationAddress to Sender Addr (maybe way to store this in SendToAddr and not show in daemon out?)
    // TODO Future: Save ~1% or less for tx fees outside of chain txfees into SC balance
    // TODO Future: loop back and get all pending Tx, not just the first one that comes up (need todo in CheckPendingTx as well)

    10 DIM tempcounter,depositAmount,block_height_limit as Uint64
    20 DIM senderAddr as String
    30 LET tempcounter = LOAD("total_deposit_count")

    100 IF EXISTS(SIGNER() + tempcounter) == 1 THEN GOTO 500    
    110 LET tempcounter = tempcounter - 1
    120 PRINTF "Decreasing tempcounter to %d" tempcounter
    130 IF tempcounter != 0 THEN GOTO 100 ELSE GOTO 200

    200 PRINTF "Did not find any transactions for %d" SIGNER() // doesn't know what SIGNER() is, assign to a variable and print that instead but got here . PERFECT!
    210 RETURN 1

    500 PRINTF "Transaction found!" // value of SIGNER() + tempcounter is the first step to receiving the amount
    510 LET senderAddr = LOAD(SIGNER() + tempcounter)
    520 LET depositAmount = LOAD(SIGNER() + senderAddr)
    530 IF EXISTS(senderAddr + tempcounter) THEN GOTO 540 ELSE GOTO 700 // if no block_height_limit, then means transaction reverted at some point and original sender gets amount back
    540 LET block_height_limit = LOAD(senderAddr + tempcounter)
    550 IF block_height_limit >= BLOCK_TOPOHEIGHT() THEN GOTO 700

    560 STORE(senderAddr + (LOAD("total_deposit_count") + 1), SIGNER()) // start re-assignment process. Set Withdrawer to original sender
    570 STORE(senderAddr + SIGNER(), depositAmount) // Set deposit amount variable
    580 STORE(SIGNER() + (LOAD("total_deposit_count") + 1), BLOCK_TOPOHEIGHT() + LOAD("block_between_withdraw"))
    590 PRINTF "Reached top block height for deposit, reversing deposit back to sender."
    600 RETURN 0

    700 PRINTF "Reached withdraw stage" // TODO: Start withdraw process, make sure to set values to 0 afterwards (or remove variables from memory if possible?)
    710 RETURN 0
End Function

/*
//30 IF LOAD("deposit_address" + tempcounter) == SIGNER() THEN GOTO 500
//530 LET block_height_limit = LOAD(senderAddr + tempcounter)
*/


// each time called: need to have unique # associate with depositor; deposit_count = LOAD("deposit_count")+1
// then STORE("depositor_address" + (deposit_count-1), SIGNER()) // store address for later on if needed
// then STORE("depositee_address", destinationAddress) // store 
// see tester.bas, works to check a unique val after deposit addr (test string 'words')