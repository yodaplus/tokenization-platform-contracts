//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TokenomicsTypes.sol";
import "./ReasonCodes.sol";

contract Tokenomics is Ownable, ReasonCodes {
  string public constant VERSION = "0.0.1";
  /**
   * @dev perTokenFee is the fee that will be charged per token
   */
  uint256 internal perTokenFee;
  /**
   * @dev feeDestinationAddress is the address where the fees will be deposited
   */
  address internal feeDestinationAddress;
  /**
   * @dev custodianContractAddress is the address of the custodian contract which will be used to call depositFee function
   */
  address internal custodianContractAddress;

  // TODO: Create a Modifier to check if the caller is the custodian contract address

  struct TokenFee {
    string symbol;
    uint256 quantity;
    address issuerPrimaryAddress;
    uint256 feeRate;
    uint256 fees;
    uint256 timestamp;
  }

  /**
   * @dev feesLog is a mapping of token address to an array of TokenFee struct
   */
  mapping(address => TokenFee[]) public feesLog;

  // Should we add more details to the event ?

  event FeeDeposited(
    string symbol,
    address addr,
    address issuerPrimaryAddress,
    uint256 fees
  );

  error ERC1066Error(bytes1 errorCode, string message);

  constructor(
    uint256 fees,
    address _feeDestinationAddress,
    address _custodianContractAddress
  ) {
    perTokenFee = fees;
    feeDestinationAddress = _feeDestinationAddress;
    custodianContractAddress = _custodianContractAddress;
  }

  //  Add a modifier to check if the caller is the custodian contract address

  modifier onlyCustodianContract() {
    if (msg.sender == custodianContractAddress) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "caller is not allowed"
      );
    }
    _;
  }

  function depositFee(TokenFeeData calldata input)
    external
    payable
    onlyCustodianContract
  {
    // check if the fee amount is correct
    require(
      input.quantity * perTokenFee == msg.value,
      "Incorrect funds received!"
    );
    TokenFee memory log = TokenFee(
      input.symbol,
      input.quantity,
      input.issuerPrimaryAddress,
      perTokenFee,
      msg.value,
      block.timestamp
    );
    feesLog[input.addr].push(log);

    payable(feeDestinationAddress).transfer(msg.value);
    emit FeeDeposited(
      input.symbol,
      input.addr,
      input.issuerPrimaryAddress,
      msg.value
    );
  }

  //   set the address of the wallet that receives the fee
  function setFeeDestinationAddress(address addr) external onlyOwner {
    feeDestinationAddress = addr;
  }

  // set the fee per token
  function setPerTokenFee(uint256 amount) external onlyOwner {
    perTokenFee = amount;
  }

  function getFeeDestinationAddress() public view returns (address) {
    return feeDestinationAddress;
  }

  function getPerTokenFee() public view returns (uint256) {
    return perTokenFee;
  }
}
