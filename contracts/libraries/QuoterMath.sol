// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.6;
pragma abicoder v2;

import {IUniswapV3Pool} from "v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IQuoter} from "../interfaces/IQuoter.sol";
import {SwapMath} from "v3-core/contracts/libraries/SwapMath.sol";
import {FullMath} from "v3-core/contracts/libraries/FullMath.sol";
import {TickMath} from "v3-core/contracts/libraries/TickMath.sol";
import "v3-core/contracts/libraries/LowGasSafeMath.sol";
import "v3-core/contracts/libraries/SafeCast.sol";
import "v3-periphery/contracts/libraries/Path.sol";
import {SqrtPriceMath} from "v3-core/contracts/libraries/SqrtPriceMath.sol";
import {LiquidityMath} from "v3-core/contracts/libraries/LiquidityMath.sol";
import {PoolTickBitmap} from "./PoolTickBitmap.sol";
import {PoolAddress} from "./PoolAddress.sol";

library QuoterMath {
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;

    struct Slot0 {
        // the current price
        uint160 sqrtPriceX96;
        // the current tick
        int24 tick;
        // tick spacing
        int24 tickSpacing;
    }

    // used for packing under the stack limit
    struct QuoteParams {
        bool zeroForOne;
        bool exactInput;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    function fillSlot0(IUniswapV3Pool pool) private view returns (Slot0 memory slot0) {
        (slot0.sqrtPriceX96, slot0.tick,,,,,) = pool.slot0();
        slot0.tickSpacing = pool.tickSpacing();

        return slot0;
    }

        struct SwapCache {
        // the protocol fee for the input token
        uint8 feeProtocol;
        // liquidity at the beginning of the swap
        uint128 liquidityStart;
        // the timestamp of the current block
        uint32 blockTimestamp;
        // the current value of the tick accumulator, computed only if we cross an initialized tick
        int56 tickCumulative;
        // the current value of seconds per liquidity accumulator, computed only if we cross an initialized tick
        uint160 secondsPerLiquidityCumulativeX128;
        // whether we've computed and cached the above two accumulators
        bool computedLatestObservation;
    }

    // the top level state of the swap, the results of which are recorded in storage at the end
    struct SwapState {
        // the amount remaining to be swapped in/out of the input/output asset
        int256 amountSpecifiedRemaining;
        // the amount already swapped out/in of the output/input asset
        int256 amountCalculated;
        // current sqrt(price)
        uint160 sqrtPriceX96;
        // the tick associated with the current price
        int24 tick;
        // the global fee growth of the input token
        uint256 feeGrowthGlobalX128;
        // amount of input token paid as protocol fee
        uint128 protocolFee;
        // the current liquidity in range
        uint128 liquidity;
    }

    struct StepComputations {
        // the price at the beginning of the step
        uint160 sqrtPriceStartX96;
        // the next tick to swap to from the current tick in the swap direction
        int24 tickNext;
        // whether tickNext is initialized or not
        bool initialized;
        // sqrt(price) for the next tick (1/0)
        uint160 sqrtPriceNextX96;
        // how much is being swapped in in this step
        uint256 amountIn;
        // how much is being swapped out
        uint256 amountOut;
        // how much fee is being paid in
        uint256 feeAmount;
    }

    function quote(IUniswapV3Pool pool, int256 amount, QuoteParams memory quoteParams)
        public
        view
        returns (int256 amount0, int256 amount1, uint160 sqrtPriceAfterX96, uint32 initializedTicksCrossed)
    {
        quoteParams.exactInput = amount > 0;
        initializedTicksCrossed = 1;

        Slot0 memory slot0 = fillSlot0(pool);

        SwapState memory state = SwapState({
            amountSpecifiedRemaining: amount,
            amountCalculated: 0,
            sqrtPriceX96: slot0.sqrtPriceX96,
            tick: slot0.tick,
            feeGrowthGlobalX128: 0,
            protocolFee: 0,
            liquidity: pool.liquidity()
        });

        while (state.amountSpecifiedRemaining != 0 && state.sqrtPriceX96 != quoteParams.sqrtPriceLimitX96) {
            StepComputations memory step;

            step.sqrtPriceStartX96 = state.sqrtPriceX96;

            (step.tickNext, step.initialized) =
                PoolTickBitmap.nextInitializedTickWithinOneWord(pool, slot0.tickSpacing, state.tick, quoteParams.zeroForOne);

            // ensure that we do not overshoot the min/max tick, as the tick bitmap is not aware of these bounds
            if (step.tickNext < TickMath.MIN_TICK) {
                step.tickNext = TickMath.MIN_TICK;
            } else if (step.tickNext > TickMath.MAX_TICK) {
                step.tickNext = TickMath.MAX_TICK;
            }

            // get the price for the next tick
            step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.tickNext);

            // compute values to swap to the target tick, price limit, or point where input/output amount is exhausted
            (state.sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath.computeSwapStep(
                state.sqrtPriceX96,
                (
                    quoteParams.zeroForOne
                        ? step.sqrtPriceNextX96 < quoteParams.sqrtPriceLimitX96
                        : step.sqrtPriceNextX96 > quoteParams.sqrtPriceLimitX96
                ) ? quoteParams.sqrtPriceLimitX96 : step.sqrtPriceNextX96,
                state.liquidity,
                state.amountSpecifiedRemaining,
                quoteParams.fee
            );

            if (quoteParams.exactInput) {
                state.amountSpecifiedRemaining -= (step.amountIn + step.feeAmount).toInt256();
                state.amountCalculated = state.amountCalculated.sub(step.amountOut.toInt256());
            } else {
                state.amountSpecifiedRemaining += step.amountOut.toInt256();
                state.amountCalculated = state.amountCalculated.add((step.amountIn + step.feeAmount).toInt256());
            }

            // shift tick if we reached the next price
            if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
                // if the tick is initialized, run the tick transition
                if (step.initialized) {
                    (, int128 liquidityNet,,,,,,) = pool.ticks(step.tickNext);

                    // if we're moving leftward, we interpret liquidityNet as the opposite sign
                    // safe because liquidityNet cannot be type(int128).min
                    if (quoteParams.zeroForOne) liquidityNet = -liquidityNet;

                    state.liquidity = LiquidityMath.addDelta(state.liquidity, liquidityNet);

                    initializedTicksCrossed++;
                }

                state.tick = quoteParams.zeroForOne ? step.tickNext - 1 : step.tickNext;
            } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
                // recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved
                state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
            }
        }

        (amount0, amount1) = quoteParams.zeroForOne == quoteParams.exactInput
            ? (amount - state.amountSpecifiedRemaining, state.amountCalculated)
            : (state.amountCalculated, amount - state.amountSpecifiedRemaining);

        sqrtPriceAfterX96 = state.sqrtPriceX96;
    }

    /// it is possible with rounding bc of breaking up the inputs in the last tick that the quotes may be 1 wei off.
    function quoteBatch(IUniswapV3Pool pool, int256[] memory amounts, QuoteParams memory quoteParams)
        public
        view
        returns (int256[] memory amounts0, int256[] memory amounts1, uint160[] memory sqrtPricesAfterX96, uint32[] memory initializedTicksCrossedList)
    {
        // start the iteration
        int256 amount = amounts[0];

        amounts0 = new int256[](amounts.length); 
        amounts1 = new int256[](amounts.length); 
        sqrtPricesAfterX96 = new uint160[](amounts.length); 
        initializedTicksCrossedList = new uint32[](amounts.length); 
        
        quoteParams.exactInput = amount > 0;

        uint256 i = 0;
        // we are really tracking ticks sload (thus start w/ 1) not crossed
        uint32 initializedTicksCrossed = 1;

        Slot0 memory slot0 = fillSlot0(pool);
        
        SwapState memory state = SwapState({
            amountSpecifiedRemaining: amount,
            amountCalculated: 0,
            sqrtPriceX96: slot0.sqrtPriceX96,
            tick: slot0.tick,
            feeGrowthGlobalX128: 0,
            protocolFee: 0,
            liquidity: pool.liquidity()
        });

        StepComputations memory step;
        while (state.amountSpecifiedRemaining != 0 && state.sqrtPriceX96 != quoteParams.sqrtPriceLimitX96) {
            // we either haven't ever filled it in or we want to re-caculate everything (if we transitioned) 
            if (step.sqrtPriceStartX96 == 0) {
                step.sqrtPriceStartX96 = state.sqrtPriceX96;

                (step.tickNext, step.initialized) =
                    PoolTickBitmap.nextInitializedTickWithinOneWord(pool, slot0.tickSpacing, state.tick, quoteParams.zeroForOne);

                // ensure that we do not overshoot the min/max tick, as the tick bitmap is not aware of these bounds
                if (step.tickNext < TickMath.MIN_TICK) {
                    step.tickNext = TickMath.MIN_TICK;
                } else if (step.tickNext > TickMath.MAX_TICK) {
                    step.tickNext = TickMath.MAX_TICK;
                }

                // get the price for the next tick
                step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.tickNext);
            }

            // compute values to swap to the target tick, price limit, or point where input/output amount is exhausted
            (state.sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath.computeSwapStep(
                state.sqrtPriceX96,
                (
                    quoteParams.zeroForOne
                        ? step.sqrtPriceNextX96 < quoteParams.sqrtPriceLimitX96
                        : step.sqrtPriceNextX96 > quoteParams.sqrtPriceLimitX96
                ) ? quoteParams.sqrtPriceLimitX96 : step.sqrtPriceNextX96,
                state.liquidity,
                state.amountSpecifiedRemaining,
                quoteParams.fee
            );

            if (quoteParams.exactInput) {
                state.amountSpecifiedRemaining -= (step.amountIn + step.feeAmount).toInt256();
                state.amountCalculated = state.amountCalculated.sub(step.amountOut.toInt256());
            } else {
                state.amountSpecifiedRemaining += step.amountOut.toInt256();
                state.amountCalculated = state.amountCalculated.add((step.amountIn + step.feeAmount).toInt256());
            }

            // shift tick if we reached the next price
            if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
                // if the tick is initialized, run the tick transition
                if (step.initialized) {
                    (, int128 liquidityNet,,,,,,) = pool.ticks(step.tickNext);

                    // if we're moving leftward, we interpret liquidityNet as the opposite sign
                    // safe because liquidityNet cannot be type(int128).min
                    if (quoteParams.zeroForOne) liquidityNet = -liquidityNet;

                    state.liquidity = LiquidityMath.addDelta(state.liquidity, liquidityNet);

                    initializedTicksCrossed++;
                }

                state.tick = quoteParams.zeroForOne ? step.tickNext - 1 : step.tickNext;
                // force the recompute of the transition steps
                step.sqrtPriceStartX96 = 0;

            } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
                // transition state to the next price in case we are going to continue searching
                // could be avoided
                step.sqrtPriceStartX96 = state.sqrtPriceX96;

                // recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved
                state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
            }

            // v3 early returns at this point, we want to quote several values
            // at once, which means we need to intead start a new swap if needed
            if (state.amountSpecifiedRemaining == 0) {
                (amounts0[i], amounts1[i]) = (quoteParams.zeroForOne == quoteParams.exactInput
                        ? (amount - state.amountSpecifiedRemaining, state.amountCalculated)
                        : (state.amountCalculated, amount - state.amountSpecifiedRemaining));
                // each iteration calculates the amount between amount[i] to amount[i + 1]
                // we want to know the cumulative sum from 0 to amount[i + 1], so we add
                // amounts[i] to add cumulative sum, at amounts[0] we are going from 
                // 0 to amounts[0], which means we could add 0 but this just skipped
                
                if (i != 0) {
                    amounts0[i] = amounts0[i] + amounts0[i-1];
                    amounts1[i] = amounts1[i] + amounts1[i-1];
                }
        
                sqrtPricesAfterX96[i] = state.sqrtPriceX96;
                initializedTicksCrossedList[i] = initializedTicksCrossed;

                // gg - go next
                i++;
                if (i != amounts.length) {
                    // we have more to calculate
                    // we assume that amounts[i] 
                    amount = amounts[i] - amounts[i - 1];
                    
                    // this means that amount[i] < amounts[i-1]
                    if (amount > amounts[i]) {
                        revert('OVR');
                    }
                    state.amountSpecifiedRemaining = amount;
                    state.amountCalculated = 0;
                    step.feeAmount = 0;
                }
            } 
        }
    }
}