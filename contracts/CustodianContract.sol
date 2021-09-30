//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import {Token as TokenContract} from "./Token.sol";

contract CustodianContract is Ownable {
  string public constant VERSION = "0.0.1";

  struct User {
    uint256 id;
    string lei;
    string countryCode;
    address primaryAddress;
    address[] addresses;
  }

  enum TokenStatus {
    Published
  }

  struct Token {
    uint256 id;
    string name;
    string symbol;
    uint8 decimal;
    uint256 totalSupply;
    uint256 value;
    string currency;
    uint256 issuerId;
    uint256 custodianId;
    bool earlyRedemption;
    uint256 minSubscription;
    TokenStatus status;
    address address_;
  }

  mapping(uint256 => User) internal _issuers;
  mapping(uint256 => User) internal _custodians;
  mapping(uint256 => User) internal _kycProviders;

  mapping(address => uint256) internal _addressToIssuerId;
  mapping(address => uint256) internal _addressToCustodianId;
  mapping(address => uint256) internal _addressToKycProviderId;

  mapping(uint256 => bool) internal _isIssuer;
  mapping(uint256 => bool) internal _isCustodian;
  mapping(uint256 => bool) internal _isKycProvider;

  mapping(uint256 => Token) internal _tokens;
  mapping(address => uint256) internal _addressToTokenId;
  mapping(uint256 => address[]) internal _tokenAddressesByIssuerId;
  mapping(string => bool) internal _tokenWithNameExists;
  mapping(string => bool) internal _tokenWithSymbolExists;

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
      _issuers,
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
      _custodians,
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
      _kycProviders,
      _addressToKycProviderId,
      id,
      lei,
      countryCode,
      primaryAddress
    );
  }

  function removeIssuer(uint256 id) external onlyOwner {
    _removeUser(_isIssuer, _issuers, _addressToIssuerId, id);
  }

  function removeCustodian(uint256 id) external onlyOwner {
    _removeUser(_isCustodian, _custodians, _addressToCustodianId, id);
  }

  function removeKycProvider(uint256 id) external onlyOwner {
    _removeUser(_isKycProvider, _kycProviders, _addressToKycProviderId, id);
  }

  function addIssuerAccounts(uint256 id, address[] calldata addresses)
    external
    onlyOwner
  {
    _addUserAddresses(_isIssuer, _issuers, _addressToIssuerId, id, addresses);
  }

  function addCustodianAccounts(uint256 id, address[] calldata addresses)
    external
    onlyOwner
  {
    _addUserAddresses(
      _isCustodian,
      _custodians,
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
      _kycProviders,
      _addressToKycProviderId,
      id,
      addresses
    );
  }

  struct TokenInput {
    uint256 id;
    string name;
    string symbol;
    uint8 decimal;
    uint256 totalSupply;
    uint256 value;
    string currency;
    uint256 issuerId;
    uint256 custodianId;
    bool earlyRedemption;
    uint256 minSubscription;
  }

  function publishToken(TokenInput calldata token) external onlyIssuer {
    require(_isIssuer[token.issuerId] == true, "issuer does not exists");
    require(
      _isCustodian[token.custodianId] == true,
      "custodian does not exists"
    );
    require(
      _tokens[token.id].address_ != address(0),
      "token with the same id already exists"
    );
    require(
      _tokenWithNameExists[token.name] == false,
      "token with the same name already exists"
    );
    require(
      _tokenWithSymbolExists[token.symbol] == false,
      "token with the same symbol already exists"
    );
    TokenContract deployedToken = new TokenContract(
      token.name,
      token.symbol,
      token.decimal
    );
    _tokens[token.id].id = token.id;
    _tokens[token.id].name = token.name;
    _tokens[token.id].symbol = token.symbol;
    _tokens[token.id].decimal = token.decimal;
    _tokens[token.id].totalSupply = token.totalSupply;
    _tokens[token.id].value = token.value;
    _tokens[token.id].currency = token.currency;
    _tokens[token.id].issuerId = token.issuerId;
    _tokens[token.id].custodianId = token.custodianId;
    _tokens[token.id].earlyRedemption = token.earlyRedemption;
    _tokens[token.id].minSubscription = token.minSubscription;
    _tokens[token.id].status = TokenStatus.Published;
    _tokens[token.id].address_ = address(deployedToken);
    _tokenWithNameExists[token.name] = true;
    _tokenWithSymbolExists[token.symbol] = true;
    _addressToTokenId[address(deployedToken)] = token.id;
    _tokenAddressesByIssuerId[token.issuerId].push(address(deployedToken));
  }

  function getTokens(uint256 issuerId)
    external
    view
    returns (Token[] memory result)
  {
    result = new Token[](_tokenAddressesByIssuerId[issuerId].length);

    for (uint256 i = 0; i < _tokenAddressesByIssuerId[issuerId].length; i++) {
      result[i] = _tokens[
        _addressToTokenId[_tokenAddressesByIssuerId[issuerId][i]]
      ];
    }
  }

  constructor() {}
}
