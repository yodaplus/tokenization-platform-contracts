const _ = require("lodash/fp");
const chai = require("chai");
const chaiSnapshot = require("mocha-chai-snapshot");
const { ethers, deployments, getNamedAccounts } = require("hardhat");
const { expect } = chai;
const { TOKEN_EXAMPLE } = require("./utils");
chai.use(chaiSnapshot);

const normalizeOutput = (output) =>
  output.map((v) => (ethers.BigNumber.isBigNumber(v) ? v.toNumber() : v));

const normalizeArrayOutput = (arrOutput) => arrOutput.map(normalizeOutput);

describe("CustodianContract", function () {
  let CustodianContract;
  let TokenCreator;

  beforeEach(async () => {
    await deployments.fixture(["CustodianContract"]);
    const { custodianContractOwner } = await getNamedAccounts();
    CustodianContract = await ethers.getContract(
      "CustodianContract",
      custodianContractOwner
    );
  });

  it("has a version", async () => {
    expect(await CustodianContract.VERSION()).to.equal("0.0.1");
  });

  describe("token creator", () => {
    beforeEach(async () => {
      await deployments.fixture(["TokenCreator"]);
      const { custodianContractOwner } = await getNamedAccounts();
      TokenCreator = await ethers.getContract(
        "TokenCreator",
        custodianContractOwner
      );
      console.log(TokenCreator.address);
      expect(
        await CustodianContract.setTokenCreatorAddress(TokenCreator.address)
      );
    });
    it("has a token creator contract", async () => {
      expect(await CustodianContract.TokenCreatorAddr()).to.equal(
        TokenCreator.address
      );
    });
  });

  describe("tokens", () => {
    let CustodianContractIssuer;
    let TokenCreatorIssuer;

    beforeEach(async () => {
      const { issuer, custodian, kycProvider } = await getNamedAccounts();
      await CustodianContract.addIssuer("countryCode", issuer);
      await CustodianContract.addCustodian("countryCode", custodian);
      await CustodianContract.addKycProvider("countryCode", kycProvider);
      CustodianContractIssuer = await ethers.getContract(
        "CustodianContract",
        issuer
      );
      TokenCreatorIssuer = await ethers.getContract("TokenCreator", issuer);
      await CustodianContractIssuer.setTokenCreatorAddress(
        TokenCreatorIssuer.address
      );
      await CustodianContract.setTokenCreatorAddress(TokenCreator.address);
    });

    it("has a token creator address", async () => {
      console.log(await CustodianContract.TokenCreatorAddr());
      console.log(TokenCreator.address);
      expect(await CustodianContract.TokenCreatorAddr()).to.equal(
        TokenCreator.address
      );
    });

    it(`doesn't allow non-issuers to publish tokens`, async () => {
      const { issuer, custodian, kycProvider } = await getNamedAccounts();

      await expect(
        CustodianContract.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: custodian,
          kycProviderPrimaryAddress: kycProvider,
        })
      ).to.be.revertedWith("caller is not allowed");
    });

    it(`can't publish a token for non-existent issuer`, async () => {
      const { userOfOtherType, custodian, kycProvider } =
        await getNamedAccounts();

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: userOfOtherType,
          custodianPrimaryAddress: custodian,
          kycProviderPrimaryAddress: kycProvider,
        })
      ).to.be.revertedWith("issuer does not exists");
    });

    it(`can't publish a token for non-existent custodian`, async () => {
      const { userOfOtherType, issuer, kycProvider } = await getNamedAccounts();

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: userOfOtherType,
          kycProviderPrimaryAddress: kycProvider,
        })
      ).to.be.revertedWith("custodian does not exists");
    });

    it(`can't publish a token for non-existent KYC provider`, async () => {
      const { custodian, issuer, userOfOtherType } = await getNamedAccounts();

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: custodian,
          kycProviderPrimaryAddress: userOfOtherType,
        })
      ).to.be.revertedWith("kyc provider does not exists");
    });

    it(`can't publish a token with the same name twice`, async () => {
      const { custodian, issuer, kycProvider } = await getNamedAccounts();

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: custodian,
          kycProviderPrimaryAddress: kycProvider,
        })
      );

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          symbol: "TT2",
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: custodian,
          kycProviderPrimaryAddress: kycProvider,
        })
      ).to.be.revertedWith("token with the same name already exists");
    });

    it(`can't publish a token with the same symbol twice`, async () => {
      const { custodian, issuer, kycProvider } = await getNamedAccounts();

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: custodian,
          kycProviderPrimaryAddress: kycProvider,
        })
      ).not.to.be.reverted;

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          name: "Test Token 2",
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: custodian,
          kycProviderPrimaryAddress: kycProvider,
        })
      ).to.be.revertedWith("token with the same symbol already exists");
    });

    it(`can publish a token`, async () => {
      const { custodian, issuer, kycProvider } = await getNamedAccounts();

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: custodian,
          kycProviderPrimaryAddress: kycProvider,
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
      const { custodian, issuer, kycProvider } = await getNamedAccounts();

      const publishTokenHandler = await CustodianContractIssuer.publishToken({
        ...TOKEN_EXAMPLE,
        issuerPrimaryAddress: issuer,
        custodianPrimaryAddress: custodian,
        kycProviderPrimaryAddress: kycProvider,
      });

      const tokens = await CustodianContractIssuer.getTokens(issuer);

      await expect(publishTokenHandler)
        .to.emit(CustodianContractIssuer, "TokenPublished")
        .withArgs(TOKEN_EXAMPLE.symbol, tokens[0].address_);
    });

    it(`sets proper name, symbol and decimals for the published token`, async () => {
      const { custodian, issuer, kycProvider } = await getNamedAccounts();

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: custodian,
          kycProviderPrimaryAddress: kycProvider,
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
      expect(await TokenContract.decimals()).to.be.equal(
        TOKEN_EXAMPLE.decimals
      );
    });

    it(`sets proper owner for the published token`, async () => {
      const { custodian, issuer, kycProvider } = await getNamedAccounts();

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: custodian,
          kycProviderPrimaryAddress: kycProvider,
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
      const { custodian, issuer, kycProvider } = await getNamedAccounts();

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: custodian,
          kycProviderPrimaryAddress: kycProvider,
        })
      ).not.to.be.reverted;

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          name: "Test Token 2",
          symbol: "TT2",
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: custodian,
          kycProviderPrimaryAddress: kycProvider,
        })
      ).not.to.be.reverted;

      const tokens = await CustodianContractIssuer.getTokens(issuer);

      expect(tokens.length).to.be.equal(2);
      expect(tokens[0].name).to.be.equal(TOKEN_EXAMPLE.name);
      expect(tokens[1].name).to.be.equal("Test Token 2");
      expect(tokens[0].address_).not.to.be.equal(tokens[1].address_);
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

      it(`doesn't allow non-owners to add ${roleName} addresses`, async () => {
        const { userOfType, userOfType2 } = await getNamedAccounts();
        const CustodianContractNonOwner = await ethers.getContract(
          "CustodianContract",
          userOfType
        );

        await expect(
          CustodianContractNonOwner[addUserAccounts](userOfType, [userOfType2])
        ).to.be.revertedWith("Ownable: caller is not the owner");
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

      it(`adds ${roleName} addresses successfully`, async () => {
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

      it(`removes ${roleName} addresses successfully`, async () => {
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

      it(`can't add addresses to non-existent ${roleName}`, async () => {
        const { userOfType, userOfType2 } = await getNamedAccounts();

        await expect(
          CustodianContract[addUserAccounts](userOfType, [userOfType2])
        ).to.be.revertedWith("user does not exists");
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
        ).to.be.revertedWith("user does not exists");
      });

      it(`can't remove ${roleName} with tokens`, async () => {
        const namedAccounts = await getNamedAccounts();
        const { issuer, custodian, kycProvider } = namedAccounts;

        const CustodianContractIssuer = await ethers.getContract(
          "CustodianContract",
          issuer
        );

        await expect(CustodianContract.addIssuer("countryCode", issuer)).not.to
          .be.reverted;
        await expect(CustodianContract.addCustodian("countryCode", custodian))
          .not.to.be.reverted;
        await expect(
          CustodianContract.addKycProvider("countryCode", kycProvider)
        ).not.to.be.reverted;
        await expect(
          CustodianContractIssuer.publishToken({
            ...TOKEN_EXAMPLE,
            issuerPrimaryAddress: issuer,
            custodianPrimaryAddress: custodian,
            kycProviderPrimaryAddress: kycProvider,
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

    describe("custodian", () => {
      createTests({
        roleName: "custodian",
        addUser: "addCustodian",
        addUserAccounts: "addCustodianAccounts",
        removeUserAccounts: "removeCustodianAccounts",
        removeUser: "removeCustodian",
        isUser: "isCustodian",
        userAddressName: "custodian",
      });
    });

    describe("KYC provider", async () => {
      createTests({
        roleName: "KYC provider",
        addUser: "addKycProvider",
        addUserAccounts: "addKycProviderAccounts",
        removeUserAccounts: "removeKycProviderAccounts",
        removeUser: "removeKycProvider",
        isUser: "isKycProvider",
        userAddressName: "kycProvider",
      });
    });

    it("can add multiple roles for the same primary address", async () => {
      const { issuer } = await getNamedAccounts();

      await expect(CustodianContract.addIssuer("countryCode", issuer)).not.to.be
        .reverted;
      await expect(CustodianContract.addCustodian("countryCode", issuer)).not.to
        .be.reverted;
      await expect(CustodianContract.addKycProvider("countryCode", issuer)).not
        .to.be.reverted;
      expect(await CustodianContract.isIssuer(issuer)).to.be.equal(true);
      expect(await CustodianContract.isCustodian(issuer)).to.be.equal(true);
      expect(await CustodianContract.isKycProvider(issuer)).to.be.equal(true);
    });
  });
});
