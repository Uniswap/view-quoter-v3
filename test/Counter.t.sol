// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import {Test, console2, console} from "forge-std/Test.sol";
import {Quoter} from "../contracts/Quoter.sol";
import {IQuoter} from "../contracts/interfaces/IQuoter.sol";
import {IQuoterV2} from "v3-periphery/contracts/interfaces/IQuoterV2.sol";

contract CounterTest is Test {
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

    function testQuoterV3() public {
        IQuoter.QuoteExactInputSingleParams memory params = IQuoter.QuoteExactInputSingleParams({
            tokenIn: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            tokenOut: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            amountIn: 1000 * 1e6, // 1k
            fee: 500,
            sqrtPriceLimitX96: 0
        });

        (uint256 amountReceived, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed) =
            quoterV3.quoteExactInputSingle(params);
        
        console2.log('First');
        console2.log(amountReceived);
        console.log(sqrtPriceX96After);
        console.log(initializedTicksCrossed);

        
        params = IQuoter.QuoteExactInputSingleParams({
            tokenIn: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            tokenOut: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            amountIn: 10000 * 1e6, // 1k
            fee: 500,
            sqrtPriceLimitX96: 0
        });

        (amountReceived, sqrtPriceX96After, initializedTicksCrossed) =
            quoterV3.quoteExactInputSingle(params);
        
        console2.log('Second');
        console2.log(amountReceived);
        console.log(sqrtPriceX96After);
        console.log(initializedTicksCrossed);


        params = IQuoter.QuoteExactInputSingleParams({
            tokenIn: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            tokenOut: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            amountIn: 100000 * 1e6, // 1k
            fee: 500,
            sqrtPriceLimitX96: 0
        });

        (amountReceived, sqrtPriceX96After, initializedTicksCrossed) =
            quoterV3.quoteExactInputSingle(params);
        
        console2.log('third');
        console2.log(amountReceived);
        console.log(sqrtPriceX96After);
        console.log(initializedTicksCrossed);
        assertEq(true, true);
    }

    function testQuoterBatchV3() public {

        uint256[] memory amountsIn = new uint256[](3);
        uint256[3] memory amountStatic = [uint256(1000 * 1e6), uint256(10000 * 1e6), uint256(100000 * 1e6)];

        for (uint256 i = 0; i < amountStatic.length; i++) {
            amountsIn[i] = amountStatic[i];
        }
         
        IQuoter.QuoteExactInputSingleBatchParams memory params = IQuoter.QuoteExactInputSingleBatchParams({
            tokenIn: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            tokenOut: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            amountsIn: amountsIn, // 1k
            fee: 500,
            sqrtPriceLimitX96: 0
        });


        (uint256[] memory amountReceived, uint160[] memory sqrtPriceX96After, uint32[] memory initializedTicksCrossed) =
            quoterV3.quoteExactInputBatch(params);
        console.log('1');

        for (uint256 i = 0; i < amountReceived.length; i++) {
            console.log(i);
            console2.log(amountReceived[i]);
            console.log(sqrtPriceX96After[i]);
            console.log(initializedTicksCrossed[i]);
        }
        console.log('2');
        assertEq(true, true);
    }

    

    // function testQuoterV2() public {
    //     IQuoterV2.QuoteExactInputSingleParams memory params = IQuoterV2.QuoteExactInputSingleParams({
    //         tokenIn: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
    //         tokenOut: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
    //         amountIn: 2896580898754976, // 1m
    //         fee: 500,
    //         sqrtPriceLimitX96: 0
    //     });

    //     (uint256 amountReceived, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed,) =
    //         quoterV2.quoteExactInputSingle(params);

    //     console2.log(amountReceived);
    //     console.log(sqrtPriceX96After);
    //     console.log(initializedTicksCrossed);

    //     assertEq(true, true);
    // }

    // function testFuzzQuoters(bool side, uint256 amount) public {
    //     // make the tests mean something bc otherwise everything rounds to 0
    //     vm.assume(amount > 10000);

    //     IQuoterV2.QuoteExactInputSingleParams memory paramsV2 = IQuoterV2.QuoteExactInputSingleParams({
    //             tokenIn: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
    //             tokenOut: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
    //             amountIn: amount, 
    //             fee: 500,
    //             sqrtPriceLimitX96: 0
    //         });

    //     IQuoter.QuoteExactInputSingleParams memory paramsV3 = IQuoter.QuoteExactInputSingleParams({
    //             tokenIn: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
    //             tokenOut: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
    //             amountIn: amount, 
    //             fee: 500,
    //             sqrtPriceLimitX96: 0
    //         });

    //     if (side) {
    //         // flip the input and output
    //         paramsV2.tokenOut = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    //         paramsV2.tokenIn = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
           
    //         paramsV3.tokenOut = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    //         paramsV3.tokenIn = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    //     } 


    //     (uint256 amountReceivedV3, uint160 sqrtPriceX96AfterV3, uint32 initializedTicksCrossedV3) =
    //         quoterV3.quoteExactInputSingle(paramsV3);
        
    //     (uint256 amountReceivedV2, uint160 sqrtPriceX96AfterV2, uint32 initializedTicksCrossedV2,) =
    //         quoterV2.quoteExactInputSingle(paramsV2);

    //     assertEq(amountReceivedV3 == amountReceivedV2, true);
    //     assertEq(sqrtPriceX96AfterV3 == sqrtPriceX96AfterV2, true);
    //     assertEq(initializedTicksCrossedV3 == initializedTicksCrossedV2, true);
    // }
}
