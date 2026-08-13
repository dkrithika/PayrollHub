//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {GaslessPayrollSystem} from "../../src/PayrollSystem.sol";
import {MockUSDCTokens} from "../../src/MockUSDCTokens.sol";
import {Harness} from "../../src/PayrollSystem.sol";

contract PayrollSystemIntegration is Test {
    Harness public harness;
    MockUSDCTokens public usdc;

    uint256 internal constant HR_PRIVATE_KEY = 0xA23CC;
    address HR = vm.addr(HR_PRIVATE_KEY);
    address USER = makeAddr("user");

    uint256 amount = 5000e6;
    uint256 nonce = 1;
    string month = "May";
    uint256 deadline = 30 days;

    function setUp() public {
        usdc = new MockUSDCTokens();

        vm.prank(HR);
        harness = new Harness(address(usdc));
        usdc.mint(address(harness), 100000 * 10 ** 6);
    }

    function test_IntegrationClaimSalary() public {
        bytes32 digest = harness.hashEmployeePay(USER, amount, month, nonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(HR_PRIVATE_KEY, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.startPrank(USER);
        harness.claimSalary(USER, amount, month, nonce, deadline, signature);
        vm.stopPrank();
        assertEq(usdc.balanceOf(USER), amount);
        assertEq(harness.usedNonces(USER, nonce), true);
    }

    function test_IntegrationReplayAttack() public {
        bytes32 digest = harness.hashEmployeePay(USER, amount, month, nonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(HR_PRIVATE_KEY, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.startPrank(USER);
        harness.claimSalary(USER, amount, month, nonce, deadline, signature);
        vm.stopPrank();
        assertEq(usdc.balanceOf(USER), amount);
        assertEq(harness.usedNonces(USER, nonce), true);

        vm.startPrank(USER);
        vm.expectRevert(GaslessPayrollSystem.PayrollSystem__NonceAlreadyUsed.selector);
        harness.claimSalary(USER, amount, month, nonce, deadline, signature);
        vm.stopPrank();
    }
}
