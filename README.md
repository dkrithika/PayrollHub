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
```text

## FEATURES
