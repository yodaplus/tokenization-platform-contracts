const deployOptions = {
  log: true,
  gasPrice: ethers.utils.parseUnits("1", "gwei"),
};

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deploy } = deployments;
  const { custodianContractOwner } = await getNamedAccounts();

  const { address: liqiudityPoolAddress } = await deploy("PoolContractB", {
    from: custodianContractOwner,
    args: [],
    ...deployOptions,
  });
};

module.exports.tags = ["PoolContractB"];
