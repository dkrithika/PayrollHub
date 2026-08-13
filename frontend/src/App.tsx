import { useState } from "react";
import "./App.css";
import {parseUnits} from "viem";

import {
  connectWallet as connectPayrollWallet,
  signEmployeePay,
  claimSalary,
} from "./assets/Payroll";

import {
  enterOrganisation as enterOrganisationService,
  claim as claimVestingService,
  clawback as clawbackService,
} from "./assets/VestingToken";

function App() {

  const [wallet, setWallet] = useState("");
  const [status, setStatus] = useState("");
  const [statusType, setStatusType] = useState<"success" | "error" | "info">("info");
  const [txHash, setTxHash] = useState("");
 

  // HR payment
  const [employeeAddress, setEmployeeAddress] = useState("");
  const [salaryAmount, setSalaryAmount] = useState("");
  const [month, setMonth] = useState("");
  const [nonce, setNonce] = useState("0");
  const [deadlineDays, setDeadlineDays] = useState("");
  

  const [signature, setSignature] = useState("");

  // Employee claim
  const [claimEmployee, setClaimEmployee] = useState("");
  const [claimAmount, setClaimAmount] = useState("");
  const [claimMonth, setClaimMonth] = useState("");
  const [claimNonce, setClaimNonce] = useState("0");
  const [claimDeadline, setClaimDeadline] = useState("");
  const [claimSignature, setClaimSignature] = useState("");

  // Vesting
  const [executiveAddress, setExecutiveAddress] = useState("");
  const [totalAmount, setTotalAmount] = useState("");
  const [vestingDuration, setVestingDuration] = useState("");
  const [cliffDuration, setCliffDuration] = useState("");

  const connectWallet = async () => {
    // Connect button
    try{
      setStatus("Connecting wallet...");

      const address = await connectPayrollWallet();
      setWallet(address);
      setStatus('Wallet connected successfully');
    } catch (error){
      setStatus(
        error instanceof Error ? error.message:String(error)
      );
    }
    
  };

  const getDeadline = (days: number): bigint => {
  const now = Math.floor(Date.now() / 1000);
  return BigInt(now + days * 24 * 60 * 60);
};

  const signPayment = async () => {
    // signEmployeePay() will be wired here
    

    try {
      if(!employeeAddress){
        setStatusType("error");
        setStatus("Enter an employee address");
        return;
      }

      if(!salaryAmount){
        setStatusType("error");
        setStatus("Enter a salary amount");
        return;
      }
      if(!month){
        setStatusType("error");
        setStatus("Enter the payment month");
        return;
      }
      if(!deadlineDays){
        setStatusType("error");
        setStatus("Enter a deadline");
        return;
      }
      setStatusType("info");
      setStatus("Waiting for signature...");
      const deadlineTimestamp = getDeadline(Number(deadlineDays));
      const amountInUSDC = parseUnits(salaryAmount, 6);

      const result = await signEmployeePay(
        employeeAddress as `0x${string}`,
        amountInUSDC,
        month,
        BigInt(nonce),
        deadlineTimestamp
      );

      if(!result.success){
        setStatusType("error");
        setStatus(result.error ?? "Failed to sign payment");
        return;
      }
      if(result.signature){
        setSignature(result.signature);
        setNonce((prev) => String(Number(prev) + 1));
      }
      setStatusType("success");
      setStatus("Payment signed successfully");
      setClaimDeadline(deadlineTimestamp.toString());
    } catch (error){
      setStatusType("error");
      setStatus(
        error instanceof Error ? error.message:String(error)
      );
    }
    
    
  };

  const handleClaimSalary = async () => {
    // claimSalary() will be wired here
          try {
    if (!claimEmployee) {
      setStatusType("error");
      setStatus("Enter your employee address.");
      return;
    }

    if (!claimAmount) {
      setStatusType("error");
      setStatus("Enter the salary amount.");
      return;
    }

    if (!claimMonth) {
      setStatusType("error");
      setStatus("Enter the month.");
      return;
    }

    if (!claimDeadline) {
      setStatusType("error");
      setStatus("Enter the deadline.");
      return;
    }

    if (!claimSignature) {
      setStatusType("error");
      setStatus("Enter the HR signature.");
      return;
    }

    setStatusType("info");
    setStatus("Waiting for transaction...");
    const amountInUSDC = parseUnits(salaryAmount, 6);

    const result = await claimSalary(
      claimEmployee as `0x${string}`,
      amountInUSDC,
      claimMonth,
      BigInt(claimNonce),
      BigInt(claimDeadline),
      claimSignature as `0x${string}`
    );

    if (!result.success) {
      setStatusType("error");
      setStatus(result.error ?? "Failed to claim salary");
      return;
    }

    if(result.hash){
      setTxHash(result.hash);
    }
    setStatusType("success");
    setStatus("Salary claimed successfully.");
  } catch (error) {
    setStatusType("error");
    setStatus(
      error instanceof Error ? error.message : String(error)
    );
  }
  };

  const enterOrganisation = async () => {
    // Vesting enterOrganisation function will be wired here
        try {
    setStatusType("info");
    setStatus("Entering organisation...");

    const result = await enterOrganisationService(
      executiveAddress as `0x${string}`,
      BigInt(vestingDuration),
      BigInt(cliffDuration),
      BigInt(totalAmount)
    );

    if (!result.success) {
      setStatusType("error");
      setStatus(result.error ?? "Failed to enter organisation");
      return;
    }

    if(result.hash){
      setTxHash(result.hash);
    }
    setStatusType("success");
    setStatus("Executive added successfully.");
  } catch (error) {
    setStatusType("error");
    setStatus(
      error instanceof Error ? error.message : String(error)
    );
  }
  };

  const claimVesting = async () => {
    // claim() will be wired here
       try {
        if(!wallet){
          setStatusType("error");
          setStatus("Connect the executive wallet first");
          return;
        }
    setStatusType("info");
    setStatus("Claiming vested tokens...");

    const result = await claimVestingService(
      wallet as `0x${string}`
    );

    if (!result.success) {
      setStatusType("error");
      setStatus(result.error || "");
      return;
    }

    setTxHash(result.hash || "");
    setStatusType("success");
    setStatus("Vesting claimed successfully.");
  } catch (error) {
    setStatusType("error");
    setStatus(
      error instanceof Error ? error.message : String(error)
    );
  }
  };

  const clawback = async () => {
    // clawback() will be wired here
       try {
    setStatusType("info");
    setStatus("Processing clawback...");

    const result = await clawbackService(
      executiveAddress as `0x${string}`
    );

    if (!result.success) {
      setStatusType("error");
      setStatus(result.error ?? "Clawback failed");
      return;
    }
     if(result.hash){
    setTxHash(result.hash);
     }
    setStatusType("success");
    setStatus("Token clawed back successfully.");
  } catch (error) {
    setStatusType("error");
    setStatus(
      error instanceof Error ? error.message : String(error)
    );
  }
  };

  return (
    <div className="app">

      {/* HEADER */}
      <header className="header">
        <div className="brand">
          <div className="logo">◈</div>

          <div>
            <h1>Web3 Payroll</h1>
            <p>Gasless. Trustless. Transparent.</p>
          </div>
        </div>

        <div className="network">
          <span className="status-dot"></span>
          Network: Sepolia
        </div>

        <button className="wallet-button" onClick={connectWallet}>
          {wallet
    ? `${wallet.slice(0, 6)}...${wallet.slice(-4)}`
    : "Connect Wallet"}
        </button>
      </header>

      <main className="container">

        {/* TITLE */}
        <div className="page-heading">
          <div>
            <h2>Payroll Dashboard</h2>
            <p>
              Decentralized payroll for Web3 teams powered by USDC.
            </p>
          </div>

          <div className="contract-info">
            <span>Payroll Contract</span>
            <strong>
              0xA49a53FdDA78541CcaC01e717aE95b074A1AF77a
            </strong>
          </div>
          </div>

        {/* ROLE NOTICE */}
        <div className="role-notice">
          <span>🛡</span>
          <strong>Connected as HR / Owner</strong>
          <span className="role-description">
            You have access to HR and owner features.
          </span>
        </div>

        {/* MAIN GRID */}
        <div className="dashboard-grid">

          {/* ================= HR ================= */}
          <section className="card hr-card">

            <div className="card-heading">
              <div className="icon purple">👥</div>

              <div>
                <h3>HR: Sign Payment</h3>
                <p>Create and sign a payment authorization for an employee.</p>
              </div>
            </div>

            <label>Employee Address</label>
            <input
              value={employeeAddress}
              onChange={(e) => setEmployeeAddress(e.target.value)}
              placeholder="0x..."
            />

            <label>Salary Amount (USDC)</label>
            <input
              value={salaryAmount}
              onChange={(e) => setSalaryAmount(e.target.value)}
              placeholder="1000000 = 1 USDC"
            />

            <label>Month</label>
            <input
              value={month}
              onChange={(e) => setMonth(e.target.value)}
              placeholder="August 2026"
            />

            <div className="two-columns">
              <div>
                <label>Nonce</label>
                <input
                  value={nonce}
                  onChange={(e) => setNonce(e.target.value)}
                  placeholder="0"
                />
              </div>

              <div>
                <label>Signature Valid For</label>
                  <input
                  type="number"
                min="1"
                  value={deadlineDays}
              onChange={(e) => setDeadlineDays(e.target.value)}
                placeholder="Enter number of days"
                    />
                 <span>days</span>
              </div>
              </div>
            

            <button
              className="primary-button purple-button"
              onClick={signPayment}
            >
              ✎ Sign Payment
            </button>

            {signature && (
              <div className="result-box">
                <div className="result-header">
                  <strong>Signature</strong>
                  <span className="success-badge">Signed</span>
                </div>

                <div className="hash">
                  {signature}
                </div>
              </div>
            )}

          </section>


          {/* ================= EMPLOYEE ================= */}
          <section className="card employee-card">

            <div className="card-heading">
              <div className="icon green">👤</div>

              <div>
                <h3>Employee: Claim Salary</h3>
                <p>Use the HR signature to claim your salary.</p>
              </div>
            </div>

            <label>Employee Address</label>
            <input
              value={claimEmployee}
              onChange={(e) => setClaimEmployee(e.target.value)}
              placeholder="0x... (your wallet)"
            />

            <label>Amount (USDC)</label>
            <input
              value={claimAmount}
              onChange={(e) => setClaimAmount(e.target.value)}
              placeholder="1000000 = 1 USDC"
            />

            <label>Month</label>
            <input
              value={claimMonth}
              onChange={(e) => setClaimMonth(e.target.value)}
              placeholder="August 2026"
            />

            <div className="two-columns">
              <div>
                <label>Nonce</label>
                <input
                  value={claimNonce}
                  onChange={(e) => setClaimNonce(e.target.value)}
                  placeholder="0"
                />
              </div>

              <div>
                <label>Deadline</label>
                <input
                value={claimDeadline}
                readOnly
                placeholder="Generated by HR"
                />
            
              </div>
            </div>

            <label>Signature from HR</label>
            <textarea
              value={claimSignature}
              onChange={(e) => setClaimSignature(e.target.value)}
              placeholder="Paste HR signature here..."
            />

            <button
              className="primary-button green-button"
              onClick={handleClaimSalary}
            >
              ↓ Claim Salary
            </button>

            <div className="transaction-box">
              <div className="result-header">
                <strong>Transaction Status</strong>

                {txHash && (
                  <span className="success-badge">Success</span>
                )}
              </div>

              {txHash ? (
                <>
                  <p>Transaction Hash</p>
                  <div className="hash">{txHash}</div>
                </>
              ) : (
                <span className="muted">
                  No transaction yet
                </span>
              )}
            </div>

          </section>


          {/* ================= VESTING ================= */}
          <section className="card vesting-card">

            <div className="card-heading">
              <div className="icon orange">🎁</div>

              <div>
                <h3>Vesting: Founder / Executive</h3>
                <p>Manage token vesting schedules.</p>
              </div>
            </div>

            <div className="owner-warning">
              🔒 Enter Organisation is restricted to HR / Owner only.
            </div>

            <div className="tabs">
              <button className="active-tab">
                Enter Organisation
              </button>

              <button>
                Claim / Clawback
              </button>
            </div>

            <label>Executive Address</label>
            <input
              value={executiveAddress}
              onChange={(e) => setExecutiveAddress(e.target.value)}
              placeholder="0x..."
            />

            <label>Total Amount (Tokens)</label>
            <input
              value={totalAmount}
              onChange={(e) => setTotalAmount(e.target.value)}
              placeholder="120000"
            />

            <label>Vesting Duration (Seconds)</label>
            <input
              value={vestingDuration}
              onChange={(e) => setVestingDuration(e.target.value)}
              placeholder="31536000 = 12 months"
            />

            <label>Cliff Duration (Seconds)</label>
            <input
              value={cliffDuration}
              onChange={(e) => setCliffDuration(e.target.value)}
              placeholder="7776000 = 3 months"
            />

            <button
              className="primary-button orange-button"
              onClick={enterOrganisation}
            >
              🏢 Enter Organisation
            </button>

            <div className="vesting-actions">

              <button
                className="secondary-button"
                onClick={claimVesting}
              >
                Claim Vesting
              </button>

              <button
                className="danger-button"
                onClick={clawback}
              >
                Clawback
              </button>

            </div>

            <div className="transaction-box">

              <div className="result-header">
                <strong>Last Transaction</strong>

                {txHash && (
                  <span className="success-badge">
                    Success
                  </span>
                )}
              </div>

              {txHash ? (
                <div className="hash">
                  {txHash}
                </div>
              ) : (
                <span className="muted">
                  No transaction yet
                </span>
              )}

            </div>

          </section>

        </div>


        {/* GLOBAL STATUS */}
{status && (
  <div className={`global-status ${statusType}`}>
    <span className="status-icon">
      {statusType === "error"
        ? "⚠️"
        : statusType === "success"
        ? "✓"
        : "ℹ️"}
    </span>

    <span>{status}</span>
  </div>
)}


        <footer>
          All transactions are on Sepolia Testnet. Make sure you have
          Sepolia ETH available for gas fees.
        </footer>

      </main>
    </div>
  );
}

export default App;