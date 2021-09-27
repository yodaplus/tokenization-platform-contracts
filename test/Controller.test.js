const { expect } = require("chai");
const { ethers, deployments, getNamedAccounts } = require("hardhat");

describe("Controller", function () {
  it("has a version", async function () {
    await deployments.fixture(["Controller"]);
    const Controller = await ethers.getContract("Controller");

    expect(await Controller.VERSION()).to.equal("0.0.1");
  });
});
