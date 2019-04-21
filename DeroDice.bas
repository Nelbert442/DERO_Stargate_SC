/*  DeroDice.bas
    Attempt at similar product as Ether Dice etc. Dice rolling game in which you can choose between a 2x and a 10x multiplier (increment by 1s [e.g. 2x, 3x, 4x, ... 10x]) and roll high or low.
    The high and low numbers are defined as such:

    2x --> Over 50 --> Under 49
    3x --> 67 or over --> 33 or under
    4x --> 75 or over --> 25 or under
    5x --> 80 or over --> 20 or under
    6x --> 84 or over --> 16 or under
    7x --> 86 or over --> 14 or under
    8x --> 88 or over --> 12 or under
    9x --> 89 or over --> 11 or under
    10x --> 90 or over --> 10 or under

    There is a minimum wager/bet amount of 0.5 DERO and maximum wager/bet amount of 10 DERO

    Author: Nelbert442
    Media Handles: @Nelbert442
*/

Function Initialize() Uint64
    10 STORE("owner", SIGNER())
    20 STORE("minWager", 500000000000) // Minimum wager set to 0.5 DERO
    30 STORE("maxWager", 10000000000000) // Maximum wager set to 10 DERO
    40 STORE("sc_giveback", 9800)   // SC will give reward 98% of deposits/winnings, 2.0 % is accumulated for owner to withdraw as well as SC to keep for processing fees etc.
    50 STORE("balance", 0)
    60 PRINTF "Initialize executed"
    70 RETURN 0
End Function

Function TuneWagerParameters(minWager Uint64, maxWager Uint64, sc_giveback Uint64) Uint64
	10 IF ADDRESS_RAW(LOAD("owner")) == ADDRESS_RAW(SIGNER()) THEN GOTO 30 // Validate owner is one calling this function, otherwise return 1
	20 RETURN 1
	30 IF minWager != 0 THEN STORE("minWager", minWager)
	40 IF maxWager != 0 THEN STORE("maxWager", maxWager)
    50 IF sc_giveback != 0 THEN STORE("sc_giveback", sc_giveback)
	60 RETURN 0 
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

Function RollDiceHigh(value Uint64) Uint64
    10 IF value < LOAD("minWager") THEN GOTO 900 // If value is less than 0.5 DERO, Error and send DERO back
    20 IF value > LOAD("maxWager") THEN GOTO 900 // If value is greater than 10 DERO, Error and send DERO back
    
    900 RETURN Error(value)
End Function

Function RollDiceLow(value Uint64) Uint64
    10 IF value < LOAD("minWager") THEN GOTO 900 // If value is less than 0.5 DERO, Error and send DERO back
    20 IF value > LOAD("maxWager") THEN GOTO 900 // If value is greater than 10 DERO, Error and send DERO back
    
    900 RETURN Error(value)
End Function