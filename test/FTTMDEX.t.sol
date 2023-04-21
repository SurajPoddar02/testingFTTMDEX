// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/FTTMDEX.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../src/mocks/mocksERC20.sol";
contract FTTMDEXTest is Test {

   FTTMDEX public fttmdex;
   mocksERC20 public mockCash ;
   mocksERC20 public mockFTTM;
   address public FTTMTokenOwner;
   uint256 public primaryMarketExchangeRate;
   uint256 public minFTTMPrice;
   uint256 public feePercentage;
   uint256 public lastExchangeRate;
   IERC20 public tokenCash;
   IERC20 public tokenFTTM;
    // address[] liquidityProviderAddresses;
  
    address[] public liquidityProviderAddresses;
    struct LiquidityProvider {
        uint256 tokenFTTMAmount;
        uint256 tokenCashAmount;
    }
    mapping(address => LiquidityProvider) public liquidityProviders;

   // Invoked before each test
    function setUp() public virtual{
        mockCash = new mocksERC20(); // set up mock IERC20 instances for tokenFTTM and tokenCash
        mockFTTM = new mocksERC20();
        FTTMTokenOwner = address(this);
        primaryMarketExchangeRate = 100;
        minFTTMPrice = 50;
        feePercentage = 1;
        lastExchangeRate = 10;
        tokenCash = IERC20(address(mockCash));
        tokenFTTM = IERC20(address(mockFTTM));
        fttmdex = new FTTMDEX(tokenFTTM, tokenCash, FTTMTokenOwner, primaryMarketExchangeRate, minFTTMPrice, feePercentage);

         liquidityProviders[address(this)].tokenFTTMAmount = 0;
        liquidityProviders[address(this)].tokenCashAmount = 0;
    }

    function testConstructor() public  {
        // check that the values were set correctly during deployment
       require(fttmdex.tokenFTTM() == tokenFTTM, "ERR : Invalid tokenFTTM");
       require(fttmdex.tokenCash() == tokenCash, "ERR : Invalid tokenCash");
       require(fttmdex.FTTMTokenOwner() == FTTMTokenOwner,"ERR : Invalid tokenFTTM address");
       require(fttmdex.primaryMarketExchangeRate() == primaryMarketExchangeRate,"ERR : invalid marketExchangeRate");
       require(fttmdex.minFTTMPrice() == minFTTMPrice,"ERR : invalid FTTMPrice");
       require(fttmdex.feePercentage () == feePercentage,"ERR : invalid feePercentage");
}

   function testProvideLiquidity() public {
    // Set up test case inputs
    uint256 amountFTTMIn = 1000;
    uint256 amountCashIn = 500;

    // Call function under test
       
     uint256 initialFTTMBalance = fttmdex.reserveFTTM();
     uint256 initialCashBalance = fttmdex.reserveCash();
    //  console.log(initialFTTMBalance);
     
    //  Get initial liquidity provider balances
    uint256 initialFTTMLPBalance = fttmdex.getTokenFTTMAmountByAddress(address(this));
    
    uint256 initialCashLPBalance = fttmdex.getTokenCashAmountByAddress(address(this));

    liquidityProviders[address(this)].tokenFTTMAmount += amountFTTMIn;

     console.log(liquidityProviders[address(this)].tokenFTTMAmount);
    liquidityProviders[address(this)].tokenCashAmount += amountCashIn;

    mockCash.approve(address(fttmdex),amountCashIn);
    mockFTTM.approve(address(fttmdex),amountFTTMIn);

    // Call provideLiquidity() function
    fttmdex.provideLiquidity(amountFTTMIn, amountCashIn);
    

    // Get updated contract balances
    uint256 updatedFTTMBalance = fttmdex.reserveFTTM();
    console.log(updatedFTTMBalance);
    uint256 updatedCashBalance = fttmdex.reserveCash();

    // Get updated liquidity provider balances
    uint256 updatedFTTMLPBalance = fttmdex.getTokenFTTMAmountByAddress(address(this));
    uint256 updatedCashLPBalance = fttmdex.getTokenCashAmountByAddress(address(this));


    
    // Check that contract balances have been updated correctly
    assertTrue(updatedFTTMBalance == initialFTTMBalance + amountFTTMIn, "Incorrect updated FTTM token balance for contract");
    assertTrue(updatedCashBalance == initialCashBalance + amountCashIn, "Incorrect updated cash token balance for contract");

    // Check that liquidity provider balances have been updated correctly
    assertTrue(updatedFTTMLPBalance == initialFTTMLPBalance + amountFTTMIn, "Incorrect updated FTTM token balance for liquidity provider");
    assertTrue(updatedCashLPBalance == initialCashLPBalance + amountCashIn, "Incorrect updated cash token balance for liquidity provider");

    // Check that liquidity provider information has been updated correctly
    assertTrue(fttmdex.getTokenFTTMAmountByAddress(address(this)) == amountFTTMIn, "Incorrect FTTM token amount for liquidity provider");
    assertTrue(fttmdex.getTokenCashAmountByAddress(address(this)) == amountCashIn, "Incorrect cash token amount for liquidity provider");

    // Check that liquidity provider has been added to array
    assertTrue(fttmdex.liquidityProviderAddresses(0) == address(this), "Liquidity provider not added to array");
  //  console.log(fttmdex.getTokenFTTMAmountByAddress(address(this)));  

}

 function testWithdrawLiquidity() public {
   testProvideLiquidity();
   uint amountFTTMOut= 500;
   uint  amountCashOut = 300;
   console.log(liquidityProviders[address(this)].tokenFTTMAmount);
  require(fttmdex.getTokenFTTMAmountByAddress(address(this)) >= amountFTTMOut, "Insufficient tokenFTTM balance");
  require( fttmdex.getTokenCashAmountByAddress(address(this)) >= amountCashOut, "Insufficient tokenCash balance");

 uint256 initialFTTMBalance = fttmdex.reserveFTTM();
 uint256 initialCashBalance = fttmdex.reserveCash();

 
// length of unique address intilaly
 uint256 initialAddressLength = fttmdex.liquidityProvidersCount();

//  Get initial liquidity provider balances
  uint256 initialFTTMLPBalance = fttmdex.getTokenFTTMAmountByAddress(address(this));
    
  
   uint256 initialCashLPBalance = fttmdex.getTokenCashAmountByAddress(address(this));

  mockCash.approve(address(this),amountCashOut);
  mockFTTM.approve(address(this),amountFTTMOut);
 fttmdex.withdrawLiquidity(amountFTTMOut,amountCashOut);
  
   // Get updated contract balances
    uint256 updatedFTTMBalance = fttmdex.reserveFTTM();
    uint256 updatedCashBalance = fttmdex.reserveCash();
    
   //updated unique address 
   uint256 updatedAddressLength = fttmdex.liquidityProvidersCount();

    // Get updated liquidity provider balances
    uint256 updatedFTTMLPBalance = fttmdex.getTokenFTTMAmountByAddress(address(this));
    uint256 updatedCashLPBalance = fttmdex.getTokenCashAmountByAddress(address(this));

     require(updatedCashBalance == initialCashBalance-amountCashOut,"ERR: invalid updatedCash Balance");

     require(updatedFTTMBalance == initialFTTMBalance-amountFTTMOut,"ERR: invalid updatedCash Balance");

     require(updatedFTTMLPBalance == initialFTTMLPBalance - amountFTTMOut, "ERR: Invalid updatedFTTMLPBalance" );

     require(updatedCashLPBalance == initialCashLPBalance - amountCashOut, "ERR: Invalid updatedCashLPBalance" );

     require(updatedAddressLength==initialAddressLength, "Not removing the address from the liquidityProviders");
     
 }

  // function testBuyFTTMTokenPrimaryMarket() public {
    
  //   uint256 amountCashIn= 300;

  //   uint256 amountFTTMOut = lastExchangeRate/lastExchangeRate;

  //   if(lastExchangeRate <=0 ){
  //    vm.expectRevert(stdError.arithmeticError);
  //   }
    
  //  uint256 initialReverseCash = fttmdex.reserveCash();
  //  uint256 initialReverseFTTM = fttmdex.reserveFTTM();

  //  uint256 initialFTTMLPBalance = fttmdex.getTokenFTTMAmountByAddress(address(this));
    
  //  uint256 initialCashLPBalance = fttmdex.getTokenCashAmountByAddress(address(this));

  //    mockCash.approve(address(fttmdex),amountCashIn);
  //    mockFTTM.approve(address(this),amountFTTMOut);
  //   fttmdex.buyFTTMTokenPrimaryMarket(amountCashIn);
    
  //   uint256 updatedFTTMLPBalance = fttmdex.getTokenFTTMAmountByAddress(address(this));
  //   uint256 updatedCashLPBalance = fttmdex.getTokenCashAmountByAddress(address(this));

  //    require(updatedFTTMLPBalance == initialFTTMLPBalance - amountFTTMOut, "ERR: Invalid updatedFTTMLPBalance" );

  //    require(updatedCashLPBalance == initialCashLPBalance - amountCashIn, "ERR: Invalid updatedCashLPBalance" );

  //    require(fttmdex.reserveCash() == initialReverseCash - amountCashIn, "ERR: Invalid Reverse Cash" );

  //    require(fttmdex.reserveFTTM() == initialReverseFTTM - amountFTTMOut, "ERR: Invalid Reverse Cash" );
  //   }

    // function testBuyFTTMSecondaryMarket() public {
    //  uint256 amountFTTM = 500;
    //  uint256 amountCash = 300;

    //  uint k =  
    // }
  
}
