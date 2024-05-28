// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import {ReentrancyGuardUpgradeable} from "@openzeppelin5/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin5/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin5/contracts/utils/cryptography/MerkleProof.sol";

import {ISaldcoinStaking} from "./interfaces/ISaldcoinStaking.sol";


contract SaldcoinStaking is
    ReentrancyGuardUpgradeable,
    ISaldcoinStaking
{
    using SafeERC20 for IERC20;

    uint256 private constant _MINIMUM_AMOUNT = 1e18;

    IERC20 public saldcoin;
    bool public stakingActive;

    uint64 public stakingStartDate;


    mapping(address user => uint256 balance) public balanceOf;
    mapping(uint256 rewardId => bytes32 merkleRoot) public rewardsMerkleRoots;
    mapping(address user => mapping(uint256 rewardId => uint256 redeemedAt)) private _usersRewardRedeemedAt;

    string public constant name = "Staked Saldcoin";
    string public constant symbol = "";
    uint8 public constant decimals = 18;
    address public owner;

 
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        owner=msg.sender;
        stakingActive=true;
        saldcoin=IERC20(0x5582a479f0c403E207D2578963CceF5D03BA636f);
    }

    function setSaldcoinAddr(address addr) external onlyOwner{
        saldcoin = IERC20(addr);
    }

    // ==================
    // External Functions
    // ==================

    /// @inheritdoc ISaldcoinStaking
    function stake(uint256 amount)
        external
        nonReentrant
        onlyValidStakingSetup
    {
        _stake(msg.sender, amount);
    }

    /// @inheritdoc ISaldcoinStaking
    function unstake(uint256 amount)
        external
        nonReentrant
        onlyValidStakingSetup
    {
        _unstake(msg.sender, amount);
    }

    // ============================
    // Internal & Private Functions
    // ============================

    function _stake(address user, uint256 amount) private {
        unchecked {
            balanceOf[user] += amount;
        }
        saldcoin.safeTransferFrom(user, address(this), amount);
        emit Transfer(address(0), user, amount);

        emit Staked(user, amount, block.timestamp);
    }

    function _unstake(address user, uint256 amount) private {
        uint256 userBalance = balanceOf[user];
        if (userBalance < amount) revert InsufficientStakedBalance();

        balanceOf[user] = userBalance - amount;
        
        saldcoin.safeTransfer(user, amount);
        emit Transfer(user, address(0), amount);

        emit Unstaked(user, amount, block.timestamp);
    }

    /**
     * @dev Redeem and stake user's unredeemed rewards
     * @param user The address of user
     * @param rewards Array of Rewards (rewardId, amount, and proof) for verifying any unredeemed rewards
     */
    function _redeemRewards(address user, Reward[] calldata rewards) private {
        for (uint256 i; i < rewards.length; i++) {
            Reward calldata reward = rewards[i];
            uint256 rewardId = reward.rewardId;

            if (_usersRewardRedeemedAt[user][rewardId] > 0) continue;

            uint256 amount = reward.amount;
            if (!_verifyProof(user, rewardId, amount, reward.proof)) revert InvalidProof();

            unchecked {
                balanceOf[user] += amount;
            }
            emit Transfer(address(this), user, amount);
            _usersRewardRedeemedAt[user][rewardId] = block.timestamp;
            emit RewardRedeemed(user, rewardId, amount, block.timestamp);
        }
    }

    /**
     * @dev Verify the proof against the Merkle root of specified rewardId
     * @param user The address of user
     * @param rewardId The ID of reward
     * @param amount The amount of reward
     * @param merkleProof The Merkle proof to be verified
     */
    function _verifyProof(address user, uint256 rewardId, uint256 amount, bytes32[] calldata merkleProof)
        private
        view
        returns (bool)
    {
        return MerkleProof.verifyCalldata(
            merkleProof, rewardsMerkleRoots[rewardId], keccak256(bytes.concat(keccak256(abi.encode(user, amount))))
        );
    }

    // ====================
    // Validation Modifiers
    // ====================
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _; // Continue execution of the function if the condition is met
    }

    modifier onlyValidStakingSetup() {
        if (!stakingActive) revert StakingNotAvailable();
        _;
    }

    modifier onlyValidAmount(uint256 amount) {
        if (amount == 0 || amount < _MINIMUM_AMOUNT) revert InvalidAmount();
        _;
    }

    // ==============
    // Admin Functions
    // ==============

    function stakeRewards(address depositor, uint256 rewardId, uint256 amount, bytes32 root) external onlyOwner {
        if (depositor == address(0) || amount == 0 || root == bytes32(0)) revert InvalidStakingSetup();

        rewardsMerkleRoots[rewardId] = root;
        saldcoin.safeTransferFrom(depositor, address(this), amount);
        emit Transfer(address(0), address(this), amount);

        emit RewardStaked(rewardId, amount, block.timestamp);
    }

    /// @inheritdoc ISaldcoinStaking
    function setStakingActive(bool isActive) external onlyOwner {
        stakingActive = isActive;

        emit StakingStatusUpdated(isActive);
    }

    /// @inheritdoc ISaldcoinStaking
    function setStakingStartDate(uint64 _stakingStartDate) external onlyOwner {
        stakingActive = true;
        stakingStartDate = _stakingStartDate;

        emit StakingStatusUpdated(true);
    }


    // ==============
    // Getters
    // ==============

    /**
     * @notice Get the total staked amount
     */
    function totalSupply() external view returns (uint256) {
        return saldcoin.balanceOf(address(this));
    }

    /// @inheritdoc ISaldcoinStaking
    function getRewardRedeemedAt(address user, uint256 rewardId) external view returns (uint256) {
        return _usersRewardRedeemedAt[user][rewardId];
    }
}
