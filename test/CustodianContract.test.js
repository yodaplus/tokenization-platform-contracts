const _ = require("lodash/fp");
const chai = require("chai");
const chaiSnapshot = require("mocha-chai-snapshot");
const { ethers, deployments, getNamedAccounts } = require("hardhat");
const { expect } = chai;

chai.use(chaiSnapshot);

const TOKEN_EXAMPLE = {
  name: "Test Token",
  symbol: "TT1",
  decimals: 18,
  totalSupply: 0,
  value: 1000,
  currency: "USD",
  earlyRedemption: true,
  minSubscription: 1,
};

const normalizeOutput = (output) =>
  output.map((v) => (ethers.BigNumber.isBigNumber(v) ? v.toNumber() : v));

const normalizeArrayOutput = (arrOutput) => arrOutput.map(normalizeOutput);

describe("CustodianContract", function () {
  let CustodianContract;

  beforeEach(async () => {
    await deployments.fixture(["CustodianContract"]);
    const { custodianContractOwner } = await getNamedAccounts();
    CustodianContract = await ethers.getContract(
      "CustodianContract",
      custodianContractOwner
    );
  });

  it("has a version", async () => {
    const CustodianContract = await ethers.getContract("CustodianContract");

    expect(await CustodianContract.VERSION()).to.equal("0.0.1");
  });

  describe("tokens", () => {
    let CustodianContractIssuer;

    beforeEach(async () => {
      const { issuer, custodian } = await getNamedAccounts();
      CustodianContract.addIssuer("lei", "countryCode", issuer);
      CustodianContract.addCustodian("lei", "countryCode", custodian);
      CustodianContractIssuer = await ethers.getContract(
        "CustodianContract",
        issuer
      );
    });

    it(`doesn't allow non-issuers to publish tokens`, async () => {
      const { issuer, custodian } = await getNamedAccounts();

      await expect(
        CustodianContract.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: custodian,
        })
      ).to.be.revertedWith("caller is not an issuer");
    });

    it(`can't publish a token for non-existent issuer`, async () => {
      const { userOfOtherType, custodian } = await getNamedAccounts();

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: userOfOtherType,
          custodianPrimaryAddress: custodian,
        })
      ).to.be.revertedWith("issuer does not exists");
    });

    it(`can't publish a token for non-existent custodian`, async () => {
      const { userOfOtherType, issuer } = await getNamedAccounts();

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: userOfOtherType,
        })
      ).to.be.revertedWith("custodian does not exists");
    });

    it(`can't publish a token with the same name twice`, async () => {
      const { custodian, issuer } = await getNamedAccounts();

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: custodian,
        })
      ).not.to.be.reverted;

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          symbol: "TT2",
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: custodian,
        })
      ).to.be.revertedWith("token with the same name already exists");
    });

    it(`can't publish a token with the same symbol twice`, async () => {
      const { custodian, issuer } = await getNamedAccounts();

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: custodian,
        })
      ).not.to.be.reverted;

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          name: "Test Token 2",
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: custodian,
        })
      ).to.be.revertedWith("token with the same symbol already exists");
    });

    it(`can't publish a token with totalSupply != 0`, async () => {
      const { custodian, issuer } = await getNamedAccounts();

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          totalSupply: 1,
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: custodian,
        })
      ).to.be.revertedWith("totalSupply must be 0");
    });

    it(`can publish a token`, async () => {
      const { custodian, issuer } = await getNamedAccounts();

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: custodian,
        })
      ).not.to.be.reverted;

      const tokens = await CustodianContractIssuer.getTokens(issuer);

      expect(tokens.length).to.be.equal(1);
      expect(tokens.every(({ address_ }) => address_ !== "0x")).to.be.equal(
        true
      );

      expect(normalizeArrayOutput(tokens)).to.matchSnapshot(this);
    });

    it(`sets proper name, symbol and decimals for the published token`, async () => {
      const { custodian, issuer } = await getNamedAccounts();

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: custodian,
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
      const { custodian, issuer } = await getNamedAccounts();

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: custodian,
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
      const { custodian, issuer } = await getNamedAccounts();

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: custodian,
        })
      ).not.to.be.reverted;

      await expect(
        CustodianContractIssuer.publishToken({
          ...TOKEN_EXAMPLE,
          name: "Test Token 2",
          symbol: "TT2",
          issuerPrimaryAddress: issuer,
          custodianPrimaryAddress: custodian,
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
      removeUser,
      isUser,
    }) => {
      it(`doesn't allow non-owners to add ${roleName}`, async () => {
        const { userOfType } = await getNamedAccounts();
        const CustodianContractNonOwner = await ethers.getContract(
          "CustodianContract",
          userOfType
        );

        await expect(
          CustodianContractNonOwner[addUser]("lei", "countryCode", userOfType)
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

        await expect(
          CustodianContract[addUser]("lei", "countryCode", userOfType)
        ).not.to.be.reverted;
        expect(await CustodianContract[isUser](userOfType)).to.be.equal(true);
        expect(await CustodianContract[isUser](userOfOtherType)).to.be.equal(
          false
        );
      });

      it(`can't add ${roleName} with the same id twice`, async () => {
        const { userOfType, userOfOtherType } = await getNamedAccounts();

        await expect(
          CustodianContract[addUser]("lei", "countryCode", userOfType)
        ).not.to.be.reverted;
        await expect(
          CustodianContract[addUser]("lei", "countryCode", userOfType)
        ).to.be.revertedWith("user already exists");
        expect(await CustodianContract[isUser](userOfType)).to.be.equal(true);
        expect(await CustodianContract[isUser](userOfOtherType)).to.be.equal(
          false
        );
      });

      it(`adds ${roleName} addresses successfully`, async () => {
        const { userOfType, userOfType2, userOfOtherType } =
          await getNamedAccounts();

        await expect(
          CustodianContract[addUser]("lei", "countryCode", userOfType)
        ).not.to.be.reverted;
        await expect(
          CustodianContract[addUserAccounts](userOfType, [userOfType2])
        ).not.to.be.reverted;
        expect(await CustodianContract[isUser](userOfType)).to.be.equal(true);
        expect(await CustodianContract[isUser](userOfType2)).to.be.equal(true);
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

        await expect(
          CustodianContract[addUser]("lei", "countryCode", userOfType)
        ).not.to.be.reverted;
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
        const { userOfType, userOfType2 } = await getNamedAccounts();

        await expect(
          CustodianContract[removeUser](userOfType)
        ).to.be.revertedWith("user does not exists");
      });
    };

    describe("issuer", () => {
      createTests({
        roleName: "issuer",
        addUser: "addIssuer",
        addUserAccounts: "addIssuerAccounts",
        removeUser: "removeIssuer",
        isUser: "isIssuer",
      });

      it("can't remove an issuer with tokens", async () => {
        const { issuer, custodian } = await getNamedAccounts();

        const CustodianContractIssuer = await ethers.getContract(
          "CustodianContract",
          issuer
        );

        await expect(CustodianContract.addIssuer("lei", "countryCode", issuer))
          .not.to.be.reverted;
        await expect(
          CustodianContract.addCustodian("lei", "countryCode", custodian)
        ).not.to.be.reverted;
        await expect(
          CustodianContractIssuer.publishToken({
            ...TOKEN_EXAMPLE,
            issuerPrimaryAddress: issuer,
            custodianPrimaryAddress: custodian,
          })
        ).not.to.be.reverted;
        await expect(CustodianContract.removeIssuer(issuer)).to.be.revertedWith(
          "removed issuer must not have tokens"
        );
      });
    });

    describe("custodian", () => {
      createTests({
        roleName: "custodian",
        addUser: "addCustodian",
        addUserAccounts: "addCustodianAccounts",
        removeUser: "removeCustodian",
        isUser: "isCustodian",
      });
    });

    describe("KYC provider", () => {
      createTests({
        roleName: "KYC provider",
        addUser: "addKycProvider",
        addUserAccounts: "addKycProviderAccounts",
        removeUser: "removeKycProvider",
        isUser: "isKycProvider",
      });
    });

    it("can add multiple roles for the same primary address", async () => {
      const { issuer } = await getNamedAccounts();

      await expect(CustodianContract.addIssuer("lei", "countryCode", issuer))
        .not.to.be.reverted;
      await expect(CustodianContract.addCustodian("lei", "countryCode", issuer))
        .not.to.be.reverted;
      await expect(
        CustodianContract.addKycProvider("lei", "countryCode", issuer)
      ).not.to.be.reverted;
      expect(await CustodianContract.isIssuer(issuer)).to.be.equal(true);
      expect(await CustodianContract.isCustodian(issuer)).to.be.equal(true);
      expect(await CustodianContract.isKycProvider(issuer)).to.be.equal(true);
    });
  });
});
