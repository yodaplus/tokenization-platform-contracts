// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "hardhat/console.sol";

contract PoolContractB is Pausable, Ownable {
  using Address for address payable;
  using SafeERC20 for IERC20;

  // ENUMERATIONS
  enum PaymentTokenStatus {
    Inactive,
    Active
  }
  //   VARIABLES
  mapping(address => bool) public tokenizationPlatform;
  mapping(address => PaymentTokenStatus) internal _paymentTokensStatus;

  // variables to store balance of pool for each payment token
  mapping(address => uint256) public _paymentTokenBalance;

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

  function getPoolBalance(address tokenAddress) public view returns (uint256) {
    return _paymentTokenBalance[tokenAddress];
  }

  function escrowFunds(
    address escrowManager,
    address tokenAddress,
    uint256 amount
  ) public onlyOwner {
    // check if escrowManager is a tokenization platform
    require(
      tokenizationPlatform[escrowManager],
      "escrowManager is not a tokenization platform"
    );
    // check if tokenAddress is a payment token
    require(
      _paymentTokensStatus[tokenAddress] == PaymentTokenStatus.Active,
      "tokenAddress is not a payment token"
    );
    require(amount > 0, "Amount must be greater than 0");
    IERC20(tokenAddress).safeApprove(escrowManager, amount);
  }
}
