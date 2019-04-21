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
    40 STORE("sc_giveback", 9800)   // SC will give reward 98% of deposits/winnings, 2.0 % is accumulated for owner to withdraw as well as SC to keep for processing fees etc.
    50 STORE("balance", 0)
    60 PRINTF "Initialize executed"
    70 RETURN 0
End Function

Function RollDiceHigh(value Uint64) Uint64
End Function

Function RollDiceLow(value Uint64) Uint64
End Function