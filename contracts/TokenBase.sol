//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/ICustodianContractQuery.sol";
import "./ReasonCodes.sol";
import "./Tokenomics.sol";
import "./TokenomicsTypes.sol";

abstract contract TokenBase is ERC20Burnable, Pausable, Ownable, ReasonCodes {
  bool internal _isFinalized;
  uint256 internal _maxTotalSupply;
  string internal _symbol;
  ICustodianContractQuery internal _custodianContract;
  Tokenomics public tokenomics;

  constructor(
    string memory name,
    string memory symbol,
    uint256 maxTotalSupply_,
    address custodianContract_,
    address tokenomicsAddr
  ) ERC20(name, symbol) {
    _maxTotalSupply = maxTotalSupply_;
    _custodianContract = ICustodianContractQuery(custodianContract_);
    tokenomics = Tokenomics(tokenomicsAddr);
    _symbol = symbol;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  event BurntContract(address aadr);

  function burnContract(address addr) public onlyOwner whenNotPaused {
    // require statement
    selfdestruct(payable(addr));
    emit BurntContract(addr);
  }

  event SupplyIncreased(uint256 oldValue, uint256 newValue);
  event SupplyDecreased(uint256 oldValue, uint256 newValue);
  event Issued(address _to, uint256 _value, bytes1 _data, uint256 orderId);
  event IssuanceFailure(address _to, uint256 _value, bytes1 _data);
  event Redeemed(
    address _from,
    uint256 _value,
    bytes1 _data,
    uint256 orderId,
    uint256 totalSupply
  );
  event RedeemFailed(address _from, uint256 _value, bytes1 _data);
  event IssuanceFinalized(bool _isFinalized);
  error ERC1066Error(bytes1 errorCode, string message);

  enum ErrorCondition {
    WRONG_CALLER,
    TOKEN_IS_FINALIZED,
    MAX_TOTAL_SUPPLY_MINT,
    CUSTODIAN_VALIDATION_FAIL,
    WRONG_INPUT,
    MAX_SUPPLY_LESS_THAN_TOTAL_SUPPLY,
    TOKEN_IS_PAUSED,
    KYC_INCOMPLETE,
    COUNTRY_NOT_ALLOWED,
    INVESTOR_CLASSIFICATION_NOT_ALLOWED
  }

  function throwError(ErrorCondition condition) internal pure {
    if (condition == ErrorCondition.WRONG_CALLER) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "caller is not allowed"
      );
    } else if (condition == ErrorCondition.TOKEN_IS_FINALIZED) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "token issuance is finalized"
      );
    } else if (condition == ErrorCondition.MAX_TOTAL_SUPPLY_MINT) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "can't mint more than max total supply"
      );
    } else if (condition == ErrorCondition.CUSTODIAN_VALIDATION_FAIL) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "custodian contract validation fail"
      );
    } else if (condition == ErrorCondition.WRONG_INPUT) {
      revert ERC1066Error(ReasonCodes.APP_SPECIFIC_FAILURE, "wrong input");
    } else if (condition == ErrorCondition.MAX_SUPPLY_LESS_THAN_TOTAL_SUPPLY) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "can't set less than total supply"
      );
    } else if (condition == ErrorCondition.KYC_INCOMPLETE) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "KYC is incomplete"
      );
    } else if (condition == ErrorCondition.COUNTRY_NOT_ALLOWED) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "country is not allowed"
      );
    } else if (
      condition == ErrorCondition.INVESTOR_CLASSIFICATION_NOT_ALLOWED
    ) {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "investor classification is not allowed"
      );
    } else if (condition == ErrorCondition.TOKEN_IS_PAUSED) {
      revert ERC1066Error(ReasonCodes.APP_SPECIFIC_FAILURE, "token is paused");
    } else {
      revert ERC1066Error(ReasonCodes.APP_SPECIFIC_FAILURE, "unknown error");
    }
  }

  modifier onlyIssuer() {
    bool isOwner = owner() == msg.sender;
    bool isIssuerOwnerOrEmployee = _custodianContract.isIssuerOwnerOrEmployee(
      owner(),
      msg.sender
    );

    if (!isOwner && !isIssuerOwnerOrEmployee) {
      throwError(ErrorCondition.WRONG_CALLER);
    }
    _;
  }

  function decimals() public pure override returns (uint8) {
    return 0;
  }

  function maxTotalSupply() public view returns (uint256) {
    return _maxTotalSupply;
  }

  function finalizeIssuance() external onlyOwner whenNotPaused {
    _isFinalized = true;
    emit IssuanceFinalized(_isFinalized);
  }

  function setMaxSupply(uint256 maxTotalSupply_)
    external
    payable
    onlyOwner
    whenNotPaused
  {
    if (maxTotalSupply_ < totalSupply()) {
      throwError(ErrorCondition.MAX_SUPPLY_LESS_THAN_TOTAL_SUPPLY);
    }

    if (maxTotalSupply_ > _maxTotalSupply) {
      require(
        msg.value ==
          tokenomics.getPerTokenFee() * (maxTotalSupply_ - _maxTotalSupply),
        "Insufficient funds for publishing token!"
      );

      tokenomics.depositFee{value: msg.value}(
        TokenFeeData({
          addr: address(this),
          issuerPrimaryAddress: owner(),
          symbol: _symbol,
          quantity: maxTotalSupply_ - _maxTotalSupply
        })
      );

      emit SupplyIncreased(_maxTotalSupply, maxTotalSupply_);
    } else if (maxTotalSupply_ < _maxTotalSupply) {
      emit SupplyDecreased(_maxTotalSupply, maxTotalSupply_);
    }

    _maxTotalSupply = maxTotalSupply_;
  }

  function issue(
    address subscriber,
    uint256 value,
    uint256 tranche
  ) public virtual;

  function redeem(address subscriber, uint256 value) public virtual;

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, amount);
  }
}
