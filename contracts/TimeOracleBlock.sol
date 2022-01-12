//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./TimeOracle.sol";

contract TimeOracleBlock is TimeOracle {
  function getTimestamp() external view override returns (uint256) {
    return block.timestamp;
  }
}
