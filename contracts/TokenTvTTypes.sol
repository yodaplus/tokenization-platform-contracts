//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

struct TokenTvTInput {
  string name;
  string symbol;
  uint256 maxTotalSupply;
  address[] paymentTokens;
  uint256[] issuanceSwapMultiple;
  uint256[] redemptionSwapMultiple;
  uint256 maturityPeriod;
  uint256 settlementPeriod;
  uint256 collateral;
  uint256 issuerCollateralShare;
  uint256 insurerCollateralShare;
  address collateralProvider;
}
