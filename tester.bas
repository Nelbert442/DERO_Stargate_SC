Function Initialize() Uint64
    10 DIM destAddr, newstring as String // simulate memory destination address and an inputted new string address
    20 DIM n, g, tempcounter as Uint64 // simulate n as total tx count; g as tx num in question; tempcounter as temp floater
    30 LET destAddr = "words" // simulate 'words' as test address string
    40 LET n = 10 // set total tx count to 10
    50 LET g = 3 // set tx num to look for as 3
    60 LET destAddr = destAddr + g // set unique identifier to "words"+3
	
    70 LET tempcounter = n // set tempcounter to tx count
    80 LET newstring = "words" + tempcounter // set newstring to top (could go bottom to top too, either works)
    90 IF newstring == destAddr THEN GOTO 900 // if newstring is looked for addr + unique, exit
    100 LET tempcounter = tempcounter - 1 // if not, decrease tempcounter (or increase)
    110 PRINTF "Decreasing tempcounter to %d" tempcounter
    120 IF tempcounter != 0 THEN GOTO 80 // check to ensure tempcounter != 0, else return 1, if is not 0 then go back to 80 and loop again
    130 RETURN 1

    900 PRINTF "Address string found! %d" newstring
    910 RETURN 0
End Function