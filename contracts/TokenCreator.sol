//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {Token as TokenContract} from "./Token.sol";
import {TokenTvT as TokenTvTContract} from "./TokenTvT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TokenTvTTypes.sol";

contract TokenCreator is Ownable {
  string public constant VERSION = "0.0.1";

  address internal escrowManagerAddress;

  constructor(address escrowManagerAddress_) {
    escrowManagerAddress = escrowManagerAddress_;
  }

  function publishToken(
    string calldata name,
    string calldata symbol,
    uint8 decimals_,
    uint256 maxTotalSupply_,
    address issuer
  ) external onlyOwner returns (address tokenAddress) {
    TokenContract deployedToken = new TokenContract(
      name,
      symbol,
      decimals_,
      maxTotalSupply_,
      msg.sender
    );
    deployedToken.transferOwnership(issuer);
    return address(deployedToken);
  }

  function publishTokenTvT(TokenTvTInput calldata input, address issuer)
    external
    onlyOwner
    returns (address tokenAddress)
  {
    TokenContract deployedToken = new TokenTvTContract(
      input,
      msg.sender,
      escrowManagerAddress
    );
    deployedToken.transferOwnership(issuer);
    return address(deployedToken);
  }
}
