//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICustodianContract.sol";
import "./ReasonCodes.sol";
import "./TokenCreator.sol";

contract CustodianContract is Ownable, ICustodianContract, ReasonCodes {
  string public constant VERSION = "0.0.1";

  address public tokenCreatorAddr;

  constructor(address tokenCreatorAddr_) {
    tokenCreatorAddr = tokenCreatorAddr_;
  }

  struct RoleData {
    address primaryAddress;
    string countryCode;
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
    address kycProviderPrimaryAddress;
    bool earlyRedemption;
    uint256 minSubscription;
    TokenStatus status;
    address address_;
  }

  mapping(address => RoleData) public _issuers;
  mapping(address => RoleData) public _custodians;
  mapping(address => RoleData) public _kycProviders;

  mapping(address => address) public _addressToIssuerPrimaryAddress;
  mapping(address => address) public _addressToCustodianPrimaryAddress;
  mapping(address => address) public _addressToKycProviderPrimaryAddress;

  mapping(address => bool) internal _isIssuer;
  mapping(address => bool) internal _isCustodian;
  mapping(address => bool) internal _isKycProvider;

  mapping(address => Token) internal _tokens;
  mapping(address => address[]) internal _tokenAddressesByIssuerPrimaryAddress;
  mapping(address => address[])
    internal _tokenAddressesByCustodianPrimaryAddress;
  mapping(address => address[])
    internal _tokenAddressesByKycProviderPrimaryAddress;

  mapping(string => bool) internal _tokenWithNameExists;
  mapping(string => bool) internal _tokenWithSymbolExists;

  mapping(address => mapping(address => bool)) internal _whitelist;

  event TokenPublished(string symbol, address address_);
  event AddWhitelist(address tokenAddress, address address_);
  event RemoveWhitelist(address tokenAddress, address address_);

  event AddIssuer(address PrimaryAddress);
  event RemoveIssuer(address primaryAddress);
  event AddIssuerAddress(address primaryAddress, address[] addresses);
  event RemoveIssuerAddress(address primaryAddress, address[] addresses);

  event AddCustodian(address primaryAddress);
  event RemoveCustodian(address primaryAddress);
  event AddCustodianAddress(address primaryAddress, address[] addresses);
  event RemoveCustodianAddress(address primaryAddress, address[] addresses);

  event AddKYCProvider(address primaryAddress);
  event RemoveKYCProvider(address primaryAddress);
  event AddKYCProviderAddress(address primaryAddress, address[] addresses);
  event RemoveKYCProviderAddress(address primaryAddress, address[] addresses);

  error ERC1066Error(bytes1 errorCode, string message);

  enum ErrorCondition {
    WRONG_CALLER,
    USER_ALREADY_EXISTS,
    USER_DOES_NOT_EXIST,
    REMOVED_ISSUER_HAS_TOKENS,
    REMOVED_CUSTODIAN_HAS_TOKENS,
    REMOVED_KYCPROVIDER_HAS_TOKENS,
    TOKEN_WRONG_ISSUER,
    TOKEN_WRONG_CUSTODIAN,
    TOKEN_WRONG_KYCPROVIDER,
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
    } else if (condition == ErrorCondition.REMOVED_CUSTODIAN_HAS_TOKENS) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "removed custodian must not have tokens"
      );
    } else if (condition == ErrorCondition.REMOVED_KYCPROVIDER_HAS_TOKENS) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "removed KYC provider must not have tokens"
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
    } else if (condition == ErrorCondition.TOKEN_WRONG_KYCPROVIDER) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "kyc provider does not exists"
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
    } else {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "unknown error condition"
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
    string calldata countryCode,
    address primaryAddress
  ) internal {
    if (_isUserType[primaryAddress] == true) {
      throwError(ErrorCondition.USER_ALREADY_EXISTS);
    }

    _isUserType[primaryAddress] = true;
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

  function _removeRoleAddresses(
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
      for (uint256 j = 0; j < userAddresses.length; j++) {
        if (userAddresses[j] == addresses[i]) {
          delete _addressToUserPrimaryAddress[userAddresses[j]];
          delete userAddresses[j];
        }
      }
    }
  }

  function addIssuer(string calldata countryCode, address primaryAddress)
    external
    onlyOwner
  {
    _addRole(
      _isIssuer,
      _issuers,
      _addressToIssuerPrimaryAddress,
      countryCode,
      primaryAddress
    );
    emit AddIssuer(primaryAddress);
  }

  function addCustodian(string calldata countryCode, address primaryAddress)
    external
    onlyOwner
  {
    _addRole(
      _isCustodian,
      _custodians,
      _addressToCustodianPrimaryAddress,
      countryCode,
      primaryAddress
    );
    emit AddCustodian(primaryAddress);
  }

  function addKycProvider(string calldata countryCode, address primaryAddress)
    external
    onlyOwner
  {
    _addRole(
      _isKycProvider,
      _kycProviders,
      _addressToKycProviderPrimaryAddress,
      countryCode,
      primaryAddress
    );
    emit AddKYCProvider(primaryAddress);
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
    emit RemoveIssuer(primaryAddress);
  }

  function removeCustodian(address primaryAddress) external onlyOwner {
    if (_tokenAddressesByCustodianPrimaryAddress[primaryAddress].length > 0) {
      throwError(ErrorCondition.REMOVED_CUSTODIAN_HAS_TOKENS);
    }
    _removeRole(
      _isCustodian,
      _custodians,
      _addressToCustodianPrimaryAddress,
      primaryAddress
    );
    emit RemoveCustodian(primaryAddress);
  }

  function removeKycProvider(address primaryAddress) external onlyOwner {
    if (_tokenAddressesByKycProviderPrimaryAddress[primaryAddress].length > 0) {
      throwError(ErrorCondition.REMOVED_KYCPROVIDER_HAS_TOKENS);
    }
    _removeRole(
      _isKycProvider,
      _kycProviders,
      _addressToKycProviderPrimaryAddress,
      primaryAddress
    );
    emit RemoveKYCProvider(primaryAddress);
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
    emit AddIssuerAddress(primaryAddress, addresses);
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
    emit AddCustodianAddress(primaryAddress, addresses);
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
    emit AddKYCProviderAddress(primaryAddress, addresses);
  }

  function removeIssuerAccounts(
    address primaryAddress,
    address[] calldata addresses
  ) external onlyOwner {
    _removeRoleAddresses(
      _isIssuer,
      _issuers,
      _addressToIssuerPrimaryAddress,
      primaryAddress,
      addresses
    );
    emit RemoveIssuerAddress(primaryAddress, addresses);
  }

  function removeCustodianAccounts(
    address primaryAddress,
    address[] calldata addresses
  ) external onlyOwner {
    _removeRoleAddresses(
      _isCustodian,
      _custodians,
      _addressToCustodianPrimaryAddress,
      primaryAddress,
      addresses
    );
    emit RemoveCustodianAddress(primaryAddress, addresses);
  }

  function removeKycProviderAccounts(
    address primaryAddress,
    address[] calldata addresses
  ) external onlyOwner {
    _removeRoleAddresses(
      _isKycProvider,
      _kycProviders,
      _addressToKycProviderPrimaryAddress,
      primaryAddress,
      addresses
    );
    emit RemoveKYCProviderAddress(primaryAddress, addresses);
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
    address kycProviderPrimaryAddress;
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

    if (_isKycProvider[token.kycProviderPrimaryAddress] == false) {
      throwError(ErrorCondition.TOKEN_WRONG_KYCPROVIDER);
    }

    if (_tokenWithNameExists[token.name] == true) {
      throwError(ErrorCondition.TOKEN_SAME_NAME_EXISTS);
    }

    if (_tokenWithSymbolExists[token.symbol] == true) {
      throwError(ErrorCondition.TOKEN_SAME_SYMBOL_EXISTS);
    }

    address tokenAddress = TokenCreator(tokenCreatorAddr).publishToken(
      token.name,
      token.symbol,
      token.decimals,
      token.maxTotalSupply,
      msg.sender
    );

    _tokens[tokenAddress].name = token.name;
    _tokens[tokenAddress].symbol = token.symbol;
    _tokens[tokenAddress].decimals = token.decimals;
    _tokens[tokenAddress].value = token.value;
    _tokens[tokenAddress].currency = token.currency;
    _tokens[tokenAddress].issuerPrimaryAddress = token.issuerPrimaryAddress;
    _tokens[tokenAddress].custodianPrimaryAddress = token
      .custodianPrimaryAddress;
    _tokens[tokenAddress].kycProviderPrimaryAddress = token
      .kycProviderPrimaryAddress;
    _tokens[tokenAddress].earlyRedemption = token.earlyRedemption;
    _tokens[tokenAddress].minSubscription = token.minSubscription;
    _tokens[tokenAddress].status = TokenStatus.Published;
    _tokens[tokenAddress].address_ = tokenAddress;
    _tokenWithNameExists[token.name] = true;
    _tokenWithSymbolExists[token.symbol] = true;
    _tokenAddressesByIssuerPrimaryAddress[token.issuerPrimaryAddress].push(
      tokenAddress
    );
    _tokenAddressesByCustodianPrimaryAddress[token.custodianPrimaryAddress]
      .push(tokenAddress);
    _tokenAddressesByKycProviderPrimaryAddress[token.kycProviderPrimaryAddress]
      .push(tokenAddress);

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

    if (value == 0) {
      return ReasonCodes.APP_SPECIFIC_FAILURE;
    }

    return ReasonCodes.TRANSFER_SUCCESS;
  }

  function canRedeem(
    address tokenAddress,
    address owner,
    address from,
    uint256 value
  ) external view override returns (bytes1) {
    if (_whitelist[tokenAddress][from] != true) {
      return ReasonCodes.INVALID_RECEIVER;
    }
    if (value == 0) {
      return ReasonCodes.APP_SPECIFIC_FAILURE;
    }
    IERC20 _token = IERC20(tokenAddress);
    if (_token.balanceOf(from) == 0) {
      return ReasonCodes.APP_SPECIFIC_FAILURE;
    }

    if (_token.allowance(from, owner) < value) {
      return ReasonCodes.APP_SPECIFIC_FAILURE;
    }
    return ReasonCodes.TRANSFER_SUCCESS;
  }
}
