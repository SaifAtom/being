// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Being is ERC20, Ownable, ReentrancyGuard {
    // Staking Data

    mapping(address => uint256) public  stakedBalance;

    mapping(address => uint256) public lastStakeTime;

    uint256 public constant MINIMUM_STAKE_AMOUNT = 1000; // Minimum stake amount in tokens

    uint256 public constant YEAR_DURATION = 365 days; // Define 1 year as 365 days

    uint256 public totalStakedBalance;

    uint256 public DEPLOYMENT_TIMESTAMP; // Track contract deployment time

    // Staking Reward Rates

    uint256 public constant FIRST_YEAR_RATE = 10; // 10% annual rate for the first year

    uint256 public constant SECOND_YEAR_RATE = 8; // 8% annual rate for the second year

    uint256 public constant THIRD_YEAR_RATE = 5; // 5% annual rate thereafter

    event TokensStaked(address indexed user, uint256 amount);

    event TokensUnstaked(address indexed user, uint256 amount);

    // Constructor optimization

    constructor() ERC20("Being", "BNG") Ownable(msg.sender) {
        _mint(msg.sender, 80_000_000_000 * 10**decimals()); // Ensure decimals() is efficient

        DEPLOYMENT_TIMESTAMP = block.timestamp; // Use block.timestamp for better efficiency
    }

    function getCurrentRewardRate() public view returns (uint256) {
        uint256 timeElapsed = block.timestamp - DEPLOYMENT_TIMESTAMP;

        if (timeElapsed < 365 days) return FIRST_YEAR_RATE;

        if (timeElapsed < 2 * 365 days) return SECOND_YEAR_RATE;

        return THIRD_YEAR_RATE;
    }

    function stakeTokens(uint256 amount) external nonReentrant {
        require(
            amount >= MINIMUM_STAKE_AMOUNT,
            "Stake amount must be at least the minimum."
        );

        require(
            balanceOf(msg.sender) >= amount,
            "Insufficient balance to stake."
        );

        _transfer(msg.sender, address(this), amount); // Lock tokens in contract

        stakedBalance[msg.sender] += amount;

        lastStakeTime[msg.sender] = block.timestamp;

        totalStakedBalance += amount;

        emit TokensStaked(msg.sender, amount);
    }

    function unstakeTokens() external nonReentrant {
        uint256 stakedAmount = stakedBalance[msg.sender];

        require(stakedAmount > 0, "No tokens staked");

        uint256 rewards = calculateRewards(msg.sender);

        stakedBalance[msg.sender] = 0;

        lastStakeTime[msg.sender] = 0;

        totalStakedBalance -= stakedAmount;

        _mint(msg.sender, rewards); // Mint rewards to staker

        _transfer(address(this), msg.sender, stakedAmount);

        emit TokensUnstaked(msg.sender, stakedAmount + rewards);
    }

    function calculateRewards(address staker) public view returns (uint256) {
        uint256 stakedAmount = stakedBalance[staker]; // Fetch the user's staked balance

        uint256 rewardRate = getCurrentRewardRate(); // Fetch the current reward rate

        uint256 duration = block.timestamp - lastStakeTime[staker]; // Use timestamps for duration in seconds

        uint256 rewards = (stakedAmount * rewardRate * duration) /
            (YEAR_DURATION * 100);

        return rewards; // Return calculated rewards
    }

    // Utility function: Fetch user's total staked tokens

    function getUserStake(address user) external view returns (uint256) {
        return stakedBalance[user];
    }

    function getTotalStaked() external view returns (uint256) {
        return totalStakedBalance; // Use the declared variable
    }
}
