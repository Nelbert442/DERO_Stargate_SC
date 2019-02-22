// Forking off of Zoz's Faucet (SCID: 5845680ef31cc8b0e8ad43248473adfeae7501d3611cb98c4df34444711ed61b)
// Adding GetFaucetParameters() to return current 'TuneFaucetParameters()' configured parameters

Function Initialize() Uint64
	10 STORE("owner", SIGNER())
	20 STORE("block_between_withdraw", 2)   
	30 STORE("amount_faucet", 1000000000000)  // 1 DERO
	35 STORE("balance", 0) 
	40 PRINTF "Initialize executed"
	50 RETURN 0 
End Function

Function TuneFaucetParameters(block_between_withdraw Uint64, amount_faucet Uint64) Uint64
	10  IF ADDRESS_RAW(LOAD("owner")) == ADDRESS_RAW(SIGNER()) THEN GOTO 30 
	20  RETURN 1
	30  STORE("block_between_withdraw", block_between_withdraw) 
	40  STORE("amount_faucet", amount_faucet)   
	50  RETURN 0 
End Function

Function GetFaucetParameters() String
    10 DIM block_between_withdraw, amount_faucet as Uint64
    20 LET block_between_withdraw = LOAD("block_between_withdraw")
    30 LET amount_faucet = LOAD("amount_faucet")

    40 RETURN "Blocks between withdraw: ("+block_between_withdraw+"); Amount Faucet: ("+amount_faucet+")"
End Function

Function Deposit(value Uint64) Uint64
	10 DIM balance as Uint64
	20 LET balance = LOAD("balance") + value
	25 STORE("balance", balance)
	30 PRINTF "Deposit executed"
	40 RETURN 0
End Function

Function GetDeroFaucet() Uint64
	10 DIM balance,signer_block,amount_faucet,block_between_withdraw,balance_updated,block_topoheight as Uint64
	20 LET balance = LOAD("balance")
	30 LET amount_faucet = LOAD("amount_faucet")

	40 IF balance < amount_faucet THEN GOTO 150
	50 IF EXISTS(SIGNER()) == 1 THEN GOTO 70
	60 STORE(SIGNER(), 0)

	70 LET signer_block = LOAD(SIGNER())
	80 LET block_between_withdraw = LOAD("block_between_withdraw")
	85 LET block_topoheight = BLOCK_TOPOHEIGHT()
	90 IF block_topoheight - signer_block < block_between_withdraw THEN GOTO 150
	100 SEND_DERO_TO_ADDRESS(SIGNER(), amount_faucet)
	110 LET balance_updated = balance - amount_faucet
	120 STORE("balance", balance_updated)
	130 STORE(SIGNER(), BLOCK_TOPOHEIGHT()) 

	140 RETURN 0
	150 RETURN 1
End Function

Function Withdraw(amount Uint64) Uint64 
	10 DIM balance, balance_updated as Uint64
	20 LET balance = LOAD("balance")
	30 IF balance < amount THEN GOTO 90
	40 IF ADDRESS_RAW(LOAD("owner")) != ADDRESS_RAW(SIGNER()) THEN GOTO 90 

	50 SEND_DERO_TO_ADDRESS(SIGNER(),amount)
	60 LET balance_updated = balance - amount
	70 STORE("balance", balance_updated)

	80 RETURN 0
	90 RETURN 1
End Function