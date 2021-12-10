const _ = require("lodash/fp");
const chai = require("chai");
const chaiSnapshot = require("mocha-chai-snapshot");
const { ethers, deployments, getNamedAccounts } = require("hardhat");
const { expect } = chai;
const { TOKEN_EXAMPLE } = require("./utils");
chai.use(chaiSnapshot);

describe("Token", function () {
  let CustodianContract;
  let CustodianContractIssuer;
  let CustodianContractKycProvider;
  let TokenContract;
  let TokenContractNonIssuer;

  beforeEach(async () => {
    await deployments.fixture(["CustodianContract", "TokenCreator"]);
    const {
      custodianContractOwner,
      custodian,
      issuer,
      subscriber,
      subscriber2,
      kycProvider,
    } = await getNamedAccounts();
    CustodianContract = await ethers.getContract(
      "CustodianContract",
      custodianContractOwner
    );
    CustodianContractIssuer = await ethers.getContract(
      "CustodianContract",
      issuer
    );
    CustodianContractKycProvider = await ethers.getContract(
      "CustodianContract",
      kycProvider
    );
    await CustodianContract.addIssuer("countryCode", issuer);
    await CustodianContract.addCustodian("countryCode", custodian);
    await CustodianContract.addKycProvider("countryCode", kycProvider);
    CustodianContractIssuer.publishToken({
      ...TOKEN_EXAMPLE,
      issuerPrimaryAddress: issuer,
      custodianPrimaryAddress: custodian,
      kycProviderPrimaryAddress: kycProvider,
    });
    const tokens = await CustodianContract.getTokens(issuer);
    TokenContract = await ethers.getContractAt(
      "Token",
      tokens[0].address_,
      issuer
    );
    TokenContractNonIssuer = await ethers.getContractAt(
      "Token",
      tokens[0].address_,
      custodianContractOwner
    );
    await CustodianContractKycProvider.addWhitelist(tokens[0].address_, [
      subscriber,
      subscriber2,
    ]);
  });

  it("has a version", async () => {
    expect(await TokenContract.VERSION()).to.equal("0.0.1");
  });

  describe("only token owner permissions", async () => {
    it("setMaxSupply", async () => {
      await expect(TokenContractNonIssuer.setMaxSupply(1)).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
      await expect(TokenContract.setMaxSupply(TOKEN_EXAMPLE.maxTotalSupply + 1))
        .not.to.be.reverted;
    });
    it("pause", async () => {
      await expect(TokenContractNonIssuer.pause()).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
      await expect(TokenContract.pause()).not.to.be.reverted;
    });
    it("unpause", async () => {
      await TokenContract.pause();

      await expect(TokenContractNonIssuer.unpause()).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
      await expect(TokenContract.unpause()).not.to.be.reverted;
    });
    it("finalizeIssuance", async () => {
      await expect(
        TokenContractNonIssuer.finalizeIssuance()
      ).to.be.revertedWith("Ownable: caller is not the owner");
      await expect(TokenContract.finalizeIssuance()).not.to.be.reverted;
    });
    it("issue", async () => {
      const { subscriber } = await getNamedAccounts();

      await expect(
        TokenContractNonIssuer.issue(subscriber, 1)
      ).to.be.revertedWith("Ownable: caller is not the owner");
      await expect(TokenContract.issue(subscriber, 1)).not.to.be.reverted;
    });
    it("issueBatch", async () => {
      const { subscriber } = await getNamedAccounts();

      await expect(
        TokenContractNonIssuer.issueBatch([subscriber], [1])
      ).to.be.revertedWith("Ownable: caller is not the owner");
      await expect(TokenContract.issueBatch([subscriber], [1])).not.to.be
        .reverted;
    });
    it("redeem", async () => {
      const { subscriber } = await getNamedAccounts();

      await TokenContract.issue(subscriber, 1);

      await expect(
        TokenContractNonIssuer.redeem(subscriber, 1)
      ).to.be.revertedWith("Ownable: caller is not the owner");
      await expect(TokenContract.redeem(subscriber, 1)).not.to.be.reverted;
    });
    it("redeemBatch", async () => {
      const { subscriber } = await getNamedAccounts();

      await TokenContract.issue(subscriber, 1);

      await expect(
        TokenContractNonIssuer.redeemBatch([subscriber], [1])
      ).to.be.revertedWith("Ownable: caller is not the owner");
      await expect(TokenContract.redeemBatch([subscriber], [1])).not.to.be
        .reverted;
    });
  });

  describe("max total supply", async () => {
    it("initially is set to the value given to the constructor", async () => {
      expect(await TokenContract.maxTotalSupply()).to.be.equal(
        TOKEN_EXAMPLE.maxTotalSupply
      );
    });

    it("fires a SupplyIncreased event when increased", async () => {
      await expect(TokenContract.setMaxSupply(TOKEN_EXAMPLE.maxTotalSupply + 1))
        .to.emit(TokenContract, "SupplyIncreased")
        .withArgs(
          TOKEN_EXAMPLE.maxTotalSupply,
          TOKEN_EXAMPLE.maxTotalSupply + 1
        );
    });

    it("fires a SupplyDecreased event when decreased", async () => {
      await expect(TokenContract.setMaxSupply(TOKEN_EXAMPLE.maxTotalSupply - 1))
        .to.emit(TokenContract, "SupplyDecreased")
        .withArgs(
          TOKEN_EXAMPLE.maxTotalSupply,
          TOKEN_EXAMPLE.maxTotalSupply - 1
        );
    });
  });

  describe("token issue", async () => {
    it("can't issue if it's finalized", async () => {
      const { subscriber } = await getNamedAccounts();

      await TokenContract.finalizeIssuance();

      await expect(TokenContract.issue(subscriber, 1)).to.be.revertedWith(
        "token issuance is finalized"
      );
      await expect(
        TokenContract.issueBatch([subscriber], [1])
      ).to.be.revertedWith("token issuance is finalized");
    });

    it("can't issue if it's paused", async () => {
      const { subscriber } = await getNamedAccounts();

      await TokenContract.pause();

      await expect(TokenContract.issue(subscriber, 1)).to.be.revertedWith(
        "ERC20Pausable: token transfer while paused"
      );
      await expect(
        TokenContract.issueBatch([subscriber], [1])
      ).to.be.revertedWith("ERC20Pausable: token transfer while paused");
    });

    it("can issue if it's unpaused", async () => {
      const { subscriber } = await getNamedAccounts();

      await TokenContract.pause();
      await TokenContract.unpause();

      await expect(TokenContract.issue(subscriber, 1)).not.to.be.reverted;
      await expect(TokenContract.issueBatch([subscriber], [1])).not.to.be
        .reverted;
    });

    it("reverts on wrong batch input", async () => {
      await expect(TokenContract.issueBatch([], [1])).to.be.revertedWith(
        "wrong input"
      );
    });

    it("can't issue more than max total supply", async () => {
      const { subscriber } = await getNamedAccounts();

      await expect(
        TokenContract.issue(subscriber, TOKEN_EXAMPLE.maxTotalSupply + 1)
      ).to.be.revertedWith("can't mint more than max total supply");
      await expect(
        TokenContract.issueBatch(
          [subscriber],
          [TOKEN_EXAMPLE.maxTotalSupply + 1]
        )
      ).to.be.revertedWith("can't mint more than max total supply");
    });

    it("can't issue more than max total supply when many subscribers", async () => {
      const { subscriber, subscriber2 } = await getNamedAccounts();

      await expect(
        TokenContract.issue(subscriber, TOKEN_EXAMPLE.maxTotalSupply)
      ).not.to.be.reverted;

      await expect(TokenContract.issue(subscriber2, 1)).to.be.revertedWith(
        "can't mint more than max total supply"
      );
      await expect(
        TokenContract.issueBatch([subscriber], [1])
      ).to.be.revertedWith("can't mint more than max total supply");
    });

    it("can't issue if canIssue fails on custodian contract", async () => {
      const { nonSubscriber } = await getNamedAccounts();

      await expect(TokenContract.issue(nonSubscriber, 1)).to.be.revertedWith(
        "custodian contract validation fail"
      );
      await expect(
        TokenContract.issueBatch([nonSubscriber], [1])
      ).to.be.revertedWith("custodian contract validation fail");
    });

    it("can issue if subscriber is whitelisted", async () => {
      const { kycProvider, nonSubscriber } = await getNamedAccounts();

      const CustodianContractKycProvider = await ethers.getContract(
        "CustodianContract",
        kycProvider
      );

      await expect(
        CustodianContractKycProvider.addWhitelist(TokenContract.address, [
          nonSubscriber,
        ])
      ).not.to.be.reverted;
      await expect(TokenContract.issue(nonSubscriber, 1)).not.to.be.reverted;
      await expect(TokenContract.issueBatch([nonSubscriber], [1])).not.to.be
        .reverted;
      expect(await TokenContract.balanceOf(nonSubscriber)).to.be.equal(2);
      expect(await TokenContract.totalSupply()).to.be.equal(2);
    });

    it("can't issue if subscriber is removed from the whitelist", async () => {
      const { kycProvider, subscriber } = await getNamedAccounts();

      const CustodianContractKycProvider = await ethers.getContract(
        "CustodianContract",
        kycProvider
      );

      await expect(
        CustodianContractKycProvider.addWhitelist(TokenContract.address, [
          subscriber,
        ])
      ).not.to.be.reverted;
      await expect(TokenContract.issue(subscriber, 1)).not.to.be.reverted;

      await expect(
        CustodianContractKycProvider.removeWhitelist(TokenContract.address, [
          subscriber,
        ])
      ).not.to.be.reverted;
      await expect(TokenContract.issue(subscriber, 1)).to.be.revertedWith(
        "custodian contract validation fail"
      );
      await expect(
        TokenContract.issueBatch([subscriber], [1])
      ).to.be.revertedWith("custodian contract validation fail");
    });
  });

  describe("token redeem", async () => {
    beforeEach(async () => {
      const { subscriber } = await getNamedAccounts();

      await TokenContract.issue(subscriber, 2);
    });

    it(`can't redeem if tokens were not issued`, async () => {
      const { subscriber2 } = await getNamedAccounts();

      await expect(TokenContract.redeem(subscriber2, 1)).to.be.revertedWith(
        "ERC20: burn amount exceeds balance"
      );
      await expect(
        TokenContract.redeemBatch([subscriber2], [1])
      ).to.be.revertedWith("ERC20: burn amount exceeds balance");
    });

    it(`can't redeem more tokens than were issued`, async () => {
      const { subscriber } = await getNamedAccounts();

      await expect(TokenContract.redeem(subscriber, 3)).to.be.revertedWith(
        "ERC20: burn amount exceeds balance"
      );
      await expect(
        TokenContract.redeemBatch([subscriber], [3])
      ).to.be.revertedWith("ERC20: burn amount exceeds balance");
    });

    it("can't redeem if it's paused", async () => {
      const { subscriber } = await getNamedAccounts();

      await TokenContract.pause();

      await expect(TokenContract.redeem(subscriber, 1)).to.be.revertedWith(
        "ERC20Pausable: token transfer while paused"
      );
      await expect(
        TokenContract.redeemBatch([subscriber], [1])
      ).to.be.revertedWith("ERC20Pausable: token transfer while paused");
    });

    it("can redeem if it's unpaused", async () => {
      const { subscriber } = await getNamedAccounts();

      await TokenContract.pause();
      await TokenContract.unpause();

      await expect(TokenContract.redeem(subscriber, 1)).not.to.be.reverted;
      await expect(TokenContract.redeemBatch([subscriber], [1])).not.to.be
        .reverted;
    });

    it("reverts on wrong batch input", async () => {
      await expect(TokenContract.redeemBatch([], [1])).to.be.revertedWith(
        "wrong input"
      );
    });

    it("can't redeem if canIssue fails on custodian contract", async () => {
      const { nonSubscriber } = await getNamedAccounts();

      await expect(TokenContract.redeem(nonSubscriber, 1)).to.be.revertedWith(
        "custodian contract validation fail"
      );
      await expect(
        TokenContract.redeemBatch([nonSubscriber], [1])
      ).to.be.revertedWith("custodian contract validation fail");
    });

    it("can redeem if all conditions are met", async () => {
      const { subscriber } = await getNamedAccounts();

      await expect(TokenContract.redeem(subscriber, 1)).not.to.be.reverted;
      await expect(TokenContract.redeemBatch([subscriber], [1])).not.to.be
        .reverted;
    });

    it("can redeem if it's finalized", async () => {
      const { subscriber } = await getNamedAccounts();

      await TokenContract.finalizeIssuance();

      await expect(TokenContract.redeem(subscriber, 1)).not.to.be.reverted;
      await expect(TokenContract.redeemBatch([subscriber], [1])).not.to.be
        .reverted;
    });
  });
});
