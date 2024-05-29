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

    /// @inheritdoc ISaldcoinStaking
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
        return saldcoin.balanceOf(address(this));
    }

}
