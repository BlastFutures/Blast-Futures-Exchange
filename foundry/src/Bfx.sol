// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EIP712Verifier.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";

enum YieldMode {
    AUTOMATIC,
    VOID,
    CLAIMABLE
}

interface IERC20Rebasing is IERC20 {
    function configure(YieldMode) external returns (uint256);

    function claim(
        address recipient,
        uint256 amount
    ) external returns (uint256);

    function getClaimableAmount(
        address account
    ) external view returns (uint256);
}

interface IBlast {
    function configureAutomaticYield() external;
    function configureClaimableGas() external;
    function claimMaxGas(address contractAddress, address recipientOfGas) external returns (uint256);
}

interface IBlastPoints {
	function configurePointsOperator(address operator) external;
}

contract Bfx is EIP712Verifier {

    uint256 constant UNLOCKED = 1;
    uint256 constant LOCKED = 2;
    uint256 constant HUNDRED_DOLLARS = 1e19;
    uint256 constant MIN_DEPOSIT = 1e17;
    IBlast public constant BLAST = IBlast(0x4300000000000000000000000000000000000002);

    address public immutable owner;

    address public claimer;
    IERC20Rebasing public paymentToken;

    // record of already processed withdrawals
    mapping(uint256 => bool) public processedWithdrawals;

    uint256 nextDepositId = 74000;
    uint256 reentryLockStatus = UNLOCKED;

    event Deposit(uint256 indexed id, address indexed trader, uint256 amount);
    event WithdrawTo(address indexed to, uint256 amount);
    event WithdrawalReceipt(
        uint256 indexed id,
        address indexed trader,
        uint256 amount
    );
    event ClaimedYield(uint256 amount);
    event SetToken(address indexed token);
    event SetClaimer(address indexed claimer);
    event SetSigner(address indexed signer);

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    modifier onlyClaimer() {
        require(msg.sender == claimer, "ONLY_CLAIMER");
        _;
    }

    modifier nonReentrant() {
        require(reentryLockStatus == UNLOCKED, "NO_REENTRY");
        reentryLockStatus = LOCKED;
        _;
        reentryLockStatus = UNLOCKED;
    }

    constructor(
        address _owner,
        address _signer,
        address _claimer,
        address _paymentToken,
        address _points
    ) EIP712Verifier("BfxWithdrawal", "1", _signer) {
        owner = _owner;
        claimer = _claimer;
        paymentToken = IERC20Rebasing(_paymentToken);
        paymentToken.configure(YieldMode.CLAIMABLE);
        BLAST.configureAutomaticYield();
        BLAST.configureClaimableGas();
        IBlastPoints(_points).configurePointsOperator(_claimer);
    }

    function claimYield() external nonReentrant onlyClaimer {
        uint256 claimable = paymentToken.getClaimableAmount(address(this));
        if (claimable > HUNDRED_DOLLARS) {
            uint256 balanceBefore = paymentToken.balanceOf(address(this));
            paymentToken.claim(address(this), claimable);
            uint256 balanceAfter = paymentToken.balanceOf(address(this));
            require(balanceAfter > balanceBefore, "CLAIM_DIDNT_INCREASE_BALANCE");
            emit ClaimedYield(balanceAfter - balanceBefore);
        }
    }

    function claimGas() external nonReentrant onlyClaimer {
        BLAST.claimMaxGas(address(this), claimer);
    }

    function withdraw(
        uint256 id,
        address trader,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        require(amount > 0, "WRONG_AMOUNT");
        require(processedWithdrawals[id] == false, "ALREADY_PROCESSED");
        processedWithdrawals[id] = true;
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "withdrawal(uint256 id,address trader,uint256 amount)"
                    ),
                    id,
                    trader,
                    amount
                )
            )
        );

        bool valid = verify(digest, v, r, s);
        require(valid, "INVALID_SIGNATURE");

        emit WithdrawalReceipt(id, trader, amount);
        bool success = makeTransfer(trader, amount);
        require(success, "TRANSFER_FAILED");
    }

    function setPaymentToken(address _paymentToken) external onlyOwner {
        paymentToken = IERC20Rebasing(_paymentToken);
        emit SetToken(_paymentToken);
    }

    function allocateDepositId() private returns (uint256 depositId) {
        depositId = nextDepositId;
        nextDepositId++;
        return depositId;
    }

    function deposit(uint256 amount) external nonReentrant {
        require(amount >= MIN_DEPOSIT, "WRONG_AMOUNT");
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
        emit SetSigner(new_signer);
    }

    function changeClaimer(address new_claimer) external onlyOwner {
        require(new_claimer != address(0), "ZERO_claimer");
        claimer = new_claimer;
        emit SetClaimer(new_claimer);
    }

    function makeTransfer(
        address to,
        uint256 amount
    ) private returns (bool success) {
        return
            tokenCall(
                abi.encodeWithSelector(
                    paymentToken.transfer.selector,
                    to,
                    amount
                )
            );
    }

    function makeTransferFrom(
        address from,
        address to,
        uint256 amount
    ) private returns (bool success) {
        return
            tokenCall(
                abi.encodeWithSelector(
                    paymentToken.transferFrom.selector,
                    from,
                    to,
                    amount
                )
            );
    }

    function tokenCall(bytes memory data) private returns (bool) {
        (bool success, bytes memory returndata) = address(paymentToken).call(data);
        if (success) { 
            if (returndata.length > 0) {
                success = abi.decode(returndata, (bool));
            } else {
                success = address(paymentToken).code.length > 0;
            }
        }
        return success;
    }
}
