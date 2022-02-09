//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ReasonCodes.sol";
import "./TokenCreator.sol";
import "./TokenCreatorTvT.sol";
import "./TokenTvTTypes.sol";
import "./TimeOracle.sol";
import "./interfaces/ICustodianContractQuery.sol";

contract CustodianContract is Ownable, ICustodianContractQuery, ReasonCodes {
  string public constant VERSION = "0.0.1";

  TokenCreator public tokenCreator;
  TokenCreatorTvT public tokenCreatorTvT;
  TimeOracle public timeOracle;

  constructor(
    address tokenCreatorAddr,
    address tokenCreatorTvTAddr,
    address timeOracleAddr
  ) {
    tokenCreator = TokenCreator(tokenCreatorAddr);
    tokenCreatorTvT = TokenCreatorTvT(tokenCreatorTvTAddr);
    timeOracle = TimeOracle(timeOracleAddr);
  }

  struct RoleData {
    address primaryAddress;
    string countryCode;
    address[] addresses;
  }

  enum TokenStatus {
    NonExistent,
    Published
  }

  enum PaymentTokenStatus {
    Inactive,
    Active
  }

  struct Token {
    string name;
    string symbol;
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

  struct InvestorData {
    string countryCode;
    bool LEI_check;
    bool bank_check;
    bool address_check;
    bool citizenship_check;
    bool accredated;
    bool affiliated;
    bool exempted;
    bool pep_check;
    bool gol_check;
    bool fatf_compliance_check;
  }

  mapping(string => InvestorData) public _investors;
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

  mapping(address => PaymentTokenStatus) internal _paymentTokensStatus;

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
    TOKEN_SAME_SYMBOL_EXISTS,
    TOKEN_WRONG_PAYMENT_TOKEN,
    TOKEN_EARLY_REDEMPTION_NOT_ALLOWED,
    TOKEN_DOES_NOT_EXIST,
    TOKEN_PAUSED,
    WRONG_INPUT
  }

  function getTimestamp() external view override returns (uint256) {
    return timeOracle.getTimestamp();
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
        "user does not exist"
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
    } else if (condition == ErrorCondition.TOKEN_WRONG_PAYMENT_TOKEN) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "payment token is not active"
      );
    } else if (condition == ErrorCondition.TOKEN_EARLY_REDEMPTION_NOT_ALLOWED) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "early redemption is not allowed for TvT tokens"
      );
    } else if (condition == ErrorCondition.WRONG_INPUT) {
      revert ERC1066Error(ReasonCodes.APP_SPECIFIC_FAILURE, "wrong input");
    } else if (condition == ErrorCondition.TOKEN_DOES_NOT_EXIST) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "token does not exist"
      );
    } else if (condition == ErrorCondition.TOKEN_PAUSED) {
      revert ERC1066Error(ReasonCodes.APP_SPECIFIC_FAILURE, "token is paused");
    } else {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "unknown error condition"
      );
    }
  }

  function updateKyc(
    string calldata lei,
    InvestorData calldata investor_kyc_data
  ) external onlyKycProvider {
    _investors[lei] = investor_kyc_data;
  }

  function isIssuer(address addr) public view returns (bool) {
    return _isIssuer[_addressToIssuerPrimaryAddress[addr]];
  }

  function isIssuerOwnerOrEmployee(address primaryIssuer, address issuer)
    public
    view
    override
    returns (bool)
  {
    return _addressToIssuerPrimaryAddress[issuer] == primaryIssuer;
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

  modifier onlyIssuerOrKycProvider() {
    if (isIssuer(msg.sender) == false && isKycProvider(msg.sender) == false) {
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
    bool senderNotOwner = owner() != msg.sender;
    bool senderNoPrimaryArgMatch = primaryAddress != msg.sender;
    bool primaryArgNotUser = _isUserType[primaryAddress] == false;

    if (senderNotOwner && (senderNoPrimaryArgMatch || primaryArgNotUser)) {
      throwError(ErrorCondition.WRONG_CALLER);
    }

    if (primaryArgNotUser) {
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
    bool senderNotOwner = owner() != msg.sender;
    bool senderNoPrimaryArgMatch = primaryAddress != msg.sender;
    bool primaryArgNotUser = _isUserType[primaryAddress] == false;

    if (senderNotOwner && (senderNoPrimaryArgMatch || primaryArgNotUser)) {
      throwError(ErrorCondition.WRONG_CALLER);
    }

    if (primaryArgNotUser) {
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
  ) external {
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
  ) external {
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
  ) external {
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
  ) external {
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
  ) external {
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
  ) external {
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
    uint256 maxTotalSupply;
    uint256 value;
    string currency;
    address issuerPrimaryAddress;
    address custodianPrimaryAddress;
    address kycProviderPrimaryAddress;
    bool earlyRedemption;
    uint256 minSubscription;
    address[] paymentTokens;
    uint256[] issuanceSwapMultiple;
    uint256[] redemptionSwapMultiple;
    uint256 maturityPeriod;
    uint256 settlementPeriod;
    uint256 collateral;
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

    if (
      token.paymentTokens.length != token.issuanceSwapMultiple.length ||
      token.paymentTokens.length != token.redemptionSwapMultiple.length
    ) {
      throwError(ErrorCondition.WRONG_INPUT);
    }

    if (token.paymentTokens.length > 0 && token.earlyRedemption) {
      throwError(ErrorCondition.TOKEN_EARLY_REDEMPTION_NOT_ALLOWED);
    }

    for (uint256 i = 0; i < token.paymentTokens.length; i += 1) {
      if (
        _paymentTokensStatus[token.paymentTokens[i]] !=
        PaymentTokenStatus.Active
      ) {
        throwError(ErrorCondition.TOKEN_WRONG_PAYMENT_TOKEN);
      }
    }

    address tokenAddress = token.paymentTokens.length == 0
      ? tokenCreator.publishToken(
        token.name,
        token.symbol,
        token.maxTotalSupply,
        msg.sender
      )
      : tokenCreatorTvT.publishToken(
        TokenTvTInput({
          name: token.name,
          symbol: token.symbol,
          maxTotalSupply: token.maxTotalSupply,
          paymentTokens: token.paymentTokens,
          issuanceSwapMultiple: token.issuanceSwapMultiple,
          redemptionSwapMultiple: token.redemptionSwapMultiple,
          maturityPeriod: token.maturityPeriod,
          settlementPeriod: token.settlementPeriod,
          collateral: token.collateral
        }),
        msg.sender
      );

    _tokens[tokenAddress].name = token.name;
    _tokens[tokenAddress].symbol = token.symbol;
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

  function assertTokenExists(address tokenAddress) internal view {
    if (_tokens[tokenAddress].address_ == address(0x0)) {
      throwError(ErrorCondition.TOKEN_DOES_NOT_EXIST);
    }
  }

  function assertTokenNotPaused(address tokenAddress) internal view {
    bool isPaused = Pausable(tokenAddress).paused();

    if (isPaused) {
      throwError(ErrorCondition.TOKEN_PAUSED);
    }
  }

  function addWhitelist(address tokenAddress, address[] calldata addresses)
    external
    onlyIssuerOrKycProvider
  {
    assertTokenExists(tokenAddress);
    assertTokenNotPaused(tokenAddress);

    for (uint256 i = 0; i < addresses.length; i++) {
      _whitelist[tokenAddress][addresses[i]] = true;
      emit AddWhitelist(tokenAddress, addresses[i]);
    }
  }

  function removeWhitelist(address tokenAddress, address[] calldata addresses)
    external
    onlyIssuerOrKycProvider
  {
    assertTokenExists(tokenAddress);
    assertTokenNotPaused(tokenAddress);

    for (uint256 i = 0; i < addresses.length; i++) {
      delete _whitelist[tokenAddress][addresses[i]];
      emit RemoveWhitelist(tokenAddress, addresses[i]);
    }
  }

  function addPaymentToken(address tokenAddress) external onlyOwner {
    _paymentTokensStatus[tokenAddress] = PaymentTokenStatus.Active;
  }

  function removePaymentToken(address tokenAddress) external onlyOwner {
    delete _paymentTokensStatus[tokenAddress];
  }

  function canIssue(
    address tokenAddress,
    address investor,
    uint256 value
  ) external view override returns (bytes1) {
    if (_whitelist[tokenAddress][investor] != true) {
      return ReasonCodes.INVALID_RECEIVER;
    }

    if (value == 0) {
      return ReasonCodes.APP_SPECIFIC_FAILURE;
    }

    return ReasonCodes.TRANSFER_SUCCESS;
  }

  function canRedeem(
    address tokenAddress,
    address investor,
    uint256 value
  ) external view override returns (bytes1) {
    if (_whitelist[tokenAddress][investor] != true) {
      return ReasonCodes.INVALID_RECEIVER;
    }

    if (value == 0) {
      return ReasonCodes.APP_SPECIFIC_FAILURE;
    }

    return ReasonCodes.TRANSFER_SUCCESS;
  }

  function tokenExists(address tokenAddress) external view returns (bool) {
    return _tokens[tokenAddress].status == TokenStatus.Published;
  }
}
