# IVault Interface Documentation

The `IVault` interface includes everything that is strictly required by the Bfx exchange when interacting with a vault contract.

## Interface Overview

- **Solidity Version:** ^0.8.0
- **License:** MIT

## Events

### Stake

Emitted when a stake is made into the vault. It logs the stake's unique identifier, the trader's address making the stake, and the amount staked.

- **Parameters:**
  - `id`: A unique identifier for the stake.
  - `trader`: The address of the user who made the stake.
  - `amount`: The amount of tokens or currency staked.

## Functions

### isValidSigner

Determines whether a given address is authorized to perform actions within the vault, based on the assigned role. This function is essential for role-based access control within the vault system.

- **Parameters:**
  - `signer`: The address to be verified.
  - `role`: An integer identifier for a specific role.

- **Returns:**
  - `bool`: A boolean value indicating whether the signer address is allowed to assume the specified role.

## Usage

The `IVault` interface should be implemented by smart contracts that manage trading vaults integrated with the Bfx exchange.
