// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.15;

// import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
// import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

// contract FTTMDEX is Ownable {
//     IERC20 public tokenFTTM;
//     IERC20 public tokenCash;
//     uint256 public reserveFTTM;
//     uint256 public reserveCash;
//     uint256 public minFTTMPrice;
//     // The last exchange rate used when the tokens minter adds new FTTM on the primary market.
//     uint256 public lastExchangeRate;
//     uint256 public primaryMarketExchangeRate; // Defined as tokenCash per tokenFTTM
//     address FTTMTokenOwner;

//     event liquidityProvided(uint256 indexed amountFTTMIn, uint256 indexed amountCashIn);
//     event liquidityWithdrawn(uint256 indexed amountFTTMOut, uint256 indexed amountCashOut);
//     event boughtFTTMTokenPrimaryMarket(uint indexed amountCashIn);
//     event boughtFTTMSecondaryMarket(uint indexed amountFTTM, uint indexed amountCash);
//     event soldFTTMSecondaryMarket(uint indexed amountFTTM, uint indexed amountCash);

//     struct LiquidityProvider {
//         uint256 tokenFTTMAmount;
//         uint256 tokenCashAmount;
//     }
//     address[] public liquidityProviderAddresses;
//     mapping(address => LiquidityProvider) public liquidityProviders;
//     uint256 public feePercentage;

//     constructor(
//         IERC20 _tokenFTTM,
//         IERC20 _tokenCash,
//         address _FTTMTokenOwner,
//         uint256 _primaryMarketExchangeRate,
//         uint256 _minFTTMPrice,
//         uint256 _feePercentage
//     ) {
//         tokenFTTM = _tokenFTTM;
//         tokenCash = _tokenCash;
//         FTTMTokenOwner = _FTTMTokenOwner;
//         primaryMarketExchangeRate = _primaryMarketExchangeRate;
//         lastExchangeRate = primaryMarketExchangeRate;
//         minFTTMPrice = _minFTTMPrice;
//         feePercentage = _feePercentage;
//     }

//     function provideLiquidity(uint256 amountFTTMIn, uint256 amountCashIn) external {
//         // Check if the liquidity provider is new and add them to the array
//         if (
//             liquidityProviders[msg.sender].tokenFTTMAmount == 0 && liquidityProviders[msg.sender].tokenCashAmount == 0
//         ) {
//             liquidityProviderAddresses.push(msg.sender);
//         }

//         tokenFTTM.transferFrom(msg.sender, address(this), amountFTTMIn);
//         tokenCash.transferFrom(msg.sender, address(this), amountCashIn);

//         reserveFTTM += amountFTTMIn;
//         reserveCash += amountCashIn;

//         liquidityProviders[msg.sender].tokenFTTMAmount += amountFTTMIn;
//         liquidityProviders[msg.sender].tokenCashAmount += amountCashIn;

//         emit liquidityProvided(amountFTTMIn, amountCashIn);
//     }

//     function withdrawLiquidity(uint256 amountFTTMOut, uint256 amountCashOut) external {
//         require(liquidityProviders[msg.sender].tokenFTTMAmount >= amountFTTMOut, "Insufficient tokenFTTM balance");
//         require(liquidityProviders[msg.sender].tokenCashAmount >= amountCashOut, "Insufficient tokenCash balance");

//         tokenFTTM.transfer(msg.sender, amountFTTMOut);
//         tokenCash.transfer(msg.sender, amountCashOut);

//         reserveFTTM -= amountFTTMOut;
//         reserveCash -= amountCashOut;

//         liquidityProviders[msg.sender].tokenFTTMAmount -= amountFTTMOut;
//         liquidityProviders[msg.sender].tokenCashAmount -= amountCashOut;

//         // Remove the liquidity provider address if they have withdrawn all liquidity
//         if (
//             liquidityProviders[msg.sender].tokenFTTMAmount == 0 && liquidityProviders[msg.sender].tokenCashAmount == 0
//         ) {
//             for (uint i = 0; i < liquidityProviderAddresses.length - 1; i++) {
//                 if (liquidityProviderAddresses[i] == msg.sender) {
//                     liquidityProviderAddresses[i] = liquidityProviderAddresses[liquidityProviderAddresses.length - 1];
//                     break;
//                 }
//             }
//             liquidityProviderAddresses.pop();
//         }
//         emit liquidityWithdrawn(amountFTTMOut, amountCashOut);
//     }

//     function getLiquidityProvidersCount() public view returns (uint256) {
//         return liquidityProviderAddresses.length;
//     }

//     function getLiquidityProviderByIndex(uint256 index) public view returns (address) {
//         require(index < liquidityProviderAddresses.length, "Index out of bounds");
//         return liquidityProviderAddresses[index];
//     }

//     // It is up to the buyer to find if primary market emission is better than secondary market.
//     function buyFTTMTokenPrimaryMarket(uint256 amountCashIn) external {
//         require(lastExchangeRate > 0, "Min exchange rate not set");

