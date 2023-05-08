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

describe("CustodianContract", function () {
  let CustodianContract;
  // let amount;
  // let TokenomicsContract;
  beforeEach(async () => {
    await deployments.fixture(["CustodianContract", "TokenCreator"]);
    const { custodianContractOwner } = await getNamedAccounts();
    CustodianContract = await ethers.getContract(
      "CustodianContract",
      custodianContractOwner
    );

    // TokenomicsContract = await ethers.getContract(
    //   "Tokenomics",
    //   custodianContractOwner
    // )
    // amount = TokenomicsContract.getPerTokenFee();
  });

  it("has a version", async () => {
    expect(await CustodianContract.VERSION()).to.equal("0.0.1");
  });

  describe("tokens", () => {
    let CustodianContractIssuer;
    // let CustodianContractKycProvider;

    beforeEach(async () => {
      const { issuer, insurer } = await getNamedAccounts();
      await CustodianContract.addIssuer("countryCode", issuer);
      // await CustodianContract.addKycProvider("countryCode", kycProvider);
      await CustodianContract.addInsurer("countryCode", insurer);
      CustodianContractIssuer = await ethers.getContract(
        "CustodianContract",
        issuer
      );
      /*  CustodianContractKycProvider = await ethers.getContract(
        "CustodianContract",
        kycProvider
      ); */
    });

    describe("whitelisting", () => {
      let tokenAddress;

      beforeEach(async () => {
        const { issuer, insurer } = await getNamedAccounts();
        await expect(
          CustodianContractIssuer.publishToken({
            ...TOKEN_EXAMPLE,
            issuerPrimaryAddress: issuer,
            // kycProviderPrimaryAddress: kycProvider,
            insurerPrimaryAddress: insurer,
            issuerSettlementAddress: issuer,
          },
          { 
            value:100
          }
          )
        ).not.to.be.reverted;

        const tokens = await CustodianContractIssuer.getTokens(issuer);

        tokenAddress = tokens[0].address_;
      });

      it("only issuers can add/remove whitelisted addresses", async () => {
        const { subscriber } = await getNamedAccounts();

        await expect(
          CustodianContractIssuer.addWhitelist(tokenAddress, [subscriber])
        ).not.to.be.reverted;

        // await expect(
        //   CustodianContractKycProvider.addWhitelist(tokenAddress, [subscriber])
        // ).not.to.be.reverted;

        await expect(
          CustodianContract.addWhitelist(tokenAddress, [subscriber])
        ).to.be.revertedWith("caller is not allowed");

        await expect(
          CustodianContractIssuer.removeWhitelist(tokenAddress, [subscriber])
        ).not.to.be.reverted;

        // await expect(
        //   CustodianContractKycProvider.removeWhitelist(tokenAddress, [
        //     subscriber,
        //   ])
        // ).not.to.be.reverted;

        await expect(
          CustodianContract.removeWhitelist(tokenAddress, [subscriber])
        ).to.be.revertedWith("caller is not allowed");
      });

      it("cannot whitelist for non-existent tokens", async () => {
        const { subscriber } = await getNamedAccounts();

        await expect(
          CustodianContractIssuer.addWhitelist(subscriber, [subscriber])
        ).to.be.revertedWith("token does not exist");

        await expect(
          CustodianContractIssuer.removeWhitelist(subscriber, [subscriber])
        ).to.be.revertedWith("token does not exist");
      });

      it("cannot whitelist for paused tokens", async () => {
        const { issuer, subscriber } = await getNamedAccounts();

        const TokenContract = await ethers.getContractAt(
          "Token",
          tokenAddress,
          issuer
        );

        await TokenContract.pause();

        await expect(
          CustodianContractIssuer.addWhitelist(tokenAddress, [subscriber])
        ).to.be.revertedWith("token is paused");

        await expect(
          CustodianContractIssuer.removeWhitelist(tokenAddress, [subscriber])
        ).to.be.revertedWith("token is paused");
      });

      it("can whitelist if token is unpaused", async () => {
        const { issuer, subscriber } = await getNamedAccounts();

        const TokenContract = await ethers.getContractAt(
          "Token",
          tokenAddress,
          issuer
        );

        await TokenContract.pause();
        await TokenContract.unpause();

        await expect(
          CustodianContractIssuer.addWhitelist(tokenAddress, [subscriber])
        ).not.to.be.reverted;

        await expect(
          CustodianContractIssuer.removeWhitelist(tokenAddress, [subscriber])
        ).not.to.be.reverted;
      });
    });
    describe("issuer whitelisting", () => {
      let tokenAddress;

      beforeEach(async () => {
        const { issuer, insurer } = await getNamedAccounts();
        
        await expect(
          CustodianContractIssuer.publishToken({
            ...TOKEN_EXAMPLE,
            issuerPrimaryAddress: issuer,
            // kycProviderPrimaryAddress: kycProvider,
            insurerPrimaryAddress: insurer,
            issuerSettlementAddress: issuer,
          },
          {
            value: 100
          })
        ).not.to.be.reverted;

        const tokens = await CustodianContractIssuer.getTokens(issuer);

        tokenAddress = tokens[0].address_;
      });

      it("only issuers  can add/remove whitelisted addresses", async () => {
        const { subscriber, issuer } = await getNamedAccounts();

        await expect(
          CustodianContractIssuer.addIssuerWhitelist(issuer, [subscriber])
        ).not.to.be.reverted;

        await expect(
          CustodianContract.addIssuerWhitelist(issuer, [subscriber])
        ).to.be.revertedWith("caller is not allowed");

        await expect(
          CustodianContractIssuer.removeIssuerWhitelist(issuer, [subscriber])
        ).not.to.be.reverted;

        await expect(
          CustodianContract.removeIssuerWhitelist(issuer, [subscriber])
        ).to.be.revertedWith("caller is not allowed");
      });
    });

    it(`doesn't allow non-issuers to publish tokens`, async () => {
      const { issuer, insurer } = await getNamedAccounts();
      
      await expect(
        CustodianContract.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: issuer,
          // kycProviderPrimaryAddress: kycProvider,
          insurerPrimaryAddress: insurer,
          issuerSettlementAddress: issuer,
        },
        {
            value: 100
          })
      ).to.be.revertedWith("caller is not allowed");
    });

    it(`can't publish a token for non-existent issuer`, async () => {
      const { userOfOtherType, insurer, issuer } = await getNamedAccounts();
      
      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: userOfOtherType,
          // kycProviderPrimaryAddress: kycProvider,
          insurerPrimaryAddress: insurer,
          issuerSettlementAddress: issuer,
        },{
            value: 100
          })
      ).to.be.revertedWith("issuer does not exists");
    });

    // it(`can't publish a token for non-existent KYC provider`, async () => {
    //   const { issuer, userOfOtherType, insurer } = await getNamedAccounts();

    //   await expect(
    //     CustodianContractIssuer.publishToken({
    //       ...TOKEN_EXAMPLE,
    //       issuerPrimaryAddress: issuer,
    //       kycProviderPrimaryAddress: userOfOtherType,
    //       insurerPrimaryAddress: insurer,
    //       issuerSettlementAddress: issuer,
    //     })
    //   ).to.be.revertedWith("kyc provider does not exists");
    // });

    it(`can't publish a token with the same name twice`, async () => {
      const { issuer, insurer } = await getNamedAccounts();
      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: issuer,
          // kycProviderPrimaryAddress: kycProvider,
          insurerPrimaryAddress: insurer,
          issuerSettlementAddress: issuer,
        },
        {
            value: 100
          })
      );

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          symbol: "TT2",
          issuerPrimaryAddress: issuer,
          // kycProviderPrimaryAddress: kycProvider,
          insurerPrimaryAddress: insurer,
          issuerSettlementAddress: issuer,
        },
        {
            value: 100
          }
        )
      ).to.be.revertedWith("token with the same name already exists");
    });

    it(`can't publish a token with the same symbol twice`, async () => {
      const { issuer, insurer } = await getNamedAccounts();
      
      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: issuer,
          // kycProviderPrimaryAddress: kycProvider,
          insurerPrimaryAddress: insurer,
          issuerSettlementAddress: issuer,
        },
        {
            value: 100
          })
      ).not.to.be.reverted;

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          name: "Test Token 2",
          issuerPrimaryAddress: issuer,
          // kycProviderPrimaryAddress: kycProvider,
          insurerPrimaryAddress: insurer,
          issuerSettlementAddress: issuer,
        },
        {
            value: 100
          })
      ).to.be.revertedWith("token with the same symbol already exists");
    });

    it(`can publish a token`, async () => {
      const { issuer, insurer } = await getNamedAccounts();
      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,

          issuerPrimaryAddress: issuer,
          // kycProviderPrimaryAddress: kycProvider,
          insurerPrimaryAddress: insurer,
          issuerSettlementAddress: issuer,

          tokenType: 0,
        },
        {
            value: 100
          })
      ).not.to.be.reverted;

      const tokens = await CustodianContractIssuer.getTokens(issuer);

      expect(tokens.length).to.be.equal(1);
      expect(tokens.every(({ address_ }) => address_ !== "0x")).to.be.equal(
        true
      );
      expect(normalizeArrayOutput(tokens)).to.matchSnapshot(this);
    });

    it(`emits TokenPublished(...) event on token publish`, async () => {
      const { issuer, insurer } = await getNamedAccounts();
      const publishTokenHandler = await CustodianContractIssuer.publishToken({
        ...TOKEN_EXAMPLE,
        issuerPrimaryAddress: issuer,
        // kycProviderPrimaryAddress: kycProvider,
        insurerPrimaryAddress: insurer,
        issuerSettlementAddress: issuer,
      },
      {
        value: 100
      });

      const tokens = await CustodianContractIssuer.getTokens(issuer);

      await expect(publishTokenHandler)
        .to.emit(CustodianContractIssuer, "TokenPublished")
        .withArgs(TOKEN_EXAMPLE.symbol, tokens[0].address_);
    });

    it(`sets proper name, symbol and decimals for the published token`, async () => {
      const { issuer, insurer } = await getNamedAccounts();
      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: issuer,
          // kycProviderPrimaryAddress: kycProvider,
          insurerPrimaryAddress: insurer,
          issuerSettlementAddress: issuer,
        },
      {
        value: 100
      })
      ).not.to.be.reverted;

      const tokens = await CustodianContractIssuer.getTokens(issuer);
      expect(tokens.length).to.be.equal(1);

      const TokenContract = await ethers.getContractAt(
        "Token",
        tokens[0].address_
      );

      expect(await TokenContract.symbol()).to.be.equal(TOKEN_EXAMPLE.symbol);
      expect(await TokenContract.name()).to.be.equal(TOKEN_EXAMPLE.name);
      expect(await TokenContract.decimals()).to.be.equal(0);
    });

    it(`sets proper owner for the published token`, async () => {
      const { issuer, insurer } = await getNamedAccounts();
      
      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: issuer,
          // kycProviderPrimaryAddress: kycProvider,
          insurerPrimaryAddress: insurer,
          issuerSettlementAddress: issuer,
        },
      {
        value: 100
      })
      ).not.to.be.reverted;

      const tokens = await CustodianContractIssuer.getTokens(issuer);

      const TokenContract = await ethers.getContractAt(
        "Token",
        tokens[0].address_
      );

      expect(await TokenContract.owner()).to.be.equal(issuer);
    });

    it(`can publish different tokens with unique symbol and name`, async () => {
      const { issuer, insurer } = await getNamedAccounts();
      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: issuer,
          // kycProviderPrimaryAddress: kycProvider,
          insurerPrimaryAddress: insurer,
          issuerSettlementAddress: issuer,
        },
      {
        value: 100
      })
      ).not.to.be.reverted;

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          name: "Test Token 2",
          symbol: "TT2",
          issuerPrimaryAddress: issuer,
          // kycProviderPrimaryAddress: kycProvider,
          insurerPrimaryAddress: insurer,
          issuerSettlementAddress: issuer,
        },
      {
        value: 100
      })
      ).not.to.be.reverted;

      const tokens = await CustodianContractIssuer.getTokens(issuer);

      expect(tokens.length).to.be.equal(2);
      expect(tokens[0].name).to.be.equal(TOKEN_EXAMPLE.name);
      expect(tokens[1].name).to.be.equal("Test Token 2");
      expect(tokens[0].address_).not.to.be.equal(tokens[1].address_);
    });
  });
  describe("paymentToken", () => {
    it("can set payment token", async () => {
      const { issuer, custodianContractOwner } = await getNamedAccounts();
      const CustodianContract = await ethers.getContract(
        "CustodianContract",
        custodianContractOwner
      );
      const PaymentToken = await ethers.getContract(
        "PaymentToken",
        custodianContractOwner
      );
      await expect(CustodianContract.addPaymentToken(PaymentToken.address))
        .to.emit(CustodianContract, "PaymentTokenAdded")
        .withArgs(PaymentToken.address);
    });
  });
  describe("roles CRUD", () => {
    const createTests = ({
      roleName,
      addUser,
      addUserAccounts,
      removeUserAccounts,
      removeUser,
      isUser,
      userAddressName,
    }) => {
      it(`doesn't allow non-owners to add ${roleName}`, async () => {
        const { userOfType } = await getNamedAccounts();
        const CustodianContractNonOwner = await ethers.getContract(
          "CustodianContract",
          userOfType
        );

        await expect(
          CustodianContractNonOwner[addUser]("countryCode", userOfType)
        ).to.be.revertedWith("Ownable: caller is not the owner");
      });

      it(`doesn't allow non-owners and non-primary-${roleName}s to add ${roleName} addresses`, async () => {
        const { userOfType, userOfType2 } = await getNamedAccounts();
        const CustodianContractNonOwner = await ethers.getContract(
          "CustodianContract",
          userOfType
        );
        const CustodianContractNonOwner2 = await ethers.getContract(
          "CustodianContract",
          userOfType2
        );

        await expect(
          CustodianContractNonOwner[addUserAccounts](userOfType, [userOfType2])
        ).to.be.revertedWith("caller is not allowed");

        await expect(
          CustodianContractNonOwner2[addUserAccounts](userOfType, [userOfType2])
        ).to.be.revertedWith("caller is not allowed");
      });

      it(`doesn't allow primary ${roleName}s to add ${roleName} addresses for other primary ${roleName}s`, async () => {
        const { userOfType, userOfType2, userOfOtherType } =
          await getNamedAccounts();
        const CustodianContractPrimary1 = await ethers.getContract(
          "CustodianContract",
          userOfType
        );
        const CustodianContractPrimary2 = await ethers.getContract(
          "CustodianContract",
          userOfType2
        );

        await expect(CustodianContract[addUser]("countryCode", userOfType)).not
          .to.be.reverted;
        await expect(CustodianContract[addUser]("countryCode", userOfType2)).not
          .to.be.reverted;

        await expect(
          CustodianContractPrimary1[addUserAccounts](userOfType2, [
            userOfOtherType,
          ])
        ).to.be.revertedWith("caller is not allowed");

        await expect(
          CustodianContractPrimary2[addUserAccounts](userOfType, [
            userOfOtherType,
          ])
        ).to.be.revertedWith("caller is not allowed");
      });

      it(`doesn't allow non-owners and non-primary-${roleName}s to remove ${roleName} addresses`, async () => {
        const { userOfType, userOfOtherType, userOfType2 } =
          await getNamedAccounts();
        const CustodianContractNonOwner = await ethers.getContract(
          "CustodianContract",
          userOfOtherType
        );
        const CustodianContractNonOwner2 = await ethers.getContract(
          "CustodianContract",
          userOfType2
        );

        await expect(CustodianContract[addUser]("countryCode", userOfType)).not
          .to.be.reverted;
        await expect(
          CustodianContract[addUserAccounts](userOfType, [userOfType2])
        ).not.to.be.reverted;

        await expect(
          CustodianContractNonOwner[removeUserAccounts](userOfType, [
            userOfType2,
          ])
        ).to.be.revertedWith("caller is not allowed");

        await expect(
          CustodianContractNonOwner2[removeUserAccounts](userOfType, [
            userOfType2,
          ])
        ).to.be.revertedWith("caller is not allowed");
      });

      it(`doesn't allow primary ${roleName}s to remove ${roleName} addresses for other primary ${roleName}s`, async () => {
        const { userOfType, userOfType2, userOfOtherType } =
          await getNamedAccounts();
        const CustodianContractPrimary1 = await ethers.getContract(
          "CustodianContract",
          userOfType
        );
        const CustodianContractPrimary2 = await ethers.getContract(
          "CustodianContract",
          userOfType2
        );

        await expect(CustodianContract[addUser]("countryCode", userOfType)).not
          .to.be.reverted;
        await expect(CustodianContract[addUser]("countryCode", userOfType2)).not
          .to.be.reverted;

        await expect(
          CustodianContractPrimary1[addUserAccounts](userOfType, [
            userOfOtherType,
          ])
        ).not.to.be.reverted;

        await expect(
          CustodianContractPrimary2[addUserAccounts](userOfType2, [
            userOfOtherType,
          ])
        ).not.to.be.reverted;

        await expect(
          CustodianContractPrimary1[removeUserAccounts](userOfType2, [
            userOfOtherType,
          ])
        ).to.be.revertedWith("caller is not allowed");

        await expect(
          CustodianContractPrimary2[removeUserAccounts](userOfType, [
            userOfOtherType,
          ])
        ).to.be.revertedWith("caller is not allowed");
      });

      it(`doesn't allow non-owners to remove ${roleName}`, async () => {
        const { userOfType } = await getNamedAccounts();
        const CustodianContractNonOwner = await ethers.getContract(
          "CustodianContract",
          userOfType
        );

        await expect(
          CustodianContractNonOwner[removeUser](userOfType)
        ).to.be.revertedWith("Ownable: caller is not the owner");
      });

      it(`adds ${roleName} successfully`, async () => {
        const { userOfType, userOfOtherType } = await getNamedAccounts();

        await expect(CustodianContract[addUser]("countryCode", userOfType)).not
          .to.be.reverted;
        expect(await CustodianContract[isUser](userOfType)).to.be.equal(true);
        expect(await CustodianContract[isUser](userOfOtherType)).to.be.equal(
          false
        );
      });

      it(`can't add ${roleName} with the same id twice`, async () => {
        const { userOfType, userOfOtherType } = await getNamedAccounts();

        await expect(CustodianContract[addUser]("countryCode", userOfType)).not
          .to.be.reverted;
        await expect(
          CustodianContract[addUser]("countryCode", userOfType)
        ).to.be.revertedWith("user already exists");
        expect(await CustodianContract[isUser](userOfType)).to.be.equal(true);
        expect(await CustodianContract[isUser](userOfOtherType)).to.be.equal(
          false
        );
      });

      it(`adds ${roleName} addresses successfully, if sender is owner`, async () => {
        const { userOfType, userOfType2, userOfOtherType } =
          await getNamedAccounts();

        await expect(CustodianContract[addUser]("countryCode", userOfType)).not
          .to.be.reverted;
        await expect(
          CustodianContract[addUserAccounts](userOfType, [userOfType2])
        ).not.to.be.reverted;
        expect(await CustodianContract[isUser](userOfType)).to.be.equal(true);
        expect(await CustodianContract[isUser](userOfType2)).to.be.equal(true);
        expect(await CustodianContract[isUser](userOfOtherType)).to.be.equal(
          false
        );
      });

      it(`adds ${roleName} addresses successfully, if sender is primary ${roleName} and adding for themselves`, async () => {
        const { userOfType, userOfType2, userOfOtherType } =
          await getNamedAccounts();

        await expect(CustodianContract[addUser]("countryCode", userOfType)).not
          .to.be.reverted;

        const CustodianContractPrimaryUser = await ethers.getContract(
          "CustodianContract",
          userOfType
        );

        await expect(
          CustodianContractPrimaryUser[addUserAccounts](userOfType, [
            userOfType2,
          ])
        ).not.to.be.reverted;

        expect(await CustodianContract[isUser](userOfType)).to.be.equal(true);
        expect(await CustodianContract[isUser](userOfType2)).to.be.equal(true);
        expect(await CustodianContract[isUser](userOfOtherType)).to.be.equal(
          false
        );
      });

      it(`removes ${roleName} addresses successfully, if sender is owner`, async () => {
        const { userOfType, userOfType2, userOfOtherType } =
          await getNamedAccounts();

        await expect(CustodianContract[addUser]("countryCode", userOfType)).not
          .to.be.reverted;
        await expect(
          CustodianContract[addUserAccounts](userOfType, [userOfType2])
        ).not.to.be.reverted;
        await expect(
          CustodianContract[removeUserAccounts](userOfType, [userOfType2])
        ).not.to.be.reverted;
        expect(await CustodianContract[isUser](userOfType)).to.be.equal(true);
        expect(await CustodianContract[isUser](userOfType2)).to.be.equal(false);
        expect(await CustodianContract[isUser](userOfOtherType)).to.be.equal(
          false
        );
      });

      it(`removes ${roleName} addresses successfully, if sender is primary ${roleName} and removing for themselves`, async () => {
        const { userOfType, userOfType2, userOfOtherType } =
          await getNamedAccounts();

        await expect(CustodianContract[addUser]("countryCode", userOfType)).not
          .to.be.reverted;
        await expect(
          CustodianContract[addUserAccounts](userOfType, [userOfType2])
        ).not.to.be.reverted;

        const CustodianContractPrimaryUser = await ethers.getContract(
          "CustodianContract",
          userOfType
        );

        await expect(
          CustodianContractPrimaryUser[removeUserAccounts](userOfType, [
            userOfType2,
          ])
        ).not.to.be.reverted;
        expect(await CustodianContract[isUser](userOfType)).to.be.equal(true);
        expect(await CustodianContract[isUser](userOfType2)).to.be.equal(false);
        expect(await CustodianContract[isUser](userOfOtherType)).to.be.equal(
          false
        );
      });

      it(`can't add addresses to non-existent ${roleName}`, async () => {
        const { userOfType, userOfType2 } = await getNamedAccounts();

        await expect(
          CustodianContract[addUserAccounts](userOfType, [userOfType2])
        ).to.be.revertedWith("user does not exist");
      });

      it(`removes ${roleName} successfully`, async () => {
        const { userOfType, userOfType2, userOfOtherType } =
          await getNamedAccounts();

        await expect(CustodianContract[addUser]("countryCode", userOfType)).not
          .to.be.reverted;
        await expect(
          CustodianContract[addUserAccounts](userOfType, [userOfType2])
        ).not.to.be.reverted;
        await expect(CustodianContract[removeUser](userOfType)).not.to.be
          .reverted;
        expect(await CustodianContract[isUser](userOfType)).to.be.equal(false);
        expect(await CustodianContract[isUser](userOfType2)).to.be.equal(false);
        expect(await CustodianContract[isUser](userOfOtherType)).to.be.equal(
          false
        );
      });

      it(`can't remove non-existent ${roleName}`, async () => {
        const { userOfType } = await getNamedAccounts();

        await expect(
          CustodianContract[removeUser](userOfType)
        ).to.be.revertedWith("user does not exist");
      });

      it(`can't remove ${roleName} with tokens`, async () => {
        const namedAccounts = await getNamedAccounts();
        const { issuer, insurer } = namedAccounts;
        
        const CustodianContractIssuer = await ethers.getContract(
          "CustodianContract",
          issuer
        );

        await expect(CustodianContract.addIssuer("countryCode", issuer)).not.to
          .be.reverted;
        /*    await expect(
          CustodianContract.addKycProvider("countryCode", kycProvider)
        ).not.to.be.reverted; */
        await expect(CustodianContract.addInsurer("countryCode", insurer)).not
          .to.be.reverted;
        await expect(
          CustodianContractIssuer.publishToken({
            ...TOKEN_EXAMPLE,
            issuerPrimaryAddress: issuer,
            // kycProviderPrimaryAddress: kycProvider,
            insurerPrimaryAddress: insurer,
            issuerSettlementAddress: issuer,
          },
          {
            value: 100
          })
        ).not.to.be.reverted;
        await expect(
          CustodianContract[removeUser](namedAccounts[userAddressName])
        ).to.be.revertedWith(`removed ${roleName} must not have tokens`);
      });
    };

    describe("issuer", () => {
      createTests({
        roleName: "issuer",
        addUser: "addIssuer",
        addUserAccounts: "addIssuerAccounts",
        removeUserAccounts: "removeIssuerAccounts",
        removeUser: "removeIssuer",
        isUser: "isIssuer",
        userAddressName: "issuer",
      });
    });

    /*   describe("KYC provider", async () => {
      createTests({
        roleName: "KYC provider",
        addUser: "addKycProvider",
        addUserAccounts: "addKycProviderAccounts",
        removeUserAccounts: "removeKycProviderAccounts",
        removeUser: "removeKycProvider",
        isUser: "isKycProvider",
        userAddressName: "kycProvider",
      });
    }); */
    describe("insurer", async () => {
      createTests({
        roleName: "insurer",
        addUser: "addInsurer",
        removeUser: "removeInsurer",
        isUser: "isInsurer",
        userAddressName: "insurer",
        addUserAccounts: "addInsurerAccounts",
        removeUserAccounts: "removeInsurerAccounts",
      });
    });

    it("can add multiple roles for the same primary address", async () => {
      const { issuer } = await getNamedAccounts();

      await expect(CustodianContract.addIssuer("countryCode", issuer)).not.to.be
        .reverted;
      /*    await expect(CustodianContract.addKycProvider("countryCode", issuer)).not
        .to.be.reverted; */
      await expect(CustodianContract.addInsurer("countryCode", issuer)).not.to;
      expect(await CustodianContract.isIssuer(issuer)).to.be.equal(true);
      /* expect(await CustodianContract.isKycProvider(issuer)).to.be.equal(true); */
      expect(await CustodianContract.isInsurer(issuer)).to.be.equal(true);
    });
  });
  describe("liquidity pool", () => {
    it("can add liquidity pool", async () => {
      const { issuer, custodianContractOwner } = await getNamedAccounts();
      const CustodianContract = await ethers.getContract(
        "CustodianContract",
        custodianContractOwner
      );
      await expect(CustodianContract.addLiqudityPool(issuer, issuer))
        .to.emit(CustodianContract, "AddLiquidityPool")
        .withArgs(issuer, issuer);
    });
    it("can remove liquidity pool", async () => {
      const { issuer, custodianContractOwner } = await getNamedAccounts();
      const CustodianContract = await ethers.getContract(
        "CustodianContract",
        custodianContractOwner
      );
      await expect(CustodianContract.addLiqudityPool(issuer, issuer))
        .to.emit(CustodianContract, "AddLiquidityPool")
        .withArgs(issuer, issuer);
      await expect(CustodianContract.removeLiquidityPool(issuer))
        .to.emit(CustodianContract, "RemoveLiquidityPool")
        .withArgs(issuer);
    });
  });
  //describe("KYC", () => {
  //  let CustodianContractIssuer;
  //  let PaymentToken;

  //   beforeEach(async () => {
  //     const {
  //       issuer,
  //    kycProvider,
  //       custodianContractOwner,
  //       subscriber,
  //       insurer,
  //     } = await getNamedAccounts();
  //     await CustodianContract.addIssuer("countryCode", issuer);
  //        await CustodianContract.addKycProvider("countryCode", kycProvider);
  //     await CustodianContract.addInsurer("countryCode", insurer);
  //     CustodianContractIssuer = await ethers.getContract(
  //       "CustodianContract",
  //       issuer
  //     );
  //     PaymentToken = await ethers.getContract(
  //       "PaymentToken",
  //       custodianContractOwner
  //     );
  //     await PaymentToken.transfer(subscriber, 1000);
  //     await CustodianContract.addPaymentToken(PaymentToken.address);
  //   });
  //   it("should issue if kyc is disabled for token", async () => {
  //     const { issuer, subscriber, insurer } = await getNamedAccounts();

  //     await CustodianContractIssuer.publishToken({
  //       ...TOKEN_EXAMPLE,
  //       paymentTokens: [PaymentToken.address],
  //       issuanceSwapMultiple: [2],
  //       redemptionSwapMultiple: [3],
  //       earlyRedemption: false,
  //       issuerPrimaryAddress: issuer,
  //        kycProviderPrimaryAddress: kycProvider,
  //       insurerPrimaryAddress: insurer,
  //       issuerSettlementAddress: issuer,

  //       onChainKyc: false,
  //       countries: [],
  //       investorClassifications: {
  //         isExempted: false,
  //         isAccredited: false,
  //         isAffiliated: false,
  //       },
  //       useIssuerWhitelist: false,
  //     });
  //     const tokens = await CustodianContractIssuer.getTokens(issuer);

  //     const tokenAddress = tokens[0].address_;
  //     await CustodianContractIssuer.addWhitelist(tokenAddress, [subscriber]);
  //     const TokenTvT = await ethers.getContractAt(
  //       "TokenTvT",
  //       tokenAddress,
  //       issuer
  //     );
  //     await expect(TokenTvT["issue(address,uint256,uint256)"](subscriber, 2, 0))
  //       .not.to.be.reverted;
  //   });
  // });
  describe("TransferRestrictions", () => {
    let CustodianContractIssuer;
    let PaymentToken;

    beforeEach(async () => {
      const { issuer, custodianContractOwner, subscriber, insurer } =
        await getNamedAccounts();
      await CustodianContract.addIssuer("countryCode", issuer);
      /*  await CustodianContract.addKycProvider("countryCode", kycProvider); */
      await CustodianContract.addInsurer("countryCode", insurer);
      CustodianContractIssuer = await ethers.getContract(
        "CustodianContract",
        issuer
      );
      PaymentToken = await ethers.getContract(
        "PaymentToken",
        custodianContractOwner
      );
      await PaymentToken.transfer(subscriber, 1000);
      await CustodianContract.addPaymentToken(PaymentToken.address);
    });
    it("can't issue if issuer not in allowed countries", async () => {
      const { issuer, subscriber, insurer } = await getNamedAccounts();
      
      await CustodianContractIssuer.publishToken({
        ...TOKEN_EXAMPLE,
        paymentTokens: [PaymentToken.address],
        issuanceSwapMultiple: [2],
        redemptionSwapMultiple: [3],
        earlyRedemption: false,
        issuerPrimaryAddress: issuer,
        // kycProviderPrimaryAddress: kycProvider,
        insurerPrimaryAddress: insurer,
        issuerSettlementAddress: issuer,
      },
      {
        value: 100
      });
      const tokens = await CustodianContractIssuer.getTokens(issuer);

      const tokenAddress = tokens[0].address_;

      await CustodianContractIssuer.updateKyc(issuer, subscriber, {
        ...KYC_DATA,
        countryCode: stringToBytes32("PAK"),
      });
      const TokenTvT = await ethers.getContractAt(
        "TokenTvT",
        tokenAddress,
        issuer
      );
      await expect(
        TokenTvT["issue(address,uint256,uint256)"](subscriber, 2, 0)
      ).to.be.revertedWith("country is not allowed");
    });
    it("issue if issuer in allowed countries", async () => {
      const { issuer, subscriber, insurer } = await getNamedAccounts();
      await CustodianContractIssuer.publishToken({
        ...TOKEN_EXAMPLE,
        paymentTokens: [PaymentToken.address],
        issuanceSwapMultiple: [2],
        redemptionSwapMultiple: [3],
        earlyRedemption: false,
        issuerPrimaryAddress: issuer,
        // kycProviderPrimaryAddress: kycProvider,
        insurerPrimaryAddress: insurer,
        issuerSettlementAddress: issuer,
      },
      {
        value: 100
      });
      const tokens = await CustodianContractIssuer.getTokens(issuer);

      const tokenAddress = tokens[0].address_;

      await CustodianContractIssuer.updateKyc(issuer, subscriber, {
        ...KYC_DATA,
        countryCode: stringToBytes32("IND"),
      });
      await CustodianContractIssuer.addWhitelist(tokenAddress, [subscriber]);
      const TokenTvT = await ethers.getContractAt(
        "TokenTvT",
        tokenAddress,
        issuer
      );
      await expect(TokenTvT["issue(address,uint256,uint256)"](subscriber, 2, 0))
        .not.to.be.reverted;
    });
    it("should not issue if kyc is complete", async () => {
      const { issuer, subscriber, insurer } = await getNamedAccounts();
      await CustodianContractIssuer.publishToken({
        ...TOKEN_EXAMPLE,
        paymentTokens: [PaymentToken.address],
        issuanceSwapMultiple: [2],
        redemptionSwapMultiple: [3],
        earlyRedemption: false,
        issuerPrimaryAddress: issuer,
        // kycProviderPrimaryAddress: kycProvider,
        insurerPrimaryAddress: insurer,
        issuerSettlementAddress: issuer,
      },
      {
        value: 100
      });
      const tokens = await CustodianContractIssuer.getTokens(issuer);

      const tokenAddress = tokens[0].address_;

      await CustodianContractIssuer.addWhitelist(tokenAddress, [subscriber]);
      const TokenTvT = await ethers.getContractAt(
        "TokenTvT",
        tokenAddress,
        issuer
      );
      await expect(
        TokenTvT["issue(address,uint256,uint256)"](subscriber, 2, 0)
      ).to.be.revertedWith("KYC is incomplete");
    });
    it("should revert if investor is not isAccredited else issue", async () => {
      const { issuer, subscriber, insurer } = await getNamedAccounts();
      await CustodianContractIssuer.publishToken({
        ...TOKEN_EXAMPLE,
        paymentTokens: [PaymentToken.address],
        issuanceSwapMultiple: [2],
        redemptionSwapMultiple: [3],
        earlyRedemption: false,
        issuerPrimaryAddress: issuer,
        // kycProviderPrimaryAddress: kycProvider,
        insurerPrimaryAddress: insurer,
        issuerSettlementAddress: issuer,

        investorClassifications: {
          isExempted: false,
          isAccredited: true,
          isAffiliated: false,
        },
      },
      {
        value: 100
      });
      const tokens = await CustodianContractIssuer.getTokens(issuer);

      const tokenAddress = tokens[0].address_;
      await CustodianContractIssuer.updateKyc(issuer, subscriber, {
        ...KYC_DATA,
        kycStatus: false,
      });
      await CustodianContractIssuer.addWhitelist(tokenAddress, [subscriber]);
      const TokenTvT = await ethers.getContractAt(
        "TokenTvT",
        tokenAddress,
        issuer
      );
      await expect(
        TokenTvT["issue(address,uint256,uint256)"](subscriber, 2, 0)
      ).to.be.revertedWith("KYC is incomplete");
      await CustodianContractIssuer.updateKyc(issuer, subscriber, {
        ...KYC_DATA,
        kycStatus: true,
      });
      await expect(TokenTvT["issue(address,uint256,uint256)"](subscriber, 2, 0))
        .not.to.be.reverted;
    });
    it("should revert if investor is not isExempted else issue", async () => {
      const { issuer, subscriber, insurer } = await getNamedAccounts();
      await CustodianContractIssuer.publishToken({
        ...TOKEN_EXAMPLE,
        paymentTokens: [PaymentToken.address],
        issuanceSwapMultiple: [2],
        redemptionSwapMultiple: [3],
        earlyRedemption: false,
        issuerPrimaryAddress: issuer,
        // kycProviderPrimaryAddress: kycProvider,
        insurerPrimaryAddress: insurer,
        issuerSettlementAddress: issuer,

        investorClassifications: {
          isExempted: true,
          isAccredited: false,
          isAffiliated: false,
        },
      },
      {
        value: 100
      });
      const tokens = await CustodianContractIssuer.getTokens(issuer);

      const tokenAddress = tokens[0].address_;
      await CustodianContractIssuer.updateKyc(issuer, subscriber, {
        ...KYC_DATA,
        kycStatus: false,
      });
      await CustodianContractIssuer.addWhitelist(tokenAddress, [subscriber]);
      const TokenTvT = await ethers.getContractAt(
        "TokenTvT",
        tokenAddress,
        issuer
      );
      await expect(
        TokenTvT["issue(address,uint256,uint256)"](subscriber, 2, 0)
      ).to.be.revertedWith("KYC is incomplete");
      await CustodianContractIssuer.updateKyc(issuer, subscriber, {
        ...KYC_DATA,
        kycStatus: true,
      });
      await expect(TokenTvT["issue(address,uint256,uint256)"](subscriber, 2, 0))
        .not.to.be.reverted;
    });
    it("should revert if investor is not isAffiliated else issue", async () => {
      const { issuer, subscriber, insurer } = await getNamedAccounts();
      await CustodianContractIssuer.publishToken({
        ...TOKEN_EXAMPLE,
        paymentTokens: [PaymentToken.address],
        issuanceSwapMultiple: [2],
        redemptionSwapMultiple: [3],
        earlyRedemption: false,
        issuerPrimaryAddress: issuer,
        // kycProviderPrimaryAddress: kycProvider,
        insurerPrimaryAddress: insurer,
        issuerSettlementAddress: issuer,

        investorClassifications: {
          isExempted: false,
          isAccredited: false,
          isAffiliated: true,
        },
      },
      {
        value: 100
      });
      const tokens = await CustodianContractIssuer.getTokens(issuer);

      const tokenAddress = tokens[0].address_;
      await CustodianContractIssuer.updateKyc(issuer, subscriber, {
        ...KYC_DATA,
        kycStatus: false,
      });
      await CustodianContractIssuer.addWhitelist(tokenAddress, [subscriber]);
      const TokenTvT = await ethers.getContractAt(
        "TokenTvT",
        tokenAddress,
        issuer
      );
      await expect(
        TokenTvT["issue(address,uint256,uint256)"](subscriber, 2, 0)
      ).to.be.revertedWith("KYC is incomplete");
      await CustodianContractIssuer.updateKyc(issuer, subscriber, {
        ...KYC_DATA,
        kycStatus: true,
      });
      await expect(TokenTvT["issue(address,uint256,uint256)"](subscriber, 2, 0))
        .not.to.be.reverted;
    });
    it("should not issue if investor not in issuer whitelist", async () => {
      const { issuer, subscriber, insurer } = await getNamedAccounts();
      
      await CustodianContractIssuer.publishToken({
        ...TOKEN_EXAMPLE,
        paymentTokens: [PaymentToken.address],
        issuanceSwapMultiple: [2],
        redemptionSwapMultiple: [3],
        earlyRedemption: false,
        issuerPrimaryAddress: issuer,
        // kycProviderPrimaryAddress: kycProvider,
        insurerPrimaryAddress: insurer,
        issuerSettlementAddress: issuer,

        useIssuerWhitelist: true,
      },
      {
        value: 100
      });
      const tokens = await CustodianContractIssuer.getTokens(issuer);

      const tokenAddress = tokens[0].address_;
      await CustodianContractIssuer.updateKyc(issuer, subscriber, {
        ...KYC_DATA,
      });
      const TokenTvT = await ethers.getContractAt(
        "TokenTvT",
        tokenAddress,
        issuer
      );
      await expect(
        TokenTvT["issue(address,uint256,uint256)"](subscriber, 2, 0)
      ).to.be.revertedWith("custodian contract validation fail");
    });
    it("should issue if investor in issuer whitelist", async () => {
      const { issuer, subscriber, kycProvider } = await getNamedAccounts();
      await CustodianContractIssuer.publishToken({
        ...TOKEN_EXAMPLE,
        paymentTokens: [PaymentToken.address],
        issuanceSwapMultiple: [2],
        redemptionSwapMultiple: [3],
        earlyRedemption: false,
        issuerPrimaryAddress: issuer,
        // kycProviderPrimaryAddress: kycProvider,
        useIssuerWhitelist: true,
        issuerSettlementAddress: issuer,
      },
      {
        value: 100
      });
      const tokens = await CustodianContractIssuer.getTokens(issuer);

      const tokenAddress = tokens[0].address_;
      await CustodianContractIssuer.updateKyc(issuer, subscriber, {
        ...KYC_DATA,
      });
      await CustodianContractIssuer.addIssuerWhitelist(issuer, [subscriber]);
      const TokenTvT = await ethers.getContractAt(
        "TokenTvT",
        tokenAddress,
        issuer
      );
      await expect(TokenTvT["issue(address,uint256,uint256)"](subscriber, 2, 0))
        .not.to.be.reverted;
    });
  });
});
