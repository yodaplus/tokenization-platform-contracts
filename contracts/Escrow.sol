//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Escrow is Ownable {
  string public constant VERSION = "0.0.1";

  IERC20 internal tokenA;
  IERC20 internal tokenB;

  uint256 internal amountA;
  uint256 internal amountB;

  address internal addressA;
  address internal addressB;

  enum Status {
    Pending,
    Done
  }

  Status internal status;

  constructor(
    address tokenA_,
    uint256 amountA_,
    address addressA_,
    address tokenB_,
    uint256 amountB_,
    address addressB_
  ) {
    tokenA = IERC20(tokenA_);
    amountA = amountA_;
    addressA = addressA_;
    tokenB = IERC20(tokenB_);
    amountB = amountB_;
    addressB = addressB_;

    status = Status.Pending;
  }

  function checkEscrowConditionsA() public view returns (bool) {
    uint256 allowanceA = tokenA.allowance(addressA, address(this));
    uint256 balanceA = tokenA.balanceOf(addressA);

    return allowanceA >= amountA && balanceA >= amountA;
  }

  function checkEscrowConditionsB() public view returns (bool) {
    uint256 allowanceB = tokenB.allowance(addressB, address(this));
    uint256 balanceB = tokenB.balanceOf(addressB);

    return allowanceB >= amountB && balanceB >= amountB;
  }

  function checkEscrowConditions() public view returns (bool) {
    return checkEscrowConditionsA() && checkEscrowConditionsB();
  }

  function swap() external {
    require(status != Status.Done, "Escrow is completed");

    assert(status == Status.Pending);

    if (!checkEscrowConditions()) {
      revert("Escrow conditions are not met");
    }

    tokenA.transferFrom(addressA, addressB, amountA);
    tokenB.transferFrom(addressB, addressA, amountB);
    status = Status.Done;
  }

  function refundA(address recipient, uint256 amount) external onlyOwner {
    tokenA.transfer(recipient, amount);
  }

  function refundB(address recipient, uint256 amount) external onlyOwner {
    tokenA.transfer(recipient, amount);
  }
}
