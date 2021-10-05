//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ReasonCodes {
  // ERC1400
  bytes1 public constant TRANSFER_FAILURE = hex"50";
  bytes1 public constant TRANSFER_SUCCESS = hex"51";
  bytes1 public constant INSUFFICIENT_BALANCE = hex"52";
  bytes1 public constant INSUFFICIENT_ALLOWANCE = hex"53";
  bytes1 public constant TRANSFERS_HALTED = hex"54";
  bytes1 public constant FUNDS_LOCKED = hex"55";
  bytes1 public constant INVALID_SENDER = hex"56";
  bytes1 public constant INVALID_RECEIVER = hex"57";
  bytes1 public constant INVALID_OPERATOR = hex"58";

  // ERC1066
  bytes1 public constant APP_SPECIFIC_FAILURE = hex"A0";
}
