//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {GaslessPayrollSystem} from "../src/PayrollSystem.sol";
import {MockUSDCTokens} from "../src/MockUSDCTokens.sol";

contract DeployPayrollSystem is Script {
    GaslessPayrollSystem public payroll;

    function run() external {
        address usdc = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
        vm.startBroadcast();
        payroll = new GaslessPayrollSystem(usdc);
        vm.stopBroadcast();
    }
}
