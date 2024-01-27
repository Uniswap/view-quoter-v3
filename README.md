## Uniswap v3 view-only quoter

Impliments [QuoterV2](https://github.com/Uniswap/v3-periphery/blob/main/contracts/lens/QuoterV2.sol) but removes the revert and the unused state updates

The interfaces are the same as the old quoter, but the underlying calls are different.

This code is unaudited and is a proof of concept.

[Link](https://etherscan.io/address/0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24) to a current deployment at 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24 on Mainnet
