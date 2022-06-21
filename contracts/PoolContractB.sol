// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ITokenTvT.sol";

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

  // variables to store balance of pool for each asset token
  address[] public _assetTokens;

  // Events
  event TokenizationPlatformAdded(address tokenizationPlatform);
  event TokenizationPlatformRemoved(address tokenizationPlatform);
  event PaymentTokenAdded(address paymentToken);
  event PaymentTokenRemoved(address paymentToken);
  event AssetTokenAdded(address assetToken);
  event AssetTokenRemoved(address assetToken);

  //   Functions
  /*
  This function is not required if we are planning to keep the contract generic.
  */
  function addTokenizationPlatform(address escrowManagerAddress)
    public
    onlyOwner
  {
    tokenizationPlatform[escrowManagerAddress] = true;
    emit TokenizationPlatformAdded(escrowManagerAddress);
  }

  /*
  This function is not required if we are planning to keep the contract generic.
  */
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

  // Owner of the pool will need to add the asset token invested in to help the pool to maintain the balance. and NAV
  function addAsset(address tokenAddress) external onlyOwner {
    _assetTokens.push(tokenAddress);
    emit AssetTokenAdded(tokenAddress);
  }

  function approve(
    address spender,
    address tokenAddress,
    uint256 amount
  ) public onlyOwner {
    // // check if escrowManager is a tokenization platform
    // require(
    //   tokenizationPlatform[escrowManager],
    //   "escrowManager is not a tokenization platform"
    // );
    // check if tokenAddress is a payment token
    require(
      _paymentTokensStatus[tokenAddress] == PaymentTokenStatus.Active,
      "tokenAddress is not a payment token"
    );
    require(amount > 0, "Amount must be greater than 0");
    IERC20(tokenAddress).safeApprove(spender, amount);
  }

  function transfer(
    address to,
    address tokenAddress,
    uint256 amount
  ) public onlyOwner {
    // check if tokenAddress is a payment token
    require(
      _paymentTokensStatus[tokenAddress] == PaymentTokenStatus.Active,
      "tokenAddress is not a payment token"
    );
    require(amount > 0, "Amount must be greater than 0");
    IERC20(tokenAddress).safeTransfer(to, amount);
  }

  function redeemTvT(address tokenAddress, uint256 amount) public {
    require(amount > 0, "Amount must be greater than 0");
    ITokenTvT(tokenAddress).redeem(address(this), amount);
  }
}
