// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";

contract EIP712Verifier is EIP712 {
    address public external_signer;

    constructor(string memory domainName, string memory version, address signer) EIP712(domainName, version) {
        external_signer = signer;
        require(signer != address(0), "ZERO_SIGNER");
    }

    /* 
        Standard EIP712 verifier but with different v combinations
    */
    function verify(bytes32 digest, uint8 v, bytes32 r, bytes32 s) internal view returns (bool) {

        address recovered_signer = ecrecover(digest, v, r, s);
        if (recovered_signer != external_signer) {
            uint8 other_v = 27;
            if (other_v == v) {
                other_v = 28;
            }

            recovered_signer = ecrecover(digest, other_v, r, s);
        }

        if (recovered_signer != external_signer) {
            return false;
        }

        return true;
    }
}
