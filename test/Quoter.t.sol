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

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("MAINNET_RPC_URL"));
        vm.selectFork(mainnetFork);

        quoterV3 = new Quoter(0x1F98431c8aD98523631AE4a59f267346ea31F984);

        // existing quoter
        quoterV2 = IQuoterV2(0x61fFE014bA17989E743c5F6cB21bF9697530B21e);
    }

    /// forge-config: default.fuzz.runs = 1000
    function testFuzzQuoters(bool side, uint256 amount) public {
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
                tokenIn: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
                tokenOut: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                amountIn: amount, 
                fee: 500,
                sqrtPriceLimitX96: 0
            });

        IQuoter.QuoteExactInputSingleParams memory paramsV3 = IQuoter.QuoteExactInputSingleParams({
                tokenIn: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
                tokenOut: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                amountIn: amount, 
                fee: 500,
                sqrtPriceLimitX96: 0
            });

        if (side) {
            // flip the input and output
            paramsV2.tokenOut = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
            paramsV2.tokenIn = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
           
            paramsV3.tokenOut = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
            paramsV3.tokenIn = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        } 

        (uint256 amountReceivedV3, uint160 sqrtPriceX96AfterV3, uint32 initializedTicksCrossedV3) =
            quoterV3.quoteExactInputSingle(paramsV3);
        
        (uint256 amountReceivedV2, uint160 sqrtPriceX96AfterV2, uint32 initializedTicksCrossedV2,) =
            quoterV2.quoteExactInputSingle(paramsV2);

        assertEq(amountReceivedV3 == amountReceivedV2, true);
        assertEq(sqrtPriceX96AfterV3 == sqrtPriceX96AfterV2, true);
        assertEq(initializedTicksCrossedV3 == initializedTicksCrossedV2, true);
    }
}
