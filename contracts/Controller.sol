//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Controller is Ownable {
  string public constant VERSION = "0.0.1";

  address[] internal _issuers;
  mapping(address => bool) internal _isIssuer;

  modifier onlyIssuer() {
    require(isIssuer(msg.sender), "caller is not an issuer");
    _;
  }

  function isIssuer(address addr) public view returns (bool) {
    return _isIssuer[addr];
  }

  function addIssuer(address addr) external onlyOwner {
    require(_isIssuer[addr] == false, "issuer already exists");

    _isIssuer[addr] = true;
    _issuers.push(addr);
  }

  function deployTokenContract() external onlyIssuer {}

  constructor() {}
}
