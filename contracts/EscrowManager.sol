//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./ReasonCodes.sol";
import "./interfaces/ITokenHooks.sol";
import "./interfaces/IEscrowInitiate.sol";
import "./CustodianContract.sol";
import "./EscrowTypes.sol";

enum EscrowType {
  Issuance,
  Redemption
}

enum EscrowStatus {
  Pending,
  Done
}

contract EscrowManager is Ownable, IEscrowInitiate, ReasonCodes {
  using Address for address payable;

  string public constant VERSION = "0.0.1";

  mapping(address => uint256) internal _collateralBalance;
  mapping(address => uint256) internal _collateralBalanceLocked;
  mapping(address => mapping(address => uint256))
    internal _insurerCollateralBalanceByIssuer;
  mapping(address => mapping(address => uint256))
    internal _insurerLockedCollateralBalanceByIssuer;

  mapping(uint256 => EscrowOrder) internal _escrowOrders;
  mapping(uint256 => EscrowType) internal _escrowOrdersType;
  mapping(uint256 => EscrowStatus) internal _escrowOrdersStatus;
  mapping(uint256 => uint256) internal _escrowStartTimestamp;

  uint256 internal _nextEscrowOrderId = 0;

  CustodianContract custodianContract;

  error ERC1066Error(bytes1 errorCode, string message);

  enum ErrorCondition {
    ACCESS_ERROR,
    INSUFFICIENT_COLLATERAL_BALANCE,
    INSUFFICIENT_LOCKED_COLLATERAL_BALANCE,
    INVALID_ESCROW_ORDER_ID,
    INVALID_ESCROW_ORDER_TYPE,
    ESCROW_ORDER_ALREADY_COMPLETE,
    ESCROW_CONDITIONS_NOT_MET,
    FULL_ESCROW_CONDITIONS_NOT_MET_BEFORE_EXPIRY,
    INVESTOR_ESCROW_CONDITIONS_NOT_MET_AFTER_EXPIRY,
    UN_COLLATRIZED_ORDER_CANNOT_BE_REDEEMED_AFTER_EXPIRY
  }

  event IssuanceEscrowComplete(uint256 orderId);
  event RedemptionEscrowComplete(uint256 orderId);
  event DefaultedEscrow(uint256 orderId);

  function throwError(ErrorCondition condition) internal pure {
    if (condition == ErrorCondition.ACCESS_ERROR) {
      revert ERC1066Error(ReasonCodes.APP_SPECIFIC_FAILURE, "access error");
    } else if (condition == ErrorCondition.INSUFFICIENT_COLLATERAL_BALANCE) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "Insufficient funds"
      );
    } else if (
      condition == ErrorCondition.INSUFFICIENT_LOCKED_COLLATERAL_BALANCE
    ) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "Insufficient funds"
      );
    } else if (condition == ErrorCondition.INVALID_ESCROW_ORDER_ID) {
      revert ERC1066Error(ReasonCodes.APP_SPECIFIC_FAILURE, "invalid order id");
    } else if (condition == ErrorCondition.INVALID_ESCROW_ORDER_TYPE) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "invalid order type"
      );
    } else if (condition == ErrorCondition.ESCROW_ORDER_ALREADY_COMPLETE) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "escrow is complete"
      );
    } else if (condition == ErrorCondition.ESCROW_CONDITIONS_NOT_MET) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "escrow conditions are not met"
      );
    } else if (
      condition == ErrorCondition.FULL_ESCROW_CONDITIONS_NOT_MET_BEFORE_EXPIRY
    ) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "full escrow conditions are not met before expiry"
      );
    } else if (
      condition ==
      ErrorCondition.INVESTOR_ESCROW_CONDITIONS_NOT_MET_AFTER_EXPIRY
    ) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "escrow expired, but investor conditions are not met"
      );
    } else if (
      condition ==
      ErrorCondition.UN_COLLATRIZED_ORDER_CANNOT_BE_REDEEMED_AFTER_EXPIRY
    ) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "un-collateralized order cannot be redeemed after expiry"
      );
    } else {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "unknown error condition"
      );
    }
  }

  modifier onlyOrderType(EscrowType type_, uint256 orderId) {
    if (_escrowStartTimestamp[orderId] == 0) {
      throwError(ErrorCondition.INVALID_ESCROW_ORDER_ID);
    }

    if (_escrowOrdersType[orderId] != type_) {
      throwError(ErrorCondition.INVALID_ESCROW_ORDER_TYPE);
    }

    _;
  }

  function getEscrowOrder(uint256 orderId)
    public
    view
    returns (EscrowOrder memory)
  {
    return _escrowOrders[orderId];
  }

  function setCustodianContract(address custodianContractAddress)
    external
    onlyOwner
  {
    if (address(custodianContract) != address(0x00)) {
      revert("custodian contract is already registered");
    }

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

  function depositInsurerCollateral(address account, address issuer)
    external
    payable
  {
    _insurerCollateralBalanceByIssuer[issuer][account] += msg.value;
    _collateralBalance[account] += msg.value;
  }

  function collateralBalance(address account) external view returns (uint256) {
    return _collateralBalance[account];
  }

  function insurerCollateralBalanceByIssuer(address account, address issuer)
    external
    view
    returns (uint256)
  {
    return _insurerCollateralBalanceByIssuer[issuer][account];
  }

  function lockedCollateralBalance(address account)
    external
    view
    returns (uint256)
  {
    return _collateralBalanceLocked[account];
  }

  function lockedInsurerCollateralBalanceByIssuer(
    address account,
    address issuer
  ) external view returns (uint256) {
    return _insurerLockedCollateralBalanceByIssuer[issuer][account];
  }

  function withdrawCollateral(uint256 value) external {
    if (value > _collateralBalance[msg.sender]) {
      throwError(ErrorCondition.INSUFFICIENT_COLLATERAL_BALANCE);
    }

    payable(msg.sender).transfer(value);
    _collateralBalance[msg.sender] -= value;
  }

  function withdrawInsurerCollateral(
    address account,
    address issuer,
    uint256 value
  ) external {
    if (value > _insurerCollateralBalanceByIssuer[issuer][account]) {
      throwError(ErrorCondition.INSUFFICIENT_LOCKED_COLLATERAL_BALANCE);
    }

    payable(msg.sender).transfer(value);
    _insurerCollateralBalanceByIssuer[issuer][account] -= value;
    _collateralBalance[account] -= value;
  }

  function lockCollateral(address account, uint256 value) internal {
    if (value > _collateralBalance[account]) {
      throwError(ErrorCondition.INSUFFICIENT_COLLATERAL_BALANCE);
    }

    _collateralBalanceLocked[account] += value;
    _collateralBalance[account] -= value;
  }

  function lockInsurerCollateral(
    address issuer,
    address account,
    uint256 value
  ) internal {
    if (value > _insurerCollateralBalanceByIssuer[issuer][account]) {
      throwError(ErrorCondition.INSUFFICIENT_LOCKED_COLLATERAL_BALANCE);
    }

    _insurerLockedCollateralBalanceByIssuer[issuer][account] += value;
    _insurerCollateralBalanceByIssuer[issuer][account] -= value;
    _collateralBalance[account] -= value;
  }

  function unlockCollateral(address account, uint256 value) internal {
    if (value > _collateralBalanceLocked[account]) {
      throwError(ErrorCondition.INSUFFICIENT_LOCKED_COLLATERAL_BALANCE);
    }

    _collateralBalanceLocked[account] -= value;
    _collateralBalance[account] += value;
  }

  function unlockInsurerCollateral(
    address account,
    address issuer,
    uint256 value
  ) internal {
    if (value > _insurerLockedCollateralBalanceByIssuer[issuer][account]) {
      throwError(ErrorCondition.INSUFFICIENT_LOCKED_COLLATERAL_BALANCE);
    }

    _insurerLockedCollateralBalanceByIssuer[issuer][account] -= value;
    _insurerCollateralBalanceByIssuer[issuer][account] += value;
    _collateralBalance[account] += value;
  }

  function spendCollateral(
    address account,
    address payable destination,
    uint256 value
  ) internal {
    if (value > _collateralBalanceLocked[account]) {
      throwError(ErrorCondition.INSUFFICIENT_LOCKED_COLLATERAL_BALANCE);
    }

    _collateralBalanceLocked[account] -= value;
    destination.sendValue(value);
  }

  function spendInsurerCollateral(
    address account,
    address issuer,
    address payable destination,
    uint256 value
  ) internal {
    if (value > _insurerLockedCollateralBalanceByIssuer[issuer][account]) {
      throwError(ErrorCondition.INSUFFICIENT_LOCKED_COLLATERAL_BALANCE);
    }

    _insurerLockedCollateralBalanceByIssuer[issuer][account] -= value;
    destination.sendValue(value);
  }

  function checkOrderCollatrized(uint256 orderId) public view returns (bool) {
    return _escrowOrders[orderId].collateral > 0;
  }

  function checkIssuanceEscrowConditionsIssuerToken(uint256 orderId)
    public
    view
    onlyOrderType(EscrowType.Issuance, orderId)
    returns (bool)
  {
    EscrowOrder storage escrowOrder = _escrowOrders[orderId];

    uint256 allowanceIssuer = IERC20(escrowOrder.tradeToken).allowance(
      escrowOrder.issuerAddress,
      address(this)
    );
    uint256 balanceIssuer = IERC20(escrowOrder.tradeToken).balanceOf(
      escrowOrder.issuerAddress
    );
    uint256 tokenAmount = escrowOrder.tradeTokenAmount;

    return allowanceIssuer >= tokenAmount && balanceIssuer >= tokenAmount;
  }

  function checkIssuanceEscrowConditionsIssuerCollateral(uint256 orderId)
    public
    view
    onlyOrderType(EscrowType.Issuance, orderId)
    returns (bool)
  {
    EscrowOrder storage escrowOrder = _escrowOrders[orderId];

    return
      escrowOrder.issuerCollateral <=
      _collateralBalance[escrowOrder.issuerAddress];
  }

  function checkIssuanceEscrowConditionsInsurerCollateral(uint256 orderId)
    public
    view
    onlyOrderType(EscrowType.Issuance, orderId)
    returns (bool)
  {
    EscrowOrder storage escrowOrder = _escrowOrders[orderId];

    return
      escrowOrder.insurerCollateral <=
      _insurerCollateralBalanceByIssuer[escrowOrder.issuerAddress][
        escrowOrder.collateralProvider
      ];
  }

  function checkIssuanceEscrowConditionsIssuer(uint256 orderId)
    public
    view
    onlyOrderType(EscrowType.Issuance, orderId)
    returns (bool)
  {
    return
      checkIssuanceEscrowConditionsIssuerToken(orderId) &&
      checkIssuanceEscrowConditionsIssuerCollateral(orderId);
  }

  function checkIssuanceEscrowConditionsInvestor(uint256 orderId)
    public
    view
    onlyOrderType(EscrowType.Issuance, orderId)
    returns (bool)
  {
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
    onlyOrderType(EscrowType.Redemption, orderId)
    returns (bool)
  {
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

  function checkRedemptionEscrowConditionsInvestor(uint256 orderId)
    public
    view
    onlyOrderType(EscrowType.Redemption, orderId)
    returns (bool)
  {
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

  function checkIssuanceEscrowConditions(uint256 orderId)
    public
    view
    returns (bool)
  {
    return
      checkIssuanceEscrowConditionsIssuer(orderId) &&
      checkIssuanceEscrowConditionsInvestor(orderId) &&
      checkIssuanceEscrowConditionsInsurerCollateral(orderId);
  }

  function getIssuanceEscrowConditions(uint256 orderId)
    public
    view
    returns (bool[4] memory flags)
  {
    flags[0] = checkIssuanceEscrowConditionsIssuerToken(orderId);
    flags[1] = checkIssuanceEscrowConditionsIssuerCollateral(orderId);
    flags[2] = checkIssuanceEscrowConditionsInvestor(orderId);
    flags[3] = checkIssuanceEscrowConditionsInsurerCollateral(orderId);
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

  function getRedemptionEscrowConditions(uint256 orderId)
    public
    view
    returns (bool[2] memory flags)
  {
    flags[0] = checkRedemptionEscrowConditionsIssuer(orderId);
    flags[1] = checkRedemptionEscrowConditionsInvestor(orderId);
  }

  function startIssuanceEscrow(EscrowOrder calldata escrowOrder)
    external
    override
    onlyToken
    returns (uint256 orderId)
  {
    orderId = _nextEscrowOrderId;
    _nextEscrowOrderId += 1;

    _escrowOrders[orderId] = escrowOrder;
    _escrowOrdersType[orderId] = EscrowType.Issuance;
    _escrowStartTimestamp[orderId] = custodianContract.getTimestamp();
    _escrowOrdersStatus[orderId] = EscrowStatus.Pending;
  }

  function startRedemptionEscrow(EscrowOrder calldata escrowOrder)
    external
    override
    onlyToken
    returns (uint256 orderId)
  {
    // This should never break,
    // as locked collateral must be enough to compensate all
    // tokens, transferred to investors via escrow
    assert(
      escrowOrder.issuerCollateral <=
        _collateralBalanceLocked[escrowOrder.issuerAddress]
    );
    assert(
      escrowOrder.insurerCollateral <=
        _insurerLockedCollateralBalanceByIssuer[escrowOrder.issuerAddress][
          escrowOrder.collateralProvider
        ]
    );

    orderId = _nextEscrowOrderId;
    _nextEscrowOrderId += 1;

    _escrowOrders[orderId] = escrowOrder;
    _escrowOrdersType[orderId] = EscrowType.Redemption;
    _escrowStartTimestamp[orderId] = custodianContract.getTimestamp();
    _escrowOrdersStatus[orderId] = EscrowStatus.Pending;
  }

  function swapIssuance(uint256 orderId) external {
    if (_escrowStartTimestamp[orderId] == 0) {
      throwError(ErrorCondition.INVALID_ESCROW_ORDER_ID);
    }

    if (_escrowOrdersType[orderId] != EscrowType.Issuance) {
      throwError(ErrorCondition.INVALID_ESCROW_ORDER_TYPE);
    }

    if (_escrowOrdersStatus[orderId] == EscrowStatus.Done) {
      throwError(ErrorCondition.ESCROW_ORDER_ALREADY_COMPLETE);
    }

    assert(_escrowOrdersStatus[orderId] == EscrowStatus.Pending);

    _escrowOrdersStatus[orderId] = EscrowStatus.Done;

    bool escrowConditionsFlag = checkIssuanceEscrowConditions(orderId);

    if (!escrowConditionsFlag) {
      throwError(ErrorCondition.ESCROW_CONDITIONS_NOT_MET);
    }

    EscrowOrder storage escrowOrder = _escrowOrders[orderId];

    IERC20(escrowOrder.tradeToken).transferFrom(
      escrowOrder.issuerAddress,
      escrowOrder.tradeTokenDestination,
      escrowOrder.tradeTokenAmount
    );

    IERC20(escrowOrder.paymentToken).transferFrom(
      escrowOrder.investorAddress,
      escrowOrder.paymentTokenDestination,
      escrowOrder.paymentTokenAmount
    );

    lockCollateral(escrowOrder.issuerAddress, escrowOrder.issuerCollateral);
    lockInsurerCollateral(
      escrowOrder.issuerAddress,
      escrowOrder.collateralProvider,
      escrowOrder.insurerCollateral
    );

    ITokenHooks(escrowOrder.tradeToken).onIssue(
      escrowOrder.tradeTokenDestination,
      escrowOrder.tradeTokenAmount,
      orderId
    );

    emit IssuanceEscrowComplete(orderId);
  }

  function swapRedemption(uint256 orderId) external {
    if (_escrowStartTimestamp[orderId] == 0) {
      throwError(ErrorCondition.INVALID_ESCROW_ORDER_ID);
    }

    if (_escrowOrdersType[orderId] != EscrowType.Redemption) {
      throwError(ErrorCondition.INVALID_ESCROW_ORDER_TYPE);
    }

    if (_escrowOrdersStatus[orderId] == EscrowStatus.Done) {
      throwError(ErrorCondition.ESCROW_ORDER_ALREADY_COMPLETE);
    }

    assert(_escrowOrdersStatus[orderId] == EscrowStatus.Pending);

    _escrowOrdersStatus[orderId] = EscrowStatus.Done;

    EscrowOrder storage escrowOrder = _escrowOrders[orderId];

    bool escrowConditionsFlag = checkRedemptionEscrowConditions(orderId);
    bool escrowConditionsInvestorFlag = checkRedemptionEscrowConditionsInvestor(
      orderId
    );
    bool timeoutFlag = custodianContract.getTimestamp() -
      _escrowStartTimestamp[orderId] >
      escrowOrder.timeout;

    if (!escrowConditionsFlag && !timeoutFlag) {
      throwError(ErrorCondition.FULL_ESCROW_CONDITIONS_NOT_MET_BEFORE_EXPIRY);
    }

    assert(escrowConditionsFlag || timeoutFlag);

    if (escrowConditionsFlag) {
      IERC20(escrowOrder.tradeToken).transferFrom(
        escrowOrder.investorAddress,
        escrowOrder.tradeTokenDestination,
        escrowOrder.tradeTokenAmount
      );

      IERC20(escrowOrder.paymentToken).transferFrom(
        escrowOrder.issuerAddress,
        escrowOrder.paymentTokenDestination,
        escrowOrder.paymentTokenAmount
      );

      unlockCollateral(escrowOrder.issuerAddress, escrowOrder.issuerCollateral);
      unlockInsurerCollateral(
        escrowOrder.collateralProvider,
        escrowOrder.issuerAddress,
        escrowOrder.insurerCollateral
      );
    } else {
      assert(timeoutFlag);

      if (!escrowConditionsInvestorFlag) {
        throwError(
          ErrorCondition.INVESTOR_ESCROW_CONDITIONS_NOT_MET_AFTER_EXPIRY
        );
      }

      IERC20(escrowOrder.tradeToken).transferFrom(
        escrowOrder.investorAddress,
        escrowOrder.tradeTokenDestination,
        escrowOrder.tradeTokenAmount
      );

      spendCollateral(
        escrowOrder.issuerAddress,
        payable(escrowOrder.paymentTokenDestination),
        escrowOrder.issuerCollateral
      );
      spendInsurerCollateral(
        escrowOrder.collateralProvider,
        escrowOrder.issuerAddress,
        payable(escrowOrder.paymentTokenDestination),
        escrowOrder.insurerCollateral
      );
      emit DefaultedEscrow(orderId);
    }

    ITokenHooks(escrowOrder.tradeToken).onRedeem(
      escrowOrder.investorAddress,
      escrowOrder.tradeTokenAmount,
      orderId
    );

    emit RedemptionEscrowComplete(orderId);
  }
}
