//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {EIP712} from "lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";

contract GaslessPayrollSystem is EIP712{
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;
    
    error PayrollSystem__NonceAlreadyUsed();
    error PayrollSystem__InvalidSignature();
    error PayrollSystem__InsufficientBalance();
    error PayrollSystem__InvalidUser();
    error  PayrollSystem__SignatureExpired();

    
    struct EmployeePay{
        address employeeId;
        uint256 amount;
        string month;
        uint256 nonce;
        uint256 deadline;

    }

    bytes32 public constant EMPLOYEE_PAYMENT_HASH = 
    keccak256("EmployeePay(address employeeId,uint256 amount,string month,uint256 nonce,uint256 deadline)");
   
   address public hrManager;
   IERC20 public usdc;
   mapping(address => mapping(uint256 => bool)) public usedNonces;
   

   event SalaryClaimed(address employeeId,uint256 amount,string month,uint256 nonce,uint256 deadline);

   constructor(address _usdc) EIP712("GaslessPayrollSystem","1"){
    hrManager = msg.sender;
    usdc = IERC20( _usdc);
   }

   function _hashEmployeePay(address _employeeId,uint256 _amount,string memory _month,uint256 _nonce,uint256 _deadline) internal view returns (bytes32){
    return _hashTypedDataV4(
        keccak256(
            abi.encode(
                EMPLOYEE_PAYMENT_HASH,
                _employeeId,
                _amount,
                keccak256(bytes(_month)),
                _nonce,
                _deadline
            )
        )
        );
   }

   

   function claimSalary(
    address _employeeId,
    uint256 _amount,
    string calldata _month,
    uint256 _nonce,
    uint256 _deadline,
    bytes memory signature
   ) external{
    if(msg.sender != _employeeId) revert PayrollSystem__InvalidUser();
    if(usedNonces[_employeeId][_nonce]) revert PayrollSystem__NonceAlreadyUsed();
    if(block.timestamp > _deadline) revert PayrollSystem__SignatureExpired();

    bytes32 digest = _hashEmployeePay(_employeeId, _amount,_month, _nonce,_deadline);
    address signer = digest.recover(signature);

    if(signer != hrManager) revert PayrollSystem__InvalidSignature();

    usedNonces[_employeeId][_nonce] = true;

    if(usdc.balanceOf(address(this)) < _amount ) revert PayrollSystem__InsufficientBalance();

    usdc.safeTransfer(_employeeId,_amount);
    
    emit SalaryClaimed(_employeeId,_amount,_month,_nonce,_deadline);
   }


}