//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CustodianContract is Ownable {
  string public constant VERSION = "0.0.1";

  struct User {
    uint256 id;
    string lei;
    string countryCode;
    address primaryAddress;
    address[] addresses;
  }

  mapping(uint256 => User) internal _issuersData;
  mapping(uint256 => User) internal _custodiansData;
  mapping(uint256 => User) internal _kycProvidersData;

  mapping(address => uint256) internal _addressToIssuerId;
  mapping(address => uint256) internal _addressToCustodianId;
  mapping(address => uint256) internal _addressToKycProviderId;

  mapping(uint256 => bool) internal _isIssuer;
  mapping(uint256 => bool) internal _isCustodian;
  mapping(uint256 => bool) internal _isKycProvider;

  function isIssuer(address addr) public view returns (bool) {
    return _isIssuer[_addressToIssuerId[addr]];
  }

  function isCustodian(address addr) public view returns (bool) {
    return _isCustodian[_addressToCustodianId[addr]];
  }

  function isKycProvider(address addr) public view returns (bool) {
    return _isKycProvider[_addressToKycProviderId[addr]];
  }

  modifier onlyIssuer() {
    require(isIssuer(msg.sender), "caller is not an issuer");
    _;
  }

  modifier onlyCustodian() {
    require(isCustodian(msg.sender), "caller is not a custodian");
    _;
  }

  modifier onlyKYCProvider() {
    require(isKycProvider(msg.sender), "caller is not a KYC provider");
    _;
  }

  function _addUser(
    mapping(uint256 => bool) storage _isUserType,
    mapping(uint256 => User) storage _usersData,
    mapping(address => uint256) storage _addressToUserId,
    uint256 id,
    string calldata lei,
    string calldata countryCode,
    address primaryAddress
  ) internal {
    require(_isUserType[id] == false, "user already exists");

    _isUserType[id] = true;
    _usersData[id].id = id;
    _usersData[id].lei = lei;
    _usersData[id].countryCode = countryCode;
    _usersData[id].primaryAddress = primaryAddress;
    _usersData[id].addresses.push(primaryAddress);
    _addressToUserId[primaryAddress] = id;
  }

  function _removeUser(
    mapping(uint256 => bool) storage _isUserType,
    mapping(uint256 => User) storage _usersData,
    mapping(address => uint256) storage _addressToUserId,
    uint256 id
  ) internal {
    require(_isUserType[id] == true, "user does not exists");

    address[] storage addresses = _usersData[id].addresses;

    for (uint256 i = 0; i < addresses.length; i++) {
      delete _addressToUserId[addresses[i]];
    }

    delete _isUserType[id];
    delete _usersData[id];
  }

  function _addUserAddresses(
    mapping(uint256 => bool) storage _isUserType,
    mapping(uint256 => User) storage _usersData,
    mapping(address => uint256) storage _addressToUserId,
    uint256 id,
    address[] calldata addresses
  ) internal {
    require(_isUserType[id] == true, "user does not exists");

    address[] storage userAddresses = _usersData[id].addresses;

    for (uint256 i = 0; i < addresses.length; i++) {
      _addressToUserId[addresses[i]] = id;
      userAddresses.push(addresses[i]);
    }
  }

  function addIssuer(
    uint256 id,
    string calldata lei,
    string calldata countryCode,
    address primaryAddress
  ) external onlyOwner {
    _addUser(
      _isIssuer,
      _issuersData,
      _addressToIssuerId,
      id,
      lei,
      countryCode,
      primaryAddress
    );
  }

  function addCustodian(
    uint256 id,
    string calldata lei,
    string calldata countryCode,
    address primaryAddress
  ) external onlyOwner {
    _addUser(
      _isCustodian,
      _custodiansData,
      _addressToCustodianId,
      id,
      lei,
      countryCode,
      primaryAddress
    );
  }

  function addKycProvider(
    uint256 id,
    string calldata lei,
    string calldata countryCode,
    address primaryAddress
  ) external onlyOwner {
    _addUser(
      _isKycProvider,
      _kycProvidersData,
      _addressToKycProviderId,
      id,
      lei,
      countryCode,
      primaryAddress
    );
  }

  function removeIssuer(uint256 id) external onlyOwner {
    _removeUser(_isIssuer, _issuersData, _addressToIssuerId, id);
  }

  function removeCustodian(uint256 id) external onlyOwner {
    _removeUser(_isCustodian, _custodiansData, _addressToCustodianId, id);
  }

  function removeKycProvider(uint256 id) external onlyOwner {
    _removeUser(_isKycProvider, _kycProvidersData, _addressToKycProviderId, id);
  }

  function addIssuerAccounts(uint256 id, address[] calldata addresses)
    external
    onlyOwner
  {
    _addUserAddresses(
      _isIssuer,
      _issuersData,
      _addressToIssuerId,
      id,
      addresses
    );
  }

  function addCustodianAccounts(uint256 id, address[] calldata addresses)
    external
    onlyOwner
  {
    _addUserAddresses(
      _isCustodian,
      _custodiansData,
      _addressToCustodianId,
      id,
      addresses
    );
  }

  function addKycProviderAccounts(uint256 id, address[] calldata addresses)
    external
    onlyOwner
  {
    _addUserAddresses(
      _isKycProvider,
      _kycProvidersData,
      _addressToKycProviderId,
      id,
      addresses
    );
  }

  constructor() {}
}
