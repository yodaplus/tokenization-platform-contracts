//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract TimeOracle {
  function getTimestamp() external view virtual returns (uint256);
}
