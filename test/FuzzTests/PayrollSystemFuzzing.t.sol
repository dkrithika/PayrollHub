//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {GaslessPayrollSystem} from "../../src/PayrollSystem.sol";
import {MockUSDCTokens} from "../../src/MockUSDCTokens.sol";
import {Harness} from "../../src/PayrollSystem.sol";

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

    function testFuzz_ClaimSalary(uint256 amount) public {
        amount = bound(amount, 1, 100_000e6);

        uint256 nonce = 1;
        string memory month = "May";
        uint256 deadline = block.timestamp + 30 days;

        bytes32 digest = harness.hashEmployeePay(USER, amount, month, nonce, deadline);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(HR_PRIVATE_KEY, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(USER);
        harness.claimSalary(USER, amount, month, nonce, deadline, signature);
        assertEq(usdcToken.balanceOf(USER), amount);
    }

    function testFuzz_ClaimWithDifferentNonces(uint256 nonce) public {
        nonce = bound(nonce, 1, type(uint256).max);

        uint256 amount = 5000e6;
        string memory month = "May";
        uint256 deadline = block.timestamp + 30 days;

        bytes32 digest = harness.hashEmployeePay(USER, amount, month, nonce, deadline);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(HR_PRIVATE_KEY, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(USER);
        harness.claimSalary(USER, amount, month, nonce, deadline, signature);
        assertEq(usdcToken.balanceOf(USER), amount);
        assertTrue(harness.usedNonces(USER, nonce));
    }
}
