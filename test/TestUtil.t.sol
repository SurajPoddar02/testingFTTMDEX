// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../src/LiquidTimeToken.sol";
import "../src/TimeTokenStaking.sol";
import "../src/FTTMDEX.sol";
import "../src/DAOContract.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract TestUtil is Test {
    DAO dao;
    LiquidTimeToken tokenFTTM;
    TimeTokenStaking staking;
    ERC20 tokenCash;
    FTTMDEX exchange;

    address FTTMTokenOwner = address(this);
    address UFTTTokenOwner = address(this);

    uint256 minimumStakingPeriodInMonths = 1;
    uint256 primaryMarketExchangeRate = 100;
    uint256 private minFTTMPrice = 1;
    uint256 private feePercentage = 1;
    uint256 initialFTTMBalance = 1000;
    uint256 initialCashBalance = 1000;
    uint256 liquidityFTTM = 100;
    uint256 liquidityCash = 100;
    uint256 private votingDuration = 3600;

    function testSetUp(uint8 _case) public {
        dao = new DAO(UFTTTokenOwner, votingDuration);
        tokenFTTM = deployLiquidTimeToken("LiquidTimeToken", "LTT", address(dao));

        if (_case == 1) {
            staking = deployTimeTokenStaking(address(tokenFTTM));
        } else if (_case == 2) {
            exchange = deployFTTMDEX(address(tokenFTTM));
        }
    }

    function deployLiquidTimeToken(
        string memory _name,
        string memory _symbol,
        address _dao
    ) internal returns (LiquidTimeToken) {
        LiquidTimeToken newToken = new LiquidTimeToken(_name, _symbol, _dao);
        return newToken;
    }

    function deployTimeTokenStaking(address _tokenFTTM) internal returns (TimeTokenStaking) {
        require(_tokenFTTM != address(0x0), "ERR: Invalid token address");
        TimeTokenStaking newStaking = new TimeTokenStaking(_tokenFTTM, minimumStakingPeriodInMonths);
        return newStaking;
    }

    function deployFTTMDEX(address _tokenFTTM) internal returns (FTTMDEX) {
        LiquidTimeToken(_tokenFTTM).mint(initialFTTMBalance);
        require(_tokenFTTM != address(0x0), "ERR: Invalid token address");
        tokenCash = new ERC20("Cash", "CASH");
        FTTMDEX newExchange = new FTTMDEX(
            IERC20(_tokenFTTM),
            tokenCash,
            FTTMTokenOwner,
            primaryMarketExchangeRate,
            minFTTMPrice,
            feePercentage
        );
        vm.prank(address(dao));
        tokenFTTM.transfer(address(newExchange), initialFTTMBalance);

        deal(address(tokenCash), address(this), initialCashBalance);
        tokenCash.transfer(address(newExchange), initialCashBalance);

        // exchange.provideLiquidity(liquidityFTTM, liquidityCash);

        return newExchange;
    }
}