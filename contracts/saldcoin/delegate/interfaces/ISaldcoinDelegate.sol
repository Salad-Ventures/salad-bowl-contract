// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

interface ISaldcoinDelegate {
    function saldcoin() external view returns (address);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function allowance(address user) external view returns (uint256);
    function isAuthorized(address addr) external view returns (bool);
}
