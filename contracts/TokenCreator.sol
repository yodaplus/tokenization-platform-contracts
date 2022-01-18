//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {Token as TokenContract} from "./Token.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TokenTvTTypes.sol";

contract TokenCreator is Ownable {
  string public constant VERSION = "0.0.1";

  function publishToken(
    string calldata name,
    string calldata symbol,
    uint256 maxTotalSupply_,
    address issuer
  ) external onlyOwner returns (address tokenAddress) {
    TokenContract deployedToken = new TokenContract(
      name,
      symbol,
      maxTotalSupply_,
      msg.sender
    );
    deployedToken.transferOwnership(issuer);
    return address(deployedToken);
  }
}
