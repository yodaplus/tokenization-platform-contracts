const { expect } = require("chai");
const { ethers, deployments, getNamedAccounts } = require("hardhat");

describe("Controller", () => {
  let Controller;

  beforeEach(async () => {
    await deployments.fixture(["Controller"]);
    const { controllerOwner } = await getNamedAccounts();
    Controller = await ethers.getContract("Controller", controllerOwner);
  });

  it("has a version", async () => {
    const Controller = await ethers.getContract("Controller");

    expect(await Controller.VERSION()).to.equal("0.0.1");
  });

  it("only allows controller owner to add issuers", async () => {
    const { issuer } = await getNamedAccounts();
    const ControllerIssuer = await ethers.getContract("Controller", issuer);

    await expect(ControllerIssuer.addIssuer(issuer)).to.be.revertedWith(
      "Ownable: caller is not the owner"
    );
    await expect(Controller.addIssuer(issuer)).not.to.be.reverted;
  });

  it("cannot add the same issuer twice", async () => {
    const { issuer } = await getNamedAccounts();

    await expect(Controller.addIssuer(issuer)).not.to.be.reverted;
    await expect(Controller.addIssuer(issuer)).to.be.revertedWith(
      "issuer already exists"
    );
  });
});
