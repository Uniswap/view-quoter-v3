## Uniswap v3 view-only quoter

This view-only quoter aims to replace [QuoterV2](https://github.com/Uniswap/v3-periphery/blob/main/contracts/lens/QuoterV2.sol) with [Quoter](https://github.com/Uniswap/view-quoter-v3/blob/master/contracts/Quoter.sol) by removing the revert and the unused state updates. [QuoterV2](https://github.com/Uniswap/v3-periphery/blob/main/contracts/lens/QuoterV2.sol) is being used in [smart-order-router](https://github.com/Uniswap/smart-order-router) for displaying the quote on uniswap UIs. 

The interfaces are the same as the old quoter, but the underlying calls are different.

This code is not audited yet, but actively being shadow tested in [routing-api](https://github.com/Uniswap/routing-api/).

### View-Only Quoter Addresses
| Chain Id | Deployment Address                         | V3 Factory                                 |
|----------|--------------------------------------------|--------------------------------------------|
| 1        | 0x5e55c9e631fae526cd4b0526c4818d6e0a9ef0e3 | 0x1F98431c8aD98523631AE4a59f267346ea31F984 |
| 10       | 0x5e55c9e631fae526cd4b0526c4818d6e0a9ef0e3 | 0x1F98431c8aD98523631AE4a59f267346ea31F984 |
| 56       | 0x5e55c9e631fae526cd4b0526c4818d6e0a9ef0e3 | 0xdB1d10011AD0Ff90774D0C6Bb92e5C5c8b4461F7 |
| 137      | 0x5e55c9e631fae526cd4b0526c4818d6e0a9ef0e3 | 0x1F98431c8aD98523631AE4a59f267346ea31F984 |
| 8453     | 0x222ca98f00ed15b1fae10b61c277703a194cf5d2 | 0x33128a8fC17869897dcE68Ed026d694621f6FDfD |
| 42161    | 0x5e55c9e631fae526cd4b0526c4818d6e0a9ef0e3 | 0x1F98431c8aD98523631AE4a59f267346ea31F984 |
| 42220    | 0x5e55c9e631fae526cd4b0526c4818d6e0a9ef0e3 | 0xAfE208a311B21f13EF87E33A90049fC17A7acDEc |
| 43114    | 0xf0c802dcb0cf1c4f7b953756b49d940eed190221 | 0x1F98431c8aD98523631AE4a59f267346ea31F984 |
| 81457    | 0x9D0F15f2cf58655fDDcD1EE6129C547fDaeD01b1 | 0x792edAdE80af5fC680d96a2eD80A44247D2Cf6Fd |
| 7777777  | 0x9D0F15f2cf58655fDDcD1EE6129C547fDaeD01b1 | 0x7145f8aeef1f6510e92164038e1b6f8cb2c42cbb |

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
