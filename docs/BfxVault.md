# BfxVault Contract Documentation

The `BfxVault` contract serves as a management layer for user permissions and staking operations for the BFX Vault.

## Contract Overview

- **SPDX-License-Identifier:** MIT
- **Solidity Version:** ^0.8.0

### Dependencies

- `IVault`: Interface required to be implemented by  any vault on the BFX exchange.
- `IERC20`: Interface for interacting with ERC20 tokens.
- `IBfx`: Interface implemented by the `Bfx` contract, allowing for deposit functionality.

### State Variables

- `owner`: Immutable address of the contract owner.
- `bfx`: Address of the `Bfx` contract for deposit operations.
- `paymentToken`: IERC20 token used for payment and staking.
- `_nextStakeId`: Internal counter for stake IDs, starting from 1.
- `ADMIN_ROLE`, `TRADER_ROLE`, `TREASURER_ROLE`: Constants defining specific roles within the contract.
- `signers`: Mapping of addresses to their roles, determining their permissions within the vault.

### Events

- `AddRole`: Emitted when a new role is assigned to an address.
- `RemoveRole`: Emitted when a role is removed from an address.
- `WithdrawTo`: Emitted when tokens are withdrawn to a specific address.

### Constructor

Initializes the contract by setting the owner, `bfx` contract address, and payment token address. Also, it assigns the `ADMIN_ROLE` and `TREASURER_ROLE` to the owner.

### Modifiers

- `onlyOwner`: Ensures that only the owner can call the function.

### Functions

#### Stake

Allows users to stake a specified amount of tokens by transferring them to the `Bfx` contract.

- Parameters: `amount` of tokens to stake.
- Emits: A `Stake` event with the stake ID, sender, and amount.

#### Role Management

Includes functions to check if an address has a specific role (`isAdmin`, `isTrader`, `isTreasurer`), to add or remove roles (`addAdmin`, `removeAdmin`, `addTrader`, `removeTrader`, `addTreasurer`, `removeTreasurer`), and to verify if an address is a valid signer for a role (`isValidSigner`).

- These functions are designed to manage access control within the vault, segregating duties among different actors. The exchange code retrieves an actor's address from their ECDSA signature and then determines whether the actor is authorized by the vault contract to perform a requested action by calling `isValidSigner`.

#### Deposits and Withdrawals

- `makeDeposit`: Allows users with the `TREASURER_ROLE` to deposit funds into the `Bfx` contract.
- `withdrawTokensTo`: Enables the owner to withdraw tokens to a specified address. This function is intended for recovery of funds sent by mistake to this contract. In normal use the contract holds no funds because `makeDeposit` sends them directly to the `Bfx` contract.

#### Payment Token and Bfx Contract Management

- `setPaymentToken`: Updates the payment token used by the vault.
- `setBfx`: Sets the address of the `Bfx` exchange contract, allowing for future updates or migrations.

### Internal Functions

- `_allocateStakeId`: Generates a unique stake ID for each new stake.
- `_doDeposit`: Handles the internal logic for depositing funds into the `Bfx` contract.
- `_makeTransfer` and `_makeTransferFrom`: Facilitate token transfers and approvals.

### Security Considerations

- The contract procvides role-based access control to restrict sensitive operations to authorized users.
- It utilizes an immutable owner pattern for critical administrative capabilities.
- Care should be taken to ensure that the `paymentToken` and `bfx` contract addresses are correctly set to prevent misrouting of funds.
