//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import {Token as TokenContract} from "./Token.sol";

contract CustodianContract is Ownable {
  string public constant VERSION = "0.0.1";

  struct RoleData {
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
    address issuerPrimaryAddress;
    address custodianPrimaryAddress;
    bool earlyRedemption;
    uint256 minSubscription;
    TokenStatus status;
    address address_;
  }

  mapping(address => RoleData) internal _issuers;
  mapping(address => RoleData) internal _custodians;
  mapping(address => RoleData) internal _kycProviders;

  mapping(address => address) internal _addressToIssuerPrimaryAddress;
  mapping(address => address) internal _addressToCustodianPrimaryAddress;
  mapping(address => address) internal _addressToKycProviderPrimaryAddress;

  mapping(address => bool) internal _isIssuer;
  mapping(address => bool) internal _isCustodian;
  mapping(address => bool) internal _isKycProvider;

  mapping(uint256 => Token) internal _tokens;
  mapping(address => uint256) internal _addressToTokenId;
  mapping(address => address[]) internal _tokenAddressesByIssuerPrimaryAddress;
  mapping(string => bool) internal _tokenWithNameExists;
  mapping(string => bool) internal _tokenWithSymbolExists;

  function isIssuer(address addr) public view returns (bool) {
    return _isIssuer[_addressToIssuerPrimaryAddress[addr]];
  }

  function isCustodian(address addr) public view returns (bool) {
    return _isCustodian[_addressToCustodianPrimaryAddress[addr]];
  }

  function isKycProvider(address addr) public view returns (bool) {
    return _isKycProvider[_addressToKycProviderPrimaryAddress[addr]];
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

  function _addRole(
    mapping(address => bool) storage _isUserType,
    mapping(address => RoleData) storage _usersData,
    mapping(address => address) storage _addressToUserPrimaryAddress,
    string calldata lei,
    string calldata countryCode,
    address primaryAddress
  ) internal {
    require(_isUserType[primaryAddress] == false, "user already exists");

    _isUserType[primaryAddress] = true;
    _usersData[primaryAddress].lei = lei;
    _usersData[primaryAddress].countryCode = countryCode;
    _usersData[primaryAddress].primaryAddress = primaryAddress;
    _usersData[primaryAddress].addresses.push(primaryAddress);
    _addressToUserPrimaryAddress[primaryAddress] = primaryAddress;
  }

  function _removeRole(
    mapping(address => bool) storage _isUserType,
    mapping(address => RoleData) storage _usersData,
    mapping(address => address) storage _addressToUserPrimaryAddress,
    address primaryAddress
  ) internal {
    require(_isUserType[primaryAddress] == true, "user does not exists");

    address[] storage addresses = _usersData[primaryAddress].addresses;

    for (uint256 i = 0; i < addresses.length; i++) {
      delete _addressToUserPrimaryAddress[addresses[i]];
    }

    delete _isUserType[primaryAddress];
    delete _usersData[primaryAddress];
  }

  function _addRoleAddresses(
    mapping(address => bool) storage _isUserType,
    mapping(address => RoleData) storage _usersData,
    mapping(address => address) storage _addressToUserPrimaryAddress,
    address primaryAddress,
    address[] calldata addresses
  ) internal {
    require(_isUserType[primaryAddress] == true, "user does not exists");

    address[] storage userAddresses = _usersData[primaryAddress].addresses;

    for (uint256 i = 0; i < addresses.length; i++) {
      _addressToUserPrimaryAddress[addresses[i]] = primaryAddress;
      userAddresses.push(addresses[i]);
    }
  }

  function addIssuer(
    string calldata lei,
    string calldata countryCode,
    address primaryAddress
  ) external onlyOwner {
    _addRole(
      _isIssuer,
      _issuers,
      _addressToIssuerPrimaryAddress,
      lei,
      countryCode,
      primaryAddress
    );
  }

  function addCustodian(
    string calldata lei,
    string calldata countryCode,
    address primaryAddress
  ) external onlyOwner {
    _addRole(
      _isCustodian,
      _custodians,
      _addressToCustodianPrimaryAddress,
      lei,
      countryCode,
      primaryAddress
    );
  }

  function addKycProvider(
    string calldata lei,
    string calldata countryCode,
    address primaryAddress
  ) external onlyOwner {
    _addRole(
      _isKycProvider,
      _kycProviders,
      _addressToKycProviderPrimaryAddress,
      lei,
      countryCode,
      primaryAddress
    );
  }

  function removeIssuer(address primaryAddress) external onlyOwner {
    _removeRole(
      _isIssuer,
      _issuers,
      _addressToIssuerPrimaryAddress,
      primaryAddress
    );
  }

  function removeCustodian(address primaryAddress) external onlyOwner {
    _removeRole(
      _isCustodian,
      _custodians,
      _addressToCustodianPrimaryAddress,
      primaryAddress
    );
  }

  function removeKycProvider(address primaryAddress) external onlyOwner {
    _removeRole(
      _isKycProvider,
      _kycProviders,
      _addressToKycProviderPrimaryAddress,
      primaryAddress
    );
  }

  function addIssuerAccounts(
    address primaryAddress,
    address[] calldata addresses
  ) external onlyOwner {
    _addRoleAddresses(
      _isIssuer,
      _issuers,
      _addressToIssuerPrimaryAddress,
      primaryAddress,
      addresses
    );
  }

  function addCustodianAccounts(
    address primaryAddress,
    address[] calldata addresses
  ) external onlyOwner {
    _addRoleAddresses(
      _isCustodian,
      _custodians,
      _addressToCustodianPrimaryAddress,
      primaryAddress,
      addresses
    );
  }

  function addKycProviderAccounts(
    address primaryAddress,
    address[] calldata addresses
  ) external onlyOwner {
    _addRoleAddresses(
      _isKycProvider,
      _kycProviders,
      _addressToKycProviderPrimaryAddress,
      primaryAddress,
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
    address issuerPrimaryAddress;
    address custodianPrimaryAddress;
    bool earlyRedemption;
    uint256 minSubscription;
  }

  function publishToken(TokenInput calldata token) external onlyIssuer {
    require(
      _isIssuer[token.issuerPrimaryAddress] == true,
      "issuer does not exists"
    );
    require(
      _isCustodian[token.custodianPrimaryAddress] == true,
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
    _tokens[token.id].issuerPrimaryAddress = token.issuerPrimaryAddress;
    _tokens[token.id].custodianPrimaryAddress = token.custodianPrimaryAddress;
    _tokens[token.id].earlyRedemption = token.earlyRedemption;
    _tokens[token.id].minSubscription = token.minSubscription;
    _tokens[token.id].status = TokenStatus.Published;
    _tokens[token.id].address_ = address(deployedToken);
    _tokenWithNameExists[token.name] = true;
    _tokenWithSymbolExists[token.symbol] = true;
    _addressToTokenId[address(deployedToken)] = token.id;
    _tokenAddressesByIssuerPrimaryAddress[token.issuerPrimaryAddress].push(
      address(deployedToken)
    );
  }

  function getTokens(address issuerPrimaryAddress)
    external
    view
    returns (Token[] memory result)
  {
    result = new Token[](
      _tokenAddressesByIssuerPrimaryAddress[issuerPrimaryAddress].length
    );

    for (
      uint256 i = 0;
      i < _tokenAddressesByIssuerPrimaryAddress[issuerPrimaryAddress].length;
      i++
    ) {
      result[i] = _tokens[
        _addressToTokenId[
          _tokenAddressesByIssuerPrimaryAddress[issuerPrimaryAddress][i]
        ]
      ];
    }
  }

  constructor() {}
}
