pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface ITokenCreator {
  function publishToken(
    string memory,
    string memory,
    uint8,
    uint256,
    address
  ) external returns (address);
}
