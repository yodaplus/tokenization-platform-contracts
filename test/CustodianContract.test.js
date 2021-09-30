const { expect } = require("chai");
const { ethers, deployments, getNamedAccounts } = require("hardhat");

describe("CustodianContract", () => {
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

  describe("entities CRUD", () => {
    const createTests = ({
      entityName,
      addUser,
      addUserAccounts,
      removeUser,
      isUser,
    }) => {
      describe(`${entityName}`, () => {
        it(`doesn't allow non-owners to add ${entityName}`, async () => {
          const { userOfType } = await getNamedAccounts();
          const CustodianContractNonOwner = await ethers.getContract(
            "CustodianContract",
            userOfType
          );

          await expect(
            CustodianContractNonOwner[addUser](
              1,
              "lei",
              "countryCode",
              userOfType
            )
          ).to.be.revertedWith("Ownable: caller is not the owner");
        });

        it(`doesn't allow non-owners to add ${entityName} addresses`, async () => {
          const { userOfType, userOfType2 } = await getNamedAccounts();
          const CustodianContractNonOwner = await ethers.getContract(
            "CustodianContract",
            userOfType
          );

          await expect(
            CustodianContractNonOwner[addUserAccounts](1, [userOfType2])
          ).to.be.revertedWith("Ownable: caller is not the owner");
        });

        it(`doesn't allow non-owners to remove ${entityName}`, async () => {
          const { userOfType } = await getNamedAccounts();
          const CustodianContractNonOwner = await ethers.getContract(
            "CustodianContract",
            userOfType
          );

          await expect(
            CustodianContractNonOwner[removeUser](1)
          ).to.be.revertedWith("Ownable: caller is not the owner");
        });

        it(`adds ${entityName} successfully`, async () => {
          const { userOfType, userOfOtherType } = await getNamedAccounts();

          await expect(
            CustodianContract[addUser](1, "lei", "countryCode", userOfType)
          ).not.to.be.reverted;
          expect(await CustodianContract[isUser](userOfType)).to.be.equal(true);
          expect(await CustodianContract[isUser](userOfOtherType)).to.be.equal(
            false
          );
        });

        it(`cannot add ${entityName} with the same id twice`, async () => {
          const { userOfType, userOfOtherType } = await getNamedAccounts();

          await expect(
            CustodianContract[addUser](1, "lei", "countryCode", userOfType)
          ).not.to.be.reverted;
          await expect(
            CustodianContract[addUser](1, "lei", "countryCode", userOfType)
          ).to.be.revertedWith("user already exists");
          expect(await CustodianContract[isUser](userOfType)).to.be.equal(true);
          expect(await CustodianContract[isUser](userOfOtherType)).to.be.equal(
            false
          );
        });

        it(`adds ${entityName} addresses successfully`, async () => {
          const { userOfType, userOfType2, userOfOtherType } =
            await getNamedAccounts();

          await expect(
            CustodianContract[addUser](1, "lei", "countryCode", userOfType)
          ).not.to.be.reverted;
          await expect(CustodianContract[addUserAccounts](1, [userOfType2])).not
            .to.be.reverted;
          expect(await CustodianContract[isUser](userOfType)).to.be.equal(true);
          expect(await CustodianContract[isUser](userOfType2)).to.be.equal(
            true
          );
          expect(await CustodianContract[isUser](userOfOtherType)).to.be.equal(
            false
          );
        });

        it(`cannot add addresses to non-existent ${entityName}`, async () => {
          const { userOfType } = await getNamedAccounts();

          await expect(
            CustodianContract[addUserAccounts](1, [userOfType])
          ).to.be.revertedWith("user does not exists");
        });

        it(`removes ${entityName} successfully`, async () => {
          const { userOfType, userOfType2, userOfOtherType } =
            await getNamedAccounts();

          await expect(
            CustodianContract[addUser](1, "lei", "countryCode", userOfType)
          ).not.to.be.reverted;
          await expect(CustodianContract[addUserAccounts](1, [userOfType2])).not
            .to.be.reverted;
          await expect(CustodianContract[removeUser](1)).not.to.be.reverted;
          expect(await CustodianContract[isUser](userOfType)).to.be.equal(
            false
          );
          expect(await CustodianContract[isUser](userOfType2)).to.be.equal(
            false
          );
          expect(await CustodianContract[isUser](userOfOtherType)).to.be.equal(
            false
          );
        });

        it(`cannot remove non-existent ${entityName}`, async () => {
          await expect(CustodianContract[removeUser](1)).to.be.revertedWith(
            "user does not exists"
          );
        });
      });
    };

    createTests({
      entityName: "issuer",
      addUser: "addIssuer",
      addUserAccounts: "addIssuerAccounts",
      removeUser: "removeIssuer",
      isUser: "isIssuer",
    });

    createTests({
      entityName: "custodian",
      addUser: "addCustodian",
      addUserAccounts: "addCustodianAccounts",
      removeUser: "removeCustodian",
      isUser: "isCustodian",
    });

    createTests({
      entityName: "KYC provider",
      addUser: "addKycProvider",
      addUserAccounts: "addKycProviderAccounts",
      removeUser: "removeKycProvider",
      isUser: "isKycProvider",
    });

    it("can add multiple entities with the same id", async () => {
      const { issuer } = await getNamedAccounts();

      await expect(CustodianContract.addIssuer(1, "lei", "countryCode", issuer))
        .not.to.be.reverted;
      await expect(
        CustodianContract.addCustodian(1, "lei", "countryCode", issuer)
      ).not.to.be.reverted;
      await expect(
        CustodianContract.addKycProvider(1, "lei", "countryCode", issuer)
      ).not.to.be.reverted;
      expect(await CustodianContract.isIssuer(issuer)).to.be.equal(true);
      expect(await CustodianContract.isCustodian(issuer)).to.be.equal(true);
      expect(await CustodianContract.isKycProvider(issuer)).to.be.equal(true);
    });
  });
});
