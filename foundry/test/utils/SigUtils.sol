// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SigUtils {
    string private constant EIP712_PREFIX = "\x19\x01";
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant WITHDRAWAL_TYPEHASH = keccak256("withdrawal(uint256 id,address trader,uint256 amount)");
    bytes32 private constant DOMAIN_NAME_HASH = keccak256("RabbitXWithdrawal");
    bytes32 private constant VERSION_HASH = keccak256("1");
    bytes32 private immutable DOMAIN_SEPARATOR;

    constructor(address rabbitAddress) {
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            DOMAIN_NAME_HASH,
            VERSION_HASH,
            block.chainid,
            rabbitAddress
        ));
    }

    struct Withdrawal {
        uint256 id;
        address trader;
        uint256 amount;
    }

    function getStructHash(Withdrawal memory _withdrawal)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    WITHDRAWAL_TYPEHASH,
                    _withdrawal.id,
                    _withdrawal.trader,
                    _withdrawal.amount
                )
            );
    }

    function getTypedDataHash(Withdrawal memory _withdrawal)
        public
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    getStructHash(_withdrawal)
                )
            );
    }
}
