pragma solidity ^0.8.0;

// SPDX-License-Identifier: BUSL-1.1

interface IVault {
    event Stake(
        uint256 indexed id,
        address indexed trader,
        uint256 amount
    );

    event Unstake(
        uint256 indexed id,
        address indexed trader,
        uint256 shares,
        uint256 value
    );

    function isValidSigner(
        address signer,
        uint256 role
    ) external view returns (bool);
}
