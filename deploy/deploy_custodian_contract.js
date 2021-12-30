module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { custodianContractOwner } = await getNamedAccounts();

  const { address: escrowManagerAddress } = await deploy("EscrowManager", {
    from: custodianContractOwner,
    args: [],
    log: true,
  });

  const { address: tokenCreatorAddress } = await deploy("TokenCreator", {
    from: custodianContractOwner,
    args: [],
    log: true,
  });

  const { address: tokenCreatorTvTAddress } = await deploy("TokenCreatorTvT", {
    from: custodianContractOwner,
    args: [escrowManagerAddress],
    log: true,
  });

  const { address: custodianContractAddress } = await deploy(
    "CustodianContract",
    {
      from: custodianContractOwner,
      args: [tokenCreatorAddress, tokenCreatorTvTAddress],
      log: true,
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
    log: true,
  });
};

module.exports.tags = ["CustodianContract", "TokenCreator"];
