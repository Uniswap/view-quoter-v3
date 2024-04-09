## Uniswap v3 view-only quoter

Impliments [QuoterV2](https://github.com/Uniswap/v3-periphery/blob/main/contracts/lens/QuoterV2.sol) but removes the revert and the unused state updates

The interfaces are the same as the old quoter, but the underlying calls are different.

This code is unaudited and is a proof of concept.

[Link](https://etherscan.io/address/0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24) to a current deployment at 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24 on Mainnet

## Forge CLI

local .env setup:

 ```
#mainnet
MAINNET_RPC_URL=<JSON_RPC_PROVIDER>
MAINNET_ETHERSCAN_API_KEY=<POLYSCAN_API_KEY>

#polygon
POLYGON_RPC_URL=<JSON_RPC_PROVIDER>
POLYGON_MUMBAI_RPC_URL=<JSON_RPC_PROVIDER>
POLYGON_ETHERSCAN_API_KEY=<POLYSCAN_API_KEY>

PRIVATE_KEY=<DEPLOPYER_PK>
```

forge deploy command:
```
forge script  script/Quoter.s.sol:MyScript --chain-id <CHAIN_ID> --rpc-url <NETWORK_ALIAS_IN_FOUNDRYTOML_RPC_ENDPOINTS> \
 --etherscan-api-key <NETWORK_ALIAS_IN_FOUNDRYTOML_ETHERSCAN> \
 --broadcast --verify -vvvv
 ```

For example, deploy to mumbai:
```
forge script  script/Quoter.s.sol:MyScript --chain-id 80001 --rpc-url polygon_mumbai \
 --etherscan-api-key polygon_mumbai \
 --broadcast --verify -vvvv
 ```