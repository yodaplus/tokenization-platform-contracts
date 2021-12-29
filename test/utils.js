const TOKEN_EXAMPLE = {
  name: "Test Token",
  symbol: "TT1",
  decimals: 18,
  maxTotalSupply: 10,
  value: 1000,
  currency: "USD",
  earlyRedemption: true,
  minSubscription: 1,
  paymentTokens: [],
  issuanceSwapMultiple: [],
  redemptionSwapMultiple: [],
  maturityPeriod: 30 * 24 * 60 * 60,
  collateral: 0,
};

module.exports = {
  TOKEN_EXAMPLE,
};
