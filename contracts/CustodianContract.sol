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

  struct TokenData {
    string name;
    string symbol;
    uint256 value;
    string currency;
    address issuerPrimaryAddress;
    address custodianPrimaryAddress;
    address kycProviderPrimaryAddress;
    address insurerPrimaryAddress;
    bool earlyRedemption;
    uint256 minSubscription;
    TokenStatus status;
    address address_;
    bool onChainKyc;
  }

  struct KycBasicDetails {
    bool leiCheck;
    bool bankCheck;
    bool citizenshipCheck;
    bool addressCheck;
  }

  struct KycAMLCTF {
    bool pepCheck;
    bool sanctionScreening;
    bool suspiciousActivityReport;
    bool cddReport;
    bool fatfComplianceCheck;
  }

  struct KycData {
    bytes32 countryCode;
    bool kycStatus;
    bool accredation;
    bool affiliation;
    bool exempted;
    KycBasicDetails kycBasicDetails;
    KycAMLCTF kycAmlCtf;
  }

  mapping(address => mapping(address => KycData)) public kycVerifications;
  struct InvestorClassificationRules {
    bool isExempted;
    bool isAccredited;
    bool isAffiliated;
  }
  struct TokenRestrictions {
    bytes32[] allowedCountries;
    InvestorClassificationRules allowedInvestorClassifications;
    bool useIssuerWhitelist;
  }
  mapping(address => RoleData) public _issuers;
  mapping(address => RoleData) public _custodians;
  mapping(address => RoleData) public _kycProviders;
  mapping(address => RoleData) public _insurers;

  mapping(address => address) public _addressToIssuerPrimaryAddress;
  mapping(address => address) public _addressToCustodianPrimaryAddress;
  mapping(address => address) public _addressToKycProviderPrimaryAddress;
  mapping(address => address) public _addressToInsurerPrimaryAddress;

  mapping(address => bool) internal _isIssuer;
  mapping(address => bool) internal _isCustodian;
  mapping(address => bool) internal _isKycProvider;
  mapping(address => bool) internal _isInsurer;

  mapping(address => TokenData) internal _tokens;
  mapping(address => TokenRestrictions) internal _tokenRestrictions;
  mapping(address => address[]) internal _tokenAddressesByIssuerPrimaryAddress;
  mapping(address => address[])
    internal _tokenAddressesByCustodianPrimaryAddress;
  mapping(address => address[])
    internal _tokenAddressesByKycProviderPrimaryAddress;
  mapping(address => address[]) internal _tokenAddressesByInsurerPrimaryAddress;

  mapping(string => bool) internal _tokenWithNameExists;
  mapping(string => bool) internal _tokenWithSymbolExists;

  mapping(address => mapping(address => bool)) internal _whitelist;
  mapping(address => mapping(address => bool)) internal _issuerWhitelist;
  mapping(address => string) internal allowedCountries;
  mapping(address => string[]) internal allowedClassifications;
  mapping(address => bool) internal useIssuerWhitelist;

  mapping(address => PaymentTokenStatus) internal _paymentTokensStatus;

  event TokenPublished(string symbol, address address_);
  event AddWhitelist(address tokenAddress, address address_);
  event RemoveWhitelist(address tokenAddress, address address_);
  event AddIssuerWhitelist(address issuerAddress, address address_);
  event RemoveIssuerWhitelist(address issuerAddress, address address_);

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

  event AddInsurer(address primaryAddress);
  event RemoveInsurer(address primaryAddress);
  event AddInsurerAddress(address primaryAddress, address[] addresses);
  event RemoveInsurerAddress(address primaryAddress, address[] addresses);
  event PaymentTokenAdded(address tokenAddress);

  event KycUpdated(address tokenAddress, address investorAddress);

  error ERC1066Error(bytes1 errorCode, string message);

  // Document Events
  event DocumentRemoved(
    bytes32 indexed _name,
    string _uri,
    bytes32 _documentHash
  );
  event DocumentUpdated(
    bytes32 indexed _name,
    string _uri,
    bytes32 _documentHash
  );

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
    TOKEN_WRONG_INSURER,
    TOKEN_SAME_NAME_EXISTS,
    TOKEN_SAME_SYMBOL_EXISTS,
    TOKEN_WRONG_PAYMENT_TOKEN,
    TOKEN_EARLY_REDEMPTION_NOT_ALLOWED,
    TOKEN_DOES_NOT_EXIST,
    TOKEN_PAUSED,
    WRONG_INPUT,
    REMOVED_INSURER_HAS_TOKENS
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
    } else if (condition == ErrorCondition.REMOVED_INSURER_HAS_TOKENS) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "removed insurer must not have tokens"
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
    } else if (condition == ErrorCondition.TOKEN_WRONG_INSURER) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "insurer does not exists"
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
    address issuerAddress,
    address investorAddress,
    KycData calldata investorKycData
  ) external onlyIssuerOrKycProvider {
    kycVerifications[issuerAddress][investorAddress] = investorKycData;
    emit KycUpdated(issuerAddress, investorAddress);
  }

  function isIssuer(address addr) public view returns (bool) {
    return _isIssuer[_addressToIssuerPrimaryAddress[addr]];
  }

  function isInsurer(address addr) public view returns (bool) {
    return _isInsurer[_addressToInsurerPrimaryAddress[addr]];
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

  function isWhitelisted(address tokenAddress, address investorAddress)
    public
    view
    returns (bool)
  {
    return _whitelist[tokenAddress][investorAddress];
  }

  function isIssuerWhitelisted(address issuerAddress, address investorAddress)
    public
    view
    returns (bool)
  {
    return _issuerWhitelist[issuerAddress][investorAddress];
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

  function addInsurer(string calldata countryCode, address primaryAddress)
    external
    onlyOwner
  {
    _addRole(
      _isInsurer,
      _insurers,
      _addressToInsurerPrimaryAddress,
      countryCode,
      primaryAddress
    );
    emit AddInsurer(primaryAddress);
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

  function removeInsurer(address primaryAddress) external onlyOwner {
    if (_tokenAddressesByInsurerPrimaryAddress[primaryAddress].length > 0) {
      throwError(ErrorCondition.REMOVED_INSURER_HAS_TOKENS);
    }
    _removeRole(
      _isInsurer,
      _insurers,
      _addressToInsurerPrimaryAddress,
      primaryAddress
    );
    emit RemoveInsurer(primaryAddress);
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

  function addInsurerAccounts(
    address primaryAddress,
    address[] calldata addresses
  ) external {
    _addRoleAddresses(
      _isInsurer,
      _insurers,
      _addressToInsurerPrimaryAddress,
      primaryAddress,
      addresses
    );
    emit AddInsurerAddress(primaryAddress, addresses);
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

  function removeInsurerAccounts(
    address primaryAddress,
    address[] calldata addresses
  ) external {
    _removeRoleAddresses(
      _isInsurer,
      _insurers,
      _addressToInsurerPrimaryAddress,
      primaryAddress,
      addresses
    );
    emit RemoveInsurerAddress(primaryAddress, addresses);
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
    address insurerPrimaryAddress;
    bool earlyRedemption;
    uint256 minSubscription;
    address[] paymentTokens;
    uint256[] issuanceSwapMultiple;
    uint256[] redemptionSwapMultiple;
    uint256 maturityPeriod;
    uint256 settlementPeriod;
    uint256 collateral;
    uint256 insurerCollateralShare;
    bytes32[] countries;
    InvestorClassificationRules investorClassifications;
    bool useIssuerWhitelist;
    bool onChainKyc;
    bytes32 documentName;
    string documentUri;
    bytes32 documentHash;
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
    if (token.insurerCollateralShare > 0) {
      if (_isInsurer[token.insurerPrimaryAddress] == false) {
        throwError(ErrorCondition.TOKEN_WRONG_INSURER);
      }
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
          collateral: token.collateral,
          issuerCollateralShare: token.collateral -
            token.insurerCollateralShare,
          insurerCollateralShare: token.insurerCollateralShare,
          collateralProvider: token.insurerPrimaryAddress,
          documentName: token.documentName,
          documentUri: token.documentUri,
          documentHash: token.documentHash
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
    _tokens[tokenAddress].insurerPrimaryAddress = token.insurerPrimaryAddress;
    _tokens[tokenAddress].earlyRedemption = token.earlyRedemption;
    _tokens[tokenAddress].minSubscription = token.minSubscription;
    _tokens[tokenAddress].status = TokenStatus.Published;
    _tokens[tokenAddress].address_ = tokenAddress;
    _tokens[tokenAddress].onChainKyc = token.onChainKyc;
    _tokenWithNameExists[token.name] = true;
    _tokenWithSymbolExists[token.symbol] = true;
    _tokenAddressesByIssuerPrimaryAddress[token.issuerPrimaryAddress].push(
      tokenAddress
    );
    _tokenAddressesByCustodianPrimaryAddress[token.custodianPrimaryAddress]
      .push(tokenAddress);
    _tokenAddressesByKycProviderPrimaryAddress[token.kycProviderPrimaryAddress]
      .push(tokenAddress);
    _tokenAddressesByInsurerPrimaryAddress[token.insurerPrimaryAddress].push(
      tokenAddress
    );
    _tokenRestrictions[tokenAddress].allowedCountries = token.countries;
    _tokenRestrictions[tokenAddress].allowedInvestorClassifications = token
      .investorClassifications;
    _tokenRestrictions[tokenAddress].useIssuerWhitelist = token
      .useIssuerWhitelist;

    emit TokenPublished(token.symbol, tokenAddress);
  }

  function getTokens(address issuerPrimaryAddress)
    external
    view
    returns (TokenData[] memory result)
  {
    result = new TokenData[](
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

  function addIssuerWhitelist(
    address issuerAddress,
    address[] calldata addresses
  ) external onlyIssuer {
    for (uint256 i = 0; i < addresses.length; i++) {
      _issuerWhitelist[issuerAddress][addresses[i]] = true;
      emit AddIssuerWhitelist(issuerAddress, addresses[i]);
    }
  }

  function removeIssuerWhitelist(
    address issuerAddress,
    address[] calldata addresses
  ) external onlyIssuer {
    for (uint256 i = 0; i < addresses.length; i++) {
      delete _issuerWhitelist[issuerAddress][addresses[i]];
      emit RemoveIssuerWhitelist(issuerAddress, addresses[i]);
    }
  }

  function addPaymentToken(address tokenAddress) external onlyOwner {
    _paymentTokensStatus[tokenAddress] = PaymentTokenStatus.Active;
    emit PaymentTokenAdded(tokenAddress);
  }

  function removePaymentToken(address tokenAddress) external onlyOwner {
    delete _paymentTokensStatus[tokenAddress];
  }

  function canIssue(
    address tokenAddress,
    address investor,
    uint256 value
  ) external view override returns (bytes1) {
    assertTokenExists(tokenAddress);

    address tokenIssuer = _tokens[tokenAddress].issuerPrimaryAddress;

    // Check if KYC is Complete.
    if (
      !kycVerifications[tokenIssuer][investor].kycStatus &&
      _tokens[tokenAddress].onChainKyc
    ) {
      return ReasonCodes.KYC_INCOMPLETE;
    }

    // Check if investorCountry is allowed using token restrictions.
    bool isInvestorCountryAllowed = false;
    for (
      uint256 i = 0;
      i < _tokenRestrictions[tokenAddress].allowedCountries.length;
      i++
    ) {
      if (
        _tokenRestrictions[tokenAddress].allowedCountries[i] ==
        kycVerifications[tokenIssuer][investor].countryCode
      ) {
        isInvestorCountryAllowed = true;
        break;
      }
    }
    if (
      !isInvestorCountryAllowed &&
      _tokenRestrictions[tokenAddress].allowedCountries.length > 0 &&
      kycVerifications[tokenIssuer][investor].kycBasicDetails.citizenshipCheck
    ) {
      return ReasonCodes.COUNTRY_NOT_ALLOWED;
    }

    // Check if investorClassification is allowed using token restrictions.
    if (
      _tokenRestrictions[tokenAddress].allowedInvestorClassifications.isExempted
    ) {
      if (!kycVerifications[tokenIssuer][investor].exempted) {
        return ReasonCodes.INVESTOR_CLASSIFICATION_NOT_ALLOWED;
      }
    }
    if (
      _tokenRestrictions[tokenAddress]
        .allowedInvestorClassifications
        .isAccredited
    ) {
      if (!kycVerifications[tokenIssuer][investor].accredation) {
        return ReasonCodes.INVESTOR_CLASSIFICATION_NOT_ALLOWED;
      }
    }
    if (
      _tokenRestrictions[tokenAddress]
        .allowedInvestorClassifications
        .isAffiliated
    ) {
      if (!kycVerifications[tokenIssuer][investor].affiliation) {
        return ReasonCodes.INVESTOR_CLASSIFICATION_NOT_ALLOWED;
      }
    }

    if (_tokenRestrictions[tokenAddress].useIssuerWhitelist) {
      if (!_issuerWhitelist[tokenIssuer][investor]) {
        return ReasonCodes.INVALID_RECEIVER;
      }
    } else {
      if (
        (_whitelist[tokenAddress][investor] != true) &&
        (_issuerWhitelist[tokenIssuer][investor] != true)
      ) {
        return ReasonCodes.INVALID_RECEIVER;
      }
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
    address tokenIssuer = _tokens[tokenAddress].issuerPrimaryAddress;

    if (
      (_whitelist[tokenAddress][investor] != true) &&
      (_issuerWhitelist[tokenIssuer][investor] != true)
    ) {
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
