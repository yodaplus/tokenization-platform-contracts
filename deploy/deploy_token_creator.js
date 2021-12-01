module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { custodianContractOwner } = await getNamedAccounts();

  await deploy("TokenCreator", {
    from: custodianContractOwner,
    args: [],
    log: true,
  });
};

module.exports.tags = ["TokenCreator"];
