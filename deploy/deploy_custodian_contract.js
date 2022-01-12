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

  const { address: tokenCreatorAddress } = await deploy("TokenCreator", {
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
      args: [
        tokenCreatorAddress,
        tokenCreatorTvTAddress,
        timeOracleBlockAddress,
      ],
      ...deployOptions,
    }
  );

  const TokenCreator = await ethers.getContract(
    "TokenCreator",
    custodianContractOwner
  );
  const TokenCreatorTvT = await ethers.getContract(
    "TokenCreatorTvT",
    custodianContractOwner
  );

  await TokenCreator.transferOwnership(custodianContractAddress);
  await TokenCreatorTvT.transferOwnership(custodianContractAddress);

  const EscrowManager = await ethers.getContract(
    "EscrowManager",
    custodianContractOwner
  );

  await EscrowManager.setCustodianContract(custodianContractAddress);

  await deploy("PaymentToken", {
    from: custodianContractOwner,
    args: [],
    ...deployOptions,
  });
};

module.exports.tags = ["CustodianContract", "TokenCreator"];
