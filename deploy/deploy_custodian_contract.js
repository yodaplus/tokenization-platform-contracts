const deployOptions = {
  log: true,
  gasPrice: ethers.utils.parseUnits("1", "gwei"),
};

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deploy } = deployments;
  const { custodianContractOwner } = await getNamedAccounts();

  const { address: timeOracleBlockAddress } = await deploy(
    network.name === "apothem" ? "TimeOracleManual" : "TimeOracleBlock",
    {
      from: custodianContractOwner,
      args: [],
      ...deployOptions,
    }
  );

  const { address: escrowManagerAddress } = await deploy("EscrowManager", {
    from: custodianContractOwner,
    args: [],
    ...deployOptions,
  });

  const { address: tokenCreatorTvTAddress } = await deploy("TokenCreatorTvT", {
    from: custodianContractOwner,
    args: [escrowManagerAddress],
    ...deployOptions,
  });

  const { address: custodianContractAddress } = await deploy(
    "CustodianContract",
    {
      from: custodianContractOwner,
      args: [tokenCreatorTvTAddress, timeOracleBlockAddress],
      ...deployOptions,
    }
  );

  const TokenCreatorTvT = await ethers.getContract(
    "TokenCreatorTvT",
    custodianContractOwner
  );

  const tokenTvtTransferOwnership = await TokenCreatorTvT.transferOwnership(
    custodianContractAddress
  );
  await tokenTvtTransferOwnership.wait(1);

  const EscrowManager = await ethers.getContract(
    "EscrowManager",
    custodianContractOwner
  );

  const escrowSetCustodian = await EscrowManager.setCustodianContract(
    custodianContractAddress
  );
  await escrowSetCustodian.wait(1);

  await deploy("PaymentToken", {
    from: custodianContractOwner,
    args: [],
    ...deployOptions,
  });
};

module.exports.tags = ["CustodianContract"];
