//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICustodianContract.sol";
import "./ReasonCodes.sol";

contract Token is ERC20Pausable, Ownable, ReasonCodes {
  string public constant VERSION = "0.0.1";
  uint8 internal _decimals;
  bool internal _isFinalized;
  uint256 internal _maxTotalSupply;

  ICustodianContract internal _custodianContract;

  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals_,
    uint256 maxTotalSupply_,
    address custodianContract_
  ) ERC20(name, symbol) {
    _decimals = decimals_;
    _maxTotalSupply = maxTotalSupply_;
    _custodianContract = ICustodianContract(custodianContract_);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  event SupplyIncreased(uint256 oldValue, uint256 newValue);
  event SupplyDecreased(uint256 oldValue, uint256 newValue);

  error ERC1066Error(bytes1 errorCode, string message);

  enum ErrorCondition {
    TOKEN_IS_FINALIZED,
    MAX_TOTAL_SUPPLY_MINT,
    CUSTODIAN_VALIDATION_FAIL,
    WRONG_INPUT,
    MAX_SUPPLY_LESS_THAN_TOTAL_SUPPLY,
    TOKEN_IS_PAUSED
  }

  function throwError(ErrorCondition condition) internal pure {
    if (condition == ErrorCondition.TOKEN_IS_FINALIZED) {
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
    }
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

  function issue(address subscriber, uint256 value) public onlyOwner {
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
      throwError(ErrorCondition.CUSTODIAN_VALIDATION_FAIL);
    }

    _mint(subscriber, value);
  }

  function issueBatch(address[] calldata subscribers, uint256[] calldata value)
    external
    onlyOwner
  {
    if (subscribers.length != value.length) {
      throwError(ErrorCondition.WRONG_INPUT);
    }

    for (uint256 i = 0; i < subscribers.length; i++) {
      issue(subscribers[i], value[i]);
    }
  }

  function redeem(address subscriber, uint256 value) public onlyOwner {
    bytes1 reasonCode = _custodianContract.canIssue(
      address(this),
      subscriber,
      value
    );

    if (reasonCode != ReasonCodes.TRANSFER_SUCCESS) {
      throwError(ErrorCondition.CUSTODIAN_VALIDATION_FAIL);
    }

    _burn(subscriber, value);
  }

  function redeemBatch(address[] calldata subscribers, uint256[] calldata value)
    external
    onlyOwner
  {
    if (subscribers.length != value.length) {
      throwError(ErrorCondition.WRONG_INPUT);
    }

    for (uint256 i = 0; i < subscribers.length; i++) {
      redeem(subscribers[i], value[i]);
    }
  }
}
