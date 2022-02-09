//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../EscrowTypes.sol";

interface ICustodianContractQuery {
  function isIssuerOwnerOrEmployee(address primaryIssuer, address issuer)
    external
    view
    returns (bool);

  function canIssue(
    address tokenAddress,
    address investor,
    uint256 value
  ) external view returns (bytes1);

  function canRedeem(
    address tokenAddress,
    address investor,
    uint256 value
  ) external view returns (bytes1);

  function getTimestamp() external view returns (uint256);
}
