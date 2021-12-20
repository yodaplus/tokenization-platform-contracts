//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICustodianContract {
  function canIssue(
    address tokenAddress,
    address to,
    uint256 value
  ) external view returns (bytes1);

  function canRedeem(
    address tokenAddress,
    address owner,
    address to,
    uint256 value
  ) external view returns (bytes1);
}
