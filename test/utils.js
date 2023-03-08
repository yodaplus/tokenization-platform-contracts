const { T } = require("lodash/fp");
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
  insurerCollateralShare: 0,
  insurerPrimaryAddress: "0x0000000000000000000000000000000000000000",

  countries: [stringToBytes32("USA"), stringToBytes32("IND")],
  investorClassifications: {
    isExempted: true,
    isAccredited: true,
    isAffiliated: true,
  },
  useIssuerWhitelist: false,
  // onChainKyc: true,
  documentName: stringToBytes32("RICK_ASTLEY"),
  documentUri:
    "https://ipfs.io/ipfs/QmbXp7tz1v92zdARJp6576xxFuNnd2tycs3dtFikrcczNY?filename=rickastley.jpg",
  documentHash:
    "0xfb25b054b44b4518bd3d2a0c5ad1389b6476bc009b36e671afeaa09ab4f16524",
  tokenType: 0,
  liquidityPool: "0x0000000000000000000000000000000000000000",
  issueType: 0,
};
const KYC_DATA = {
  countryCode: stringToBytes32("USA"),
  kycStatus: true,
  // accredation: true,
  // affiliation: true,
  // exempted: true,
  // kycBasicDetails: {
  //   leiCheck: true,
  //   bankCheck: true,
  //   citizenshipCheck: true,
  //   addressCheck: true,
  // },
  // kycAmlCtf: {
  //   pepCheck: true,
  //   sanctionScreening: true,
  //   suspiciousActivityReport: true,
  //   cddReport: true,
  //   fatfComplianceCheck: true,
  // },
};
module.exports = {
  TOKEN_EXAMPLE,
  stringToBytes32,
  KYC_DATA,
};
