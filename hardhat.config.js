require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-web3");
require("hardhat-deploy");
require("hardhat-watcher");
require("hardhat-gas-reporter");
require("hardhat-contract-sizer");
require("solidity-coverage");
require("./tasks");
require("dotenv").config();

const { MNEMONIC } = process.env;
const DEFAULT_MNEMONIC =
  "juice whisper void palm tackle film float able plunge invest focus flee";

const sharedNetworkConfig = {
  accounts: {
    mnemonic: MNEMONIC ?? DEFAULT_MNEMONIC,
  },
};

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.4",
    settings: {
      evmVersion: "byzantium",
      optimizer: { enabled: true, runs: 200 },
    },
  },
  namedAccounts: {
    custodianContractOwner: 0,
    issuer: 1,
    nonIssuer: 2,
    issuer2: 3,
    userOfType: 4,
    userOfType2: 5,
    userOfOtherType: 6,
    custodian: 7,
    subscriber: 8,
    kycProvider: 9,
  },
  networks: {
    mainnet: {
      ...sharedNetworkConfig,
      url: `https://rpc.xinfin.yodaplus.net`,
    },
    apothem: {
      ...sharedNetworkConfig,
      url: "https://rpc-apothem.xinfin.yodaplus.net",
    },
  },
  watcher: {
    test: {
      tasks: ["test"],
      files: ["./contracts", "./test"],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS ? true : false,
  },
};
