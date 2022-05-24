// scripts/create-box.js
const {
  ethers,
  upgrades,
  deployments,
  getNamedAccounts,
  network,
} = require("hardhat");

async function main() {
  const { deploy } = deployments;
  const { custodianContractOwner } = await getNamedAccounts();
  const deployOptions = {
    log: true,
    gasPrice: ethers.utils.parseUnits("1", "gwei"),
  };
  const { address: timeOracleBlockAddress } = await deploy(
    network.name === "apothem" ? "TimeOracleManual" : "TimeOracleBlock",
    {
      from: custodianContractOwner,
      args: [],
      ...deployOptions,
    }
  );
  console.log("TimeOracleBlock deployed to:", timeOracleBlockAddress);

  const EscrowManager = await ethers.getContractFactory(
    "EscrowManager",
    custodianContractOwner
  );
  const escrowManager = await upgrades.deployProxy(EscrowManager, []);
  await escrowManager.deployed();
  console.log("EscrowManager deployed to:", escrowManager.address);
  const escrowManagerAddress = escrowManager.address;

  const { address: tokenCreatorTvTAddress } = await deploy("TokenCreatorTvT", {
    from: custodianContractOwner,
    args: [escrowManagerAddress],
    ...deployOptions,
  });
  console.log("TokenCreatorTvT deployed to:", tokenCreatorTvTAddress);

  const CustodianContract = await ethers.getContractFactory(
    "CustodianContract"
  );
  const custodianContract = await upgrades.deployProxy(CustodianContract, [
    timeOracleBlockAddress,
    escrowManagerAddress,
  ]);
  await custodianContract.deployed();
  const custodianContractAddress = custodianContract.address;
  console.log("CustodianContract deployed to:", custodianContract.address);

  const TokenCreatorTvT = await ethers.getContract(
    "TokenCreatorTvT",
    custodianContractOwner
  );

  const tokenTvtTransferOwnership = await TokenCreatorTvT.transferOwnership(
    custodianContractAddress
  );
  console.log("Transferred ownership of TokenCreatorTvT to CustodianContract");
  await tokenTvtTransferOwnership.wait(1);

  const escrowManager1 = await ethers.getContractAt(
    "EscrowManager",
    escrowManagerAddress
  );
  const escrowSetCustodian = await escrowManager1.setCustodianContract(
    custodianContractAddress
  );
  console.log("Transferred ownership of EscrowManager to CustodianContract");

  await escrowSetCustodian.wait(1);

  await deploy("PaymentToken", {
    from: custodianContractOwner,
    args: [],
    ...deployOptions,
  });
}

main();
