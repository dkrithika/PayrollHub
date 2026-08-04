//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {VestingToken} from "../src/VestingToken.sol";
import {MockToken} from "../src/MockTokens.sol";

contract VestingTokenTest is Test{
   VestingToken public vesting;
   MockToken public token;
   address public OWNER = makeAddr("owner");
   address public USER = makeAddr("user");
   address public ANOTHERUSER = makeAddr("useranother");
   uint256 constant VESTING_DURATION = 365 days;
   uint256 constant CLIFF_DURATION = 90 days;
   uint256 constant TOTAL_AMOUNT = 120000 * 10**18;

 
  function setUp() public{
   token = new MockToken();

   vm.startPrank(OWNER);
   vesting = new VestingToken(address(token));
    vm.stopPrank();

    token.mint(OWNER,TOTAL_AMOUNT);

    vm.startPrank(OWNER);
    token.approve(address(vesting), TOTAL_AMOUNT);
    vm.stopPrank();
   }
   function testEnterOrganisation() public{
    vm.startPrank(OWNER);
    vesting.enterOrganisation(USER, VESTING_DURATION, CLIFF_DURATION,TOTAL_AMOUNT);
    vm.stopPrank();
    ( address executiveId,
        uint256 startTime,
        uint256 endTime,
        uint256 cliffTime,
        uint256 totalAmount,
        uint256 amountClaimed,
        uint256 lastClaimedTime,
        bool isActive) = vesting.vestingSchedules(USER);

        uint256 expectedStartTime = block.timestamp;
        uint256 expectedEndTime = expectedStartTime + VESTING_DURATION;
        uint256 expectedCliffTime = expectedStartTime + CLIFF_DURATION;
        

        assertEq(executiveId,USER);
        assertEq(startTime,expectedStartTime);
        assertEq(endTime,expectedEndTime);
        assertEq(cliffTime,expectedCliffTime);
        assertEq(totalAmount,TOTAL_AMOUNT);
        assertEq(amountClaimed,0);
        assertEq(lastClaimedTime,expectedStartTime);
        assertTrue(isActive);
   }



   function test_AlreadyEnteredTheOrganisation() public{
    vesting.getVestingSchedule(USER);
    vm.startPrank(OWNER);
    vesting.enterOrganisation(USER,VESTING_DURATION,CLIFF_DURATION, TOTAL_AMOUNT);
    vm.stopPrank();

    vm.startPrank(OWNER);
    vm.expectRevert(VestingToken.VestingToken__AlreadyEnteredTheOrganisation.selector);
    vesting.enterOrganisation(USER,VESTING_DURATION,CLIFF_DURATION, TOTAL_AMOUNT);
    vm.stopPrank();
    
     uint256 expectedStartTime = block.timestamp;
        uint256 expectedEndTime = expectedStartTime + VESTING_DURATION;
        uint256 expectedCliffTime = expectedStartTime + CLIFF_DURATION;
        

    VestingToken.ExecutiveVestingSchedule memory schedule = vesting.getVestingSchedule(USER);
    assertEq(schedule.isActive,true);
    assertEq(schedule.executiveId,USER);
    assertEq(schedule.totalAmount,TOTAL_AMOUNT);
    assertEq(schedule.cliffTime,expectedCliffTime);
   }


   function test_InvalidId() public{
     vm.startPrank(OWNER);
     vm.expectRevert(VestingToken.VestingToken__InvalidId.selector);
     vesting.enterOrganisation(address(0),VESTING_DURATION,CLIFF_DURATION, TOTAL_AMOUNT);
     vm.stopPrank();

   }


   function test_InvalidDuration() public{
    vm.startPrank(OWNER);
     vm.expectRevert(VestingToken.VestingToken__InvalidDuration.selector);
     vesting.enterOrganisation(USER,0,CLIFF_DURATION, TOTAL_AMOUNT);
     vm.stopPrank();

   }

   function test_InvalidDurationInCaseOfFalseCliffTime() public{
    uint256 expectedStartTime = block.timestamp;
    uint256 falseCliffTime = VESTING_DURATION + expectedStartTime;
    vm.startPrank(OWNER);
    vm.expectRevert(VestingToken.VestingToken__InvalidDuration.selector);
    vesting.enterOrganisation(USER,VESTING_DURATION,falseCliffTime, TOTAL_AMOUNT);
    vm.stopPrank();
   }

   function testClaim() public{
     vm.startPrank(OWNER);
    vesting.enterOrganisation(USER, VESTING_DURATION, CLIFF_DURATION,TOTAL_AMOUNT);
    vm.stopPrank();
    uint256 expectedStartTime = block.timestamp;
    uint256 expectedCliffTime = expectedStartTime + CLIFF_DURATION;
    uint256 timeElapsed = CLIFF_DURATION;
    uint256 expectedClaim = (TOTAL_AMOUNT * timeElapsed) / VESTING_DURATION;
    ( address executiveId,
        uint256 startTime,
        uint256 endTime,
        uint256 cliffTime,
        uint256 totalAmount,
        uint256 amountClaimed,
        uint256 lastClaimedTime,
        bool isActive) = vesting.vestingSchedules(USER);

         assertEq(executiveId,USER);
        assertEq(startTime,expectedStartTime);
        assertEq(amountClaimed,0);
        assertEq(lastClaimedTime,expectedStartTime);
    vm.warp(expectedCliffTime);
    vm.startPrank(USER);
    vesting.claim(USER);
    vm.stopPrank();
    (
        ,
        ,
        ,
        ,
        ,
        uint256 newAmountClaimed,
        uint256 newLastClaimedTime,
        bool newIsActive) = vesting.vestingSchedules(USER);
    assertEq(newAmountClaimed,expectedClaim);
    assertEq(newLastClaimedTime,block.timestamp);
    assertEq(token.balanceOf(USER),expectedClaim);
    assertEq(token.balanceOf(address(vesting)),TOTAL_AMOUNT - expectedClaim);
    assertTrue(newIsActive);
   }

   function test_YouArentPartOfTheOrganisation() public{
   vm.startPrank(USER);
   vm.expectRevert(VestingToken.VestingToken__YouArentPartOfTheOrganisation.selector);
   vesting.claim(ANOTHERUSER);
   vm.stopPrank();
   }

   function test_IfInactiveAfterClawback() public{
    vm.startPrank(OWNER);
    vesting.enterOrganisation(USER,VESTING_DURATION,CLIFF_DURATION, TOTAL_AMOUNT);
    vm.stopPrank();

    uint256 startTime = block.timestamp;

    vm.warp(startTime + CLIFF_DURATION);

    vm.startPrank(OWNER);
    vesting.clawback(USER);
    vm.stopPrank();

    (,,,,,,,bool isActive) = vesting.vestingSchedules(USER);
    assertFalse(isActive);

    vm.startPrank(USER);
    vm.expectRevert(VestingToken.VestingToken__YouArentActiveParticipant.selector);
    vesting.claim(USER);
    vm.stopPrank();
   }


   function test_RevertIfNeverActive() public{
    vm.startPrank(OWNER);
    vesting.enterOrganisation(USER, VESTING_DURATION, CLIFF_DURATION,TOTAL_AMOUNT);
    vm.stopPrank();

    vm.startPrank(OWNER);
    //Usedclawback to inactivate since no helper function to to manually deactivate
    vesting.clawback(USER);
    vm.stopPrank();

    vm.startPrank(USER);
    vm.expectRevert(VestingToken.VestingToken__YouArentActiveParticipant.selector);
    vesting.claim(USER);
    vm.stopPrank();
   }

   function test_RevertsIfNotInSystem() public{
    vm.startPrank(USER);
    vm.expectRevert(VestingToken.VestingToken__YouArentPartOfTheOrganisation.selector);
    vesting.claim(USER);
    vm.stopPrank();
   }
   function test_RevertIfClaimedBeforeCliffTime(uint256 quitBeforeCliff) public{
    uint256 startTime = block.timestamp;
     quitBeforeCliff = bound(quitBeforeCliff, startTime, CLIFF_DURATION - 1);
    vm.startPrank(OWNER);
    vesting.enterOrganisation(USER, VESTING_DURATION, CLIFF_DURATION,TOTAL_AMOUNT);
    vm.stopPrank();

    vm.warp(startTime + quitBeforeCliff);

    vm.startPrank(USER);
    vm.expectRevert(VestingToken.VestingToken__CantClaimBeforeCliffTime.selector);
    vesting.claim(USER);
    vm.stopPrank();
   }

   /*function test_ClaimEveryThreeMonths() public{
    uint256 startTime = block.timestamp;
    vm.startPrank(OWNER);
    vesting.enterOrganisation(USER, VESTING_DURATION, CLIFF_DURATION,TOTAL_AMOUNT);
    vm.stopPrank();

    vm.warp(CLIFF_DURATION + 1 days);

    vm.startPrank(USER);
    vesting.claim(USER);
    vm.stopPrank();
   }*/

   function testClawback() public{
     vm.startPrank(OWNER);
    vesting.enterOrganisation(USER, VESTING_DURATION, CLIFF_DURATION,TOTAL_AMOUNT);
    vm.stopPrank();
    uint256 startTime = block.timestamp;


    vm.warp(startTime + 100 days);

   uint256 expectedVested = (TOTAL_AMOUNT * 100 days) / VESTING_DURATION;
    
    vm.startPrank(USER);
    vesting.claim(USER);
    vm.stopPrank();
    
    assertEq(token.balanceOf(USER), expectedVested);

    vm.warp(startTime + 150 days);
     
     uint256 quitDay = 150 days;
     uint256 totalVestedAtQuit = (TOTAL_AMOUNT * quitDay) / VESTING_DURATION;
     //uint256 unclaimedVested = totalVestedAtQuit - expectedVested;
     uint256 lockedAmount = TOTAL_AMOUNT - totalVestedAtQuit;

     vm.startPrank(OWNER);
     vesting.clawback(USER);
     vm.stopPrank();

     assertEq(token.balanceOf(USER),totalVestedAtQuit);
     assertEq(token.balanceOf(OWNER), lockedAmount);
     assertEq(token.balanceOf(address(vesting)),0);

    // Schedule is inactive
    (,,,,,uint256 amountClaimed,,bool isActive) = vesting.vestingSchedules(USER);
    assertFalse(isActive);
    assertEq(amountClaimed, totalVestedAtQuit);
   }

   function test_ZeroBalance() public{
     vm.startPrank(OWNER);
    vesting.enterOrganisation(USER, VESTING_DURATION, CLIFF_DURATION,TOTAL_AMOUNT);
    vm.stopPrank();
    
   }
}