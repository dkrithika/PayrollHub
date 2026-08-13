//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {VestingToken} from "../src/VestingToken.sol";
import {MockToken} from "../src/MockTokens.sol";

contract DeployVestingTokens is Script {
    VestingToken public vesting;
    MockToken public token;

    function run() external {
        vm.startBroadcast();
        token = new MockToken();
        vesting = new VestingToken(address(token));
        vm.stopBroadcast();
    }
}