//         uint256 amountFTTMOut = amountCashIn / lastExchangeRate;
//         require(liquidityProviders[FTTMTokenOwner].tokenFTTMAmount > amountFTTMOut);
//         tokenCash.transferFrom(msg.sender, address(this), amountCashIn);
//         tokenFTTM.transfer(msg.sender, amountFTTMOut);
//         liquidityProviders[FTTMTokenOwner].tokenFTTMAmount -= amountFTTMOut;
//         liquidityProviders[FTTMTokenOwner].tokenCashAmount += amountCashIn;
//         reserveCash += amountCashIn;
//         reserveFTTM -= amountFTTMOut;

//         emit boughtFTTMTokenPrimaryMarket(amountCashIn);
//     }

//     // Only buy FTTM tokens using cash
//     function buyFTTMSecondaryMarket(uint256 amountFTTM, uint256 amountCash) external {
//         require(reserveFTTM >= amountFTTM, "Insufficient reserveFTTM");

//         uint256 k = reserveFTTM * reserveCash;
//         uint256 newReserveFTTM = reserveFTTM - amountFTTM;
//         uint256 newReserveCash = reserveCash + amountCash;

//         require(newReserveFTTM * newReserveCash >= k, "Price slippage too high");

//         uint256 feeFTTM = (amountFTTM * feePercentage) / 100;
//         uint256 netAmountFTTM = amountFTTM - feeFTTM;

//         // Ensure the effective exchange rate is above the minimum FTTM token price
//         uint256 effectiveExchangeRate = amountCash / amountFTTM;
//         require(effectiveExchangeRate >= minFTTMPrice, "FTTM price below minimum allowed by the freelancer");
//         lastExchangeRate = effectiveExchangeRate;

//         tokenFTTM.transfer(msg.sender, netAmountFTTM);
//         tokenCash.transferFrom(msg.sender, address(this), amountCash);

//         // Distribute FTTM tokens to liquidity providers according to their cash token balance weight
//         for (uint256 i = 0; i < getLiquidityProvidersCount(); i++) {
//             address provider = getLiquidityProviderByIndex(i);
//             uint256 providerFTTMWeight = liquidityProviders[provider].tokenFTTMAmount / reserveFTTM;
//             uint256 providerFTTMShare = netAmountFTTM * providerFTTMWeight;
//             liquidityProviders[provider].tokenFTTMAmount -= providerFTTMShare;
//             uint256 providerCashShare = amountCash * providerFTTMWeight;
//             liquidityProviders[provider].tokenCashAmount += providerCashShare;
//         }

//         reserveFTTM = newReserveFTTM + feeFTTM;
//         reserveCash = newReserveCash;

//         emit boughtFTTMSecondaryMarket(amountFTTM, amountCash);
//     }

//     function liquidityProvidersCount() public view returns (uint256) {
//         return liquidityProviderAddresses.length;
//     }

//     function sellFTTMSecondaryMarket(uint256 amountFTTM, uint256 amountCash) external {
//         require(reserveCash >= amountCash, "Insufficient reserveCash");

//         uint256 k = reserveFTTM * reserveCash;
//         uint256 newReserveFTTM = reserveFTTM + amountFTTM;
//         uint256 newReserveCash = reserveCash - amountCash;

//         require(newReserveFTTM * newReserveCash >= k, "Price slippage too high");

//         uint256 feeCash = (amountCash * feePercentage) / 100;
//         uint256 netAmountCash = amountCash - feeCash;

//         // Ensure the effective exchange rate is below the maximum FTTM token price
//         uint256 effectiveExchangeRate = amountCash / amountFTTM;
//         require(effectiveExchangeRate >= minFTTMPrice, "FTTM price below minimum allowed by the freelancer");
//         lastExchangeRate = effectiveExchangeRate;

//         tokenCash.transfer(msg.sender, netAmountCash);
//         tokenFTTM.transferFrom(msg.sender, address(this), amountFTTM);

//         // Distribute FTTM to liquidity providers according to their cash token balance weight
//         for (uint256 i = 0; i < getLiquidityProvidersCount(); i++) {
//             address provider = getLiquidityProviderByIndex(i);
//             uint256 providerCashWeight = liquidityProviders[provider].tokenCashAmount / reserveCash;
//             uint256 providerFTTMShare = amountFTTM * providerCashWeight;
//             liquidityProviders[provider].tokenFTTMAmount += providerFTTMShare;
//             uint256 providerCashShare = netAmountCash * providerCashWeight;
//             liquidityProviders[provider].tokenCashAmount += providerCashShare;
//         }
//         reserveFTTM = newReserveFTTM;
//         reserveCash = newReserveCash + feeCash;

//         emit soldFTTMSecondaryMarket(amountFTTM, amountCash);
//     }
// }