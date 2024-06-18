// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BITS is ERC20 {
    constructor() ERC20("BITS", "$BITS") {}

    function mint(address account, uint256 amount ) external {
        _mint(account, amount);
    }
}
