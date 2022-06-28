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
  let PaymentToken;
  let EscrowManager;

  beforeEach(async () => {
    await deployments.fixture([
      "PoolContractB",
      "CustodianContract",
      "PaymentToken",
    ]);
    const { custodianContractOwner } = await getNamedAccounts();
    PoolContractB = await ethers.getContract(
      "PoolContractB",
      custodianContractOwner
    );

    PaymentToken = await ethers.getContract(
      "PaymentToken",
      custodianContractOwner
    );
    EscrowManager = await ethers.getContract(
      "EscrowManager",
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
    it("can escrow funds", async () => {
      const { custodian, issuer, custodianContractOwner } =
        await getNamedAccounts();

      const escrowAmount = ethers.utils.parseEther("1");

      await expect(
        PaymentToken.freshMint(custodianContractOwner, escrowAmount)
      );
      await expect(PaymentToken.transfer(PoolContractB.address, escrowAmount))
        .not.to.be.reverted;

      await expect(PoolContractB.addTokenizationPlatform(EscrowManager.address))
        .not.to.be.reverted;

      await expect(PoolContractB.addPaymentToken(PaymentToken.address)).not.to
        .be.reverted;

      await expect(
        PoolContractB.approve(
          EscrowManager.address,
          PaymentToken.address,
          escrowAmount
        )
      );
    });
    it("can transfer funds", async () => {
      const { custodian, issuer, custodianContractOwner } =
        await getNamedAccounts();

      const escrowAmount = ethers.utils.parseEther("1");

      await expect(
        PaymentToken.freshMint(custodianContractOwner, escrowAmount)
      );
      await expect(PaymentToken.transfer(PoolContractB.address, escrowAmount))
        .not.to.be.reverted;

      await expect(
        PoolContractB.transfer(
          EscrowManager.address,
          PaymentToken.address,
          escrowAmount
        )
      );
    });
    it("can get the balanceOf for a tokenAddress", async () => {
      const { custodianContractOwner } = await getNamedAccounts();

      const escrowAmount = ethers.utils.parseEther("1");

      await expect(
        PaymentToken.freshMint(custodianContractOwner, escrowAmount)
      );
      await expect(PaymentToken.transfer(PoolContractB.address, escrowAmount))
        .not.to.be.reverted;

      const balance = await PoolContractB.getPoolBalance(PaymentToken.address);

      expect(balance).to.equal(escrowAmount);
    });
  });
});
