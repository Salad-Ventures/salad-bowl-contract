// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import {ReentrancyGuardUpgradeable} from "@openzeppelin5/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin5/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin5/contracts/utils/cryptography/MerkleProof.sol";
import {IERC20Metadata} from "@openzeppelin5/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {ITokenStaking} from "./interfaces/ITokenStaking.sol";


contract TokenStaking is
    ReentrancyGuardUpgradeable,
    ITokenStaking
{
    using SafeERC20 for IERC20;

    uint256 private constant _MINIMUM_AMOUNT = 1e18;

    IERC20 public stakeToken;
    bool public stakingActive;

    uint64 public stakingStartDate;


    mapping(address user => uint256 balance) public balanceOf;
    mapping(address user => mapping(uint256 rewardId => uint256 redeemedAt)) private _usersRewardRedeemedAt;

    address public owner;

 
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _stakeToken) {
        owner=msg.sender;
        stakingActive=true;
        stakeToken = IERC20(_stakeToken);
    }

    function setStakeToken(address _stakeToken) external onlyOwner{
        stakeToken = IERC20(_stakeToken);
    }


    function name() external view returns (string memory) {
        return IERC20Metadata(address(stakeToken)).name();
    }

    function symbol() external view returns (string memory) {
        return IERC20Metadata(address(stakeToken)).symbol();
    }

    function decimals() external view returns (uint8) {
        return IERC20Metadata(address(stakeToken)).decimals();
    }

    // ==================
    // External Functions
    // ==================

    /// @inheritdoc ITokenStaking
    function stake(uint256 amount)
        external
        nonReentrant
        onlyValidStakingSetup
    {
        _stake(msg.sender, amount);
    }

    /// @inheritdoc ITokenStaking
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
        stakeToken.safeTransferFrom(user, address(this), amount);
        emit Transfer(address(0), user, amount);

        emit Staked(user, amount, block.timestamp);
    }

    function _unstake(address user, uint256 amount) private {
        uint256 userBalance = balanceOf[user];
        if (userBalance < amount) revert InsufficientStakedBalance();

        balanceOf[user] = userBalance - amount;
        
        stakeToken.safeTransfer(user, amount);
        emit Transfer(user, address(0), amount);

        emit Unstaked(user, amount, block.timestamp);
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

    /// @inheritdoc ITokenStaking
    function setStakingActive(bool isActive) external onlyOwner {
        stakingActive = isActive;

        emit StakingStatusUpdated(isActive);
    }
    
    /// set owner
    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    // ==============
    // Getters
    // ==============

    /**
     * @notice Get the total staked amount
     */
    function totalSupply() external view returns (uint256) {
        return stakeToken.balanceOf(address(this));
    }

}
