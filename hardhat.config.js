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

const namedAccounts = Object.fromEntries(
  [
    "custodianContractOwner",
    "issuer",
    "secondaryIssuer",
    "nonIssuer",
    "issuer2",
    "userOfType",
    "userOfType2",
    "userOfOtherType",
    "custodian",
    "subscriber",
    "subscriber2",
    "kycProvider",
    "nonSubscriber",
  ].map((name, i) => [name, i])
);

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
  namedAccounts,
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
