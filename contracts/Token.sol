//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "./CustodianContract.sol";
import "./ReasonCodes.sol";

contract Token is ERC20Pausable, Ownable, ReasonCodes {
  string public constant VERSION = "0.0.1";
  uint8 internal _decimals;
  bool internal _isFinalized;
  uint256 internal _maxTotalSupply;

  CustodianContract internal _custodianContract;

  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals_,
    uint256 maxTotalSupply_,
    address custodianContract_
  ) ERC20(name, symbol) {
    _decimals = decimals_;
    _maxTotalSupply = maxTotalSupply_;
    _custodianContract = CustodianContract(custodianContract_);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  event SupplyIncreased(uint256 oldValue, uint256 newValue);
  event SupplyDecreased(uint256 oldValue, uint256 newValue);
  event Issued(address _to, uint256 _value, bytes1 _data);
  event IssuanceFailure(address _to, uint256 _value, bytes1 _data);
  event Redeemed(address _from, uint256 _value, bytes1 _data);
  event RedeemFailed(address _from, uint256 _value, bytes1 _data);

  error ERC1066Error(bytes1 errorCode, string message);

  enum ErrorCondition {
    WRONG_CALLER,
    TOKEN_IS_FINALIZED,
    MAX_TOTAL_SUPPLY_MINT,
    CUSTODIAN_VALIDATION_FAIL,
    WRONG_INPUT,
    MAX_SUPPLY_LESS_THAN_TOTAL_SUPPLY,
    TOKEN_IS_PAUSED
  }

  function throwError(ErrorCondition condition) internal pure {
    if (condition == ErrorCondition.WRONG_CALLER) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "caller is not allowed"
      );
    } else if (condition == ErrorCondition.TOKEN_IS_FINALIZED) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "token issuance is finalized"
      );
    } else if (condition == ErrorCondition.MAX_TOTAL_SUPPLY_MINT) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "can't mint more than max total supply"
      );
    } else if (condition == ErrorCondition.CUSTODIAN_VALIDATION_FAIL) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "custodian contract validation fail"
      );
    } else if (condition == ErrorCondition.WRONG_INPUT) {
      revert ERC1066Error(ReasonCodes.APP_SPECIFIC_FAILURE, "wrong input");
    } else if (condition == ErrorCondition.MAX_SUPPLY_LESS_THAN_TOTAL_SUPPLY) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "can't set less than total supply"
      );
    } else {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "unknown error condition"
      );
    }
  }

  modifier onlyIssuer() {
    if (
      owner() != msg.sender &&
      _custodianContract.isIssuerOwnerOrEmployee(owner(), msg.sender) == false
    ) {
      throwError(ErrorCondition.WRONG_CALLER);
    }
    _;
  }

  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  function maxTotalSupply() public view returns (uint256) {
    return _maxTotalSupply;
  }

  function finalizeIssuance() external onlyOwner {
    _isFinalized = true;
  }

  function setMaxSupply(uint256 maxTotalSupply_) external onlyOwner {
    if (maxTotalSupply_ < totalSupply()) {
      throwError(ErrorCondition.MAX_SUPPLY_LESS_THAN_TOTAL_SUPPLY);
    }

    if (maxTotalSupply_ > _maxTotalSupply) {
      emit SupplyIncreased(_maxTotalSupply, maxTotalSupply_);
    } else if (maxTotalSupply_ < _maxTotalSupply) {
      emit SupplyDecreased(_maxTotalSupply, maxTotalSupply_);
    }

    _maxTotalSupply = maxTotalSupply_;
  }

  function issue(address subscriber, uint256 value) public virtual onlyIssuer {
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

    if (reasonCode != ReasonCodes.TRANSFER_SUCCESS) {
      emit IssuanceFailure(subscriber, value, reasonCode);
    } else {
      _mint(subscriber, value);
      emit Issued(subscriber, value, reasonCode);
    }
  }

  function issueBatch(address[] calldata subscribers, uint256[] calldata value)
    external
    onlyIssuer
  {
    if (subscribers.length != value.length) {
      throwError(ErrorCondition.WRONG_INPUT);
    }

    for (uint256 i = 0; i < subscribers.length; i++) {
      issue(subscribers[i], value[i]);
    }
  }

  function redeem(address subscriber, uint256 value) public virtual onlyIssuer {
    bytes1 reasonCode = _custodianContract.canRedeem(
      address(this),
      subscriber,
      value
    );

    address tokenOwner = owner();

    if (balanceOf(subscriber) < value) {
      reasonCode = ReasonCodes.INSUFFICIENT_BALANCE;
    }

    if (allowance(subscriber, tokenOwner) < value) {
      reasonCode = ReasonCodes.INSUFFICIENT_ALLOWANCE;
    }

    if (reasonCode != ReasonCodes.TRANSFER_SUCCESS) {
      emit RedeemFailed(subscriber, value, reasonCode);
    } else {
      uint256 currentAllowance = allowance(subscriber, tokenOwner);
      _approve(subscriber, tokenOwner, currentAllowance - value);
      _burn(subscriber, value);
      emit Redeemed(subscriber, value, reasonCode);
    }
  }

  function redeemBatch(address[] calldata subscribers, uint256[] calldata value)
    external
    onlyIssuer
  {
    if (subscribers.length != value.length) {
      throwError(ErrorCondition.WRONG_INPUT);
    }

    for (uint256 i = 0; i < subscribers.length; i++) {
      redeem(subscribers[i], value[i]);
    }
  }
}
