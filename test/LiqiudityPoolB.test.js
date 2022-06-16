const _ = require("lodash/fp");
const chai = require("chai");
const chaiSnapshot = require("mocha-chai-snapshot");
const { ethers, deployments, getNamedAccounts } = require("hardhat");
const { expect } = chai;
const { TOKEN_EXAMPLE, KYC_DATA, stringToBytes32 } = require("./utils");
chai.use(chaiSnapshot);

const normalizeOutput = (output) =>
  output.map((v) => (ethers.BigNumber.isBigNumber(v) ? v.toNumber() : v));

const normalizeArrayOutput = (arrOutput) => arrOutput.map(normalizeOutput);

describe("PoolContractB", function () {
  let PoolContractB;

  beforeEach(async () => {
    await deployments.fixture(["PoolContractB"]);
    const { custodianContractOwner } = await getNamedAccounts();
    PoolContractB = await ethers.getContract(
      "PoolContractB",
      custodianContractOwner
    );
  });

  describe("liquidity pool", () => {
    it("can add a tokenization platform", async () => {
      const { custodian, issuer, custodianContractOwner } =
        await getNamedAccounts();

      await expect(PoolContractB.addTokenizationPlatform(issuer))
        .to.emit(PoolContractB, "TokenizationPlatformAdded")
        .withArgs(issuer);
    });
    it("can remove a tokenization platform", async () => {
      const { custodian, issuer, custodianContractOwner } =
        await getNamedAccounts();

      await expect(PoolContractB.removeTokenizationPlatform(issuer))
        .to.emit(PoolContractB, "TokenizationPlatformRemoved")
        .withArgs(issuer);
    });
    it("can add  a payment  token", async () => {
      const { custodian, issuer, custodianContractOwner } =
        await getNamedAccounts();

      await expect(PoolContractB.addPaymentToken(issuer))
        .to.emit(PoolContractB, "PaymentTokenAdded")
        .withArgs(issuer);
    });
    it("can remove a payment token", async () => {
      const { custodian, issuer, custodianContractOwner } =
        await getNamedAccounts();

      await expect(PoolContractB.removePaymentToken(issuer))
        .to.emit(PoolContractB, "PaymentTokenRemoved")
        .withArgs(issuer);
    });
  });
});
