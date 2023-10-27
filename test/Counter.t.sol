// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import {Test, console2, console} from "forge-std/Test.sol";
import {Quoter} from "../src/Quoter.sol";
import {IQuoter} from "../src/IQuoter.sol";
import {IQuoterV2} from "v3-periphery/contracts/interfaces/IQuoterV2.sol";

contract CounterTest is Test {
    uint256 mainnetFork;
    Quoter quoter;
    IQuoterV2 quoterV2;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("MAINNET_RPC_URL"));
        vm.selectFork(mainnetFork);

        quoter = new Quoter(0x1F98431c8aD98523631AE4a59f267346ea31F984);
        quoterV2 = IQuoterV2(0x61fFE014bA17989E743c5F6cB21bF9697530B21e);
    }

    function testQuoterV3() public {
        IQuoter.QuoteExactInputSingleParams memory params = IQuoter.QuoteExactInputSingleParams({
            tokenIn: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            tokenOut: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            amountIn: 10000 * 1e6, // 1m
            fee: 500,
            sqrtPriceLimitX96: 0
        });

        (uint256 amountReceived, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed) =
            quoter.quoteExactInputSingle(params);

        console2.log(amountReceived);
        console.log(sqrtPriceX96After);
        console.log(initializedTicksCrossed);

        assertEq(true, true);
    }

    function testQuoterV2() public {
        IQuoterV2.QuoteExactInputSingleParams memory params = IQuoterV2.QuoteExactInputSingleParams({
            tokenIn: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            tokenOut: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            amountIn: 10000 * 1e6, // 1m
            fee: 500,
            sqrtPriceLimitX96: 0
        });

        (uint256 amountReceived, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed,) =
            quoterV2.quoteExactInputSingle(params);

        console2.log(amountReceived);
        console.log(sqrtPriceX96After);
        console.log(initializedTicksCrossed);

        assertEq(true, true);
    }
}
