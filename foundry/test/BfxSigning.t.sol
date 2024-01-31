// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/test.sol";

import {Bfx} from "../src/Bfx.sol";
import {DummyToken} from "../test/DummyToken.sol";
import {SigUtils} from "./utils/SigUtils.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";

contract BfxSigningTest is Test, EIP712 {
    Bfx internal _bfx;
    SigUtils internal _sigUtils;
    DummyToken internal _token;

    uint256 internal _ownerPrivateKey;
    uint256 internal _settlerPrivateKey;
    uint256 internal _claimantPrivateKey;

    address internal _owner;
    address internal _settler;
    address internal _claimant;

    constructor() EIP712("BfxWithdrawal", "1") {
    }

    function setUp() public {
        _ownerPrivateKey = 0xA11CE;
        _settlerPrivateKey = 0x1111;
        _claimantPrivateKey = 0xB0B;

        _owner = vm.addr(_ownerPrivateKey);
        _settler = vm.addr(_settlerPrivateKey);
        _claimant = vm.addr(_claimantPrivateKey);

        _token = new DummyToken();
        _bfx = new Bfx(_owner, _settler, address(_token));
        _sigUtils = new SigUtils(address(_bfx), "BfxWithdrawal", "1");

        _token.mint(address(_bfx), 1e18);
    }

    function testWithdrawal(uint256 amount, uint256 id) public {
        amount = bound(amount, 1, 1e18);       
        SigUtils.Withdrawal memory withdrawal = SigUtils.Withdrawal({
            id: id,
            trader: _claimant,
            amount: amount
        });

        bytes32 digest = _sigUtils.getTypedDataHash(withdrawal);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_settlerPrivateKey, digest);

        _bfx.withdraw(
            withdrawal.id,
            withdrawal.trader,
            withdrawal.amount,
            v,
            r,
            s
        );

        assertEq(_token.balanceOf(withdrawal.trader), withdrawal.amount);
    }

    function testRevertRepeatClaim(uint256 amount, uint256 id) public {
        amount = bound(amount, 1, 1e18);       
        SigUtils.Withdrawal memory withdrawal = SigUtils.Withdrawal({
            id: id,
            trader: _claimant,
            amount: amount
        });

        bytes32 digest = _sigUtils.getTypedDataHash(withdrawal);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_settlerPrivateKey, digest);

        _bfx.withdraw(
            withdrawal.id,
            withdrawal.trader,
            withdrawal.amount,
            v,
            r,
            s
        );
        assertEq(_token.balanceOf(withdrawal.trader), withdrawal.amount);
        vm.expectRevert("ALREADY_PROCESSED");
        _bfx.withdraw(
            withdrawal.id,
            withdrawal.trader,
            withdrawal.amount,
            v,
            r,
            s
        );
    }

    function testRevertInvalidSigner(uint256 amount, uint256 id) public {
        amount = bound(amount, 1, 1e18);       
        SigUtils.Withdrawal memory withdrawal = SigUtils.Withdrawal({
            id: id,
            trader: _claimant,
            amount: amount
        });

        bytes32 digest = _sigUtils.getTypedDataHash(withdrawal);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_ownerPrivateKey, digest);

        vm.expectRevert("INVALID_SIGNATURE");
        _bfx.withdraw(
            withdrawal.id,
            withdrawal.trader,
            withdrawal.amount,
            v,
            r,
            s
        );
    }
    
    function testRevertInvalidId(uint256 amount, uint256 id) public {
        amount = bound(amount, 1, 1e18);       
        SigUtils.Withdrawal memory withdrawal = SigUtils.Withdrawal({
            id: id,
            trader: _claimant,
            amount: amount
        });

        bytes32 digest = _sigUtils.getTypedDataHash(withdrawal);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_settlerPrivateKey, digest);

        uint256 invalidId;
        if (id > 0) {
            invalidId = id - 1;
        } else {
            invalidId = id + 1;
        }
        vm.expectRevert("INVALID_SIGNATURE");
        _bfx.withdraw(
            invalidId,
            withdrawal.trader,
            withdrawal.amount,
            v,
            r,
            s
        );
    }

    function testRevertInvalidTrader(uint256 amount, uint256 id) public {
        amount = bound(amount, 1, 1e18);       
        SigUtils.Withdrawal memory withdrawal = SigUtils.Withdrawal({
            id: id,
            trader: _claimant,
            amount: amount
        });

        bytes32 digest = _sigUtils.getTypedDataHash(withdrawal);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_settlerPrivateKey, digest);

        vm.expectRevert("INVALID_SIGNATURE");
        _bfx.withdraw(
            withdrawal.id,
            _owner,
            withdrawal.amount,
            v,
            r,
            s
        );
    }

    function testRevertInvalidAmount(uint256 amount, uint256 id) public {
        amount = bound(amount, 1, 1e18);       
        SigUtils.Withdrawal memory withdrawal = SigUtils.Withdrawal({
            id: id,
            trader: _claimant,
            amount: amount
        });

        bytes32 digest = _sigUtils.getTypedDataHash(withdrawal);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_settlerPrivateKey, digest);

        vm.expectRevert("INVALID_SIGNATURE");
        _bfx.withdraw(
            withdrawal.id,
            withdrawal.trader,
            bound(((withdrawal.amount * 11)/10) + 1, 1, 1e18),
            v,
            r,
            s
        );
    }
}
