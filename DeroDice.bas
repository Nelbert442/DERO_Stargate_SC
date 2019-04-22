/*  DeroDice.bas
    Attempt at similar product as Ether Dice etc. Dice rolling game in which you can choose between a 2x and a 10x multiplier (increment by 1s [e.g. 2x, 3x, 4x, ... 10x]) and roll high or low.
    The high and low numbers are defined as such:

    2x --> 50 or over --> 49 or under
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

    60 STORE("2xOver", 50)
    61 STORE("2xUnder", 49)
    65 STORE("3xOver", 67)
    66 STORE("3xUnder", 33)
    70 STORE("4xOver", 75)
    71 STORE("4xUnder", 25)
    75 STORE("5xOver", 80)
    76 STORE("5xUnder", 20)
    80 STORE("6xOver", 84)
    81 STORE("6xUnder", 16)
    85 STORE("7xOver", 86)
    86 STORE("7xUnder", 14)
    90 STORE("8xOver", 88)
    91 STORE("8xUnder", 12)
    95 STORE("9xOver", 89)
    96 STORE("9xUnder", 11)
    100 STORE("10xOver", 90)
    101 STORE("10xUnder", 10)

    200 PRINTF "Initialize executed"
    210 RETURN 0
End Function

Function TuneWagerParameters(minWager Uint64, maxWager Uint64, sc_giveback Uint64) Uint64
	10 IF ADDRESS_RAW(LOAD("owner")) == ADDRESS_RAW(SIGNER()) THEN GOTO 30 // Validate owner is one calling this function, otherwise return 1
	20 RETURN 1
	30 IF minWager != 0 THEN STORE("minWager", minWager)
	40 IF maxWager != 0 THEN STORE("maxWager", maxWager)
    50 IF sc_giveback != 0 THEN STORE("sc_giveback", sc_giveback)
	60 RETURN 0 
End Function

Function Error(errorMessage String, value Uint64) Uint64
    10 DIM return_balance as Uint64
    11 DIM txid as String
    12 LET txid = TXID()
    15 LET return_balance = value
    20 IF (LOAD("balance") + return_balance) > return_balance THEN GOTO 50 // seems silly, but loads balance and if balance = 0 then + return_balance is never going to be > return_balance, so take 1% off for fee
    30 LET return_balance = 9900 * return_balance / 10000 // no need to store this fee for withdraw, it's safe to have a small amount stored in SC that is not withdrawable for tx fees later "cost of doing business"
    40 STORE("balance", value - return_balance) // should only be ran when no funds (new SC initialization etc.)

    50 PRINTF "------------------------------------------------------------------"
    55 PRINTF "Returning a balance of %d to sender." return_balance
    56 PRINTF "Error_Message: %s" errorMessage
    60 PRINTF "TXID: %s" txid
    65 PRINTF "------------------------------------------------------------------"

    100 SEND_DERO_TO_ADDRESS(SIGNER(), return_balance)

    999 RETURN 0
End Function

Function RollDiceHigh(multiplier Uint64, value Uint64) Uint64
    10 DIM rolledNum, targetNumber, payoutAmount as Uint64
    40 IF value < LOAD("minWager") THEN GOTO 800 // If value is less than 0.5 DERO, Error and send DERO back
    50 IF value > LOAD("maxWager") THEN GOTO 800 // If value is greater than 10 DERO, Error and send DERO back
    
    // IF exists multiplier + "xOver", then proceed. Else exit because this means they did not supply a multiplier within 2 - 10.
    60 IF EXISTS(multiplier + "xOver") == 1 THEN GOTO 50 ELSE GOTO 900

    70 LET rolledNum = RANDOM(99) // Randomly choose number between 0 and 99
    80 LET targetNumber = LOAD(multiplier + "xOver")
    90 IF rolledNum <= targetNumber THEN GOTO 100 ELSE GOTO 500

    100 LET payoutAmount = LOAD("sc_giveback") * value * multiplier / 10000
    110 SEND_DERO_TO_ADDRESS(SIGNER(), payoutAmount)
    120 PRINTF "-----------------------------------------------------------------"
    121 PRINTF "You win! You rolled a %d which is higher than %d. You have received %d" rolledNum, targetNumber, payoutAmount
    122 PRINTF "-----------------------------------------------------------------"
    130 RETURN 0

    500 PRINTF "-----------------------------------------------------------------"
    501 PRINTF "Thanks for playing, however unfortunately you rolled a %d which is lower than %d. TRY AGAIN!" rolledNum, targetNumber
    502 PRINTF "-----------------------------------------------------------------"
    501 RETURN 0

    800 RETURN Error("Incorrect Wager amount. Please use between 0.5 and 10 DERO",value)

    900 RETURN Error("Incorrect multiplier. Please use between 2 and 10",value)
End Function

Function RollDiceLow(multiplier Uint64, value Uint64) Uint64
    10 DIM rolledNum, targetNumber, payoutAmount as Uint64
    40 IF value < LOAD("minWager") THEN GOTO 800 // If value is less than 0.5 DERO, Error and send DERO back
    50 IF value > LOAD("maxWager") THEN GOTO 800 // If value is greater than 10 DERO, Error and send DERO back
    
    // IF exists multiplier + "xUnder", then proceed. Else exit because this means they did not supply a multiplier within 2 - 10.
    60 IF EXISTS(multiplier + "xUnder") == 1 THEN GOTO 50 ELSE GOTO 900

    70 LET rolledNum = RANDOM(99) // Randomly choose number between 0 and 99
    80 LET targetNumber = LOAD(multiplier + "xUnder")
    90 IF rolledNum <= targetNumber THEN GOTO 100 ELSE GOTO 500

    100 LET payoutAmount = LOAD("sc_giveback") * value * multiplier / 10000
    110 SEND_DERO_TO_ADDRESS(SIGNER(), payoutAmount)
    120 PRINTF "-----------------------------------------------------------------"
    121 PRINTF "You win! You rolled a %d which is lower than %d. You have received %d" rolledNum, targetNumber, payoutAmount
    122 PRINTF "-----------------------------------------------------------------"
    130 RETURN 0

    500 PRINTF "-----------------------------------------------------------------"
    501 PRINTF "Thanks for playing, however unfortunately you rolled a %d which is higher than %d. TRY AGAIN!" rolledNum, targetNumber
    502 PRINTF "-----------------------------------------------------------------"
    501 RETURN 0

    800 RETURN Error("Incorrect Wager amount. Please use between 0.5 and 10 DERO",value)

    900 RETURN Error("Incorrect multiplier. Please use between 2 and 10",value)
End Function