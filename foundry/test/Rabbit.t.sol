// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/test.sol";

import {Rabbit} from "../src/Rabbit.sol";
import {DummyToken} from "../test/DummyToken.sol";
import {SigUtils} from "./utils/SigUtils.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";

contract RabbitTest is Test {
    Rabbit internal _rabbit;
    DummyToken internal _token;
    DummyToken internal _otherToken;

    uint256 internal _ownerPrivateKey;
    uint256 internal _settlerPrivateKey;
    uint256 internal _claimantPrivateKey;
    uint256 internal _userPrivateKey;

    address internal _owner;
    address internal _settler;
    address internal _claimant;
    address internal _user;

    event Deposit(uint256 indexed id, address indexed trader, uint256 amount);

    function setUp() public {
        _ownerPrivateKey = 0xA11CE;
        _settlerPrivateKey = 0x1111;
        _claimantPrivateKey = 0xB0B;
        _userPrivateKey = 0x123def;

        _owner = vm.addr(_ownerPrivateKey);
        _settler = vm.addr(_settlerPrivateKey);
        _claimant = vm.addr(_claimantPrivateKey);
        _user = vm.addr(_userPrivateKey);

        _token = new DummyToken();
        _otherToken = new DummyToken();
        _rabbit = new Rabbit(_owner, _settler, address(_token));

        _token.mint(_user, 1e18);
    }

    function testDeposit(uint256 amount) public {
        amount = bound(amount, 1, 1e18);       
        vm.startPrank(_user);
        vm.expectRevert("TRANSFER_FAILED");
        _rabbit.deposit(amount);
        _token.approve(address(_rabbit), amount);
        vm.expectEmit(true, true, true, true);
        emit Deposit(37000, _user, amount);
        _rabbit.deposit(amount);
        assertEq(_token.balanceOf(address(_rabbit)), amount);
    }

    function testChangeSigner() public {
        address newSigner = address(0xaaaaa);
        vm.expectRevert("ONLY_OWNER");
        _rabbit.changeSigner(newSigner);
        assertEq(_rabbit.external_signer(), _settler);
        vm.startPrank(_owner);
        vm.expectRevert("ZERO_SIGNER");
        _rabbit.changeSigner(address(0x0));
        _rabbit.changeSigner(newSigner);
        assertEq(_rabbit.external_signer(), newSigner);
    }

    function testChangeToken() public {
        vm.expectRevert("ONLY_OWNER");
        _rabbit.setPaymentToken(address(_otherToken));
        assertEq(address(_rabbit.paymentToken()), address(_token));
        vm.startPrank(_owner);
        _rabbit.setPaymentToken(address(_otherToken));
        assertEq(address(_rabbit.paymentToken()), address(_otherToken));
    }

    function testWithdrawTokensto(uint256 amount) public {
        if (amount == 0 || amount > 1e17) {
            amount = amount % 1e17 + 1;
        }
        address receiver = address(0x123abc456);
        vm.prank(_user);
        _token.transfer(address(_rabbit), amount);
        assertEq(_token.balanceOf(address(_rabbit)), amount);
        assertEq(_token.balanceOf(receiver), 0);
        vm.prank(_owner);
        _rabbit.withdrawTokensTo(amount, receiver);
        assertEq(_token.balanceOf(address(_rabbit)), 0);
        assertEq(_token.balanceOf(receiver), amount);
    }

    function testRevertWithdrawTokensto(uint256 amount) public {
        if (amount == 0 || amount > 1e17) {
            amount = amount % 1e17 + 1;
        }
        address receiver = address(0x123abc456);
        vm.expectRevert("ONLY_OWNER");
        _rabbit.withdrawTokensTo(amount, receiver);
        vm.startPrank(_owner);
        vm.expectRevert("WRONG_AMOUNT");
        _rabbit.withdrawTokensTo(0, receiver);
        vm.expectRevert("ZERO_ADDRESS");
        _rabbit.withdrawTokensTo(amount, address(0x0));
        vm.expectRevert("TRANSFER_FAILED");
        _rabbit.withdrawTokensTo(amount, receiver);
    }

    function testRevertWithdraw() public {
        vm.expectRevert("WRONG_AMOUNT");
        _rabbit.withdraw(0, address(0x0), 0, 0, 0, 0);
    }
}