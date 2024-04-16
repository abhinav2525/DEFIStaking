// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking {
    IERC20 public stakingToken;
    IERC20 public rewardsToken;

    address public owner;

    // Constants to set the reward mechanics
    uint256 public constant BLOCKS_PER_DAY = 14400;  // Approximate number of blocks per day based on a 6-second block time.
    uint256 public constant REWARD_PER_TOKEN_PER_DAY = 1e18;  // The amount of reward per token per day, scaled for token decimals.
    uint256 public rewardPerBlock;  // Reward per block calculated in constructor.

    // Total staked
    uint256 public totalSupply;
    // User address => staked amount
    mapping(address => uint256) public balanceOf;
    // User address => rewards to be claimed
    mapping(address => uint256) public rewards;
    // User address => last updated block for rewards calculation
    mapping(address => uint256) public lastUpdateBlock;

    constructor(address _stakingToken, address _rewardToken) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardToken);
        rewardPerBlock = REWARD_PER_TOKEN_PER_DAY / BLOCKS_PER_DAY;  // Calculate the reward per block based on daily reward.
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    modifier updateReward(address _account) {
        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            lastUpdateBlock[_account] = block.number;
        }
        _;
    }

    function earned(address _account) public view returns (uint256) {
        uint256 blocks = block.number - lastUpdateBlock[_account];
        uint256 rewardPerBlockAccount = balanceOf[_account] * rewardPerBlock / 1e3; // Reward per block for the staked amount
        return rewards[_account] + blocks * rewardPerBlockAccount;
    }

    function stake(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "Amount must be greater than zero");
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "Amount must be greater than zero");
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance to withdraw");

        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function getReward() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.transfer(msg.sender, reward);
        }
    }
}

