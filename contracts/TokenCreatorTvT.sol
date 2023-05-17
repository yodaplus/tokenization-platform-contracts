//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {TokenTvT} from "./TokenTvT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TokenTvTTypes.sol";

contract TokenCreatorTvT is Ownable {
  string public constant VERSION = "0.0.1";

  address internal escrowManagerAddress;

  constructor(address escrowManagerAddress_) {
    escrowManagerAddress = escrowManagerAddress_;
  }

  function publishToken(
    TokenTvTInput calldata input,
    address issuer,
    address tokenomicsAddr
  ) external onlyOwner returns (address tokenAddress) {
    TokenTvT deployedToken = new TokenTvT(
      input,
      msg.sender,
      escrowManagerAddress,
      tokenomicsAddr
    );
    deployedToken.transferOwnership(issuer);
    return address(deployedToken);
  }
}
