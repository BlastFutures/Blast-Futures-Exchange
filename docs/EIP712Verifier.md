# EIP712Verifier Contract Documentation

The `EIP712Verifier` contract serves as a utility for verifying EIP-712 typed data signatures against a predetermined external signer. It extends OpenZeppelin's EIP712 implementation to provide signature verification functionalities with support for different `v` values in the signature.

## Contract Overview

- **License:** MIT
- **Solidity Version:** ^0.8.0

### Dependencies

- `ECDSA`: OpenZeppelin's library for Elliptic Curve Digital Signature Algorithm operations.
- `EIP712`: OpenZeppelin's base contract for EIP-712 typed data hashing and signing.

### State Variables

- `external_signer`: Public address variable that stores the address of the external signer whose signatures the contract is designed to verify.

### Constructor

Initializes the contract by setting the domain name and version for EIP-712 typed data and the external signer's address. It ensures the signer's address is not the zero address.

- **Parameters:**
  - `domainName`: The EIP-712 domain name.
  - `version`: The EIP-712 version.
  - `signer`: The address of the external signer.

### Functions

#### verify

A function designed to verify the signature of EIP-712 typed data. It accepts a digest (hashed data according to EIP-712 standards) and the signature components (`v`, `r`, `s`). The function attempts to recover the signer's address from the signature and compares it to the `external_signer` address stored in the contract.

- **Parameters:**
  - `digest`: The keccak256 hash of the EIP-712 encoded data.
  - `v`: The recovery byte of the signature.
  - `r`: The first 32 bytes of the signature.
  - `s`: The second 32 bytes of the signature.

- **Returns:** A boolean indicating whether the signature is valid and matches the `external_signer`.

- **Implementation Details:** The function tries to recover the signer address using the provided `v`, `r`, and `s` values. If the first attempt does not match the `external_signer`, it tries again with an alternative `v` value (flipping between 27 and 28), accommodating the possibility of different `v` values due to signature malleability.

## Security Considerations

- The contract assumes that the `external_signer` address is securely managed and accurately represents the intended signer. Users should ensure that this address is correctly set during contract initialization.
- Signature verification is sensitive to the correctness of the input parameters (`digest`, `v`, `r`, `s`). Users must ensure the integrity of these parameters to avoid false validation results.
- The constructor prevents setting the `external_signer` to the zero address, mitigating the risk of uninitialized or improperly set signer addresses.

## Conclusion

`EIP712Verifier` provides a specialized solution for verifying EIP-712 typed data signatures, focusing on flexibility with respect to the `v` signature parameter. It leverages OpenZeppelin's secure and tested implementations of EIP-712 and ECDSA functionalities, ensuring reliable signature verification within Ethereum smart contracts.

