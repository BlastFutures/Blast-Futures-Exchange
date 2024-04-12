pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface IVault {
    event Stake(
        uint256 indexed id,
        address indexed trader,
        uint256 amount
    );

    function isValidSigner(
        address signer,
        uint256 role
    ) external view returns (bool);
}
