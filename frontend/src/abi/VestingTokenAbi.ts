 export const VestingTokenAbi = [
  {
    "type": "constructor",
    "inputs": [
      {
        "name": "_tokenAddress",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "admin",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "claim",
    "inputs": [
      {
        "name": "_executiveId",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "clawback",
    "inputs": [
      {
        "name": "_executiveId",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "enterOrganisation",
    "inputs": [
      {
        "name": "_executiveId",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "_vestingDuration",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "_cliffTime",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "_totalAmount",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "getVestingSchedule",
    "inputs": [
      {
        "name": "_executive",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple",
        "internalType": "struct VestingToken.ExecutiveVestingSchedule",
        "components": [
          {
            "name": "executiveId",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "startTime",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "endTime",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "cliffTime",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "totalAmount",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "amountClaimed",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "lastClaimedTime",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "isActive",
            "type": "bool",
            "internalType": "bool"
          }
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "owner",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "renounceOwnership",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "tokens",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "contract IERC20"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "transferOwnership",
    "inputs": [
      {
        "name": "newOwner",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "vestingSchedules",
    "inputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [
      {
        "name": "executiveId",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "startTime",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "endTime",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "cliffTime",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "totalAmount",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "amountClaimed",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "lastClaimedTime",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "isActive",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "event",
    "name": "ClawbackExecuted",
    "inputs": [
      {
        "name": "user",
        "type": "address",
        "indexed": false,
        "internalType": "address"
      },
      {
        "name": "amountClaimed",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "contractAmount",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "EnteredOrganisation",
    "inputs": [
      {
        "name": "user",
        "type": "address",
        "indexed": false,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "OwnershipTransferred",
    "inputs": [
      {
        "name": "previousOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "newOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "TokenClaimed",
    "inputs": [
      {
        "name": "user",
        "type": "address",
        "indexed": false,
        "internalType": "address"
      },
      {
        "name": "amount",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "error",
    "name": "OwnableInvalidOwner",
    "inputs": [
      {
        "name": "owner",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "OwnableUnauthorizedAccount",
    "inputs": [
      {
        "name": "account",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "SafeERC20FailedOperation",
    "inputs": [
      {
        "name": "token",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "VestingToken__AlreadyEnteredTheOrganisation",
    "inputs": []
  },
  {
    "type": "error",
    "name": "VestingToken__CanClaimEveryThreeMonths",
    "inputs": []
  },
  {
    "type": "error",
    "name": "VestingToken__CantClaimBeforeCliffTime",
    "inputs": []
  },
  {
    "type": "error",
    "name": "VestingToken__InvalidDuration",
    "inputs": []
  },
  {
    "type": "error",
    "name": "VestingToken__InvalidId",
    "inputs": []
  },
  {
    "type": "error",
    "name": "VestingToken__NothingToClaim",
    "inputs": []
  },
  {
    "type": "error",
    "name": "VestingToken__OnlyOwnerHaveAccess",
    "inputs": []
  },
  {
    "type": "error",
    "name": "VestingToken__YouArentActiveParticipant",
    "inputs": []
  },
  {
    "type": "error",
    "name": "VestingToken__YouArentPartOfTheOrganisation",
    "inputs": []
  },
  {
    "type": "error",
    "name": "VestingToken__ZeroBalance",
    "inputs": []
  }
] as const;
