//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICustodianContract.sol";

contract Token is ERC20, Ownable {
  string public constant VERSION = "0.0.1";

  uint8 internal _decimals;

  bool internal _isFinalized;
  uint256 internal _maxTotalSupply;

  ICustodianContract internal _custodianContract;

  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals_,
    uint256 maxTotalSupply_
  ) ERC20(name, symbol) {
    _decimals = decimals_;
    _maxTotalSupply = maxTotalSupply_;
    _custodianContract = ICustodianContract(msg.sender);
  }

  event SupplyIncreased(uint256 oldValue, uint256 newValue);

  event SupplyDecreased(uint256 oldValue, uint256 newValue);

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
    require(
      maxTotalSupply_ >= totalSupply(),
      "can't set less than total supply"
    );

    if (maxTotalSupply_ > _maxTotalSupply) {
      emit SupplyIncreased(_maxTotalSupply, maxTotalSupply_);
    } else if (maxTotalSupply_ < _maxTotalSupply) {
      emit SupplyDecreased(_maxTotalSupply, maxTotalSupply_);
    }

    _maxTotalSupply = maxTotalSupply_;
  }

  function issue(address subscriber, uint256 value) public {
    require(_isFinalized == false, "token issuance is finalized");
    require(
      _maxTotalSupply >= totalSupply() + value,
      "can't mint more than max total supply"
    );

    try _custodianContract.canIssue(address(this), subscriber, value) {} catch {
      revert("custodian contract validation fail");
    }

    _mint(subscriber, value);
  }

  function issueBatch(address[] calldata subscribers, uint256[] calldata value)
    external
    onlyOwner
  {
    require(subscribers.length == value.length, "wrong input");

    for (uint256 i = 0; i < subscribers.length; i++) {
      issue(subscribers[i], value[i]);
    }
  }
}
