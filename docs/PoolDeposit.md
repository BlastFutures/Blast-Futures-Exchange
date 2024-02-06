# PoolDeposit Contract Documentation

The `PoolDeposit` contract is designed to manage deposits into the `Bfx` exchange contract, facilitating both individual and pooled contributions. It interfaces with an ERC20 token for payment handling and assigns unique identifiers to each deposit and pool for tracking and management purposes.

## Contract Overview

- **License:** BUSL-1.1
- **Solidity Version:** ^0.8.0

### Dependencies

- `IERC20`: Interface for the ERC20 token standard, used for payment token interactions.
- `IPoolDeposit`: Interface that defines the structure for deposit operations and events.

### State Variables

- `owner`: Immutable address of the contract owner, set at deployment.
- `rabbit`: Address of the `Bfx` exchange contract to which deposited tokens are transferred.
- `paymentToken`: Instance of `IERC20` representing the token accepted for deposits. For `Bfx` this is the Blast `USDB` contract.
- `nextDepositId`: Counter for generating unique deposit identifiers, starting from `1e16`.
- `nextPoolId`: Counter for generating unique pooled deposit identifiers, starting from `1`.

### Events

- `WithdrawTo`: Emitted when tokens are withdrawn from the contract to an external address.
- `Deposit`: Emitted for each individual deposit, whether standalone or part of a pool.
- `PooledDeposit`: Emitted to summarize a pooled deposit transaction, indicating the total amount and pool identifier.

### Constructor

The constructor initializes the contract by setting the `owner`, `rabbit` and `paymentToken` addresses.

### Modifiers

- `onlyOwner`: Restricts function execution to the `owner` of the contract.

### Functions

#### setPaymentToken

Allows the owner to update the `paymentToken` address.

- **Parameters:**
  - `_paymentToken`: The address of the new ERC20 payment token.

#### individualDeposit

Handles individual deposits by transferring the specified `amount` of tokens from the contributor to the `rabbit` address.

- **Parameters:**
  - `contributor`: Address making the deposit.
  - `amount`: Amount of tokens to deposit.

#### pooledDeposit

Processes pooled deposits from multiple contributors in a single transaction, aggregating their contributions and transferring the total amount to the `rabbit` address.

- **Parameters:**
  - `contributions`: An array of `Contribution` structs, each containing a contributor address and amount.

#### withdrawTokensTo

Allows the owner to return tokens mistakenly sent to the contract. In normal use the contract holds no tokens since the `individualDeposit` and `pooledDeposit` functions transfer tokens directly to the `Bfx` contraxct.

- **Parameters:**
  - `amount`: Amount of tokens to withdraw.
  - `to`: Address to which the tokens are to be sent.

#### setRabbit

Updates the `rabbit` address, this is the address of the `Bfx` exchange contract.

- **Parameters:**
  - `_rabbit`: The new address of the `Bfx` contract.

### Private Functions

#### makeTransfer

Performs a token transfer operation to the specified address.

- **Parameters:**
  - `to`: Recipient address.
  - `amount`: Amount of tokens to transfer.

#### makeTransferFrom

Facilitates a token transfer from a contributor to the `rabbit` address.

- **Parameters:**
  - `from`: Sender address.
  - `to`: Recipient address (the `rabbit`).
  - `amount`: Amount of tokens to transfer.

#### tokenCall

Executes a low-level call to the payment token contract.

- **Parameters:**
  - `data`: Encoded function selector and arguments for the token contract call.

### Security Considerations

- The contract includes an `onlyOwner` modifier to ensure that sensitive operations such as token withdrawal and configuration updates are restricted to the owner.
- All token transfers are performed securely through the ERC20 `transfer` and `transferFrom` methods, with checks for return values to prevent silent failures.
- Special attention is given to prevent overflows and underflows, especially in the `pooledDeposit` function.

