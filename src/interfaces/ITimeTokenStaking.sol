// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface ITimeTokenStaking {
    /** Events **/
    event LogStake(address indexed staker, uint256 amount);
    event LogWithdraw(address indexed staker, uint256 amount);
    event LogClaim(address indexed staker, uint256 amount);
    event LogSetInterestRate(uint indexed rate);

    /** Functions **/
    function setInterestRate(uint256 _rate) external;

    function stake(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function claimRewards() external;
}