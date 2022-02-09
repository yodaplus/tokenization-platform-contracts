//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../EscrowTypes.sol";

interface IEscrowInitiate {
  function startIssuanceEscrow(EscrowOrder calldata escrowOrder)
    external
    returns (uint256 orderId);

  function startRedemptionEscrow(EscrowOrder calldata escrowOrder)
    external
    returns (uint256 orderId);
}
