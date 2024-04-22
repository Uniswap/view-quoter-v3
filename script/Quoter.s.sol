// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import {Script, console2} from "forge-std/Script.sol";
import {Quoter} from "../contracts/Quoter.sol";
import {ChainId} from "v3-periphery/contracts/libraries/ChainId.sol";

contract MyScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address factory = getFactoryAddress();
        Quoter quoter = new Quoter(factory);

        vm.stopBroadcast();
    }

    function getFactoryAddress() internal view returns (address) {
        uint256 chainId = ChainId.get();

        // base chain
        if (chainId == uint256(8453)) {
            return 0x33128a8fC17869897dcE68Ed026d694621f6FDfD;
        // celo chain
        } else if (chainId == uint256(42220)) {
            return 0xAfE208a311B21f13EF87E33A90049fC17A7acDEc;
        // bsc chain
        } else if (chainId == uint256(56)) {
            return 0xdB1d10011AD0Ff90774D0C6Bb92e5C5c8b4461F7;
        // optimism sepolia chain
        } else if (chainId == uint256(11155420)) {
            return 0x8CE191193D15ea94e11d327b4c7ad8bbE520f6aF;
        // arbitrum sepolia chain
        } else if (chainId == uint256(421614)) {
            return 0x248AB79Bbb9bC29bB72f7Cd42F17e054Fc40188e;
        // sepolia chain
        } else if (chainId == uint256(11155111)) {
            return 0x0227628f3F023bb0B980b67D528571c95c6DaC1c;
        // avalanche chain
        } else if (chainId == uint256(43114)) {
            return 0x740b1c1de25031C31FF4fC9A62f554A55cdC1baD;
        // zora chain
        } else if (chainId == uint256(7777777)) {
            return 0x7145F8aeef1f6510E92164038E1B6F8cB2c42Cbb;
        // zora sepolia chain
        } else if (chainId == uint256(999999999)) {
            return 0x4324A677D74764f46f33ED447964252441aA8Db6;
        // rookstock chain
        } else if (chainId == uint256(30)) {
            return 0xaF37EC98A00FD63689CF3060BF3B6784E00caD82;
        // blast chain
        } else if (chainId == uint256(81457)) {
            return 0x792edAdE80af5fC680d96a2eD80A44247D2Cf6Fd;
        } else {
            return 0x1F98431c8aD98523631AE4a59f267346ea31F984;
        }
    }
}
