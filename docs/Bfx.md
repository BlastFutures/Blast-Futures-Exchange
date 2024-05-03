# Bfx Contract Documentation

The `Bfx` contract facilitates secure deposit and withdrawal of Blast `USDB` ERC20 tokens for the BFX exchange. It extends `EIP712Verifier` for EIP-712 compliant signature verification on withdrawal operations.

## Contract Overview

- **SPDX-License-Identifier:** MIT
- **Solidity Version:** ^0.8.0

### Dependencies

- `EIP712Verifier`: Provides standard EIP-712 functionality, extended by `Bfx` for signature verification on withdrawals.
- `IERC20`: Interface for Blast `USDB` ERC20 token interaction.
- `ECDSA` & `EIP712`: Utilized for cryptographic operations.

### State Variables

- `owner`: Immutable address of the contract owner.
- `paymentToken`: Address of the ERC20 token used for payments.
- `processedWithdrawals`: Mapping to track processed withdrawals by their IDs.
- `nextDepositId`: Counter for generating unique deposit IDs, starting from 37000.
- `reentryLockStatus`: Lock status to prevent re-entrancy, initialized to `UNLOCKED`.

### Events

- `Deposit`: Emitted after a successful deposit.
- `WithdrawTo`: Emitted after a successful owner withdrawal to a specific address.
- `WithdrawalReceipt`: Emitted after a successful trader withdrawal with signature verification.

### Modifiers

- `onlyOwner`: Restricts function access to the contract owner.
- `nonReentrant`: Prevents re-entrancy by checking and toggling the `reentryLockStatus`.

### Constructor

Initializes the contract by setting the owner, signer for EIP712 withdrawals, and the payment token address.

### Functions

#### withdraw

Allows a withdrawal operation with EIP-712 signature verification.

- Parameters: Withdrawal ID, trader address, amount, and signature components (v, r, s).
- Emits: `WithdrawalReceipt` on successful withdrawal.

#### setPaymentToken

Updates the payment token address. The payment token is the Blast `USDB` ERC20 token. Restricted to the contract owner.

- Parameter: New payment token address.

#### deposit

Enables the deposit of tokens into the exchange.

- Parameter: Amount of tokens to deposit.
- Emits: `Deposit` event.

#### withdrawTokensTo

Withdraws tokens to a specified address. Restricted to the contract owner.

- Parameters: Amount and recipient address.
- Emits: `WithdrawTo` event.

#### changeSigner

Updates the signer address for EIP-712 verifications. Restricted to the contract owner.

- Parameter: New signer address.

#### makeTransfer & makeTransferFrom

Private functions to handle token transfers and transfers from a specific address, respectively.

#### tokenCall

A private utility function to invoke token contract functions safely.

### Security Considerations

- Non-reentrant: The `nonReentrant` modifier is used to prevent re-entrancy attacks.
- Signature Verification: Withdrawals require a valid EIP-712 signature, ensuring that only authorized parties can initiate them.
- Owner-only Operations: Sensitive functions are protected with the `onlyOwner` modifier.

## Conclusion

The `Bfx` contract is designed for secure, non-reentrant token handling with an emphasis on signature-verified withdrawals. It employs EIP-712 for secure withdrawals and provides mechanisms for deposit tracking and token management.

