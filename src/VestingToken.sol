//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract VestingToken is Ownable {
    using SafeERC20 for IERC20;

    error VestingToken__InvalidId(); //done
    error VestingToken__CanClaimEveryThreeMonths(); //done
    error VestingToken__OnlyOwnerHaveAccess();
    error VestingToken__AlreadyEnteredTheOrganisation(); //done
    error VestingToken__YouArentPartOfTheOrganisation(); //done
    error VestingToken__YouArentActiveParticipant(); //done
    error VestingToken__NothingToClaim();
    error VestingToken__ZeroBalance(); //done
    error VestingToken__CantClaimBeforeCliffTime();
    error VestingToken__InvalidDuration(); //done

    struct ExecutiveVestingSchedule {
        address executiveId;
        uint256 startTime;
        uint256 endTime;
        uint256 cliffTime;
        uint256 totalAmount;
        uint256 amountClaimed;
        uint256 lastClaimedTime;
        bool isActive;
    }
    address public immutable admin;
    IERC20 public tokens;
    mapping(address => ExecutiveVestingSchedule) public vestingSchedules;

    event EnteredOrganisation(address user);
    event TokenClaimed(address user, uint256 amount);
    event ClawbackExecuted(address user, uint256 amountClaimed, uint256 contractAmount);

    constructor(address _tokenAddress) Ownable(msg.sender) {
        tokens = IERC20(_tokenAddress);
    }

    function enterOrganisation(address _executiveId, uint256 _vestingDuration, uint256 _cliffTime, uint256 _totalAmount)
        public
        onlyOwner
    {
        if (vestingSchedules[_executiveId].isActive) {
            revert VestingToken__AlreadyEnteredTheOrganisation();
        }
        if (_executiveId == address(0)) {
            revert VestingToken__InvalidId();
        }
        if (_vestingDuration == 0) {
            revert VestingToken__InvalidDuration();
        }
        if (_cliffTime > _vestingDuration) {
            revert VestingToken__InvalidDuration();
        }
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + _vestingDuration;
        uint256 cliffTime = startTime + _cliffTime;

        vestingSchedules[_executiveId] = ExecutiveVestingSchedule({
            executiveId: _executiveId,
            startTime: startTime,
            endTime: endTime,
            cliffTime: cliffTime,
            totalAmount: _totalAmount,
            amountClaimed: 0,
            lastClaimedTime: startTime,
            isActive: true
        });
        tokens.safeTransferFrom(msg.sender, address(this), _totalAmount);

        emit EnteredOrganisation(_executiveId);
    }

    function claim(address _executiveId) public {
        //Let's the person claim his tokens after a certain period
        uint256 threeMonths = 90 days;
        if (msg.sender != _executiveId) revert VestingToken__InvalidId();
        if (_executiveId != vestingSchedules[_executiveId].executiveId) {
            revert VestingToken__YouArentPartOfTheOrganisation();
        }
        if (!(vestingSchedules[_executiveId].isActive)) {
            revert VestingToken__YouArentActiveParticipant();
        }
        if (block.timestamp < vestingSchedules[_executiveId].cliffTime) {
            revert VestingToken__CantClaimBeforeCliffTime();
        }
        if (block.timestamp < vestingSchedules[_executiveId].lastClaimedTime + threeMonths) {
            revert VestingToken__CanClaimEveryThreeMonths();
        }
        // Calculating claimable Amount
        uint256 claimableAmount = calculateClaimableAmount(_executiveId);
        if (claimableAmount == 0) {
            revert VestingToken__NothingToClaim();
        }
        vestingSchedules[_executiveId].amountClaimed += claimableAmount;
        vestingSchedules[_executiveId].lastClaimedTime = block.timestamp;

        tokens.safeTransfer(_executiveId, claimableAmount);
        emit TokenClaimed(_executiveId, claimableAmount);
    }

    function calculateClaimableAmount(address _executive) internal view returns (uint256) {
        ExecutiveVestingSchedule storage schedule = vestingSchedules[_executive];
        if (!schedule.isActive || schedule.amountClaimed >= schedule.totalAmount) {
            return 0;
        }
        if (block.timestamp < schedule.cliffTime) {
            return 0;
        }
        if (block.timestamp >= schedule.endTime) {
            return schedule.totalAmount - schedule.amountClaimed;
        }
        //Linear vesting: Calculate how many tokens are vested
        uint256 timeElapsed = block.timestamp - schedule.startTime;
        uint256 totalVestingTime = schedule.endTime - schedule.startTime;
        uint256 totalVested = (schedule.totalAmount * timeElapsed) / totalVestingTime;
        return totalVested - schedule.amountClaimed;
    }

    function clawback(address _executiveId) public onlyOwner {
        /*
        The Clawback: If the executive gets fired in month 6, the company admin clicks a button.
        The contract instantly calculates what they earned up to that exact second,
        sends it to them, and destroys the rest of the stream, returning the remaining locked tokens back to the company.*/

        ExecutiveVestingSchedule storage schedule = vestingSchedules[_executiveId];

        if (schedule.executiveId != _executiveId) {
            revert VestingToken__InvalidId();
        }

        if (!(schedule.isActive)) {
            revert VestingToken__YouArentActiveParticipant();
        }
        uint256 unclaimedVested = 0;
        uint256 LockedAmount;

        if (block.timestamp < schedule.cliffTime) {
            unclaimedVested = 0;
            LockedAmount = schedule.totalAmount;
        } else {
            uint256 timeElapsed = block.timestamp - schedule.startTime;
            uint256 totalVestingTime = schedule.endTime - schedule.startTime;
            uint256 totalVested = (schedule.totalAmount * timeElapsed) / totalVestingTime;

            unclaimedVested = totalVested - schedule.amountClaimed;
            LockedAmount = schedule.totalAmount - totalVested;
        }

        if (unclaimedVested == 0 && LockedAmount == 0) {
            revert VestingToken__ZeroBalance();
        }
        schedule.amountClaimed += unclaimedVested;
        schedule.isActive = false;
        schedule.endTime = 0;
        schedule.startTime = 0;
        schedule.cliffTime = 0;
        tokens.safeTransfer(schedule.executiveId, unclaimedVested);

        if (LockedAmount > 0) {
            tokens.safeTransfer(owner(), LockedAmount);
        }
        emit ClawbackExecuted(_executiveId, unclaimedVested, LockedAmount);
    }

    function getVestingSchedule(address _executive) public view returns (ExecutiveVestingSchedule memory) {
        return vestingSchedules[_executive];
    }
}
