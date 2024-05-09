// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import {Initializable} from "@openzeppelin5/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin5/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin5/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin5/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin5/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin5/contracts/utils/cryptography/MerkleProof.sol";

import {ISaldcoinStaking} from "./interfaces/ISaldcoinStaking.sol";
import {SaldcoinDelegatableUpgradeable} from "contracts/memecoin/delegate/SaldcoinDelegatableUpgradeable.sol";

contract SaldcoinStaking is
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    SaldcoinDelegatableUpgradeable,
    ISaldcoinStaking
{
    using SafeERC20 for IERC20;

    uint256 private constant _MINIMUM_AMOUNT = 1e18;

    IERC20 public memecoin;
    bool public stakingActive;
    bool public upgraderRenounced;
    uint64 public stakingStartDate;

    address public upgrader; // to be set

    mapping(address user => uint256 balance) public balanceOf;
    mapping(uint256 rewardId => bytes32 merkleRoot) public rewardsMerkleRoots;
    mapping(address user => mapping(uint256 rewardId => uint256 redeemedAt)) private _usersRewardRedeemedAt;

    string public constant name = "Staked Saldcoin";
    string public constant symbol = "";
    uint8 public constant decimals = 18;

    // required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyUpgrader {}

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _memecoin, address _delegate) external initializer {
        if (_memecoin == address(0) || _delegate == address(0)) revert InvalidAddress();

        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        OwnableUpgradeable.__Ownable_init(_msgSender());
        UUPSUpgradeable.__UUPSUpgradeable_init();
        SaldcoinDelegatableUpgradeable.__SaldcoinDelegatable_init(_delegate);

        memecoin = IERC20(_memecoin);
    }

    // ==================
    // External Functions
    // ==================

    /// @inheritdoc ISaldcoinStaking
    function stake(uint256 amount, Reward[] calldata rewards, bytes calldata permit)
        external
        nonReentrant
        onlyValidStakingSetup
        onlyValidAmount(amount)
    {
        if (rewards.length != 0) _redeemRewards(_msgSender(), rewards);
        _stake(_msgSender(), amount, permit);
    }

    /// @inheritdoc ISaldcoinStaking
    function stakeFor(address user, uint256 amount, bytes calldata permit)
        external
        nonReentrant
        onlyValidStakingSetup
        onlyValidAmount(amount)
        onlyDelegatable
    {
        _stake(user, amount, permit);
    }

    /// @inheritdoc ISaldcoinStaking
    function unstake(uint256 amount, Reward[] calldata rewards)
        external
        nonReentrant
        onlyValidStakingSetup
        onlyValidAmount(amount)
    {
        if (rewards.length != 0) _redeemRewards(_msgSender(), rewards);
        _unstake(_msgSender(), amount);
    }

    // ============================
    // Internal & Private Functions
    // ============================

    function _stake(address user, uint256 amount, bytes calldata permit) private {
        if (permit.length != 0) _delegatePermit(permit);

        unchecked {
            balanceOf[user] += amount;
        }
        _delegateTransfer(address(this), amount);
        emit Transfer(address(0), user, amount);

        emit Staked(user, amount, block.timestamp);
    }

    function _unstake(address user, uint256 amount) private {
        uint256 userBalance = balanceOf[user];
        if (userBalance < amount) revert InsufficientStakedBalance();
        unchecked {
            balanceOf[user] = userBalance - amount;
        }
        memecoin.safeTransfer(user, amount);
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

    modifier onlyUpgrader() {
        if (_msgSender() != upgrader) revert Unauthorized();
        _;
    }

    modifier onlyValidStakingSetup() {
        if (!stakingActive || stakingStartDate == 0 || block.timestamp < stakingStartDate) revert StakingNotAvailable();
        _;
    }

    modifier onlyValidAmount(uint256 amount) {
        if (amount == 0 || amount < _MINIMUM_AMOUNT) revert InvalidAmount();
        _;
    }

    // ==============
    // Admin Functions
    // ==============

    /// @inheritdoc ISaldcoinStaking
    function stakeRewards(address depositor, uint256 rewardId, uint256 amount, bytes32 root) external onlyOwner {
        if (depositor == address(0) || amount == 0 || root == bytes32(0)) revert InvalidStakingSetup();

        rewardsMerkleRoots[rewardId] = root;
        memecoin.safeTransferFrom(depositor, address(this), amount);
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

    /**
     * @notice Set the new UUPS proxy upgrader. Can only be called by the owner.
     * @param _upgrader The address of new upgrader
     */
    function setUpgrader(address _upgrader) external onlyOwner {
        if (upgraderRenounced) revert UpgraderRenounced();
        if (_upgrader == address(0)) revert InvalidAddress();
        upgrader = _upgrader;

        emit UpgraderUpdated(_upgrader);
    }

    /**
     * @notice Renounce the upgradibility of staking contract. Can only be called by the owner.
     */
    function renounceUpgrader() external onlyOwner {
        if (upgraderRenounced) revert UpgraderRenounced();

        upgraderRenounced = true;
        upgrader = address(0);

        emit UpgraderUpdated(address(0));
    }

    // ==============
    // Getters
    // ==============

    /**
     * @notice Get the total staked amount
     */
    function totalSupply() external view returns (uint256) {
        return memecoin.balanceOf(address(this));
    }

    /// @inheritdoc ISaldcoinStaking
    function stakeOf(address user, Reward[] calldata rewards) external view returns (uint256 balance) {
        balance = balanceOf[user];
        if (rewards.length != 0) {
            for (uint256 i; i < rewards.length; i++) {
                Reward calldata reward = rewards[i];
                uint256 amount = reward.amount;
                uint256 rewardId = reward.rewardId;

                if (_usersRewardRedeemedAt[user][rewardId] > 0) continue;
                if (!_verifyProof(user, rewardId, amount, reward.proof)) revert InvalidProof();

                balance += amount;
            }
        }
    }

    /// @inheritdoc ISaldcoinStaking
    function getRewardRedeemedAt(address user, uint256 rewardId) external view returns (uint256) {
        return _usersRewardRedeemedAt[user][rewardId];
    }
}
