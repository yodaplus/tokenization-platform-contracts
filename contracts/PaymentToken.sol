//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PaymentToken is ERC20 {
  constructor() ERC20("Payment Token", "PMT") {
    _mint(msg.sender, 10000);
  }
}
