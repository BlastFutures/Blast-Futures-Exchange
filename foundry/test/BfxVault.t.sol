// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/test.sol";

import {BfxVault} from "../src/BfxVault.sol";
import {Bfx} from "../src/Bfx.sol";
import {DummyToken} from "../test/DummyToken.sol";

contract BfxVaultTest is Test {
    BfxVault internal _vault;
    Bfx internal _bfx;
    DummyToken internal _token;

    uint256 internal _bfxOwnerPrivateKey;
    uint256 internal _vaultOwnerPrivateKey;
    uint256 internal _settlerPrivateKey;
    uint256 internal _user1PrivateKey;
    uint256 internal _user2PrivateKey;

    address internal _bfxOwner;
    address internal _vaultOwner;
    address internal _settler;
    address internal _user1;
    address internal _user2;

    event Stake(uint256 indexed id, address indexed trader, uint256 amount);

    function setUp() public {
        _bfxOwnerPrivateKey = 0xA11CE;
        _vaultOwnerPrivateKey = 0x2222;
        _settlerPrivateKey = 0x1111;
        _user1PrivateKey = 0xB0B;
        _user2PrivateKey = 0xDED;

        _bfxOwner = vm.addr(_bfxOwnerPrivateKey);
        _vaultOwner = vm.addr(_vaultOwnerPrivateKey);
        _settler = vm.addr(_settlerPrivateKey);
        _user1 = vm.addr(_user1PrivateKey);
        _user2 = vm.addr(_user2PrivateKey);

        _token = new DummyToken();
        _bfx = new Bfx(_bfxOwner, _settler, address(_token));
        _vault = new BfxVault(
            _vaultOwner,
            address(_bfx),
            address(_token)
        );

        _token.mint(address(_user1), 1e18);
    }

    function testStake(uint256 amount) public {
        if (amount == 0 || amount > 1e18) {
            amount = 1234567;
        }
        address user = address(0x123abc);
        vm.prank(_user1);
        _token.approve(user, amount);
        vm.startPrank(user);
        _token.transferFrom(_user1, user, amount);
        _token.approve(address(_vault), amount);
        vm.expectEmit(true, false, false, true, address(_vault));
        emit Stake(1, user, amount);
        _vault.stake(amount);
        assertEq(_token.balanceOf(user), 0);
        assertEq(_token.balanceOf(address(_bfx)), amount);
    }

    function testStakeRevertsOnTransferFailed(uint256 amount) public {
        if (amount < 2 || amount > 1e18) {
            amount = 1234567;
        }
        address user = address(0x123abc);
        vm.prank(_user1);
        _token.approve(user, amount);

        vm.startPrank(user);

        // funds but insufficient approval
        _token.transferFrom(_user1, user, amount);
        _token.approve(address(_vault), amount - 1);
        vm.expectRevert("TRANSFER_FAILED");
        _vault.stake(amount);

        // approval but insufficient funds
        _token.transfer(_user1, 1);
        _token.approve(address(_vault), amount);
        vm.expectRevert("TRANSFER_FAILED");
        _vault.stake(amount);
    }

    function testStakeRevertsOnZeroAmount() public {
        address user = address(0x123abc);
        vm.startPrank(user);
        vm.expectRevert("WRONG_AMOUNT");
        _vault.stake(0);
    }

    function testMakeOwnerAdmin() public {
        vm.startPrank(_vaultOwner);
        _vault.removeAdmin(_vaultOwner);
        assertFalse(_vault.isAdmin(_vaultOwner));
        _vault.makeOwnerAdmin();
        assertTrue(_vault.isAdmin(_vaultOwner));
    }

    function testMakeDeposit(uint256 amount) public {
        address user = address(0x123abc);
        if (amount == 0 || amount > 1e18) {
            amount = 1234567;
        }
        vm.prank(_vaultOwner);
        _vault.addAdmin(_user2);
        vm.prank(_user2);
        _vault.addTreasurer(user);
        vm.prank(_user1);
        _token.approve(user, amount);
        vm.prank(user);
        _token.transferFrom(_user1, address(_vault), amount);
        vm.prank(user);
        _vault.makeDeposit(amount);
        assertEq(_token.balanceOf(address(_bfx)), amount);
    }

    function testRevertMakeDeposit(uint256 amount) public {
        address user = address(0x123abc);
        vm.prank(user);
        vm.expectRevert("NOT_A_TREASURER");
        _vault.makeDeposit(amount);
    }

    function testWithdrawTokens(uint256 amount) public {
        if (amount == 0 || amount > 1e18) {
            amount = 1234567;
        }
        address user = address(0x123abc);
        vm.prank(_vaultOwner);
        _vault.addAdmin(_user2);
        vm.prank(_user2);
        _vault.addTreasurer(user);
        vm.prank(_user1);
        _token.approve(user, amount);
        vm.prank(user);
        _token.transferFrom(_user1, address(_vault), amount);
        assertEq(_token.balanceOf(address(_vault)), amount);
        vm.prank(_vaultOwner);
        _vault.withdrawTokensTo(amount, user);
        assertEq(_token.balanceOf(user), amount);
        assertEq(_token.balanceOf(address(_vault)), 0);
    }

    function testRevertWithdrawTokens(address user, uint256 amount) public {
        if (user == address(0) || user == _vaultOwner) {
            user = address(0x123abc);
        }
        if (amount == 0 || amount > 1e18) {
            amount = 1234567;
        }
        vm.prank(_vaultOwner);
        _vault.addAdmin(_user2);
        vm.prank(_user2);
        _vault.addTreasurer(user);
        vm.prank(_user1);
        _token.approve(user, amount);
        vm.prank(user);
        _token.transferFrom(_user1, address(_vault), amount);
        assertEq(_token.balanceOf(address(_vault)), amount);
        vm.prank(_user1);
        vm.expectRevert("ONLY_OWNER");
        _vault.withdrawTokensTo(amount, user);
        assertEq(_token.balanceOf(address(_vault)), amount);
        vm.prank(user);
        vm.expectRevert("ONLY_OWNER");
        _vault.withdrawTokensTo(amount, user);
        vm.prank(_vaultOwner);
        vm.expectRevert("TRANSFER_FAILED");
        _vault.withdrawTokensTo(amount + 1, user);
    }

    function testRevertWrongAmountWithdrawTokens(address user) public {
        vm.expectRevert("WRONG_AMOUNT");
        vm.prank(_vaultOwner);
        _vault.withdrawTokensTo(0, user);
    }

    function testRevertZeroAddressWithdrawTokens() public {
        vm.expectRevert("ZERO_ADDRESS");
        vm.prank(_vaultOwner);
        _vault.withdrawTokensTo(123, address(0));
    }

    function testAddAdmin(address newUser) public {
        vm.startPrank(_vaultOwner);
        _vault.addAdmin(newUser);
        assert(_vault.isAdmin(newUser));
    }

    function testRemoveAdmin(address user) public {
        vm.startPrank(_vaultOwner);
        _vault.addAdmin(user);
        assert(_vault.isAdmin(user));
        _vault.removeAdmin(user);
        assert(!_vault.isAdmin(user));
    }

    function testAddTrader(address user) public {
        vm.startPrank(_vaultOwner);
        _vault.addTrader(user);
        assert(_vault.isTrader(user));
    }

    function testRemoveTrader(address user) public {
        vm.startPrank(_vaultOwner);
        _vault.addTrader(user);
        assert(_vault.isTrader(user));
        _vault.removeTrader(user);
        assert(!_vault.isTrader(user));
    }

    function testAddTreasurer(address user) public {
        vm.startPrank(_vaultOwner);
        _vault.addTreasurer(user);
        assert(_vault.isTreasurer(user));
    }

    function testRemoveTreasurer(address user) public {
        vm.startPrank(_vaultOwner);
        _vault.addTreasurer(user);
        assert(_vault.isTreasurer(user));
        _vault.removeTreasurer(user);
        assert(!_vault.isTreasurer(user));
    }

    function testAddRole(address user, uint256 role) public {
        vm.startPrank(_vaultOwner);
        _vault.addRole(user, role);
        assert(_vault.isValidSigner(user, role));
    }

    function testRemoveRole(address user, uint256 role) public {
        vm.startPrank(_vaultOwner);
        _vault.addRole(user, role);
        assert(_vault.isValidSigner(user, role));
        _vault.removeRole(user, role);
        assert(!_vault.isValidSigner(user, role));
    }

    function testAdminCanAddRole(address user, uint256 role) public {
        vm.startPrank(_vaultOwner);
        _vault.addAdmin(user);
        vm.stopPrank();
        vm.startPrank(user);
        _vault.addRole(_user2, role);
        assert(_vault.isValidSigner(_user2, role));
    }

    function testAdminCanRemoveRole(address user, uint256 role) public {
        vm.startPrank(_vaultOwner);
        _vault.addAdmin(user);
        vm.stopPrank();
        vm.startPrank(user);
        _vault.addRole(_user2, role);
        assert(_vault.isValidSigner(_user2, role));
        _vault.removeRole(_user2, role);
        assert(!_vault.isValidSigner(_user2, role));
    }

    function testRevertAddRole(address user, uint256 role) public {
        vm.expectRevert("NOT_AN_ADMIN");
        _vault.addRole(user, role);
    }

    function testRevertRemoveRole(address user, uint256 role) public {
        vm.expectRevert("NOT_AN_ADMIN");
        _vault.removeRole(user, role);
    }

    function testRevertAddAdmin(address user) public {
        vm.expectRevert("NOT_AN_ADMIN");
        _vault.addAdmin(user);
    }

    function testRevertRemoveAdmin(address user) public {
        vm.expectRevert("NOT_AN_ADMIN");
        _vault.removeAdmin(user);
    }

    function testRevertAddTrader(address user) public {
        vm.expectRevert("NOT_AN_ADMIN");
        _vault.addTrader(user);
    }

    function testRevertRemoveTrader(address user) public {
        vm.expectRevert("NOT_AN_ADMIN");
        _vault.removeTrader(user);
    }

    function testRevertAddTreasurer(address user) public {
        vm.expectRevert("NOT_AN_ADMIN");
        _vault.addTreasurer(user);
    }

    function testRevertRemoveTreasurer(address user) public {
        vm.expectRevert("NOT_AN_ADMIN");
        _vault.removeTreasurer(user);
    }

    function testSetToken(address newToken) public {
        vm.startPrank(_vaultOwner);
        _vault.setPaymentToken(newToken);
        assertEq(address(_vault.paymentToken()), newToken);
    }

    function testRevertSetToken(address newToken) public {
        vm.expectRevert("ONLY_OWNER");
        _vault.setPaymentToken(newToken);
    }

    function testSetBfx(address newBfx) public {
        vm.startPrank(_vaultOwner);
        _vault.setBfx(newBfx);
        assertEq(address(_vault.bfx()), newBfx);
    }

    function testRevertSetBfx(address newBfx) public {
        vm.expectRevert("ONLY_OWNER");
        _vault.setBfx(newBfx);
    }
}
