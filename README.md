# Nelbert442 DERO Stargate Smart Contracts

## TimeBox_Payment.bas
This will accomplish the use case for sending "time"-based or "block"-based transactions in which a party can send to another, and can be Withdrawn within that allotted time or block count. However, if the 2nd party does not withdraw the sent balance, then the originating party can then re-withdraw the balance back (with slight fee based on sc_giveback for processing) at any time.

### e.x.1 (SendToAddr())
Send a timed payment [50 DERO] to an address - default Initialization() block_between_withdraw is 100 blocks

```
curl -X POST http://127.0.0.1:30309/json_rpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key":true,"sc_tx":{"entrypoint":"SendToAddr","scid":"5d4549c4ea7da704152e4019804d5d91daf59b00c1342830959c44fddec272cd", "value":50000000000000, "params":{ "destinationAddress":"dETomkr9SDU6ALJHP3NW4p9fA67RJJJQH3Lj9q6UioyfTUrheVQcdL3Yacw1KjrVyvEuqbwX3k1p1A9dzzZGZvNu8e2TMrLP3r" } }}}"'
```

### e.x.2 (CheckPendingTx() - Checking in on the transaction state)
With a specified destinationAddress, you can check in on the state of the transfer. There are a few scenarios in which the information will be printed:
1) You will see that there are pending TX to withdraw for the specified address. The suggested route for this is the owner of said address performs a Withdraw() to get the DERO sent.
2) You will see that there are no pending TX to withdraw for the specified address. The most likely cause of this is if there were DERO sent to this address, they have already been Withdrawn and you can assume this.
3) You will get a message that the maximum block has been reached and the TX is being redirected back to the sender. You will get this if you reach the block_between_withdraw block, as stated in e.x.1, and the transaction automatically gets sent back to the sender (who can withdraw the balance at any time, as there is no block height set for withdraw in this scenario, since it is being returned)

```
curl -X POST http://127.0.0.1:30309/json_rpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key":true,"sc_tx":{"entrypoint":"CheckPendingTx","scid":"5d4549c4ea7da704152e4019804d5d91daf59b00c1342830959c44fddec272cd", "params":{ "destinationAddress":"dETomkr9SDU6ALJHP3NW4p9fA67RJJJQH3Lj9q6UioyfTUrheVQcdL3Yacw1KjrVyvEuqbwX3k1p1A9dzzZGZvNu8e2TMrLP3r" } }}}"'
```

### e.x.3 (Withdraw())
You will assume similar processes as CheckPendingTx() however you, as the SIGNER(), are checking for transactions with your address. You can use the above example scenarios as your address is the destinationAddress.
The one difference here is upon there being pending TX to withdraw, you then perform a withdraw and get the DERO sent to you, with a small fee taken out for SC processing (fees etc.) and this value is by default 1% of DERO sent.

```
curl -X POST http://127.0.0.1:30309/json_rpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key":true,"sc_tx":{"entrypoint":"Withdraw","scid":"5d4549c4ea7da704152e4019804d5d91daf59b00c1342830959c44fddec272cd" }}}"'
```

### e.x.4 (TuneTimeBoxParameters())
If you are the owner of the SC when initialized, you can then modify two of the built-in values: block_between_withdraw and sc_giveback. Once this function is ran, any transactions AFTER this has been ran will utilize these new values. This does not apply to previous transactions sent via the SC.

block_between_withdraw: This is the value that defines how many blocks from SendToAddr() the receiver has to claim the DERO. Otherwise, the DERO is then Withdrawable by the original sender for an indefinite amount of time.
sc_giveback: This is defining a percentage that the SC is giving to the Withdrawer. By default this value is set to 99%, however can be tuned with this function.

