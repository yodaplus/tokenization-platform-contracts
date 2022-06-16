// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract PoolContractB is Pausable, Ownable {
  // ENUMERATIONS
  enum PaymentTokenStatus {
    Inactive,
    Active
  }
  //   VARIABLES
  mapping(address => bool) public tokenizationPlatform;
  mapping(address => PaymentTokenStatus) internal _paymentTokensStatus;

  // Events
  event TokenizationPlatformAdded(address tokenizationPlatform);
  event TokenizationPlatformRemoved(address tokenizationPlatform);
  event PaymentTokenAdded(address paymentToken);
  event PaymentTokenRemoved(address paymentToken);

  //   Functions
  function addTokenizationPlatform(address escrowManagerAddress)
    public
    onlyOwner
  {
    tokenizationPlatform[escrowManagerAddress] = true;
    emit TokenizationPlatformAdded(escrowManagerAddress);
  }

  function removeTokenizationPlatform(address escrowManagerAddress)
    public
    onlyOwner
  {
    delete tokenizationPlatform[escrowManagerAddress];
    emit TokenizationPlatformRemoved(escrowManagerAddress);
  }

  function addPaymentToken(address tokenAddress) external onlyOwner {
    _paymentTokensStatus[tokenAddress] = PaymentTokenStatus.Active;
    emit PaymentTokenAdded(tokenAddress);
  }

  function removePaymentToken(address tokenAddress) external onlyOwner {
    delete _paymentTokensStatus[tokenAddress];
    emit PaymentTokenRemoved(tokenAddress);
  }
}
