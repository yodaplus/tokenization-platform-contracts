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

    return {
      name: errorDefinition.name,
      params,
    };
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

module.exports = {};
