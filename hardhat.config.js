require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("hardhat-deploy");
require("hardhat-watcher");
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
  },
  networks: {
    mainnet: {
      ...sharedNetworkConfig,
      url: `https://safe.xinfin.yodaplus.net:8083`,
    },
    apothem: {
      ...sharedNetworkConfig,
      url: "https://safe-apothem.xinfin.yodaplus.net:8083",
    },
  },
  watcher: {
    test: {
      tasks: ["test"],
      files: ["./contracts", "./test"],
    },
  },
};
