// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract RewardClaim is Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    address public signer;
    IERC20 public rewardToken;

    event RewardClaimed(address indexed user, uint256 amount);

    constructor(address _rewardToken) Ownable(msg.sender) {
        signer = msg.sender;
        rewardToken = IERC20(_rewardToken);
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function claimReward(uint256 amount, bytes memory signature) external {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, amount));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();

        address _signer = ethSignedMessageHash.recover(signature);
        require(_signer == signer, "Invalid signature");

        // Transfer the reward using the specified ERC20 token
        require(rewardToken.transfer(msg.sender, amount), "Token transfer failed");

        emit RewardClaimed(msg.sender, amount);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