In this example, you can see that block_between_withdraw is being set to 150 blocks and sc_giveback is being set to 95% given back to the Withdrawer, keeping 5% for the SC.
```
curl -X POST http://127.0.0.1:30309/json_rpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key":true,"sc_tx":{"entrypoint":"TuneTimeBoxParameters","scid":"5d4549c4ea7da704152e4019804d5d91daf59b00c1342830959c44fddec272cd", "params":{ "block_between_withdraw":"150", "sc_giveback":"9500" } }}}"'
```

## DeroDice.bas
Attempt at similar product as Ether Dice etc. Dice rolling game in which you can choose between a 2x and a 10x multiplier (increment by 1s [e.g. 2x, 3x, 4x, ... 10x]) and roll high or low.
The high and low numbers are defined as such:
```
    2x --> 50 or over --> 49 or under
    3x --> 67 or over --> 33 or under
    4x --> 75 or over --> 25 or under
    5x --> 80 or over --> 20 or under
    6x --> 84 or over --> 16 or under
    7x --> 86 or over --> 14 or under
    8x --> 88 or over --> 12 or under
    9x --> 89 or over --> 11 or under
    10x --> 90 or over --> 10 or under
```

There is a minimum wager/bet amount of 0.5 DERO and maximum wager/bet amount of 10 DERO

### Initialize Contract (initializes SC and makes you, the SIGNER(), the owner)

```
curl --request POST --data-binary @DeroDice.bas http://127.0.0.1:30309/install_sc
```

### e.x.1 (Roll High with 2x Multiplier - Wagering 2 DERO): 
```
curl -X POST http://127.0.0.1:30309/json_rpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key":true,"sc_tx":{"entrypoint":"RollDiceHigh","scid":"a1c8d2c7d945cf21a10bdd1ab51e2176801032c7b913e440cb2227f29aedceee ", "value":2000000000000, "params":{ "multiplier":"2" } }}}"'

http://pool.dero.io:8080/tx/928fbc1f015eeaa02c116686e4958d41cae9f1451facad1f001cad544df8ba61
```

### e.x.2 (Roll Low with 2x Multiplier - Wagering 2 DERO):
```
curl -X POST http://127.0.0.1:30309/json_rpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key":true,"sc_tx":{"entrypoint":"RollDiceLow","scid":"a1c8d2c7d945cf21a10bdd1ab51e2176801032c7b913e440cb2227f29aedceee ", "value":2000000000000, "params":{ "multiplier":"2" } }}}"'

http://pool.dero.io:8080/tx/b8d7a2ddc5d25530833d56f36e6eb55bfd0f2ef2d98605d892f8a69afae001ef
```

### e.x.3 (TuneWagerParameters())
If you are the owner of the SC when initialized, you can then modify two of the built-in values: minWager, maxWager and sc_giveback. Once this function is ran, any transactions AFTER this has been ran will utilize these new values. This does not apply to previous transactions sent via the SC.

minWager: This is the value that users must use as a minimum bet, if they bet lower than this it will be rejected and returned to them.
maxWager: This is the value that users must us as a maximum bet, if they bet higher than this it will be rejected and returned to them.
sc_giveback: This is defining a percentage that the SC is giving to the Winnders. By default this value is set to 98%, however can be tuned with this function.

In this example, you can see that minWager is being set to 0.5 DERO (500000000000), the maxWager is being set to 10 DERO (10000000000000) and sc_giveback is being set to 98% (9800) given back to the Winner, keeping 2% for the SC.
```
curl -X POST http://127.0.0.1:30309/json_rpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key":true,"sc_tx":{"entrypoint":"TuneWagerParameters","scid":"a1c8d2c7d945cf21a10bdd1ab51e2176801032c7b913e440cb2227f29aedceee ", "params":{ "minWager":"500000000000", "maxWager":"10000000000000", "sc_giveback":"9800" } }}}"'
```

### e.x.4 (Donate to SC DERO Pool for Payouts):
```
curl -X POST http://127.0.0.1:30309/json_rpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key":true,"sc_tx":{"entrypoint":"Donate","scid":"a1c8d2c7d945cf21a10bdd1ab51e2176801032c7b913e440cb2227f29aedceee ", "value":5000000000000 }}}"'

http://pool.dero.io:8080/tx/8c39f590511b9d5be0139f912cb3387cc61ce04f0239c4a76fe9a1f08d37932c
```

