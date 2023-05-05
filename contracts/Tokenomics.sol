//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Tokenomics {
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
    uint256 fees;
  }

  struct TokenFee {
    string symbol;
    address issuerPrimaryAddress;
    uint256 fees;
  }

  mapping(address => TokenData) public feesLog;

  event FeeDeposited(string symbol, address addr);

  constructor() {
    ownerAddress = msg.sender;
  }

  function depositFee(TokenData calldata input) external payable {
    // check if the fee amount is correct
    require(
      input.quantity * getPerTokenFee() == input.fees,
      "Incorrect funds received!"
    );
    TokenFee memory log = TokenFee(
      input.symbol,
      input.issuerPrimaryAddress,
      input.fees
    );
    feesLog[input.addr] = log;

    payable(getFeeDestinationAddress()).transfer(input.fees);
    emit FeeDeposited(input.symbol, input.addr);
  }

  function setFeeDestinationAddress(address addr) internal {
    feeDestinationAddress = addr;
  }

  function setPerTokenFee(uint256 amount) internal {
    perTokenFee = amount;
  }

  function getFeeDestinationAddress() internal returns (address) {
    return feeDestinationAddress;
  }

  function getPerTokenFee() internal returns (uint256) {
    return perTokenFee;
  }
}
