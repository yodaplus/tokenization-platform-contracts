//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Tokenomics is Ownable {
  string public constant VERSION = "0.0.1";
  address public ownerAddress;
  uint256 internal perTokenFee;
  address internal feeDestinationAddress;
  address internal custodianContractAddress;
  struct TokenData {
    address addr;
    address issuerPrimaryAddress;
    string symbol;
    uint256 quantity;
  }

  struct TokenFee {
    string symbol;
    address issuerPrimaryAddress;
    uint256 fees;
  }

  mapping(address => TokenFee[]) public feesLog;

  event FeeDeposited(string symbol, address addr);

  constructor(uint256 fees, address feeDestinationAddress_) {
    ownerAddress = msg.sender;
    perTokenFee = fees;
    feeDestinationAddress = feeDestinationAddress_;
  }

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
    emit FeeDeposited(input.symbol, input.addr);
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
