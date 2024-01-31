pragma solidity ^0.8.0;
// SPDX-License-Identifier: BUSL-1.1

import "./IVault.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IBfx {
    function deposit(uint256 amount) external;
}

contract BfxVault is IVault {
    address public immutable owner;

    IBfx public bfx;
    IERC20 public paymentToken;

    uint256 _nextStakeId = 1;

    uint256 public constant ADMIN_ROLE = 0;
    uint256 public constant TRADER_ROLE = 1;
    uint256 public constant TREASURER_ROLE = 2;

    mapping(address => mapping(uint256 => bool)) public signers;

    event AddRole(address indexed user, uint256 indexed role);
    event RemoveRole(address indexed user, uint256 indexed role);
    event WithdrawTo(address indexed to, uint256 amount);

    constructor(address _owner, address _bfx, address _paymentToken) {
        owner = _owner;
        signers[_owner][ADMIN_ROLE] = true;
        signers[_owner][TREASURER_ROLE] = true;
        bfx = IBfx(_bfx);
        paymentToken = IERC20(_paymentToken);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "WRONG_AMOUNT");
        uint256 stakeId = _allocateStakeId();
        emit Stake(stakeId, msg.sender, amount);
        require(
            _makeTransferFrom(msg.sender, address(bfx), amount),
            "TRANSFER_FAILED"
        );
    }

    function _allocateStakeId() private returns (uint256) {
        uint256 stakeId = _nextStakeId;
        _nextStakeId++;
        return stakeId;
    }

    /**
     * @notice does the user have the ADMIN_ROLE - which gives 
     * the ability to add and remove roles for other users
     * 
     * @param user the address to check
     * @return true if the user has the ADMIN_ROLE 
     */
    function isAdmin(address user) public view returns (bool) {
        return signers[user][ADMIN_ROLE];
    }

    /**
     * @notice give the user the ADMIN_ROLE - which gives 
     * the ability to add and remove roles for other users
     *
     * @dev the caller must themselves have the ADMIN_ROLE
     * 
     * @param user the address to give the ADMIN_ROLE to
     */
    function addAdmin(address user) external {
        addRole(user, ADMIN_ROLE);
    }

    /**
     * @notice take away the ADMIN_ROLE - which removes 
     * the ability to add and remove roles for other users
     *
     * @dev the caller must themselves have the ADMIN_ROLE
     * 
     * @param user the address from which to remove the ADMIN_ROLE
     */
    function removeAdmin(address user) external {
        removeRole(user, ADMIN_ROLE);
    }

    /**
     * @notice does the user have the TRADER_ROLE - which gives 
     * the ability to trade on the bfx exchange with the vault's funds
     * 
     * @param user the address to check
     * @return true if the user has the TRADER_ROLE 
     */
    function isTrader(address user) public view returns (bool) {
        return signers[user][TRADER_ROLE];
    }

    /**
     * @notice give the user the TRADER_ROLE - which gives
     * the ability to trade on the bfx exchange with the vault's funds
     *   
     * @dev the caller must have the ADMIN_ROLE
     *
     * @param user the address to give the TRADER_ROLE to
     */
    function addTrader(address user) external {
        addRole(user, TRADER_ROLE);
    }

    /**
     * @notice take away the TRADER_ROLE - which removes
     * the ability to trade on the bfx exchange with the vault's funds
     *
     * @dev the caller must have the ADMIN_ROLE
     *
     * @param user the address from which to remove the TRADER_ROLE
     */
    function removeTrader(address user) external {
        removeRole(user, TRADER_ROLE);
    }

    /**
     * @notice does the user have the TREASURER_ROLE - which gives 
     * the ability to deposit the vault's funds into the bfx exchange
     * 
     * @param user the address to check
     * @return true if the user has the TREASURER_ROLE 
     */
    function isTreasurer(address user) public view returns (bool) {
        return signers[user][TREASURER_ROLE];
    }

    /**
     * @notice give the user the TREASURER_ROLE - which gives
     * the ability to deposit the vault's funds into the bfx exchange
     *
     * @dev the caller must have the ADMIN_ROLE
     *
     * @param user the address to give the TREASURER_ROLE to
     */
    function addTreasurer(address user) external {
        addRole(user, TREASURER_ROLE);
    }

    /**
     * @notice take away the TREASURER_ROLE - which removes
     * the ability to deposit the vault's funds into the bfx exchange
     *
     * @dev the caller must have the ADMIN_ROLE
     *
     * @param user the address from which to remove the TREASURER_ROLE
     */
    function removeTreasurer(address user) external {
        removeRole(user, TREASURER_ROLE);
    }

    /**
     * @notice does the user have the specified role
     *
     * @dev the roles recognised by the vault are 
     * ADMIN_ROLE (0), TRADER_ROLE (1) and TREASURER_ROLE (2), other roles can
     * be given and removed, but they have no special meaning for the vault
     *
     * @param signer the address to check
     * @param role the role to check
     * @return true if the user has the specified role 
     */
    function isValidSigner(address signer, uint256 role) external view returns (bool) {
        return signers[signer][role];
    }

    /**
     * @notice give the user the specified role
     *
     * @dev the caller must have the ADMIN_ROLE
     * @dev the roles recognised by the vault are 
     * ADMIN_ROLE (0), TRADER_ROLE (1) and TREASURER_ROLE (2), other roles can
     * be given and removed, but they have no special meaning for the vault
     *
     * @param signer the address to which to give the role
     * @param role the role to give
     */
    function addRole(address signer, uint256 role) public {
        require(signers[msg.sender][ADMIN_ROLE], "NOT_AN_ADMIN");
        signers[signer][role] = true;
        emit AddRole(signer, role);
    }

    /**
     * @notice take away the specified role from the user
     *
     * @dev the caller must have the ADMIN_ROLE
     * @dev the roles recognised by the vault are 
     * ADMIN_ROLE (0), TRADER_ROLE (1) and TREASURER_ROLE (2), other roles can
     * be given and removed, but they have no special meaning for the vault
     *
     * @param signer the address from which to remove the role
     * @param role the role to remove
     */    
    function removeRole(address signer, uint256 role) public {
        require(signers[msg.sender][ADMIN_ROLE], "NOT_AN_ADMIN");
        signers[signer][role] = false;
        emit RemoveRole(signer, role);
    }

    function makeOwnerAdmin() external onlyOwner {
        signers[owner][ADMIN_ROLE] = true;
    }

    /**
     * @notice transfers funds from the vault to the bfx exchange contract
     *
     * @dev the vault must have at least the specified amount before calling this function
     * @dev the caller must have the TREASURER_ROLE
     *
     * @param amount the amount of tokens to transfer
     */
    function makeDeposit(uint256 amount) external {
        require(signers[msg.sender][TREASURER_ROLE], "NOT_A_TREASURER");
        _doDeposit(amount);
    }

    function _doDeposit(uint256 amount) internal {
        paymentToken.approve(address(bfx), amount);
        bfx.deposit(amount);
    }

    /**
     * @notice sets the address of the IERC20 payment token used by the bfx exchange
     *
     * @dev WARNING must match the payment token address on the bfx exchange 
     * contract, normally set during deployment
     * @dev only the vault owner can call this function
     *
     * @param _paymentToken the address of the payment token
     */
    function setPaymentToken(address _paymentToken) external onlyOwner {
        paymentToken = IERC20(_paymentToken);
    }

    /**
     * @notice sets the address of the bfx exchange contract
     *
     * @dev WARNING incorrect setting could lead to loss of funds when
     * calling makeDeposit, normally set during deployment
     * @dev only the vault owner can call this function
     *
     * @param _bfx the address of the bfx exchange contract 
     */
    function setBfx(address _bfx) external onlyOwner {
        bfx = IBfx(_bfx);
    }

    /**
     * @notice withdraws funds from the vault, not normally used 
     * as no funds are held on the vault - staking sends them directly 
     * to the bfx exchange
     *
     * @dev the vault must already have a sufficient token balance,
     * calling this function does not withdraw funds from the bfx 
     * exchange to the vault
     * @dev only the vault owner can call this function
     *
     * @param amount the amount of tokens to withdraw
     * @param to the address to which to send the tokens 
     */
    function withdrawTokensTo(uint256 amount, address to) external onlyOwner {
        require(amount > 0, "WRONG_AMOUNT");
        require(to != address(0), "ZERO_ADDRESS");
        emit WithdrawTo(to, amount);
        bool success = _makeTransfer(to, amount);
        require(success, "TRANSFER_FAILED");
    }
    
    function _makeTransferFrom(
        address from,
        address to,
        uint256 amount
    ) private returns (bool success) {
        return
            _tokenCall(
                abi.encodeWithSelector(
                    paymentToken.transferFrom.selector,
                    from,
                    to,
                    amount
                )
            );
    }

    function _makeTransfer(address to, uint256 amount) internal returns (bool success) {
        return _tokenCall(abi.encodeWithSelector(paymentToken.transfer.selector, to, amount));
    }

    function _tokenCall(bytes memory data) internal returns (bool) {
        (bool success, bytes memory returndata) = address(paymentToken).call(data);
        if (success && returndata.length > 0) {
            success = abi.decode(returndata, (bool));
        }
        return success;
    }
}
