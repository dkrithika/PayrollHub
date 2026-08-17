# Web3 Payroll System

A decentralized payroll system for Web3 organizations that enables secure employee salary payments using ERC-20 tokens and EIP-712 off-chain authorization.

The system is designed around two payroll models:

- **Token Vesting Engine** — for founders and executives with time-based token vesting.
- **Gasless Payroll Engine** — for regular employees who can claim their salary using an HR-authorized EIP-712 signature.

---

## Overview

Traditional crypto payroll can require the payroll administrator to submit individual transactions for employees, resulting in unnecessary gas costs and manual work.

This project explores a different approach using **EIP-712 typed-data signatures**.

Instead of HR directly sending a salary transaction, HR authorizes an employee's payment off-chain. The employee then submits the signed authorization to the smart contract, which verifies the HR signature before transferring the ERC-20 salary.

### Gasless Payroll Flow

```text
HR Manager
    │
    │ EIP-712 signature
    │ (off-chain)
    ▼
Payroll Authorization
    │
    │ signature
    ▼
Employee
    │
    │ claimSalary()
    ▼
Payroll Smart Contract
    │
    ├── Verify employee
    ├── Check nonce
    ├── Check deadline
    ├── Recover HR signer
    ├── Verify HR authorization
    └── Transfer ERC-20 tokens
```

## FEATURES

### Gasless Payroll
- EIP-712 typed-data payroll authorizations
- ECDSA signature verification
- Employee-specific payroll claims
- Replay protection using nonces
- Signature expiration using deadlines
- ERC-20 salary payments
- Safe ERC-20transfers using OpenZeppelin ```text SafeERC20```
- Custom errors for gas-efficient failure handling

### Token Vesting
The payroll system also includes a vesting mechanism designed for founders and executives.

Supported concepts include:
- Token allocation
- Cliff periods
- Linear vesting
- Claiming vested tokens
- Clawback of unvested tokens

## Security Considerations
The payroll contract includes several protections against common attack vectors.

### EIP-712 Signatures

Payroll authorizations use typed structured data rather than signing arbitrary messages.

The signed payroll data contains:
```text
employeeId
amount
month
nonce
deadline
```

The EIP-712 domain is bound to:
```text
GaslessPayrollSystem
Version: 1
Chain ID
Contract Address
```

This prevents a signature from being reused across a different contract or chain.

### Replay Protection

Each employee has a nonce-based authorization system:
```text
mapping(address => mapping(uint256 => bool)) public usedNonces;
```
Once a payroll authorization is successfully claimed, its nonce is marked as used.

### Signature Expiration

Payroll authorizations contain a deadline.

Expired authorizations cannot be claimed.

### Employee Authorization

The contract verifies that the caller is the employee specified in the signed payroll authorization.

### ERC-20 Safety

Token transfers use OpenZeppelin's ```text SafeERC20``` implementation.

## Testing

The project uses Foundry for smart-contract testing.

Testing includes:

- Unit tests
- Integration tests
- Fuzz tests
- Edge-case testing
- Signature verification testing
- Nonce/replay protection testing
- Deadline expiration testing
- Access-control testing
- ERC-20 payment testing

The testing strategy focuses on both expected behavior and adversarial/invalid inputs.

## Technology Stack
### Smart Contracts
- Solidity```text^0.8.30```
- Foundry
- OpenZeppelin Contracts

  ### Cryptography
- EIP-712
- ECDSA

  ### Frontend/Web3Integration
- TypeScript
- Viem
- Vite

  ### Network
- Ethereum Sepolia Testnet

## Deployment
The payroll contract has been deployed to Sepolia.

### GaslessPayrollSystem

```text
0xA49a53FdDA78541CcaC01e717aE95b074A1AF77a
```

The deployed contract has been tested with an end-to-end EIP-712 payroll claim.

## Example Payroll Authorization

An HR manager can authorize a payment containing:

```text
Employee: 0x44f71bb76fe17F016c7a4c3a64c6F08F51d0FbE7
Amount: 1 USDC
Month: August
Nonce: 1
Deadline: <timestamp>
```

The authorization is signed off-chain using EIP-712.

The employee then submits the authorization to:
```text
claimSalary(
    employeeId,
    amount,
    month,
    nonce,
    deadline,
    signature
)
```

The contract verifies the signature and transfers the salary if all conditions are satisfied

