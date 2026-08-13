//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {GaslessPayrollSystem} from "../src/PayrollSystem.sol";
import {MockUSDCTokens} from "../src/MockUSDCTokens.sol";
import {Harness} from "../src/PayrollSystem.sol";

contract TestPayrollSystem is Test {
    MockUSDCTokens public usdcToken;
    Harness public harness;
    uint256 internal constant HR_PRIVATE_KEY = 0xA23CC;
    uint256 internal constant ATTACKER_PRIVATE_KEY = 0x32CB;
    address HR = vm.addr(HR_PRIVATE_KEY);
    address USER = makeAddr("user");
    address ANOTHERUSER = makeAddr("anotherUser");

    function setUp() public {
        usdcToken = new MockUSDCTokens();

        vm.prank(HR);

        harness = new Harness(address(usdcToken));
        usdcToken.mint(address(harness), 100000 * 10 ** 6);
    }

    function setUpWithLowBalance() public {
        vm.prank(HR);
        harness = new Harness(address(usdcToken));
        usdcToken.mint(address(harness), 1000 * 10 ** 6);
    }

    function testClaim() public {
        uint256 amount = 5000e6;
        uint256 usedNonce = 1;
        string memory month = "May";
        uint256 deadline = 30 days;

        bytes32 digest = harness.hashEmployeePay(USER, amount, month, usedNonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(HR_PRIVATE_KEY, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.startPrank(USER);
        harness.claimSalary(USER, amount, month, usedNonce, deadline, signature);
        vm.stopPrank();

        assertTrue(harness.usedNonces(USER, usedNonce));
        assertEq(usdcToken.balanceOf(USER), amount);
    }

    function test_revertIfNonceAlreadyUsed() public {
        uint256 amount = 5000e6;
        uint256 usedNonce = 1;
        string memory month = "May";
        uint256 deadline = 30 days;

        bytes32 digest = harness.hashEmployeePay(USER, amount, month, usedNonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(HR_PRIVATE_KEY, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.startPrank(USER);
        harness.claimSalary(USER, amount, month, usedNonce, deadline, signature);
        vm.stopPrank();

        vm.startPrank(USER);
        vm.expectRevert(GaslessPayrollSystem.PayrollSystem__NonceAlreadyUsed.selector);
        harness.claimSalary(USER, amount, month, usedNonce, deadline, signature);
        vm.stopPrank();
    }

    function test_revertIfInvalidUser() public {
        uint256 amount = 5000e6;
        uint256 usedNonce = 1;
        string memory month = "May";
        uint256 deadline = 30 days;

        bytes32 digest = harness.hashEmployeePay(USER, amount, month, usedNonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(HR_PRIVATE_KEY, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.startPrank(USER);
        vm.expectRevert(GaslessPayrollSystem.PayrollSystem__InvalidUser.selector);
        harness.claimSalary(ANOTHERUSER, amount, month, usedNonce, deadline, signature);
        vm.stopPrank();
    }

    function test_revertIfInvalidSignature() public {
        uint256 amount = 5000e6;
        uint256 usedNonce = 1;
        string memory month = "May";
        uint256 deadline = 30 days;

        bytes32 digest = harness.hashEmployeePay(USER, amount, month, usedNonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ATTACKER_PRIVATE_KEY, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.startPrank(USER);
        vm.expectRevert(GaslessPayrollSystem.PayrollSystem__InvalidSignature.selector);
        harness.claimSalary(USER, amount, month, usedNonce, deadline, signature);
        vm.stopPrank();
    }

    function test_revertIfSignatureExpired() public {
        uint256 amount = 5000e6;
        uint256 usedNonce = 1;
        string memory month = "May";
        uint256 deadline = 30 days;

        bytes32 digest = harness.hashEmployeePay(USER, amount, month, usedNonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(HR_PRIVATE_KEY, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.warp(deadline + 1 days);

        vm.startPrank(USER);
        vm.expectRevert(GaslessPayrollSystem.PayrollSystem__SignatureExpired.selector);
        harness.claimSalary(USER, amount, month, usedNonce, deadline, signature);
        vm.stopPrank();
    }

    function test_revertIfInsufficientBalance() public {
        setUpWithLowBalance();
        uint256 amount = 5000e6;
        uint256 usedNonce = 1;
        string memory month = "May";
        uint256 deadline = 30 days;

        bytes32 digest = harness.hashEmployeePay(USER, amount, month, usedNonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(HR_PRIVATE_KEY, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.startPrank(USER);
        vm.expectRevert(GaslessPayrollSystem.PayrollSystem__InsufficientBalance.selector);
        harness.claimSalary(USER, amount, month, usedNonce, deadline, signature);
        vm.stopPrank();
    }
}
