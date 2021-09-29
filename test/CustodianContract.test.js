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

  it("only allows CustodianContract owner to add issuers", async () => {
    const { issuer } = await getNamedAccounts();
    const CustodianContractIssuer = await ethers.getContract(
      "CustodianContract",
      issuer
    );

    await expect(
      CustodianContractIssuer.addIssuer(1, "lei", "countryCode", issuer)
    ).to.be.revertedWith("Ownable: caller is not the owner");
    await expect(CustodianContract.addIssuer(1, "lei", "countryCode", issuer))
      .not.to.be.reverted;
  });

  it("cannot add the same issuer twice", async () => {
    const { issuer } = await getNamedAccounts();

    await expect(CustodianContract.addIssuer(1, "lei", "countryCode", issuer))
      .not.to.be.reverted;
    await expect(
      CustodianContract.addIssuer(1, "lei", "countryCode", issuer)
    ).to.be.revertedWith("user already exists");
  });
});
