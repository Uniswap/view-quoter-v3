// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IUniswapV3PoolSlot0Unchecked {
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
