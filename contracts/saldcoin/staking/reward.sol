// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin5/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin5/contracts/access/Ownable.sol";

// TODO - Implement a contract that allows users to claim rewards
contract RewardClaim is Ownable {
    using ECDSA for bytes32;

    mapping(address => uint256) public rewards;
    mapping(address => bool) public hasClaimed;

    event RewardClaimed(address indexed user, uint256 amount);

    function setReward(address user, uint256 amount) external onlyOwner {
        rewards[user] = amount;
    }

    function claimReward(uint256 amount, bytes memory signature) external {
        require(!hasClaimed[msg.sender], "Reward already claimed");
        uint256 rewardAmount = rewards[msg.sender];
        require(rewardAmount == amount, "Incorrect reward amount");

        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, amount));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();

        address signer = ethSignedMessageHash.recover(signature);
        require(signer == owner(), "Invalid signature");

        hasClaimed[msg.sender] = true;
        rewards[msg.sender] = 0;

        // Transfer the reward (assuming ETH for simplicity)
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit RewardClaimed(msg.sender, amount);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
