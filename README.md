# Nelbert442 DERO Stargate Smart Contracts

## TimeBox_Payment.bas
This will accomplish the use case for sending "time"-based or "block"-based transactions in which a party can send to another, and can be Withdrawn within that allotted time or block count. However, if the 2nd party does not withdraw the sent balance, then the originating party can then re-withdraw the balance back (with slight fee based on sc_giveback for processing) at any time.

### e.x.1 (SendToAddr())
Send a timed payment [50 DERO] to an address - default Initialization() block_between_withdraw is 100 blocks

```
curl -X POST http://127.0.0.1:30309/json_rpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key":true,"sc_tx":{"entrypoint":"SendToAddr","scid":"a49b1ac71e8ee35c9d1db3b258dcbb61f72ba5b3b2a87f060b0c7e17940b7b8a", "value":50000000000000, "params":{ "destinationAddress":"dETomkr9SDU6ALJHP3NW4p9fA67RJJJQH3Lj9q6UioyfTUrheVQcdL3Yacw1KjrVyvEuqbwX3k1p1A9dzzZGZvNu8e2TMrLP3r" } }}}"'
```

### e.x.2 (CheckPendingTx() - Checking in on the transaction state)
With a specified destinationAddress, you can check in on the state of the transfer. There are a few scenarios in which the information will be printed:
1) You will see that there are pending TX to withdraw for the specified address. The suggested route for this is the owner of said address performs a Withdraw() to get the DERO sent.
2) You will see that there are no pending TX to withdraw for the specified address. The most likely cause of this is if there were DERO sent to this address, they have already been Withdrawn and you can assume this.
3) You will get a message that the maximum block has been reached and the TX is being redirected back to the sender. You will get this if you reach the block_between_withdraw block, as stated in e.x.1, and the transaction automatically gets sent back to the sender (who can withdraw the balance at any time, as there is no block height set for withdraw in this scenario, since it is being returned)

```
curl -X POST http://127.0.0.1:30309/json_rpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key":true,"sc_tx":{"entrypoint":"CheckPendingTx","scid":"a49b1ac71e8ee35c9d1db3b258dcbb61f72ba5b3b2a87f060b0c7e17940b7b8a", "params":{ "destinationAddress":"dETomkr9SDU6ALJHP3NW4p9fA67RJJJQH3Lj9q6UioyfTUrheVQcdL3Yacw1KjrVyvEuqbwX3k1p1A9dzzZGZvNu8e2TMrLP3r" } }}}"'
```

### e.x.3 (Withdraw())
You will assume similar processes as CheckPendingTx() however you, as the SIGNER(), are checking for transactions with your address. You can use the above example scenarios as your address is the destinationAddress.
The one difference here is upon there being pending TX to withdraw, you then perform a withdraw and get the DERO sent to you, with a small fee taken out for SC processing (fees etc.) and this value is by default 1% of DERO sent.

```
curl -X POST http://127.0.0.1:30309/json_rpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key":true,"sc_tx":{"entrypoint":"Withdraw","scid":"a49b1ac71e8ee35c9d1db3b258dcbb61f72ba5b3b2a87f060b0c7e17940b7b8a" }}}"'
```

### e.x.4 (TuneTimeBoxParameters())
If you are the owner of the SC when initialized, you can then modify two of the built-in values: block_between_withdraw and sc_giveback. Once this function is ran, any transactions AFTER this has been ran will utilize these new values. This does not apply to previous transactions sent via the SC.

block_between_withdraw: This is the value that defines how many blocks from SendToAddr() the receiver has to claim the DERO. Otherwise, the DERO is then Withdrawable by the original sender for an indefinite amount of time.
sc_giveback: This is defining a percentage that the SC is giving to the Withdrawer. By default this value is set to 99%, however can be tuned with this function.

In this example, you can see that block_between_withdraw is being set to 150 blocks and sc_giveback is being set to 95% given back to the Withdrawer, keeping 5% for the SC.
```
curl -X POST http://127.0.0.1:30309/json_rpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key":true,"sc_tx":{"entrypoint":"TuneTimeBoxParameters","scid":"a49b1ac71e8ee35c9d1db3b258dcbb61f72ba5b3b2a87f060b0c7e17940b7b8a", "params":{ "block_between_withdraw":"150", "sc_giveback":"9500" } }}}"'
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
curl -X POST http://127.0.0.1:30309/json_rpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key":true,"sc_tx":{"entrypoint":"Deposit","scid":"f4518c6e89f3c5cbbb495e57bdc478fffdaf1fc0d418a7bb4ec25492362af89c", "value":10000000000000 }}}"'

http://pool.dero.io:8080/tx/9ce0725112640d0b959b93b81560d351c7a54b5139facc4551ab2296d3f2e0eb
```

### e.x.2 (Withdraw 1 DERO):
```
curl -X POST http://127.0.0.1:30309/json_rpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key":true,"sc_tx":{"entrypoint":"Withdraw","scid":"f4518c6e89f3c5cbbb495e57bdc478fffdaf1fc0d418a7bb4ec25492362af89c", "params":{ "amount":"1000000000000" } }}}"'

http://pool.dero.io:8080/tx/a71389f7c954f07997f92b5ce950e4ddf818cb0dac6ccdb0327acf69ba43156b
```

### e.x.3 (View Balance)
```
curl -X POST http://127.0.0.1:30309/json_rpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key":true,"sc_tx":{"entrypoint":"ViewBalance","scid":"f4518c6e89f3c5cbbb495e57bdc478fffdaf1fc0d418a7bb4ec25492362af89c" }}}"'
```

### e.x.4 (List TXIDs)
```
curl -X POST http://127.0.0.1:30309/json_rpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key":true,"sc_tx":{"entrypoint":"ListTXIDs","scid":"f4518c6e89f3c5cbbb495e57bdc478fffdaf1fc0d418a7bb4ec25492362af89c" }}}"'
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