// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {
    constructor() ERC20("TestERC20", "TST") {}

    function mint(address account ) external {
        _mint(account, 100000000000000);
    }
}
