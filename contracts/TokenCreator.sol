//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {Token as TokenContract} from "./Token.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ITokenCreator.sol";

contract TokenCreator is Ownable, ITokenCreator {
  string public constant VERSION = "0.0.1";

  function publishToken(
    string memory name,
    string memory symbol,
    uint8 decimals_,
    uint256 maxTotalSupply_,
    address issuer
  ) external override onlyOwner returns (address tokenAddress) {
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
}
