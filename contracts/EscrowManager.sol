//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import {TokenTvT as TokenTvTContract} from "./TokenTvT.sol";
import "./CustodianContract.sol";

enum EscrowType {
  Issuance,
  Redemption
}

enum EscrowStatus {
  Pending,
  Done
}

struct EscrowOrder {
  address tradeToken;
  uint256 tradeTokenAmount;
  address issuerAddress;
  address paymentToken;
  uint256 paymentTokenAmount;
  address investorAddress;
  uint256 collateral;
  uint256 timeout;
}

contract EscrowManager is Ownable {
  using Address for address payable;

  string public constant VERSION = "0.0.1";

  mapping(address => uint256) internal _collateralBalance;
  mapping(address => uint256) internal _collateralBalanceLocked;
  mapping(uint256 => EscrowOrder) internal _escrowOrders;
  mapping(uint256 => EscrowType) internal _escrowOrdersType;
  mapping(uint256 => EscrowStatus) internal _escrowOrdersStatus;
  mapping(uint256 => uint256) internal _escrowStartTimestamp;

  uint256 internal _nextEscrowOrderId = 0;

  CustodianContract custodianContract;

  function setCustodianContract(address custodianContractAddress)
    external
    onlyOwner
  {
    custodianContract = CustodianContract(custodianContractAddress);
  }

  modifier onlyToken() {
    if (custodianContract.tokenExists(msg.sender) == false) {
      revert("access error");
    }
    _;
  }

  function depositCollateral(address account) external payable {
    _collateralBalance[account] += msg.value;
  }

  function collateralBalance(address account) external view returns (uint256) {
    return _collateralBalance[account];
  }

  function lockedCollateralBalance(address account)
    external
    view
    returns (uint256)
  {
    return _collateralBalanceLocked[account];
  }

  function withdrawCollateral(uint256 value) external {
    require(value <= _collateralBalance[msg.sender], "Insufficient funds");

    payable(msg.sender).transfer(value);
    _collateralBalance[msg.sender] -= value;
  }

  function lockCollateral(address account, uint256 value) internal {
    require(value <= _collateralBalance[account], "Insufficient funds");

    _collateralBalanceLocked[account] += value;
    _collateralBalance[account] -= value;
  }

  function unlockCollateral(address account, uint256 value) internal {
    require(value <= _collateralBalanceLocked[account], "Insufficient funds");

    _collateralBalanceLocked[account] -= value;
    _collateralBalance[account] += value;
  }

  function spendCollateral(
    address account,
    address payable destination,
    uint256 value
  ) internal {
    require(value <= _collateralBalanceLocked[account], "Insufficient funds");

    _collateralBalanceLocked[account] -= value;
    destination.sendValue(value);
  }

  function checkIssuanceEscrowConditionsIssuer(uint256 orderId)
    public
    view
    returns (bool)
  {
    require(_escrowStartTimestamp[orderId] > 0, "invalid order id");
    require(
      _escrowOrdersType[orderId] == EscrowType.Issuance,
      "invalid order type"
    );

    EscrowOrder storage escrowOrder = _escrowOrders[orderId];

    uint256 allowanceIssuer = IERC20(escrowOrder.tradeToken).allowance(
      escrowOrder.issuerAddress,
      address(this)
    );
    uint256 balanceIssuer = IERC20(escrowOrder.tradeToken).balanceOf(
      escrowOrder.issuerAddress
    );
    uint256 tokenAmount = escrowOrder.tradeTokenAmount;

    return
      allowanceIssuer >= tokenAmount &&
      balanceIssuer >= tokenAmount &&
      escrowOrder.collateral <= _collateralBalance[escrowOrder.issuerAddress];
  }

  function checkRedemptionEscrowConditionsInvestor(uint256 orderId)
    public
    view
    returns (bool)
  {
    require(_escrowStartTimestamp[orderId] > 0, "invalid order id");
    require(
      _escrowOrdersType[orderId] == EscrowType.Redemption,
      "invalid order type"
    );

    EscrowOrder storage escrowOrder = _escrowOrders[orderId];

    uint256 allowanceInvestor = IERC20(escrowOrder.tradeToken).allowance(
      escrowOrder.investorAddress,
      address(this)
    );
    uint256 balanceInvestor = IERC20(escrowOrder.tradeToken).balanceOf(
      escrowOrder.investorAddress
    );
    uint256 tokenAmount = escrowOrder.tradeTokenAmount;

    return allowanceInvestor >= tokenAmount && balanceInvestor >= tokenAmount;
  }

  function checkIssuanceEscrowConditionsInvestor(uint256 orderId)
    public
    view
    returns (bool)
  {
    require(_escrowStartTimestamp[orderId] > 0, "invalid order id");
    require(
      _escrowOrdersType[orderId] == EscrowType.Issuance,
      "invalid order type"
    );

    EscrowOrder storage escrowOrder = _escrowOrders[orderId];

    uint256 allowanceInvestor = IERC20(escrowOrder.paymentToken).allowance(
      escrowOrder.investorAddress,
      address(this)
    );
    uint256 balanceInvestor = IERC20(escrowOrder.paymentToken).balanceOf(
      escrowOrder.investorAddress
    );
    uint256 tokenAmount = escrowOrder.paymentTokenAmount;

    return allowanceInvestor >= tokenAmount && balanceInvestor >= tokenAmount;
  }

  function checkRedemptionEscrowConditionsIssuer(uint256 orderId)
    public
    view
    returns (bool)
  {
    require(_escrowStartTimestamp[orderId] > 0, "invalid order id");
    require(
      _escrowOrdersType[orderId] == EscrowType.Redemption,
      "invalid order type"
    );

    EscrowOrder storage escrowOrder = _escrowOrders[orderId];

    uint256 allowanceIssuer = IERC20(escrowOrder.paymentToken).allowance(
      escrowOrder.issuerAddress,
      address(this)
    );
    uint256 balanceIssuer = IERC20(escrowOrder.paymentToken).balanceOf(
      escrowOrder.issuerAddress
    );
    uint256 tokenAmount = escrowOrder.paymentTokenAmount;

    return allowanceIssuer >= tokenAmount && balanceIssuer >= tokenAmount;
  }

  function checkIssuanceEscrowConditions(uint256 orderId)
    public
    view
    returns (bool)
  {
    return
      checkIssuanceEscrowConditionsIssuer(orderId) &&
      checkIssuanceEscrowConditionsInvestor(orderId);
  }

  function checkRedemptionEscrowConditions(uint256 orderId)
    public
    view
    returns (bool)
  {
    return
      checkRedemptionEscrowConditionsIssuer(orderId) &&
      checkRedemptionEscrowConditionsInvestor(orderId);
  }

  function startIssuanceEscrow(EscrowOrder calldata escrowOrder)
    external
    onlyToken
    returns (uint256 orderId)
  {
    orderId = _nextEscrowOrderId;
    _nextEscrowOrderId += 1;

    _escrowOrders[orderId] = escrowOrder;
    _escrowOrdersType[orderId] = EscrowType.Issuance;
    _escrowStartTimestamp[orderId] = block.timestamp;
    _escrowOrdersStatus[orderId] = EscrowStatus.Pending;
  }

  function startRedemptionEscrow(EscrowOrder calldata escrowOrder)
    external
    onlyToken
    returns (uint256 orderId)
  {
    // This should never happen,
    // as locked collateral must be enough to compensate all
    // tokens, transferred to investors via escrow
    assert(
      escrowOrder.collateral <=
        _collateralBalanceLocked[escrowOrder.issuerAddress]
    );

    orderId = _nextEscrowOrderId;
    _nextEscrowOrderId += 1;

    _escrowOrders[orderId] = escrowOrder;
    _escrowOrdersType[orderId] = EscrowType.Redemption;
    _escrowStartTimestamp[orderId] = block.timestamp;
    _escrowOrdersStatus[orderId] = EscrowStatus.Pending;
  }

  function swapIssuance(uint256 orderId) external {
    require(_escrowStartTimestamp[orderId] > 0, "invalid order id");
    require(
      _escrowOrdersType[orderId] == EscrowType.Issuance,
      "invalid order type"
    );
    require(
      _escrowOrdersStatus[orderId] != EscrowStatus.Done,
      "escrow is completed"
    );

    assert(_escrowOrdersStatus[orderId] == EscrowStatus.Pending);

    _escrowOrdersStatus[orderId] = EscrowStatus.Done;

    bool escrowConditionsFlag = checkIssuanceEscrowConditions(orderId);

    if (!escrowConditionsFlag) {
      revert("escrow conditions are not met");
    }

    EscrowOrder storage escrowOrder = _escrowOrders[orderId];

    IERC20(escrowOrder.tradeToken).transferFrom(
      escrowOrder.issuerAddress,
      escrowOrder.investorAddress,
      escrowOrder.tradeTokenAmount
    );

    IERC20(escrowOrder.paymentToken).transferFrom(
      escrowOrder.investorAddress,
      escrowOrder.issuerAddress,
      escrowOrder.paymentTokenAmount
    );

    lockCollateral(escrowOrder.issuerAddress, escrowOrder.collateral);

    TokenTvTContract(escrowOrder.tradeToken).onIssue(
      escrowOrder.investorAddress,
      escrowOrder.tradeTokenAmount
    );
  }

  function swapRedemption(uint256 orderId) external {
    require(_escrowStartTimestamp[orderId] > 0, "invalid order id");
    require(
      _escrowOrdersType[orderId] == EscrowType.Redemption,
      "invalid order type"
    );
    require(
      _escrowOrdersStatus[orderId] != EscrowStatus.Done,
      "Escrow is completed"
    );

    assert(_escrowOrdersStatus[orderId] == EscrowStatus.Pending);

    _escrowOrdersStatus[orderId] = EscrowStatus.Done;

    EscrowOrder storage escrowOrder = _escrowOrders[orderId];

    bool escrowConditionsFlag = checkRedemptionEscrowConditions(orderId);
    bool escrowConditionsInvestorFlag = checkRedemptionEscrowConditionsInvestor(
      orderId
    );
    bool timeoutFlag = block.timestamp - _escrowStartTimestamp[orderId] >
      escrowOrder.timeout;

    if (!escrowConditionsFlag && !timeoutFlag) {
      revert("full escrow conditions are not met before expiry");
    }

    assert(escrowConditionsFlag || timeoutFlag);

    if (escrowConditionsFlag) {
      IERC20(escrowOrder.tradeToken).transferFrom(
        escrowOrder.investorAddress,
        escrowOrder.issuerAddress,
        escrowOrder.tradeTokenAmount
      );

      IERC20(escrowOrder.paymentToken).transferFrom(
        escrowOrder.issuerAddress,
        escrowOrder.investorAddress,
        escrowOrder.paymentTokenAmount
      );

      unlockCollateral(escrowOrder.issuerAddress, escrowOrder.collateral);
    } else {
      assert(timeoutFlag);

      require(
        escrowConditionsInvestorFlag,
        "escrow expired, but investor conditions are not met"
      );

      IERC20(escrowOrder.tradeToken).transferFrom(
        escrowOrder.investorAddress,
        escrowOrder.issuerAddress,
        escrowOrder.tradeTokenAmount
      );

      spendCollateral(
        escrowOrder.issuerAddress,
        payable(escrowOrder.investorAddress),
        escrowOrder.collateral
      );
    }

    TokenTvTContract(escrowOrder.tradeToken).onRedeem(
      escrowOrder.investorAddress,
      escrowOrder.tradeTokenAmount
    );
  }
}
