//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {VestingToken} from "../../src/VestingToken.sol";
import {MockToken} from "../../src/MockTokens.sol";

contract VestingTokenIntegration is Test {
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

    function test_IntegrationClaimTokens() public {
        uint256 startTime = block.timestamp;
        uint256 expectedCliffTime = startTime + CLIFF_DURATION;
        uint256 timeElapsed = CLIFF_DURATION;
        uint256 expectedClaim = (TOTAL_AMOUNT * timeElapsed) / VESTING_DURATION;

        vm.startPrank(OWNER);
        vesting.enterOrganisation(USER, VESTING_DURATION, CLIFF_DURATION, TOTAL_AMOUNT);
        vm.stopPrank();
        VestingToken.ExecutiveVestingSchedule memory schedule = vesting.getVestingSchedule(USER);

        assertEq(schedule.executiveId, USER);
        assertEq(schedule.isActive, true);
        assertEq(schedule.cliffTime, expectedCliffTime);
        assertEq(schedule.totalAmount, TOTAL_AMOUNT);

        vm.warp(startTime + CLIFF_DURATION);

        vm.startPrank(USER);
        vesting.claim(USER);
        vm.stopPrank();
        schedule = vesting.getVestingSchedule(USER);

        assertEq(schedule.amountClaimed, expectedClaim);
        assertEq(schedule.lastClaimedTime, block.timestamp);
        assertEq(token.balanceOf(USER), expectedClaim);
        assertTrue(schedule.isActive);

        vm.warp(VESTING_DURATION + startTime);
        vm.startPrank(USER);
        vesting.claim(USER);
        vm.stopPrank();
        schedule = vesting.getVestingSchedule(USER);

        assertEq(token.balanceOf(USER), TOTAL_AMOUNT);
        assertEq(schedule.amountClaimed, TOTAL_AMOUNT);
        assertEq(schedule.lastClaimedTime, VESTING_DURATION + startTime);
        assertTrue(schedule.isActive);
    }

    function test_IntegrationTestClawback() public {
        uint256 startTime = block.timestamp;
        uint256 expectedCliffTime = startTime + CLIFF_DURATION;
        uint256 timeElapsed = CLIFF_DURATION;
        uint256 expectedClaim = (TOTAL_AMOUNT * timeElapsed) / VESTING_DURATION;

        vm.startPrank(OWNER);
        vesting.enterOrganisation(USER, VESTING_DURATION, CLIFF_DURATION, TOTAL_AMOUNT);
        vm.stopPrank();
        VestingToken.ExecutiveVestingSchedule memory schedule = vesting.getVestingSchedule(USER);

        assertEq(schedule.executiveId, USER);
        assertEq(schedule.isActive, true);
        assertEq(schedule.cliffTime, expectedCliffTime);
        assertEq(schedule.totalAmount, TOTAL_AMOUNT);

        vm.warp(startTime + CLIFF_DURATION);

        vm.startPrank(USER);
        vesting.claim(USER);
        vm.stopPrank();
        schedule = vesting.getVestingSchedule(USER);

        assertEq(schedule.amountClaimed, expectedClaim);
        assertEq(schedule.lastClaimedTime, block.timestamp);
        assertEq(token.balanceOf(USER), expectedClaim);
        assertTrue(schedule.isActive);

        vm.warp(startTime + 150 days);

        uint256 quitDay = 150 days;
        uint256 totalVestedAtQuit = (TOTAL_AMOUNT * quitDay) / VESTING_DURATION;
        //uint256 unclaimedVested = totalVestedAtQuit - expectedVested;
        uint256 lockedAmount = TOTAL_AMOUNT - totalVestedAtQuit;

        vm.startPrank(OWNER);
        vesting.clawback(USER);
        vm.stopPrank();
        schedule = vesting.getVestingSchedule(USER);

        assertEq(token.balanceOf(USER), totalVestedAtQuit);
        assertEq(token.balanceOf(OWNER), lockedAmount);
        assertEq(token.balanceOf(address(vesting)), 0);
        assertEq(schedule.isActive, false);
        assertEq(schedule.amountClaimed, totalVestedAtQuit);
    }
}
