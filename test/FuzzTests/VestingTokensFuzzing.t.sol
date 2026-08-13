//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {VestingToken} from "../../src/VestingToken.sol";
import {MockToken} from "../../src/MockTokens.sol";

contract VestingTokenTest is Test {
    VestingToken public vesting;
    MockToken public token;
    address public OWNER = makeAddr("owner");
    address public USER = makeAddr("user");
    address public ANOTHERUSER = makeAddr("useranother");
    uint256 constant VESTING_DURATION = 365 days;
    uint256 constant CLIFF_DURATION = 90 days;
    uint256 constant TOTAL_AMOUNT = 120000 * 10 ** 18;

    function setUp() public {
        token = new MockToken();

        vm.startPrank(OWNER);
        vesting = new VestingToken(address(token));
        vm.stopPrank();

        token.mint(OWNER, TOTAL_AMOUNT);

        vm.startPrank(OWNER);
        token.approve(address(vesting), TOTAL_AMOUNT);
        vm.stopPrank();
    }

    function testFuzz_CliamAfterCliff(uint256 claimTime) public {
        claimTime = bound(claimTime, CLIFF_DURATION, VESTING_DURATION - 1);
        uint256 startTime = block.timestamp;

        vm.startPrank(OWNER);
        vesting.enterOrganisation(USER, VESTING_DURATION, CLIFF_DURATION, TOTAL_AMOUNT);
        vm.stopPrank();

        vm.warp(startTime + claimTime);
        vm.startPrank(USER);
        vesting.claim(USER);
        vm.stopPrank();

        VestingToken.ExecutiveVestingSchedule memory schedule = vesting.getVestingSchedule(USER);
        uint256 expectedCliffTime = startTime + CLIFF_DURATION;
        uint256 timeElapsed = block.timestamp - startTime;
        uint256 expectedClaim = (TOTAL_AMOUNT * timeElapsed) / VESTING_DURATION;

        assertEq(schedule.amountClaimed, expectedClaim);
        assertEq(token.balanceOf(USER), expectedClaim);
    }

    function testFUzz_ClawbackAtTimes(uint256 quitDay) public {
        uint256 startTime = block.timestamp;
        quitDay = bound(quitDay, CLIFF_DURATION, VESTING_DURATION);

        vm.startPrank(OWNER);
        vesting.enterOrganisation(USER, VESTING_DURATION, CLIFF_DURATION, TOTAL_AMOUNT);
        vm.stopPrank();

        vm.warp(startTime + quitDay);
        uint256 expectedVested = (TOTAL_AMOUNT * quitDay) / VESTING_DURATION;

        vm.warp(quitDay + startTime);
        VestingToken.ExecutiveVestingSchedule memory schedule = vesting.getVestingSchedule(USER);
        uint256 totalVestedAtQuit = (TOTAL_AMOUNT * quitDay) / VESTING_DURATION;
        uint256 lockedAmount = TOTAL_AMOUNT - totalVestedAtQuit;

        vm.startPrank(OWNER);
        vesting.clawback(USER);
        vm.stopPrank();
        schedule = vesting.getVestingSchedule(USER);

        assertEq(token.balanceOf(USER), totalVestedAtQuit);
        assertEq(schedule.isActive, false);
        assertEq(schedule.amountClaimed, totalVestedAtQuit);
    }

    function testFuzz_CannotClaimBeforeThreeMonths(uint256 timeAfterClaim) public {
        timeAfterClaim = bound(timeAfterClaim, 0, 90 days - 1);

        // first claim at cliff
        uint256 startTime = block.timestamp;

        vm.startPrank(OWNER);
        vesting.enterOrganisation(USER, VESTING_DURATION, CLIFF_DURATION, TOTAL_AMOUNT);
        vm.stopPrank();

        vm.warp(startTime + CLIFF_DURATION);
        vm.startPrank(USER);
        vesting.claim(USER);
        vm.stopPrank();

        // warp timeAfterClaim
        vm.warp(timeAfterClaim + block.timestamp);

        // second claim should revert
        vm.startPrank(USER);
        vm.expectRevert(VestingToken.VestingToken__CanClaimEveryThreeMonths.selector);
        vesting.claim(USER);
        vm.stopPrank();
    }
}
