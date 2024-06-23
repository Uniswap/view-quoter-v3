// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IUniswapV3PoolSlot0Unchecked {
    /// Identical to IUniswapV3PoolState.slot0, but with `uint256` values for
    /// all the return values that the quoter doesn't need to decode. This
    /// prevents Solidity from doing overflow checks that can revert otherwise
    /// compliant pools, if they return values that are too large for the
    /// canonical slot0 function.
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint256 observationIndex,
            uint256 observationCardinality,
            uint256 observationCardinalityNext,
            uint256 feeProtocol,
            bool unlocked
        );
}
