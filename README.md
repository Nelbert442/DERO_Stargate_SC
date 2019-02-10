# Nelbert442 DERO Stargate Smart Contracts
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