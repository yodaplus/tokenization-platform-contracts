const _ = require("lodash/fp");
const chai = require("chai");
const chaiSnapshot = require("mocha-chai-snapshot");
const { ethers, deployments, getNamedAccounts } = require("hardhat");
const { expect } = chai;
const { TOKEN_EXAMPLE, KYC_DATA } = require("./utils");
chai.use(chaiSnapshot);

describe("EscorwManager", function () {
    let EscorwManagerIssuer;
    let EscorwManager;


    beforeEach(async () => {
        await deployments.fixture([
            "CustodianContract",
            "TokenCreator",
            "EscrowManager",
            "PaymentToken",
        ]);
        const {
            custodianContractOwner,
            issuer,
        } = await getNamedAccounts();
        EscorwManagerIssuer = await ethers.getContract("EscrowManager", issuer);
        EscorwManager = await ethers.getContract("EscrowManager", custodianContractOwner);
    });
    it("has a version", async () => {
        expect(await EscorwManager.VERSION()).to.equal("0.0.1");
    });

    describe("can transfer xdc", async () => {

        it("sends XDC", async () => {
            const { subscriber, issuer } = await getNamedAccounts();

            await expect(
                EscorwManager.sendXDC(subscriber, {
                    value: 1,
                })
            ).to.emit(EscorwManager, "XDCTransfered");
        });
    });
});
