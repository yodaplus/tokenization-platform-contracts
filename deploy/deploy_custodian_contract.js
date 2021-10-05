module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { custodianContractOwner } = await getNamedAccounts();

  await deploy("CustodianContract", {
    from: custodianContractOwner,
    args: [],
    log: true,
  });
};

module.exports.tags = ["CustodianContract"];
