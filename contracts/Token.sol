//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./TokenBase.sol";

contract Token is TokenBase {
  string public constant VERSION = "0.0.1";
  string public constant TYPE = "Token";

  constructor(
    string memory name,
    string memory symbol,
    uint256 maxTotalSupply,
    address custodianContract
  ) TokenBase(name, symbol, maxTotalSupply, custodianContract) {}

  function issue(address subscriber, uint256 value) public override onlyIssuer {
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

  function redeem(address subscriber, uint256 value)
    public
    override
    onlyIssuer
  {
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
}
