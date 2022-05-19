const { ethers, upgrades } = require("hardhat");

async function main() {
  // get address from command line argument
  const address = "";
  const EscrowManagerV2 = await ethers.getContractFactory("EscrowManagerV2");
  const escrowManager = await upgrades.upgradeProxy(address, EscrowManagerV2);
  console.log("EscrowManagerV2 upgraded");
}

main();
