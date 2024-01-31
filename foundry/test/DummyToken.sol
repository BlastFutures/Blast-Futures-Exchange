// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract DummyToken is ERC20 {
    address public immutable owner;

    constructor() ERC20("RabbitDollar", "USDR") {
        owner = msg.sender;
    }

    function mint(address account, uint256 amount) external virtual {
        require(msg.sender == owner, "ONLY_OWNER");
        _mint(account, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}
