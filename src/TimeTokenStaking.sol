// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/security/Pausable.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./interfaces/ITimeTokenStaking.sol";

contract TimeTokenStaking is ITimeTokenStaking, Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public token;
    uint256 internal interestRate = 20;
    uint256 public stakingStart;
    uint256 public minimumStakingPeriod;

    mapping(address => uint256) public stakes;
    mapping(address => uint256) public lastClaimed;

    constructor(address _token, uint256 _minimumStakingPeriodInMonths) {
        require(_token != address(0), "ERR: Invalid token");
        require(_minimumStakingPeriodInMonths != 0, "ERR: Invalid min staking period");
        token = IERC20(_token);
        stakingStart = block.timestamp;
        minimumStakingPeriod = _minimumStakingPeriodInMonths * 30 days;
    }

    /** User actions **/

    function setInterestRate(uint256 _rate) external onlyOwner whenNotPaused {
        require(_rate != 0, "ERR: Invalid rate");
        interestRate = _rate;
        emit LogSetInterestRate(_rate);
    }

    function stake(uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount != 0, "ERR: Staking amount cannot be zero");

        // Transfer tokens from sender to contract
        token.safeTransferFrom(msg.sender, address(this), _amount);

        // Update stake amount for sender
        stakes[msg.sender] += _amount;

        // Update last claimed time for sender
        if (lastClaimed[msg.sender] == 0) {
            lastClaimed[msg.sender] = stakingStart;
        }

        // Emit event
        emit LogStake(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external whenNotPaused nonReentrant {
        // Ensure sender has enough stake to withdraw
        require(stakes[msg.sender] >= _amount, "ERR: Invalid stake to withdraw");

        // Ensure minimum staking period has passed
        require(
            block.timestamp >= lastClaimed[msg.sender] + minimumStakingPeriod,
            "ERR: Min staking period not reached"
        );

        // Claim rewards before withdrawing
        _claimRewards();

        // Transfer tokens from contract to sender
        token.safeTransfer(msg.sender, _amount);

        // Update stake amount for sender
        stakes[msg.sender] -= _amount;

        // Emit event
        emit LogWithdraw(msg.sender, _amount);
    }

    function claimRewards() external whenNotPaused nonReentrant {
        _claimRewards();
    }

    function _claimRewards() internal {
        uint256 reward = calculateReward(msg.sender);
        if (reward > 0) {
            // TODO : fix mint only accepts single param in liquidTOken implemntation
            // and mints token to 'DAOAddress'
            // is mint suppose to directly mint token to non-DAO addresss ?

            // Mint new tokens for the reward
            // token.mint(msg.sender, reward);

            // Update last claimed time for sender
            lastClaimed[msg.sender] = block.timestamp;

            // Emit event
            emit LogClaim(msg.sender, reward);
        }
    }

    /** Support **/

    /// @notice Triggers stopped state.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Returns to normal state.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /** Getter **/

    function getInterestRate() external view returns (uint256) {
        return interestRate;
    }

    function calculateReward(address _staker) public view returns (uint256) {
        require(_staker != address(0), "ERR: Invalid staker");
        uint256 timeSinceLastClaimed = block.timestamp - lastClaimed[_staker];
        uint256 stakedAmount = stakes[_staker];
        return (stakedAmount * interestRate * timeSinceLastClaimed) / (100 * 365 days);
    }

    function balanceOf(address _staker) external view returns (uint256) {
        require(_staker != address(0), "ERR: Invalid staker");
        return stakes[_staker];
    }
}