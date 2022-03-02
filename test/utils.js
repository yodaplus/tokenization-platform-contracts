const web3 = require("web3");
const stringToBytes32 = (str) => {
  return web3.utils.padRight(web3.utils.fromAscii(str), 64);
};

const TOKEN_EXAMPLE = {
  name: "Test Token",
  symbol: "TT1",
  maxTotalSupply: 10,
  value: 1000,
  currency: "USD",
  earlyRedemption: true,
  minSubscription: 1,
  paymentTokens: [],
  issuanceSwapMultiple: [],
  redemptionSwapMultiple: [],
  maturityPeriod: 30 * 24 * 60 * 60,
  settlementPeriod: 2 * 24 * 60 * 60,
  collateral: 0,
  countries: [stringToBytes32("USA"), stringToBytes32("IND")],
  investorClassifications: [stringToBytes32("Exempted")],
  useIssuerWhitelist: true,
};

module.exports = {
  TOKEN_EXAMPLE,
};