## ValidateBalance.bas
Use Validate Balance to allow for you (the owner) to deposit/withdraw DERO from and 3rd parties (others) to view TXIDs and Balance totals via RPC call. This SC is intended to be utilized in the form of a public wallet so to speak, this way there is no question or FUD related to TXIDs or Balance remaining in a given address.

NOTE: If you are not the owner of the SC, and you perform a Deposit() or Withdraw(), you will be denied. Non-owners can run ViewBalance() and ListTXIDs().

### Initialize Contract (initializes SC and makes you, the SIGNER(), the owner)

```
curl --request POST --data-binary @ValidateBalance.bas http://127.0.0.1:30309/install_sc
```

### e.x.1 (Deposit 10 DERO): 
```
curl -X POST http://127.0.0.1:30309/json_rpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key":true,"sc_tx":{"entrypoint":"Deposit","scid":"d37f1c1b48c9bc180bfe635662352a2fc18ee3c054648294c1b757ef867541dd", "value":10000000000000 }}}"'

http://pool.dero.io:8080/tx/9daa457e1fc36f3329011d5c22dfcd27910f4b02c0943ef07cda8d78faf1bcc4
```

### e.x.2 (Withdraw 1 DERO):
```
curl -X POST http://127.0.0.1:30309/json_rpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key":true,"sc_tx":{"entrypoint":"Withdraw","scid":"d37f1c1b48c9bc180bfe635662352a2fc18ee3c054648294c1b757ef867541dd", "params":{ "amount":"1000000000000" } }}}"'

http://pool.dero.io:8080/tx/34101b5431473a4c7aa7ee9dcc0f6d2b8b55af183c4747591dd97ca5974392de
```

### e.x.3 (View Balance)
```
curl -X POST http://127.0.0.1:30309/json_rpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key":true,"sc_tx":{"entrypoint":"ViewBalance","scid":"d37f1c1b48c9bc180bfe635662352a2fc18ee3c054648294c1b757ef867541dd" }}}"'
```

### e.x.4 (List TXIDs)
```
curl -X POST http://127.0.0.1:30309/json_rpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key":true,"sc_tx":{"entrypoint":"ListTXIDs","scid":"d37f1c1b48c9bc180bfe635662352a2fc18ee3c054648294c1b757ef867541dd" }}}"'
```

## IsAddressValid.bas
Simple .bas file that you can run function IsAddressValid with supplied 'address' string and return is whether or not it is valid by checking aginst built-in command "IS_ADDRESS_VALID()"

### e.x.1 (returns valid): 
```
curl -X POST http://127.0.0.1:30309/json_rpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key":true,"sc_tx":{"entrypoint":"IsAddressValid","scid":"4288f8e8248cbe2aa5a46a4824d0a38b3fa0033bde51a09eaa94e0575f89d62e", "params":{ "address":"dETomkr9SDU6ALJHP3NW4p9fA67RJJJQH3Lj9q6UioyfTUrheVQcdL3Yacw1KjrVyvEuqbwX3k1p1A9dzzZGZvNu8e2TMrLP3r" } }}}"'
```

### e.x.2 (returns NOT valid):
```
curl -X POST http://127.0.0.1:30309/json_rpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key":true,"sc_tx":{"entrypoint":"IsAddressValid","scid":"4288f8e8248cbe2aa5a46a4824d0a38b3fa0033bde51a09eaa94e0575f89d62e", "params":{ "address":"dETomkrNOTVALIDHP3NW4p9fA67RJJJQH3Lj9q6UioyfTUrheVQcdL3Yacw1KjrVyvEuqbwX3k1p1A9dzzZGZvNu8e2TMrLP3r" } }}}"'
```