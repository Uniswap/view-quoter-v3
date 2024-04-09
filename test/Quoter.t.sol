// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import {Test, console2, console} from "forge-std/Test.sol";
import {Quoter} from "../contracts/Quoter.sol";
import {IQuoter} from "../contracts/interfaces/IQuoter.sol";
import {IQuoterV2} from "v3-periphery/contracts/interfaces/IQuoterV2.sol";

contract QuoterTest is Test {
    uint256 mainnetFork;
    Quoter quoterV3;
    IQuoterV2 quoterV2;

    address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address eth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    function setUp() public {
        mainnetFork = vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        quoterV3 = new Quoter(0x1F98431c8aD98523631AE4a59f267346ea31F984);

        // existing quoter
        quoterV2 = IQuoterV2(0x61fFE014bA17989E743c5F6cB21bF9697530B21e);
    }

    /// forge-config: default.fuzz.runs = 5000
    function testFuzzInputQuoters(bool side, uint256 amount) public {
        // make the tests mean something (a non-small input) bc otherwise everything rounds to 0
        vm.assume(amount > 10000);

        // we just want to limit the search bc large numbers take a long time
        if (side) {
            // 1k eth in
            vm.assume(amount < 1000 * 1e18);
        } else {
            // 1m usdc in
            vm.assume(amount < 1000000 * 1e6);
        }

        IQuoterV2.QuoteExactInputSingleParams memory paramsV2 = IQuoterV2.QuoteExactInputSingleParams({
            tokenIn: usdc,
            tokenOut: eth,
            amountIn: amount,
            fee: 500,
            sqrtPriceLimitX96: 0
        });

        IQuoter.QuoteExactInputSingleParams memory paramsV3 = IQuoter.QuoteExactInputSingleParams({
            tokenIn: usdc,
            tokenOut: eth,
            amountIn: amount,
            fee: 500,
            sqrtPriceLimitX96: 0
        });

        if (side) {
            // flip the input and output
            paramsV2.tokenOut = usdc;
            paramsV2.tokenIn = eth;

            paramsV3.tokenOut = usdc;
            paramsV3.tokenIn = eth;
        }

        (uint256 amountReceivedV3, uint160 sqrtPriceX96AfterV3,,) = quoterV3.quoteExactInputSingle(paramsV3);

        uint256 amountReceivedV2;
        uint160 sqrtPriceX96AfterV2;
        // the old version is sometimes broken and the tick lens is wrong
        try quoterV2.quoteExactInputSingle(paramsV2) returns (
            uint256 _amountReceivedV2, uint160 _sqrtPriceX96AfterV2, uint32, uint256
        ) {
            amountReceivedV2 = _amountReceivedV2;
            sqrtPriceX96AfterV2 = _sqrtPriceX96AfterV2;
        } catch {
            vm.assume(false);
        }

        assertEq(amountReceivedV3 == amountReceivedV2, true);
        assertEq(sqrtPriceX96AfterV3 == sqrtPriceX96AfterV2, true);
    }

    /// forge-config: default.fuzz.runs = 5000
    function testFuzzOutputQuoters(bool side, uint256 amount) public {
        // make the tests mean something (a non-small input) bc otherwise everything rounds to 0
        vm.assume(amount > 10000);

        // we just want to limit the search bc large numbers take a long time
        if (side) {
            // 500 eth in
            vm.assume(amount < 1000000 * 1e6);
        } else {
            // 1m usdc in
            vm.assume(amount < 500 * 1e18);
        }

        IQuoterV2.QuoteExactOutputSingleParams memory paramsV2 = IQuoterV2.QuoteExactOutputSingleParams({
            tokenIn: usdc,
            tokenOut: eth,
            amount: amount,
            fee: 500,
            sqrtPriceLimitX96: 0
        });

        IQuoter.QuoteExactOutputSingleParams memory paramsV3 = IQuoter.QuoteExactOutputSingleParams({
            tokenIn: usdc,
            tokenOut: eth,
            amount: amount,
            fee: 500,
            sqrtPriceLimitX96: 0
        });

        if (side) {
            // flip the input and output
            paramsV2.tokenOut = usdc;
            paramsV2.tokenIn = eth;

            paramsV3.tokenOut = usdc;
            paramsV3.tokenIn = eth;
        }

        (uint256 amountInV3, uint160 sqrtPriceX96AfterV3,,) = quoterV3.quoteExactOutputSingle(paramsV3);

        uint256 amountInV2;
        uint160 sqrtPriceX96AfterV2;
        // the old version is sometimes broken and the tick lens is wrong
        try quoterV2.quoteExactOutputSingle(paramsV2) returns (
            uint256 _amountInV2, uint160 _sqrtPriceX96AfterV2, uint32, uint256
        ) {
            amountInV2 = _amountInV2;
            sqrtPriceX96AfterV2 = _sqrtPriceX96AfterV2;
        } catch {
            vm.assume(false);
        }

        assertEq(amountInV2 == amountInV3, true);
        assertEq(sqrtPriceX96AfterV3 == sqrtPriceX96AfterV2, true);
    }

    function testIlliquidPoolOutputQuoters() public {
        // 10 wbtc out
        uint256 amount = 10 * 1e8;

        IQuoterV2.QuoteExactOutputSingleParams memory paramsV2 = IQuoterV2.QuoteExactOutputSingleParams({
            tokenIn: dai,
            tokenOut: wbtc,
            amount: amount,
            fee: 10000,
            sqrtPriceLimitX96: 0
        });

        IQuoter.QuoteExactOutputSingleParams memory paramsV3 = IQuoter.QuoteExactOutputSingleParams({
            tokenIn: dai,
            tokenOut: wbtc,
            amount: amount,
            fee: 10000,
            sqrtPriceLimitX96: 0
        });

        vm.expectRevert();
        quoterV3.quoteExactOutputSingle(paramsV3);

        vm.expectRevert();
        quoterV2.quoteExactOutputSingle(paramsV2);
    }
}
