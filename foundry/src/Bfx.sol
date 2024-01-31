// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./EIP712Verifier.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";

contract Bfx is EIP712Verifier {

    uint256 constant UNLOCKED = 1;
    uint256 constant LOCKED = 2;

    address public immutable owner;
    IERC20 public paymentToken;

    // record of already processed withdrawals
    mapping(uint256 => bool) public processedWithdrawals;

    uint256 nextDepositId = 37000;
    uint256 reentryLockStatus = UNLOCKED;

    event Deposit(uint256 indexed id, address indexed trader, uint256 amount);
    event Withdraw(address indexed trader, uint256 amount);
    event WithdrawTo(address indexed to, uint256 amount);
    event WithdrawalReceipt(uint256 indexed id, address indexed trader, uint256 amount);
    event UnknownReceipt(uint256 indexed messageType, uint[] payload);
    event MsgNotFound(uint256 indexed fromAddress, uint[] payload);

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    modifier nonReentrant() {
        require(reentryLockStatus == UNLOCKED, "NO_REENTRY");
        reentryLockStatus = LOCKED;
        _;
        reentryLockStatus = UNLOCKED;
    }

    constructor(address _owner, address _signer, address _paymentToken
    	) EIP712Verifier("BfxWithdrawal", "1", _signer) {
        owner = _owner;
        paymentToken = IERC20(_paymentToken);
    }
    
    function withdraw(
        uint256 id, address trader, uint256 amount, uint8 v, bytes32 r, bytes32 s
        ) external nonReentrant {
        require(amount > 0, "WRONG_AMOUNT");
        require(processedWithdrawals[id] == false, "ALREADY_PROCESSED");
        processedWithdrawals[id] = true;
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("withdrawal(uint256 id,address trader,uint256 amount)"),
            id,
            trader,
            amount
        )));

        bool valid = verify(digest, v, r, s);
        require(valid, "INVALID_SIGNATURE");

        emit WithdrawalReceipt(id, trader, amount);
        bool success = makeTransfer(trader, amount);
        require(success, "TRANSFER_FAILED");
    }

    function setPaymentToken(address _paymentToken) external onlyOwner {
        paymentToken = IERC20(_paymentToken);
    }

    function allocateDepositId() private returns (uint256 depositId) {
        depositId = nextDepositId;
        nextDepositId++;
        return depositId;
    }

    function deposit(uint256 amount) external nonReentrant {
        bool success = makeTransferFrom(msg.sender, address(this) , amount);
        require(success, "TRANSFER_FAILED");
        uint256 depositId = allocateDepositId();
        emit Deposit(depositId, msg.sender, amount);
    }

    function withdrawTokensTo(uint256 amount, address to) external onlyOwner {
        require(amount > 0, "WRONG_AMOUNT");
        require(to != address(0), "ZERO_ADDRESS");
        bool success = makeTransfer(to, amount);
        require(success, "TRANSFER_FAILED");
        emit WithdrawTo(to, amount);
    }
    
    function changeSigner(address new_signer) external onlyOwner {
        require(new_signer != address(0), "ZERO_SIGNER");
        external_signer = new_signer;
    }

    function makeTransfer(address to, uint256 amount) private returns (bool success) {
        return tokenCall(abi.encodeWithSelector(paymentToken.transfer.selector, to, amount));
    }

    function makeTransferFrom(address from, address to, uint256 amount) private returns (bool success) {
        return tokenCall(abi.encodeWithSelector(paymentToken.transferFrom.selector, from, to, amount));
    }

    function tokenCall(bytes memory data) private returns (bool) {
        (bool success, bytes memory returndata) = address(paymentToken).call(data);
        if (success && returndata.length > 0) {
            success = abi.decode(returndata, (bool));
        }
        return success;
    }
}
