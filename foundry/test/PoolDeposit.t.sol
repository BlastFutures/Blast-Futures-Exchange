
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/test.sol";
// import "forge-std/console.sol";
import {Contribution} from "../src/IPoolDeposit.sol";
import {PoolDeposit} from "../src/PoolDeposit.sol";
import {Rabbit} from "../src/Rabbit.sol";
import {DummyToken} from "../test/DummyToken.sol";

contract PoolDepositTest is Test {
    PoolDeposit internal _pool;
    Rabbit internal _rabbit;
    DummyToken internal _token;
    Contribution[] internal contributions;

    uint256 internal _rabbitOwnerPrivateKey;
    uint256 internal _poolOwnerPrivateKey;
    uint256 internal _settlerPrivateKey;
    uint256 internal _user1PrivateKey;
    uint256 internal _user2PrivateKey;

    address internal _rabbitOwner;
    address internal _poolOwner;
    address internal _settler;
    address internal _user1;
    address internal _user2;

    event Deposit(uint256 indexed id, address indexed trader, uint256 amount, uint256 indexed poolId);
    event PooledDeposit(uint256 indexed id, uint256 amount);

    function setUp() public {
        _rabbitOwnerPrivateKey = 0xA11CE;
        _poolOwnerPrivateKey = 0x2222;
        _settlerPrivateKey = 0x1111;
        _user1PrivateKey = 0xB0B;
        _user2PrivateKey = 0xDED;

        _rabbitOwner = vm.addr(_rabbitOwnerPrivateKey);
        _poolOwner = vm.addr(_poolOwnerPrivateKey);
        _settler = vm.addr(_settlerPrivateKey);
        _user1 = vm.addr(_user1PrivateKey);
        _user2 = vm.addr(_user2PrivateKey);

        _token = new DummyToken();
        _rabbit = new Rabbit(_rabbitOwner, _settler, address(_token));
        _pool = new PoolDeposit(_poolOwner, address(_rabbit), address(_token));

        _token.mint(address(_user1), 1e18);
    }

    function testIndividualDeposit(uint256 amount) public {
        address user = address(0x123abc);
        if (amount == 0 || amount > 5e17) {
            amount = amount % 5e17 + 1;
        }
        vm.prank(_user1);
        _token.transfer(user, 2*amount);
        vm.startPrank(user);
        _token.approve(address(_pool), 2*amount);
        vm.expectEmit(true, true, true, true);
        emit Deposit(1e16, _user2, amount, 0);
        _pool.individualDeposit(_user2, amount);
        assertEq(_token.balanceOf(address(_rabbit)), amount);
        vm.expectEmit(true, true, true, true);
        emit Deposit(1e16+1, _user2, amount, 0);
        _pool.individualDeposit(_user2, amount);
        assertEq(_token.balanceOf(address(_rabbit)), 2*amount);
    }

    function testPooledDeposit(address userA, uint256 amountA, 
    address userB, uint256 amountB, address userC, uint256 amountC) public {
        if (userA == address(0)) {
            userA = address(0x123abc);
        }
        if (amountA == 0 || amountA > 1e17) {
            amountA = amountA % 1e17 + 1;
        }
        if (userB == address(0)) {
            userB = address(0x123abc);
        }
        if (amountB == 0 || amountB > 1e17) {
            amountB = amountB % 1e17 + 1;
        }
        if (userC == address(0)) {
            userC = address(0x123abc);
        }
        if (amountC == 0 || amountC > 1e17) {
            amountC = amountC % 1e17 + 1;
        }

        contributions.push(Contribution(userA, amountA));
        contributions.push(Contribution(userB, amountB));
        contributions.push(Contribution(userC, amountC));
        uint256 totalAmount = amountA + amountB + amountC;

        vm.startPrank(_user1);
        _token.approve(address(_pool), totalAmount);
        vm.expectEmit(true, true, true, true);
        emit Deposit(1e16, userA, amountA, 1);
        vm.expectEmit(true, true, true, true);
        emit Deposit(1e16+1, userB, amountB, 1);
        vm.expectEmit(true, true, true, true);
        emit Deposit(1e16+2, userC, amountC, 1);
        vm.expectEmit(true, true, true, true);
        emit PooledDeposit(1, totalAmount);
        _pool.pooledDeposit(contributions);
        assertEq(_token.balanceOf(address(_rabbit)), totalAmount);
        _token.approve(address(_pool), totalAmount);
        vm.expectEmit(true, true, true, true);
        emit Deposit(1e16+3, userA, amountA, 2);
        vm.expectEmit(true, true, true, true);
        emit Deposit(1e16+4, userB, amountB, 2);
        vm.expectEmit(true, true, true, true);
        emit Deposit(1e16+5, userC, amountC, 2);
        vm.expectEmit(true, true, true, true);
        emit PooledDeposit(2, totalAmount);
        _pool.pooledDeposit(contributions);
        assertEq(_token.balanceOf(address(_rabbit)), 2*totalAmount);
    }

    function testRevertZeroAmountIndividualDeposit() public {
        vm.expectRevert("WRONG_AMOUNT");
        _pool.individualDeposit(address(0x123abc), 0);
    }
    
    function testRevertZeroAmountPoolDeposit(address userA, address userB, address userC) public {
        contributions.push(Contribution(userA, 0));
        contributions.push(Contribution(userB, 0));
        contributions.push(Contribution(userC, 0));
        vm.expectRevert("WRONG_AMOUNT");
        _pool.pooledDeposit(contributions);
    }
    
    function testRevertNoFundsIndividualDeposit(address user) public {
        vm.expectRevert("TRANSFER_FAILED");
        _pool.individualDeposit(user, 10);
    }
    
    function testRevertNoFundsPoolDeposit(address userA, address userB, address userC) public {
        contributions.push(Contribution(userA, 10));
        contributions.push(Contribution(userB, 10));
        contributions.push(Contribution(userC, 10));
        vm.expectRevert("TRANSFER_FAILED");
        _pool.pooledDeposit(contributions);
    }
    
    function testSetToken(address newToken) public {
        vm.startPrank(_poolOwner);
        _pool.setPaymentToken(newToken);
        assertEq(address(_pool.paymentToken()), newToken);
    }

    function testRevertSetToken(address newToken) public {
        vm.expectRevert("ONLY_OWNER");
        _pool.setPaymentToken(newToken);
    }

    function testSetRabbit() public {
        address newRabbit = address(0x123abc);
        vm.startPrank(_poolOwner);
        _pool.setRabbit(newRabbit);
        assertEq(address(_pool.rabbit()), newRabbit);
    }

    function testRevertSetRabbit() public {
        vm.expectRevert("ONLY_OWNER");
        _pool.setRabbit(address(0x123abc));
    }

    function testWithdrawTokensto(uint256 amount) public {
        if (amount == 0 || amount > 1e17) {
            amount = amount % 1e17 + 1;
        }
        address receiver = address(0x123abc);
        vm.prank(_user1);
        _token.transfer(address(_pool), amount);
        assertEq(_token.balanceOf(address(_pool)), amount);
        assertEq(_token.balanceOf(receiver), 0);
        vm.prank(_poolOwner);
        _pool.withdrawTokensTo(amount, receiver);
        assertEq(_token.balanceOf(address(_pool)), 0);
        assertEq(_token.balanceOf(receiver), amount);
    }

    function testRevertWithdrawTokensTo(uint256 amount) public {
        if (amount == 0 || amount > 1e17) {
            amount = amount % 1e17 + 1;
        }
        address receiver = address(0x123abc);
        vm.startPrank(_user1);
        _token.transfer(address(_pool), amount);
        assertEq(_token.balanceOf(address(_pool)), amount);
        assertEq(_token.balanceOf(receiver), 0);
        vm.expectRevert("ONLY_OWNER");
        _pool.withdrawTokensTo(amount, receiver);
    }
}