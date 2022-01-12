//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./TimeOracle.sol";

contract TimeOracleManual is TimeOracle, AccessControl {
  uint256 _timestamp;
  bool _manualMode;

  constructor() {
    _timestamp = block.timestamp;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function getTimestamp() external view override returns (uint256) {
    return _manualMode ? _timestamp : block.timestamp;
  }

  function syncWithBlock() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _timestamp = block.timestamp;
  }

  function enableManualMode() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _manualMode = true;
  }

  function disableManualMode() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _manualMode = false;
  }

  function moveForwardBySeconds(uint256 shift)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _timestamp += shift;
  }

  function moveBackwardBySeconds(uint256 shift)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _timestamp -= shift;
  }

  function moveForwardByMinutes(uint256 shift)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _timestamp += shift * 60;
  }

  function moveBackwardByMinutes(uint256 shift)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _timestamp -= shift * 60;
  }

  function moveForwardByHours(uint256 shift)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _timestamp += shift * 60 * 60;
  }

  function moveBackwardByHours(uint256 shift)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _timestamp -= shift * 60 * 60;
  }

  function moveForwardByDays(uint256 shift)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _timestamp += shift * 60 * 60 * 24;
  }

  function moveBackwardByDays(uint256 shift)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _timestamp -= shift * 60 * 60 * 24;
  }
}
