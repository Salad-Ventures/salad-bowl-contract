// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract ClaimReward is Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    address public signer;
    mapping(address => bool) private claimableTokens;
    mapping(bytes => bool) public usedSignatures;
    mapping(address => uint256) public nonces;

    event RewardClaimed(address indexed user, address indexed token, uint256 amount);
    event SignerSet(address indexed previousSigner, address indexed newSigner);
    event ClaimableTokenAdded(address indexed token);
    event ClaimableTokenRemoved(address indexed token);

    constructor() Ownable(msg.sender) {
        signer = msg.sender;
    }

    function setSigner(address _signer) external onlyOwner {
        address previousSigner = signer;
        signer = _signer;
        emit SignerSet(previousSigner, _signer);
    }

    function addClaimableToken(address _token) external onlyOwner {
        require(!claimableTokens[_token], "Token is already claimable!");
        claimableTokens[_token] = true;
        emit ClaimableTokenAdded(_token);
    }

    function removeClaimableToken(address _token) external onlyOwner {
        require(claimableTokens[_token], "Token is not currently in the contract's claimable token list!");
        claimableTokens[_token] = false;
        emit ClaimableTokenRemoved(_token);
    }

    function claimReward(address token, uint256 amount, bytes memory signature) external {
        require(claimableTokens[token], "Token is not currently in the contract's claimable token list!");

        uint256 nonce = nonces[msg.sender];
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, token, amount, nonce));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();

        address _signer = ethSignedMessageHash.recover(signature);
        require(_signer == signer, "Invalid signature");

        require(!usedSignatures[signature], "Signature has already been used");
        usedSignatures[signature] = true;
        
        nonces[msg.sender]++;

        uint256 contractBalance = IERC20(token).balanceOf(address(this));
        require(contractBalance >= amount, "Not enough tokens of that kind");

        require(IERC20(token).transfer(msg.sender, amount), "Token transfer failed");

        emit RewardClaimed(msg.sender, token, amount);
    }
}
