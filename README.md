## Uniswap v3 view-only quoter

Impliments [QuoterV2](https://github.com/Uniswap/v3-periphery/blob/main/contracts/lens/QuoterV2.sol) but removes the revert and the unused state updates

The interfaces are the same as the old quoter, but the underlying calls are different.