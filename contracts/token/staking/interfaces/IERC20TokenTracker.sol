// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

/**
 * @dev Interface for offchain token trackers (ex. Etherscan) via partial IERC20Metadata
 */
interface IERC20TokenTracker {
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address user) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}
