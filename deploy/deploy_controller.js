module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { controllerOwner } = await getNamedAccounts();

  await deploy("Controller", {
    from: controllerOwner,
    args: [],
    log: true,
  });
};
module.exports.tags = ["Controller"];
