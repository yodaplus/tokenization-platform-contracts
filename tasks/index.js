const DEFAULT_ERROR_SIGNATURE = {
  inputs: [
    {
      name: "message",
      type: "string",
    },
  ],
  name: "Error",
  type: "error",
};

class EthError extends Error {
  constructor(name, params) {
    super(name);

    this.name = name;
    this.params = params;
  }

  toString() {
    return `${this.name}: ${this.params.message}`;
  }
}

const parseError = (str, abi) => {
  const bytes = web3.utils.hexToBytes(str);
  const errorNameSignature = web3.utils.bytesToHex(bytes.slice(0, 4));
  const errorParameters = web3.utils.bytesToHex(bytes.slice(4));

  const errorDefinition = [...abi, DEFAULT_ERROR_SIGNATURE]
    .filter(({ type }) => type === "error")
    .find((errorSignature) => {
      const encodedSignature =
        web3.eth.abi.encodeFunctionSignature(errorSignature);

      return encodedSignature === errorNameSignature;
    });

  if (errorDefinition) {
    const params = web3.eth.abi.decodeParameters(
      errorDefinition.inputs,
      errorParameters
    );

    return new EthError(errorDefinition.name, params);
  } else {
    throw Error(`can't parse the error "${str}"`);
  }
};

const processTransaction = async (methodInvocation, { abi, from, to, gas }) => {
  const data = methodInvocation.encodeABI();

  const callObj = {
    from,
    to,
    data,
    gasPrice: web3.utils.toWei("1", "gwei"),
    gas,
  };

  try {
    const receipt = await web3.eth.sendTransaction(callObj);

    return receipt;
  } catch (e) {
    if (!e.receipt) {
      throw e;
    }

    const err = await web3.eth.call(callObj, e.receipt.blockNumber);
    const parsedError = parseError(err, abi);

    throw parsedError;
  }
};

task("addIssuer")
  .addParam("lei")
  .addParam("countryCode")
  .addParam("primaryAddress")
  .setAction(async (taskArgs) => {
    const {
      abi,
      address,
    } = require("../deployments/apothem/CustodianContract.json");

    const { custodianContractOwner } = await getNamedAccounts();
    const contract = new web3.eth.Contract(abi);

    try {
      const receipt = await processTransaction(
        contract.methods.addIssuer(
          taskArgs.lei,
          taskArgs.countryCode,
          taskArgs.primaryAddress
        ),
        { abi, to: address, from: custodianContractOwner, gas: 182242 }
      );

      console.log(receipt);
    } catch (err) {
      console.log(`${err.name}: ${err.params.message}`);
    }
  });

task("listNamedAccounts").setAction(async (taskArgs) => {
  const obj = await getNamedAccounts();

  console.log(obj);
});

task("addKycProvider")
  .addParam("lei")
  .addParam("countryCode")
  .addParam("primaryAddress")
  .setAction(async (taskArgs) => {
    const {
      abi,
      address,
    } = require("../deployments/apothem/CustodianContract.json");

    const { custodianContractOwner } = await getNamedAccounts();
    const contract = new web3.eth.Contract(abi);

    try {
      const receipt = await processTransaction(
        contract.methods.addKycProvider(
          taskArgs.lei,
          taskArgs.countryCode,
          taskArgs.primaryAddress
        ),
        { abi, to: address, from: custodianContractOwner }
      );

      console.log(receipt);
    } catch (err) {
      console.log(`${err.name}: ${err.params.message}`);
    }
  });

task("addCustodian")
  .addParam("lei")
  .addParam("countryCode")
  .addParam("primaryAddress")
  .setAction(async (taskArgs) => {
    const {
      abi,
      address,
    } = require("../deployments/apothem/CustodianContract.json");

    const { custodianContractOwner } = await getNamedAccounts();
    const contract = new web3.eth.Contract(abi);

    try {
      const receipt = await processTransaction(
        contract.methods.addCustodian(
          taskArgs.lei,
          taskArgs.countryCode,
          taskArgs.primaryAddress
        ),
        { abi, to: address, from: custodianContractOwner }
      );

      console.log(receipt);
    } catch (err) {
      console.log(`${err.name}: ${err.params.message}`);
    }
  });

task("getEvents").setAction(async (taskArgs) => {
  const {
    abi,
    address,
  } = require("../deployments/apothem/CustodianContract.json");

  const contract = new web3.eth.Contract(abi, address);

  const events = await contract.getPastEvents("TokenPublished", {
    fromBlock: 25338535,
  });

  console.log(events);
});

task("addWhitelist").setAction(async (taskArgs) => {
  const {
    abi,
    address,
  } = require("../deployments/apothem/CustodianContract.json");

  const { kycProvider } = await getNamedAccounts();
  const contract = new web3.eth.Contract(abi);

  try {
    const receipt = await processTransaction(
      contract.methods.addWhitelist(
        "0x1fb10D1160435013b28D92ec3b8eB79B1B1E42d9",
        [kycProvider]
      ),
      {
        abi,
        to: address,
        from: kycProvider,
        gas: 1822420,
      }
    );

    console.log(receipt);
  } catch (err) {
    console.log(err.toString());
  }
});

task("publishToken").setAction(async (taskArgs) => {
  const {
    abi,
    address,
  } = require("../deployments/apothem/CustodianContract.json");

  const { issuer, custodian } = await getNamedAccounts();
  const contract = new web3.eth.Contract(abi);

  try {
    const receipt = await processTransaction(
      contract.methods.publishToken({
        name: "Test Token 12",
        symbol: "TT12",
        decimals: 18,
        maxTotalSupply: 10,
        value: 1000,
        currency: "USD",
        earlyRedemption: true,
        minSubscription: 1,
        issuerPrimaryAddress: issuer,
        custodianPrimaryAddress: custodian,
      }),
      {
        abi,
        to: address,
        from: issuer,
        gas: 1822420,
      }
    );

    console.log(receipt);
  } catch (err) {
    console.log(err.toString());
  }
});

module.exports = {};
