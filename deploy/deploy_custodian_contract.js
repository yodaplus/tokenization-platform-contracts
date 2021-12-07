module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { custodianContractOwner } = await getNamedAccounts();

  const { address: tokenCreatorAddress } = await deploy("TokenCreator", {
    from: custodianContractOwner,
    args: [],
    log: true,
  });

  const { address: custodianContractAddress } = await deploy(
    "CustodianContract",
    {
      from: custodianContractOwner,
      args: [tokenCreatorAddress],
      log: true,
    }
  );

  const TokenCreator = await ethers.getContract(
    "TokenCreator",
    custodianContractOwner
  );

  await TokenCreator.transferOwnership(custodianContractAddress);
};

module.exports.tags = ["CustodianContract", "TokenCreator"];
