const { ethers, upgrades } = require("hardhat");

async function main() {
  // get address from command line argument
  const address = "0x6D5e87F7a13d093c458A08aC7b473AF81979f248";
  const EscrowManagerV2 = await ethers.getContractFactory("EscrowManager");
  const escrowManager = await upgrades.upgradeProxy(address, EscrowManagerV2);
  console.log("EscrowManagerV2 upgraded");
}

main();
