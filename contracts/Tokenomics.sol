//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Tokenomics is Ownable {
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

  // Declare this TokenData struct in a separate file and import it here because it will be used in the Custodian contract as well
  struct TokenData {
    address addr;
    address issuerPrimaryAddress;
    string symbol;
    uint256 quantity;
  }

  // Should we add a timestamp to the struct ?
  // Should we add a feeRate to the struct ?
  // Should we add a quantity to the struct ?

  struct TokenFee {
    string symbol;
    address issuerPrimaryAddress;
    uint256 fees;
  }

  /**
   * @dev feesLog is a mapping of token address to an array of TokenFee struct
   */
  mapping(address => TokenFee[]) public feesLog;

  // Should we add more details to the event ?

  event FeeDeposited(string symbol, address addr);

  constructor(uint256 fees, address _feeDestinationAddress) {
    perTokenFee = fees;
    feeDestinationAddress = _feeDestinationAddress;
  }

  // TODO: Add a modifier to check if the caller is the custodian contract address
  function depositFee(TokenData calldata input) external payable {
    // check if the fee amount is correct
    require(
      input.quantity * perTokenFee == msg.value,
      "Incorrect funds received!"
    );
    TokenFee memory log = TokenFee(
      input.symbol,
      input.issuerPrimaryAddress,
      msg.value
    );
    feesLog[input.addr].push(log);

    payable(feeDestinationAddress).transfer(msg.value);
    emit FeeDeposited(input.symbol, input.addr); // Also emit what amount of fees were deposited ?
  }

  function setFeeDestinationAddress(address addr) external onlyOwner {
    feeDestinationAddress = addr;
  }

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
