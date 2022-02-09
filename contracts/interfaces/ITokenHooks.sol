//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ITokenHooks {
  function onIssue(address subscriber, uint256 value) external;

  function onRedeem(address subscriber, uint256 value) external;
}
