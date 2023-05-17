const { ethers } = require("hardhat");

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

  const escrowManager = await deploy("EscrowManager", {
    from: custodianContractOwner,
    proxy: {
      proxyContract: "OpenZeppelinTransparentProxy",
      execute: {
        methodName: "initialize",
        args: [],
      },
    },
  });
  const escrowManagerAddress = escrowManager.address;

  const { address: tokenCreatorTvTAddress } = await deploy("TokenCreatorTvT", {
    from: custodianContractOwner,
    args: [escrowManagerAddress],
    ...deployOptions,
  });

  const tokenomics =  await deploy("Tokenomics", {
    from : custodianContractOwner,
    args : [10 , custodianContractOwner],
    ...deployOptions,
  });

  const tokenomicsAddress = tokenomics.address;

  const deployResult = await deploy("CustodianContract", {
    from: custodianContractOwner,
    proxy: {
      proxyContract: "OpenZeppelinTransparentProxy",
      execute: {
        methodName: "initialize",
        args: [tokenCreatorTvTAddress, timeOracleBlockAddress , tokenomicsAddress],
      },
    },
  });
  const custodianContractAddress = deployResult.address;

  const Tokenomics = await ethers.getContract(
    "Tokenomics",
    custodianContractOwner
  )
  // whitelist the custodian contract address in the tokenomics contract
  await Tokenomics.whitelistContractAddress(custodianContractAddress);

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
