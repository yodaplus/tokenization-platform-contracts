//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Token.sol";
import "./TokenTvTTypes.sol";
import "./EscrowManager.sol";

uint256 constant ISSUANCE_ESCROW_TIMEOUT = 2 * 24 * 60 * 60 * 1000;
uint256 constant REDEMPTION_ESCROW_TIMEOUT = 2 * 24 * 60 * 60 * 1000;

contract TokenTvT is Token {
  address[] internal _paymentTokens;
  uint256[] internal _issuanceSwapMultiple;
  uint256[] internal _redemptionSwapMultiple;
  uint256 internal _maturityPeriod;
  uint256 internal _collateral;

  mapping(address => mapping(uint256 => uint256))
    internal _issuedTokensByMaturityBucket;
  mapping(address => uint256[]) internal _issuedTokensMaturityBuckets;

  EscrowManager public escrowManager;

  event IssuanceEscrowInitiated(EscrowOrder order, uint256 orderId);
  event RedemptionEscrowInitiated(EscrowOrder order, uint256 orderId);

  constructor(
    TokenTvTInput memory input,
    address custodianContract,
    address escrowManagerAddress
  )
    Token(
      input.name,
      input.symbol,
      input.decimals,
      input.maxTotalSupply,
      custodianContract
    )
  {
    _paymentTokens = input.paymentTokens;
    _issuanceSwapMultiple = input.issuanceSwapMultiple;
    _redemptionSwapMultiple = input.redemptionSwapMultiple;
    _maturityPeriod = input.maturityPeriod;
    _collateral = input.collateral;
    escrowManager = EscrowManager(escrowManagerAddress);
  }

  function issue(address subscriber, uint256 value) public override onlyOwner {
    if (_isFinalized == true) {
      throwError(ErrorCondition.TOKEN_IS_FINALIZED);
    }

    if (_maxTotalSupply < totalSupply() + value) {
      throwError(ErrorCondition.MAX_TOTAL_SUPPLY_MINT);
    }

    bytes1 reasonCode = _custodianContract.canIssue(
      address(this),
      subscriber,
      value
    );

    address tokenOwner = owner();

    if (reasonCode != ReasonCodes.TRANSFER_SUCCESS) {
      emit IssuanceFailure(subscriber, value, reasonCode);
    } else {
      _mint(tokenOwner, value);
      increaseAllowance(address(escrowManager), value);
      EscrowOrder memory escrowOrder = EscrowOrder({
        tradeToken: address(this),
        tradeTokenAmount: value,
        issuerAddress: tokenOwner,
        paymentToken: _paymentTokens[0],
        paymentTokenAmount: _issuanceSwapMultiple[0] * value,
        investorAddress: subscriber,
        collateral: _collateral * value,
        timeout: ISSUANCE_ESCROW_TIMEOUT
      });
      uint256 orderId = escrowManager.startIssuanceEscrow(escrowOrder);
      emit IssuanceEscrowInitiated(escrowOrder, orderId);
    }
  }

  function onIssue(address subscriber, uint256 value) external {
    require(msg.sender == address(escrowManager), "access error");

    _issuedTokensByMaturityBucket[subscriber][block.timestamp] += value;
    _issuedTokensMaturityBuckets[subscriber].push(block.timestamp);

    emit Issued(subscriber, value, ReasonCodes.TRANSFER_SUCCESS);
  }

  function onRedeem(address subscriber, uint256 value) external {
    require(msg.sender == address(escrowManager), "access error");

    uint256 i = 0;
    uint256 remainingValue = value;
    uint256[] storage maturityBuckets = _issuedTokensMaturityBuckets[
      subscriber
    ];

    while (
      i < maturityBuckets.length &&
      remainingValue > 0 &&
      (maturityBuckets[i] + _maturityPeriod < block.timestamp)
    ) {
      uint256 currentBucketBalance = _issuedTokensByMaturityBucket[subscriber][
        maturityBuckets[i]
      ];

      if (currentBucketBalance > remainingValue) {
        _issuedTokensByMaturityBucket[subscriber][maturityBuckets[i]] =
          currentBucketBalance -
          remainingValue;
        remainingValue = 0;
      } else {
        _issuedTokensByMaturityBucket[subscriber][maturityBuckets[i]] = 0;
        remainingValue = remainingValue - currentBucketBalance;
      }

      i += 1;
    }

    emit Redeemed(subscriber, value, ReasonCodes.TRANSFER_SUCCESS);
  }

  function matureBalance(address subscriber)
    public
    view
    returns (uint256 result)
  {
    uint256 i = 0;
    uint256[] storage maturityBuckets = _issuedTokensMaturityBuckets[
      subscriber
    ];

    while (
      i < maturityBuckets.length &&
      (maturityBuckets[i] + _maturityPeriod < block.timestamp)
    ) {
      result += _issuedTokensByMaturityBucket[subscriber][maturityBuckets[i]];

      i += 1;
    }
  }

  function redeem(address subscriber, uint256 value) public override {
    require(msg.sender == subscriber, "only token owners can redeem");

    bytes1 reasonCode = _custodianContract.canRedeem(
      address(this),
      subscriber,
      value
    );

    if (matureBalance(subscriber) < value) {
      reasonCode = ReasonCodes.INSUFFICIENT_BALANCE;
    }

    if (reasonCode != ReasonCodes.TRANSFER_SUCCESS) {
      emit RedeemFailed(subscriber, value, reasonCode);
    } else {
      increaseAllowance(address(escrowManager), value);
      EscrowOrder memory escrowOrder = EscrowOrder({
        tradeToken: address(this),
        tradeTokenAmount: value,
        issuerAddress: owner(),
        paymentToken: _paymentTokens[0],
        paymentTokenAmount: _redemptionSwapMultiple[0] * value,
        investorAddress: subscriber,
        collateral: _collateral * value,
        timeout: REDEMPTION_ESCROW_TIMEOUT
      });
      uint256 orderId = escrowManager.startRedemptionEscrow(escrowOrder);
      emit RedemptionEscrowInitiated(escrowOrder, orderId);
    }
  }
}
