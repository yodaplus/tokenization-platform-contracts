const _ = require("lodash/fp");
const chai = require("chai");
const chaiSnapshot = require("mocha-chai-snapshot");
const { ethers, deployments, getNamedAccounts } = require("hardhat");
const { expect } = chai;
const { TOKEN_EXAMPLE } = require("./utils");
chai.use(chaiSnapshot);

const UNREGISTERED_PAYMENT_TOKEN_ADDRESS =
  "0x0A2B64cACE487A3eAD6C5d3c4F64669092dFE534";

const ONE_MONTH_IN_SECONDS = 30 * 24 * 60 * 60;
const TWO_DAYS_IN_SECONDS = 2 * 24 * 60 * 60;

const moveBlockTimestampBy = async (value) => {
  const { timestamp: currentTimestamp } = await ethers.provider.getBlock(
    await ethers.provider.getBlockNumber()
  );
  await ethers.provider.send("evm_mine", [currentTimestamp + value]);
};

describe("TvT", function () {
  let CustodianContract;
  let CustodianContractIssuer;
  let CustodianContractKycProvider;
  let TokenContract;
  let TokenContractNonIssuer;
  let TokenContractSubscriber;
  let PaymentToken;
  let EscrowManager;
  let EscrowManagerIssuer;
  let EscrowManagerSubscriber;

  beforeEach(async () => {
    await deployments.fixture([
      "CustodianContract",
      "TokenCreator",
      "EscrowManager",
      "PaymentToken",
    ]);
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
    PaymentToken = await ethers.getContract(
      "PaymentToken",
      custodianContractOwner
    );
    await CustodianContract.addIssuer("countryCode", issuer);
    await CustodianContract.addCustodian("countryCode", custodian);
    await CustodianContract.addKycProvider("countryCode", kycProvider);
    await PaymentToken.transfer(subscriber, 1000);
    await CustodianContract.addPaymentToken(PaymentToken.address);
    await CustodianContractIssuer.publishToken({
      ...TOKEN_EXAMPLE,
      name: "Test Token",
      symbol: "TT1",
      paymentTokens: [PaymentToken.address],
      issuanceSwapMultiple: [2],
      redemptionSwapMultiple: [3],
      earlyRedemption: false,
      issuerPrimaryAddress: issuer,
      custodianPrimaryAddress: custodian,
      kycProviderPrimaryAddress: kycProvider,
      collateral: 3,
    });
    const tokens = await CustodianContract.getTokens(issuer);
    TokenContract = await ethers.getContractAt(
      "TokenTvT",
      tokens[0].address_,
      issuer
    );
    TokenContractNonIssuer = await ethers.getContractAt(
      "TokenTvT",
      tokens[0].address_,
      custodianContractOwner
    );
    TokenContractSubscriber = await ethers.getContractAt(
      "TokenTvT",
      tokens[0].address_,
      subscriber
    );
    await CustodianContractKycProvider.addWhitelist(tokens[0].address_, [
      subscriber,
      subscriber2,
    ]);

    EscrowManager = await ethers.getContract(
      "EscrowManager",
      custodianContractOwner
    );
    EscrowManagerIssuer = await ethers.getContract("EscrowManager", issuer);
    EscrowManagerSubscriber = await ethers.getContract(
      "EscrowManager",
      subscriber
    );
  });

  it("cannot publish early redemption TvT token", async () => {
    const { issuer, custodian, kycProvider } = await getNamedAccounts();

    await expect(
      CustodianContractIssuer.publishToken({
        ...TOKEN_EXAMPLE,
        name: "Test Token 2",
        symbol: "TT2",
        paymentTokens: [PaymentToken.address],
        issuanceSwapMultiple: [1],
        redemptionSwapMultiple: [1],
        issuerPrimaryAddress: issuer,
        custodianPrimaryAddress: custodian,
        kycProviderPrimaryAddress: kycProvider,
      })
    ).to.be.revertedWith("early redemption is not allowed for TvT tokens");
  });

  it("cannot publish a token with unapproved payment token", async () => {
    const { issuer, custodian, kycProvider } = await getNamedAccounts();

    await expect(
      CustodianContractIssuer.publishToken({
        ...TOKEN_EXAMPLE,
        name: "Test Token 2",
        symbol: "TT2",
        earlyRedemption: false,
        paymentTokens: [UNREGISTERED_PAYMENT_TOKEN_ADDRESS],
        issuanceSwapMultiple: [1],
        redemptionSwapMultiple: [1],
        issuerPrimaryAddress: issuer,
        custodianPrimaryAddress: custodian,
        kycProviderPrimaryAddress: kycProvider,
      })
    ).to.be.revertedWith("payment token is not active");
  });

  it("cannot publish a token if payment token input is malformed", async () => {
    const { issuer, custodian, kycProvider } = await getNamedAccounts();

    await expect(
      CustodianContractIssuer.publishToken({
        ...TOKEN_EXAMPLE,
        name: "Test Token 2",
        symbol: "TT2",
        paymentTokens: [PaymentToken.address],
        issuanceSwapMultiple: [1],
        redemptionSwapMultiple: [],
        earlyRedemption: false,
        issuerPrimaryAddress: issuer,
        custodianPrimaryAddress: custodian,
        kycProviderPrimaryAddress: kycProvider,
      })
    ).to.be.revertedWith("wrong input");
  });

  it("publishes a TvT token if payment tokens list is not empty", async () => {
    const { issuer, custodian, kycProvider } = await getNamedAccounts();

    await expect(
      CustodianContractIssuer.publishToken({
        ...TOKEN_EXAMPLE,
        name: "Test Token 2",
        symbol: "TT2",
        paymentTokens: [PaymentToken.address],
        issuanceSwapMultiple: [1],
        redemptionSwapMultiple: [1],
        earlyRedemption: false,
        issuerPrimaryAddress: issuer,
        custodianPrimaryAddress: custodian,
        kycProviderPrimaryAddress: kycProvider,
      })
    ).not.to.be.reverted;

    const tokens = await CustodianContract.getTokens(issuer);

    expect(tokens[1].symbol).to.be.equal("TT2");

    const TokenContract1 = await ethers.getContractAt(
      "TokenTvT",
      tokens[1].address_,
      issuer
    );

    expect(await TokenContract1.escrowManager()).to.matchSnapshot(this);
  });

  it("publishes a regular token if payment tokens list is empty", async () => {
    const { issuer, custodian, kycProvider } = await getNamedAccounts();

    await expect(
      CustodianContractIssuer.publishToken({
        ...TOKEN_EXAMPLE,
        name: "Test Token 2",
        symbol: "TT2",
        paymentTokens: [],
        issuanceSwapMultiple: [],
        redemptionSwapMultiple: [],
        earlyRedemption: false,
        issuerPrimaryAddress: issuer,
        custodianPrimaryAddress: custodian,
        kycProviderPrimaryAddress: kycProvider,
      })
    ).not.to.be.reverted;

    const tokens = await CustodianContract.getTokens(issuer);

    expect(tokens[1].symbol).to.be.equal("TT2");

    const TokenContract1 = await ethers.getContractAt(
      "TokenTvT",
      tokens[1].address_,
      issuer
    );

    let failed = false;
    try {
      await TokenContract1.escrowManager();
    } catch {
      failed = true;
    }

    expect(failed).to.be.equal(true);
  });

  describe("EscrowManager", async () => {
    it("lets any accounts to deposit collateral to any balance", async () => {
      const { issuer, subscriber } = await getNamedAccounts();

      let EscrowManager = await ethers.getContract("EscrowManager", issuer);

      await expect(
        EscrowManager.depositCollateral(issuer, {
          value: 1,
        })
      ).not.to.be.reverted;

      expect(await EscrowManager.collateralBalance(issuer)).to.be.equal(1);

      EscrowManager = await ethers.getContract("EscrowManager", subscriber);

      await expect(
        EscrowManager.depositCollateral(issuer, {
          value: 1,
        })
      ).not.to.be.reverted;

      expect(await EscrowManager.collateralBalance(issuer)).to.be.equal(2);
    });

    it("lets collateral owners withdraw their non-locked balance", async () => {
      const { issuer, subscriber } = await getNamedAccounts();

      let EscrowManager = await ethers.getContract("EscrowManager", issuer);

      await expect(
        EscrowManager.depositCollateral(issuer, {
          value: 2,
        })
      ).not.to.be.reverted;

      expect(await EscrowManager.collateralBalance(issuer)).to.be.equal(2);

      await expect(EscrowManager.withdrawCollateral(1)).not.to.be.reverted;

      expect(await EscrowManager.collateralBalance(issuer)).to.be.equal(1);

      EscrowManager = await ethers.getContract("EscrowManager", subscriber);

      await expect(EscrowManager.withdrawCollateral(1)).to.be.revertedWith(
        "Insufficient funds"
      );
    });
  });

  describe("TvT token", async () => {
    const prepareIssuanceSwap = async () => {
      const { issuer, subscriber } = await getNamedAccounts();

      await TokenContract.issue(subscriber, 1);
      await EscrowManagerIssuer.depositCollateral(issuer, {
        value: 3,
      });
      const PaymentTokenSubscriber = await ethers.getContract(
        "PaymentToken",
        subscriber
      );
      await PaymentTokenSubscriber.approve(EscrowManager.address, 2);
    };

    const prepareRedemptionSwap = async (orderId) => {
      await prepareIssuanceSwap();

      await EscrowManager.swapIssuance(orderId);

      await moveBlockTimestampBy(ONE_MONTH_IN_SECONDS);

      const { issuer, subscriber } = await getNamedAccounts();

      await TokenContractSubscriber.redeem(subscriber, 1);

      const PaymentTokenIssuer = await ethers.getContract(
        "PaymentToken",
        issuer
      );

      await PaymentTokenIssuer.approve(EscrowManager.address, 3);
    };

    it("has escrowManager set properly on creation", async () => {
      expect(await TokenContract.escrowManager()).to.matchSnapshot(this);
    });

    describe("issuance", async () => {
      it("only allows issuers to start issuance", async () => {
        const { issuer, subscriber } = await getNamedAccounts();

        await expect(
          TokenContractSubscriber.issue(subscriber, 1)
        ).to.be.revertedWith("caller is not issuer");

        await expect(
          TokenContractSubscriber.issueBatch([subscriber], [1])
        ).to.be.revertedWith("caller is not issuer");

        await expect(TokenContract.issue(subscriber, 1)).not.to.be.reverted;
        await expect(TokenContract.issueBatch([subscriber], [1])).not.to.be
          .reverted;
      });

      it("mints requested amount of tokens for the issuer", async () => {
        const { issuer, subscriber } = await getNamedAccounts();

        await TokenContract.issue(subscriber, 1);

        expect(await TokenContract.balanceOf(issuer)).to.be.equal(1);
      });

      it("gives escrow manager allowance for minted tokens", async () => {
        const { issuer, subscriber } = await getNamedAccounts();

        const escrowManager = await TokenContract.escrowManager();

        await TokenContract.issue(subscriber, 1);

        expect(
          await TokenContract.allowance(issuer, escrowManager)
        ).to.be.equal(1);
      });

      it("creates an escrow order with properly calculated parameters", async () => {
        const { issuer, subscriber } = await getNamedAccounts();

        await expect(TokenContract.issue(subscriber, 1))
          .to.emit(TokenContract, "IssuanceEscrowInitiated")
          .withArgs(
            [
              TokenContract.address,
              1,
              issuer,
              PaymentToken.address,
              2,
              subscriber,
              3,
              172800,
            ],
            0
          );
      });

      describe("EscrowManager", async () => {
        it("only allows token contracts to start issuance escrow", async () => {
          const { issuer, subscriber } = await getNamedAccounts();
          const escrowOrder = [
            TokenContract.address,
            1,
            issuer,
            PaymentToken.address,
            2,
            subscriber,
            3,
            172800,
          ];

          await expect(
            EscrowManager.startIssuanceEscrow(escrowOrder)
          ).to.be.revertedWith("access error");

          await expect(
            EscrowManagerIssuer.startIssuanceEscrow(escrowOrder)
          ).to.be.revertedWith("access error");

          await expect(
            EscrowManagerSubscriber.startIssuanceEscrow(escrowOrder)
          ).to.be.revertedWith("access error");
        });

        it("checks escrow order status according to necessary conditions", async () => {
          const { issuer, subscriber } = await getNamedAccounts();

          await TokenContract.issue(subscriber, 1);

          expect(
            await EscrowManager.checkIssuanceEscrowConditionsIssuer(0)
          ).to.be.equal(false);

          await EscrowManagerIssuer.depositCollateral(issuer, {
            value: 2,
          });

          expect(
            await EscrowManager.checkIssuanceEscrowConditionsIssuer(0)
          ).to.be.equal(false);

          await EscrowManagerIssuer.depositCollateral(issuer, {
            value: 1,
          });

          expect(
            await EscrowManager.checkIssuanceEscrowConditionsIssuer(0)
          ).to.be.equal(true);

          expect(
            await EscrowManager.checkIssuanceEscrowConditions(0)
          ).to.be.equal(false);

          expect(
            await EscrowManager.checkIssuanceEscrowConditionsInvestor(0)
          ).to.be.equal(false);

          const PaymentTokenSubscriber = await ethers.getContract(
            "PaymentToken",
            subscriber
          );

          await PaymentTokenSubscriber.approve(EscrowManager.address, 2);

          expect(
            await EscrowManager.checkIssuanceEscrowConditionsInvestor(0)
          ).to.be.equal(true);

          expect(
            await EscrowManager.checkIssuanceEscrowConditions(0)
          ).to.be.equal(true);
        });

        it("cannot swap the order if escrow conditions are not met", async () => {
          const { subscriber } = await getNamedAccounts();

          await TokenContract.issue(subscriber, 1);

          await expect(EscrowManagerIssuer.swapIssuance(0)).to.be.revertedWith(
            "escrow conditions are not met"
          );
        });

        describe("success", async () => {
          beforeEach(async () => {
            await prepareIssuanceSwap();
          });

          it("allows any account to trigger the swap", async () => {
            await expect(EscrowManagerIssuer.swapIssuance(0)).not.to.be
              .reverted;

            await prepareIssuanceSwap();
            await expect(EscrowManager.swapIssuance(1)).not.to.be.reverted;

            await prepareIssuanceSwap();
            await expect(EscrowManagerSubscriber.swapIssuance(2)).not.to.be
              .reverted;
          });

          it("on success: swaps tokens", async () => {
            const { issuer, subscriber } = await getNamedAccounts();

            await expect(EscrowManagerIssuer.swapIssuance(0)).not.to.be
              .reverted;

            expect(await PaymentToken.balanceOf(issuer)).to.be.equal(2);
            expect(await PaymentToken.balanceOf(subscriber)).to.be.equal(998);
            expect(await TokenContract.balanceOf(issuer)).to.be.equal(0);
            expect(await TokenContract.balanceOf(subscriber)).to.be.equal(1);
          });

          it("on success: locks collateral", async () => {
            const { issuer, subscriber } = await getNamedAccounts();

            await expect(EscrowManagerIssuer.swapIssuance(0)).not.to.be
              .reverted;

            expect(await EscrowManager.collateralBalance(issuer)).to.be.equal(
              0
            );

            expect(
              await EscrowManager.lockedCollateralBalance(issuer)
            ).to.be.equal(3);
          });

          it("on success: sets maturity balance", async () => {
            const { issuer, subscriber } = await getNamedAccounts();

            await expect(EscrowManagerIssuer.swapIssuance(0)).not.to.be
              .reverted;

            expect(await TokenContract.matureBalance(subscriber)).to.be.equal(
              0
            );

            expect(
              await TokenContract.matureBalancePending(subscriber)
            ).to.be.equal(1);
          });

          it("cannot swap the order that was already swapped", async () => {
            await expect(EscrowManagerIssuer.swapIssuance(0)).not.to.be
              .reverted;

            await expect(
              EscrowManagerIssuer.swapIssuance(0)
            ).to.be.revertedWith("escrow is completed");
          });
        });
      });
    });

    describe("redemption", async () => {
      beforeEach(async () => {
        await prepareIssuanceSwap();
        await EscrowManagerIssuer.swapIssuance(0);
      });

      it("allows any token holders to redeem their tokens", async () => {
        const { issuer, subscriber } = await getNamedAccounts();

        await expect(TokenContract.redeem(subscriber, 1)).to.be.revertedWith(
          "only token owners can redeem"
        );

        await expect(TokenContract.redeem(issuer, 1))
          .to.emit(TokenContract, "RedeemFailed")
          .withArgs(issuer, 1, "0x52");

        expect(await TokenContract.matureBalance(subscriber)).to.be.equal(0);

        await expect(TokenContractSubscriber.redeem(subscriber, 1))
          .to.emit(TokenContract, "RedeemFailed")
          .withArgs(subscriber, 1, "0x52");
      });

      it("can only redeem matured tokens", async () => {
        const { subscriber } = await getNamedAccounts();

        await expect(TokenContractSubscriber.redeem(subscriber, 1))
          .to.emit(TokenContract, "RedeemFailed")
          .withArgs(subscriber, 1, "0x52");

        await moveBlockTimestampBy(ONE_MONTH_IN_SECONDS);

        expect(await TokenContract.matureBalance(subscriber)).to.be.equal(1);

        await expect(TokenContractSubscriber.redeem(subscriber, 1)).to.emit(
          TokenContract,
          "RedemptionEscrowInitiated"
        );
      });

      it("gives escrow manager allowance for the tokens", async () => {
        const { subscriber } = await getNamedAccounts();

        await moveBlockTimestampBy(ONE_MONTH_IN_SECONDS);

        await TokenContractSubscriber.redeem(subscriber, 1);

        const escrowManager = await TokenContract.escrowManager();

        expect(
          await TokenContract.allowance(subscriber, escrowManager)
        ).to.be.equal(1);
      });

      it("creates an escrow order with properly calculated parameters", async () => {
        const { issuer, subscriber } = await getNamedAccounts();

        await moveBlockTimestampBy(ONE_MONTH_IN_SECONDS);

        await expect(TokenContractSubscriber.redeem(subscriber, 1))
          .to.emit(TokenContract, "RedemptionEscrowInitiated")
          .withArgs(
            [
              TokenContract.address,
              1,
              issuer,
              PaymentToken.address,
              3,
              subscriber,
              3,
              172800,
            ],
            1
          );
      });

      describe("EscrowManager", async () => {
        beforeEach(async () => {
          const { issuer } = await getNamedAccounts();

          await moveBlockTimestampBy(ONE_MONTH_IN_SECONDS);

          await PaymentToken.transfer(issuer, 1000);
        });

        it("only allows token contracts to start redemption escrow", async () => {
          const { issuer, subscriber } = await getNamedAccounts();
          const escrowOrder = [
            TokenContract.address,
            1,
            issuer,
            PaymentToken.address,
            3,
            subscriber,
            3,
            172800,
          ];

          await expect(
            EscrowManager.startRedemptionEscrow(escrowOrder)
          ).to.be.revertedWith("access error");

          await expect(
            EscrowManagerIssuer.startRedemptionEscrow(escrowOrder)
          ).to.be.revertedWith("access error");

          await expect(
            EscrowManagerSubscriber.startRedemptionEscrow(escrowOrder)
          ).to.be.revertedWith("access error");
        });

        it("checks escrow order status according to necessary conditions", async () => {
          const { issuer, subscriber } = await getNamedAccounts();

          await TokenContractSubscriber.redeem(subscriber, 1);

          expect(
            await EscrowManager.checkRedemptionEscrowConditionsInvestor(1)
          ).to.be.equal(true);

          expect(
            await EscrowManager.checkRedemptionEscrowConditionsIssuer(1)
          ).to.be.equal(false);

          const PaymentTokenIssuer = await ethers.getContract(
            "PaymentToken",
            issuer
          );

          await PaymentTokenIssuer.approve(EscrowManager.address, 3);

          expect(
            await EscrowManager.checkRedemptionEscrowConditionsIssuer(1)
          ).to.be.equal(true);
        });

        it("cannot swap the order if conditions are not met before expiry", async () => {
          const { subscriber } = await getNamedAccounts();

          await TokenContractSubscriber.redeem(subscriber, 1);

          await expect(
            EscrowManagerIssuer.swapRedemption(1)
          ).to.be.revertedWith(
            "full escrow conditions are not met before expiry"
          );
        });

        it("cannot swap the order if investor conditions are not met after expiry", async () => {
          const { subscriber } = await getNamedAccounts();

          await TokenContractSubscriber.redeem(subscriber, 1);

          await TokenContractSubscriber.approve(EscrowManager.address, 0);
          await moveBlockTimestampBy(TWO_DAYS_IN_SECONDS);

          expect(
            await TokenContractSubscriber.allowance(
              subscriber,
              EscrowManager.address
            )
          ).to.be.equal(0);

          expect(
            await EscrowManagerIssuer.checkRedemptionEscrowConditionsInvestor(1)
          ).to.be.equal(false);
          await expect(
            EscrowManagerIssuer.swapRedemption(1)
          ).to.be.revertedWith(
            "escrow expired, but investor conditions are not met"
          );
        });

        it("swaps the order if conditions are met before expiry", async () => {
          await prepareRedemptionSwap(1);

          await expect(EscrowManagerIssuer.swapRedemption(2)).not.to.be
            .reverted;
        });

        it("swaps the order if conditions are met after expiry", async () => {
          await prepareRedemptionSwap(1);

          await moveBlockTimestampBy(TWO_DAYS_IN_SECONDS);

          await expect(EscrowManagerIssuer.swapRedemption(2)).not.to.be
            .reverted;
        });

        describe("success", async () => {
          beforeEach(async () => {
            await prepareRedemptionSwap(1);
          });

          it("allows any account to trigger the swap", async () => {
            await moveBlockTimestampBy(TWO_DAYS_IN_SECONDS);
            await expect(EscrowManagerIssuer.swapRedemption(2)).not.to.be
              .reverted;

            await prepareRedemptionSwap(3);
            await moveBlockTimestampBy(TWO_DAYS_IN_SECONDS);
            await expect(EscrowManager.swapRedemption(4)).not.to.be.reverted;

            await prepareRedemptionSwap(5);
            await moveBlockTimestampBy(TWO_DAYS_IN_SECONDS);
            await expect(EscrowManagerSubscriber.swapRedemption(6)).not.to.be
              .reverted;
          });

          it("on success: swaps tokens", async () => {
            const { issuer, subscriber } = await getNamedAccounts();

            await moveBlockTimestampBy(TWO_DAYS_IN_SECONDS);
            await EscrowManagerIssuer.swapRedemption(2);

            expect(await PaymentToken.balanceOf(issuer)).to.be.equal(1001); // 1000 + 2 + 2 - 3
            expect(await PaymentToken.balanceOf(subscriber)).to.be.equal(999); // 1000 - 2 - 2 + 3
            expect(await TokenContract.balanceOf(issuer)).to.be.equal(1);
            expect(await TokenContract.balanceOf(subscriber)).to.be.equal(1);
          });

          it("on success: unlocks collateral", async () => {
            const { issuer } = await getNamedAccounts();

            await moveBlockTimestampBy(TWO_DAYS_IN_SECONDS);
            await EscrowManagerIssuer.swapRedemption(2);

            expect(
              await EscrowManagerIssuer.collateralBalance(issuer)
            ).to.be.equal(3);
          });

          it("on partial success: transfers trade tokens to the issuer and collateral to the investor", async () => {
            const { issuer, subscriber } = await getNamedAccounts();

            const PaymentTokenIssuer = await ethers.getContract(
              "PaymentToken",
              issuer
            );

            await PaymentTokenIssuer.approve(EscrowManager.address, 0);

            expect(
              await EscrowManager.checkRedemptionEscrowConditionsIssuer(2)
            ).to.be.equal(false);

            const subscriberXdcBalanceBefore = await ethers.provider.getBalance(
              subscriber
            );

            expect(
              await EscrowManagerIssuer.lockedCollateralBalance(issuer)
            ).to.be.equal(6);

            await moveBlockTimestampBy(TWO_DAYS_IN_SECONDS);
            await EscrowManagerIssuer.swapRedemption(2);

            const subscriberXdcBalanceAfter = await ethers.provider.getBalance(
              subscriber
            );

            expect(
              await EscrowManagerIssuer.lockedCollateralBalance(issuer)
            ).to.be.equal(3);

            expect(await TokenContract.balanceOf(issuer)).to.be.equal(1);
            expect(
              subscriberXdcBalanceAfter
                .sub(subscriberXdcBalanceBefore)
                .toNumber()
            ).to.be.equal(3);
          });

          it("on any success: decreases maturity balance", async () => {
            const { issuer, subscriber } = await getNamedAccounts();

            expect(await TokenContract.matureBalance(subscriber)).to.be.equal(
              2
            );

            await moveBlockTimestampBy(TWO_DAYS_IN_SECONDS);
            await EscrowManagerIssuer.swapRedemption(2);

            expect(await TokenContract.matureBalance(subscriber)).to.be.equal(
              1
            );
          });
        });
      });
    });
  });
});
