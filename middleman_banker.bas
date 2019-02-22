/* General Idea
    Address 1 --> SC --> Address 2
    When address 1 sends to SC, place hold on amount for Address 2 and X number of blocks that it will hold withdrawable balance until the address gets flipped back to address 1
    Addresses can request status, maybe 'pending' transactions from x address? should sender address be shown? Idk, kinda defeats purpose, maybe just simple response but SC knows sender/receiver somehow?
    When address requests to withdraw, check to ensure within block holding limit, some stored value upon deposit, and then send to address (maybe withhold 1% for tx fee on SC side? or just send it for now and figure out fees later, prob easiest)
*/

Function Initialize() Uint64
	10 STORE("owner", SIGNER())
	20 STORE("block_between_withdraw", 100)   
	30 STORE("scbalance", 0)
	40 PRINTF "Initialize executed"
	50 RETURN 0 
End Function

Function SendToAddr(destinationAddress String, amount_transfer Uint64) Uint64
    // Add amount_transfer to SC balance, print tx fees for user, and store with destinationAddress & block_between_withdraw topoheight
    // Also store sender addr possibly hidden, useable for when Withdraw() is called and above block_between_withdraw
End Function

Function CheckPendingTx() Uint64
    // Check any pending Tx available for withdraw, similar code to use in Withdraw, however this just returns value via printF or change Function output to string
    // If not within block_between_withdraw, then change destinationAddress to Sender Addr (maybe way to store this in SendToAddr and not show in daemon out?)
End Function

Function Withdraw() Uint64
    // Withdraw all available, as long as within block_between_withdraw blocks from SendToAddr
    // If not within block_between_withdraw, then change destinationAddress to Sender Addr (maybe way to store this in SendToAddr and not show in daemon out?)
    // TODO Future: Save ~1% or less for tx fees outside of chain txfees into SC balance
End Function