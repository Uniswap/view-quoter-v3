// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import {Script, console2} from "forge-std/Script.sol";
import {Quoter} from "../contracts/Quoter.sol";

contract MyScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
        Quoter quoter = new Quoter(factory);

        vm.stopBroadcast();
    }
}
