//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import {Token as TokenContract} from "./Token.sol";
import "./ICustodianContract.sol";
import "./ReasonCodes.sol";

contract CustodianContract is Ownable, ICustodianContract, ReasonCodes {
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
    string name;
    string symbol;
    uint8 decimals;
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

  mapping(address => Token) internal _tokens;
  mapping(address => address[]) internal _tokenAddressesByIssuerPrimaryAddress;
  mapping(string => bool) internal _tokenWithNameExists;
  mapping(string => bool) internal _tokenWithSymbolExists;

  mapping(address => mapping(address => bool)) internal _whitelist;

  event TokenPublished(string symbol, address address_);
  event AddWhitelist(address tokenAddress, address address_);
  event RemoveWhitelist(address tokenAddress, address address_);

  error ERC1066Error(bytes1 errorCode, string message);

  enum ErrorCondition {
    WRONG_CALLER,
    USER_ALREADY_EXISTS,
    USER_DOES_NOT_EXIST,
    REMOVED_ISSUER_HAS_TOKENS,
    TOKEN_WRONG_ISSUER,
    TOKEN_WRONG_CUSTODIAN,
    TOKEN_SAME_NAME_EXISTS,
    TOKEN_SAME_SYMBOL_EXISTS
  }

  function throwError(ErrorCondition condition) internal pure {
    if (condition == ErrorCondition.WRONG_CALLER) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "caller is not allowed"
      );
    } else if (condition == ErrorCondition.USER_ALREADY_EXISTS) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "user already exists"
      );
    } else if (condition == ErrorCondition.USER_DOES_NOT_EXIST) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "user does not exists"
      );
    } else if (condition == ErrorCondition.REMOVED_ISSUER_HAS_TOKENS) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "removed issuer must not have tokens"
      );
    } else if (condition == ErrorCondition.TOKEN_WRONG_ISSUER) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "issuer does not exists"
      );
    } else if (condition == ErrorCondition.TOKEN_WRONG_CUSTODIAN) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "custodian does not exists"
      );
    } else if (condition == ErrorCondition.TOKEN_SAME_NAME_EXISTS) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "token with the same name already exists"
      );
    } else if (condition == ErrorCondition.TOKEN_SAME_SYMBOL_EXISTS) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "token with the same symbol already exists"
      );
    }
  }

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
    if (isIssuer(msg.sender) == false) {
      throwError(ErrorCondition.WRONG_CALLER);
    }
    _;
  }

  modifier onlyCustodian() {
    if (isCustodian(msg.sender) == false) {
      throwError(ErrorCondition.WRONG_CALLER);
    }
    _;
  }

  modifier onlyKycProvider() {
    if (isKycProvider(msg.sender) == false) {
      throwError(ErrorCondition.WRONG_CALLER);
    }
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
    if (_isUserType[primaryAddress] == true) {
      throwError(ErrorCondition.USER_ALREADY_EXISTS);
    }

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
    if (_isUserType[primaryAddress] == false) {
      throwError(ErrorCondition.USER_DOES_NOT_EXIST);
    }

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
    if (_isUserType[primaryAddress] == false) {
      throwError(ErrorCondition.USER_DOES_NOT_EXIST);
    }

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
    if (_tokenAddressesByIssuerPrimaryAddress[primaryAddress].length > 0) {
      throwError(ErrorCondition.REMOVED_ISSUER_HAS_TOKENS);
    }

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
    string name;
    string symbol;
    uint8 decimals;
    uint256 maxTotalSupply;
    uint256 value;
    string currency;
    address issuerPrimaryAddress;
    address custodianPrimaryAddress;
    bool earlyRedemption;
    uint256 minSubscription;
  }

  function publishToken(TokenInput calldata token) external onlyIssuer {
    if (_isIssuer[token.issuerPrimaryAddress] == false) {
      throwError(ErrorCondition.TOKEN_WRONG_ISSUER);
    }

    if (_isCustodian[token.custodianPrimaryAddress] == false) {
      throwError(ErrorCondition.TOKEN_WRONG_CUSTODIAN);
    }

    if (_tokenWithNameExists[token.name] == true) {
      throwError(ErrorCondition.TOKEN_SAME_NAME_EXISTS);
    }

    if (_tokenWithSymbolExists[token.symbol] == true) {
      throwError(ErrorCondition.TOKEN_SAME_SYMBOL_EXISTS);
    }

    TokenContract deployedToken = new TokenContract(
      token.name,
      token.symbol,
      token.decimals,
      token.maxTotalSupply
    );

    deployedToken.transferOwnership(msg.sender);

    address tokenAddress = address(deployedToken);

    _tokens[tokenAddress].name = token.name;
    _tokens[tokenAddress].symbol = token.symbol;
    _tokens[tokenAddress].decimals = token.decimals;
    _tokens[tokenAddress].value = token.value;
    _tokens[tokenAddress].currency = token.currency;
    _tokens[tokenAddress].issuerPrimaryAddress = token.issuerPrimaryAddress;
    _tokens[tokenAddress].custodianPrimaryAddress = token
      .custodianPrimaryAddress;
    _tokens[tokenAddress].earlyRedemption = token.earlyRedemption;
    _tokens[tokenAddress].minSubscription = token.minSubscription;
    _tokens[tokenAddress].status = TokenStatus.Published;
    _tokens[tokenAddress].address_ = tokenAddress;

    _tokenWithNameExists[token.name] = true;
    _tokenWithSymbolExists[token.symbol] = true;
    _tokenAddressesByIssuerPrimaryAddress[token.issuerPrimaryAddress].push(
      tokenAddress
    );

    emit TokenPublished(token.symbol, tokenAddress);
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
        _tokenAddressesByIssuerPrimaryAddress[issuerPrimaryAddress][i]
      ];
    }
  }

  function addWhitelist(address tokenAddress, address[] calldata addresses)
    external
    onlyKycProvider
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      _whitelist[tokenAddress][addresses[i]] = true;
      emit AddWhitelist(tokenAddress, addresses[i]);
    }
  }

  function removeWhitelist(address tokenAddress, address[] calldata addresses)
    external
    onlyKycProvider
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      delete _whitelist[tokenAddress][addresses[i]];
      emit RemoveWhitelist(tokenAddress, addresses[i]);
    }
  }

  function canIssue(
    address tokenAddress,
    address to,
    uint256 value
  ) external view override returns (bytes1) {
    if (_whitelist[tokenAddress][to] != true) {
      return ReasonCodes.INVALID_RECEIVER;
    }

    return ReasonCodes.TRANSFER_SUCCESS;
  }

  constructor() {}
}
