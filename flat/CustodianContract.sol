//SPDX-License-Identifier: Unlicense
// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts/utils/Context.sol@v4.3.2

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

// File @openzeppelin/contracts/access/Ownable.sol@v4.3.2

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    _setOwner(_msgSender());
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    _setOwner(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _setOwner(newOwner);
  }

  function _setOwner(address newOwner) private {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.3.2

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File @openzeppelin/contracts/security/Pausable.sol@v4.3.2

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
  /**
   * @dev Emitted when the pause is triggered by `account`.
   */
  event Paused(address account);

  /**
   * @dev Emitted when the pause is lifted by `account`.
   */
  event Unpaused(address account);

  bool private _paused;

  /**
   * @dev Initializes the contract in unpaused state.
   */
  constructor() {
    _paused = false;
  }

  /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function paused() public view virtual returns (bool) {
    return _paused;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  modifier whenNotPaused() {
    require(!paused(), "Pausable: paused");
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  modifier whenPaused() {
    require(paused(), "Pausable: not paused");
    _;
  }

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function _pause() internal virtual whenNotPaused {
    _paused = true;
    emit Paused(_msgSender());
  }

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function _unpause() internal virtual whenPaused {
    _paused = false;
    emit Unpaused(_msgSender());
  }
}

// File contracts/ReasonCodes.sol

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

// File @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol@v4.3.2

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
  /**
   * @dev Returns the name of the token.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the symbol of the token.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the decimals places of the token.
   */
  function decimals() external view returns (uint8);
}

// File @openzeppelin/contracts/token/ERC20/ERC20.sol@v4.3.2

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;

  /**
   * @dev Sets the values for {name} and {symbol}.
   *
   * The default value of {decimals} is 18. To select a different value for
   * {decimals} you should overload it.
   *
   * All two of these values are immutable: they can only be set once during
   * construction.
   */
  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5.05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless this function is
   * overridden;
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _balances[account];
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * Requirements:
   *
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(
      currentAllowance >= amount,
      "ERC20: transfer amount exceeds allowance"
    );
    unchecked {
      _approve(sender, _msgSender(), currentAllowance - amount);
    }

    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender] + addedValue
    );
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(
      currentAllowance >= subtractedValue,
      "ERC20: decreased allowance below zero"
    );
    unchecked {
      _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

    return true;
  }

  /**
   * @dev Moves `amount` of tokens from `sender` to `recipient`.
   *
   * This internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
      _balances[sender] = senderBalance - amount;
    }
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);

    _afterTokenTransfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);

    _afterTokenTransfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
      _balances[account] = accountBalance - amount;
    }
    _totalSupply -= amount;

    emit Transfer(account, address(0), amount);

    _afterTokenTransfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
   *
   * This internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}

  /**
   * @dev Hook that is called after any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * has been transferred to `to`.
   * - when `from` is zero, `amount` tokens have been minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}

// File @openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol@v4.3.2

pragma solidity ^0.8.0;

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
  /**
   * @dev See {ERC20-_beforeTokenTransfer}.
   *
   * Requirements:
   *
   * - the contract must not be paused.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    require(!paused(), "ERC20Pausable: token transfer while paused");
  }
}

// File contracts/EscrowTypes.sol

pragma solidity ^0.8.0;

struct EscrowOrder {
  address tradeToken;
  uint256 tradeTokenAmount;
  address tradeTokenDestination;
  address issuerAddress;
  address paymentToken;
  uint256 paymentTokenAmount;
  address paymentTokenDestination;
  address investorAddress;
  uint256 collateral;
  uint256 timeout;
}

// File contracts/interfaces/ICustodianContractQuery.sol

pragma solidity ^0.8.0;

interface ICustodianContractQuery {
  function isIssuerOwnerOrEmployee(address primaryIssuer, address issuer)
    external
    view
    returns (bool);

  function canIssue(
    address tokenAddress,
    address investor,
    uint256 value
  ) external view returns (bytes1);

  function canRedeem(
    address tokenAddress,
    address investor,
    uint256 value
  ) external view returns (bytes1);

  function getTimestamp() external view returns (uint256);
}

// File contracts/TokenBase.sol

pragma solidity ^0.8.0;

abstract contract TokenBase is ERC20Pausable, Ownable, ReasonCodes {
  bool internal _isFinalized;
  uint256 internal _maxTotalSupply;

  ICustodianContractQuery internal _custodianContract;

  constructor(
    string memory name,
    string memory symbol,
    uint256 maxTotalSupply_,
    address custodianContract_
  ) ERC20(name, symbol) {
    _maxTotalSupply = maxTotalSupply_;
    _custodianContract = ICustodianContractQuery(custodianContract_);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  event SupplyIncreased(uint256 oldValue, uint256 newValue);
  event SupplyDecreased(uint256 oldValue, uint256 newValue);
  event Issued(address _to, uint256 _value, bytes1 _data);
  event IssuanceFailure(address _to, uint256 _value, bytes1 _data);
  event Redeemed(address _from, uint256 _value, bytes1 _data);
  event RedeemFailed(address _from, uint256 _value, bytes1 _data);

  error ERC1066Error(bytes1 errorCode, string message);

  enum ErrorCondition {
    WRONG_CALLER,
    TOKEN_IS_FINALIZED,
    MAX_TOTAL_SUPPLY_MINT,
    CUSTODIAN_VALIDATION_FAIL,
    WRONG_INPUT,
    MAX_SUPPLY_LESS_THAN_TOTAL_SUPPLY,
    TOKEN_IS_PAUSED
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
    } else {
      revert ERC1066Error(
        ReasonCodes.APP_SPECIFIC_FAILURE,
        "unknown error condition"
      );
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

  function finalizeIssuance() external onlyOwner {
    _isFinalized = true;
  }

  function setMaxSupply(uint256 maxTotalSupply_) external onlyOwner {
    if (maxTotalSupply_ < totalSupply()) {
      throwError(ErrorCondition.MAX_SUPPLY_LESS_THAN_TOTAL_SUPPLY);
    }

    if (maxTotalSupply_ > _maxTotalSupply) {
      emit SupplyIncreased(_maxTotalSupply, maxTotalSupply_);
    } else if (maxTotalSupply_ < _maxTotalSupply) {
      emit SupplyDecreased(_maxTotalSupply, maxTotalSupply_);
    }

    _maxTotalSupply = maxTotalSupply_;
  }

  function issue(address subscriber, uint256 value) public virtual;

  function issueBatch(address[] calldata subscribers, uint256[] calldata value)
    external
    onlyIssuer
  {
    if (subscribers.length != value.length) {
      throwError(ErrorCondition.WRONG_INPUT);
    }
    for (uint256 i = 0; i < subscribers.length; i++) {
      issue(subscribers[i], value[i]);
    }
  }

  function redeem(address subscriber, uint256 value) public virtual;

  function redeemBatch(address[] calldata subscribers, uint256[] calldata value)
    external
    onlyIssuer
  {
    if (subscribers.length != value.length) {
      throwError(ErrorCondition.WRONG_INPUT);
    }

    for (uint256 i = 0; i < subscribers.length; i++) {
      redeem(subscribers[i], value[i]);
    }
  }
}

// File contracts/Token.sol

pragma solidity ^0.8.0;

contract Token is TokenBase {
  string public constant VERSION = "0.0.1";
  string public constant TYPE = "Token";

  constructor(
    string memory name,
    string memory symbol,
    uint256 maxTotalSupply,
    address custodianContract
  ) TokenBase(name, symbol, maxTotalSupply, custodianContract) {}

  function issue(address subscriber, uint256 value) public override onlyIssuer {
    if (_isFinalized == true) {
      throwError(ErrorCondition.TOKEN_IS_FINALIZED);
    }

    if (_maxTotalSupply < totalSupply() + value) {
      throwError(ErrorCondition.MAX_TOTAL_SUPPLY_MINT);
    }

    bytes1 reasonCode = _custodianContract.canIssue(
      address(this),
      subscriber,
      value
    );

    if (reasonCode != ReasonCodes.TRANSFER_SUCCESS) {
      emit IssuanceFailure(subscriber, value, reasonCode);
    } else {
      _mint(subscriber, value);
      emit Issued(subscriber, value, reasonCode);
    }
  }

  function redeem(address subscriber, uint256 value)
    public
    override
    onlyIssuer
  {
    bytes1 reasonCode = _custodianContract.canRedeem(
      address(this),
      subscriber,
      value
    );

    address tokenOwner = owner();

    if (balanceOf(subscriber) < value) {
      reasonCode = ReasonCodes.INSUFFICIENT_BALANCE;
    }

    if (allowance(subscriber, tokenOwner) < value) {
      reasonCode = ReasonCodes.INSUFFICIENT_ALLOWANCE;
    }

    if (reasonCode != ReasonCodes.TRANSFER_SUCCESS) {
      emit RedeemFailed(subscriber, value, reasonCode);
    } else {
      uint256 currentAllowance = allowance(subscriber, tokenOwner);
      _approve(subscriber, tokenOwner, currentAllowance - value);
      _burn(subscriber, value);
      emit Redeemed(subscriber, value, reasonCode);
    }
  }
}

// File contracts/TokenTvTTypes.sol

pragma solidity ^0.8.0;

struct TokenTvTInput {
  string name;
  string symbol;
  uint256 maxTotalSupply;
  address[] paymentTokens;
  uint256[] issuanceSwapMultiple;
  uint256[] redemptionSwapMultiple;
  uint256 maturityPeriod;
  uint256 settlementPeriod;
  uint256 collateral;
}

// File contracts/TokenCreator.sol

pragma solidity ^0.8.0;

contract TokenCreator is Ownable {
  string public constant VERSION = "0.0.1";

  function publishToken(
    string calldata name,
    string calldata symbol,
    uint256 maxTotalSupply_,
    address issuer
  ) external onlyOwner returns (address tokenAddress) {
    Token deployedToken = new Token(name, symbol, maxTotalSupply_, msg.sender);
    deployedToken.transferOwnership(issuer);
    return address(deployedToken);
  }
}

// File contracts/interfaces/ITokenHooks.sol

pragma solidity ^0.8.0;

interface ITokenHooks {
  function onIssue(address subscriber, uint256 value) external;

  function onRedeem(address subscriber, uint256 value) external;
}

// File contracts/interfaces/IEscrowInitiate.sol

pragma solidity ^0.8.0;

interface IEscrowInitiate {
  function startIssuanceEscrow(EscrowOrder calldata escrowOrder)
    external
    returns (uint256 orderId);

  function startRedemptionEscrow(EscrowOrder calldata escrowOrder)
    external
    returns (uint256 orderId);
}

// File contracts/TokenTvT.sol

pragma solidity ^0.8.0;

contract TokenTvT is TokenBase, ITokenHooks {
  string public constant VERSION = "0.0.1";
  string public constant TYPE = "TokenTvT";

  address[] internal _paymentTokens;
  uint256[] internal _issuanceSwapMultiple;
  uint256[] internal _redemptionSwapMultiple;
  uint256 internal _maturityPeriod;
  uint256 internal _settlementPeriod;
  uint256 internal _collateral;

  mapping(address => mapping(uint256 => uint256))
    internal _issuedTokensByMaturityBucket;
  mapping(address => uint256[]) internal _issuedTokensMaturityBuckets;

  IEscrowInitiate public escrowManager;

  event IssuanceEscrowInitiated(
    uint256 orderId,
    address tradeToken,
    uint256 tradeTokenAmount,
    address tradeTokenDestination,
    address issuerAddress,
    address paymentToken,
    uint256 paymentTokenAmount,
    address paymentTokenDestination,
    address investorAddress,
    uint256 collateral,
    uint256 timeout
  );

  event RedemptionEscrowInitiated(
    uint256 orderId,
    address tradeToken,
    uint256 tradeTokenAmount,
    address tradeTokenDestination,
    address issuerAddress,
    address paymentToken,
    uint256 paymentTokenAmount,
    address paymentTokenDestination,
    address investorAddress,
    uint256 collateral,
    uint256 timeout
  );

  constructor(
    TokenTvTInput memory input,
    address custodianContract,
    address escrowManagerAddress
  )
    TokenBase(input.name, input.symbol, input.maxTotalSupply, custodianContract)
  {
    _paymentTokens = input.paymentTokens;
    _issuanceSwapMultiple = input.issuanceSwapMultiple;
    _redemptionSwapMultiple = input.redemptionSwapMultiple;
    _maturityPeriod = input.maturityPeriod;
    _settlementPeriod = input.settlementPeriod;
    _collateral = input.collateral;
    escrowManager = IEscrowInitiate(escrowManagerAddress);
  }

  function issue(address subscriber, uint256 value) public override onlyIssuer {
    return issue(subscriber, owner(), subscriber, value);
  }

  function issue(
    address subscriber,
    address paymentTokenDestination,
    address tradeTokenDestination,
    uint256 value
  ) public onlyIssuer {
    if (_isFinalized == true) {
      throwError(ErrorCondition.TOKEN_IS_FINALIZED);
    }

    if (_maxTotalSupply < totalSupply() + value) {
      throwError(ErrorCondition.MAX_TOTAL_SUPPLY_MINT);
    }

    bytes1 reasonCode = _custodianContract.canIssue(
      address(this),
      subscriber,
      value
    );

    address tokenOwner = owner();

    if (reasonCode != ReasonCodes.TRANSFER_SUCCESS) {
      emit IssuanceFailure(subscriber, value, reasonCode);
    } else {
      _mint(tokenOwner, value);
      increaseAllowance(address(escrowManager), value);
      EscrowOrder memory escrowOrder = EscrowOrder({
        tradeToken: address(this),
        tradeTokenAmount: value,
        tradeTokenDestination: tradeTokenDestination,
        issuerAddress: tokenOwner,
        paymentToken: _paymentTokens[0],
        paymentTokenAmount: _issuanceSwapMultiple[0] * value,
        paymentTokenDestination: paymentTokenDestination,
        investorAddress: subscriber,
        collateral: _collateral * value,
        timeout: _settlementPeriod
      });
      uint256 orderId = escrowManager.startIssuanceEscrow(escrowOrder);
      emit IssuanceEscrowInitiated(
        orderId,
        escrowOrder.tradeToken,
        escrowOrder.tradeTokenAmount,
        escrowOrder.tradeTokenDestination,
        escrowOrder.issuerAddress,
        escrowOrder.paymentToken,
        escrowOrder.paymentTokenAmount,
        escrowOrder.paymentTokenDestination,
        escrowOrder.investorAddress,
        escrowOrder.collateral,
        escrowOrder.timeout
      );
    }
  }

  function onIssue(address subscriber, uint256 value) external override {
    if (msg.sender != address(escrowManager)) {
      throwError(ErrorCondition.WRONG_CALLER);
    }

    uint256 timestamp = _custodianContract.getTimestamp();

    _issuedTokensByMaturityBucket[subscriber][timestamp] += value;
    _issuedTokensMaturityBuckets[subscriber].push(timestamp);

    emit Issued(subscriber, value, ReasonCodes.TRANSFER_SUCCESS);
  }

  function onRedeem(address subscriber, uint256 value) external override {
    if (msg.sender != address(escrowManager)) {
      throwError(ErrorCondition.WRONG_CALLER);
    }

    uint256 i = 0;
    uint256 remainingValue = value;
    uint256[] storage maturityBuckets = _issuedTokensMaturityBuckets[
      subscriber
    ];

    while (
      i < maturityBuckets.length &&
      remainingValue > 0 &&
      (maturityBuckets[i] + _maturityPeriod < _custodianContract.getTimestamp())
    ) {
      uint256 currentBucketBalance = _issuedTokensByMaturityBucket[subscriber][
        maturityBuckets[i]
      ];

      if (currentBucketBalance > remainingValue) {
        _issuedTokensByMaturityBucket[subscriber][maturityBuckets[i]] =
          currentBucketBalance -
          remainingValue;
        remainingValue = 0;
      } else {
        _issuedTokensByMaturityBucket[subscriber][maturityBuckets[i]] = 0;
        remainingValue = remainingValue - currentBucketBalance;
      }

      i += 1;
    }

    emit Redeemed(subscriber, value, ReasonCodes.TRANSFER_SUCCESS);
  }

  function matureBalanceOf(address subscriber)
    public
    view
    returns (uint256 result)
  {
    uint256 i = 0;
    uint256[] storage maturityBuckets = _issuedTokensMaturityBuckets[
      subscriber
    ];

    while (
      i < maturityBuckets.length &&
      (maturityBuckets[i] + _maturityPeriod < _custodianContract.getTimestamp())
    ) {
      result += _issuedTokensByMaturityBucket[subscriber][maturityBuckets[i]];

      i += 1;
    }
  }

  function matureBalanceOfPending(address subscriber)
    public
    view
    returns (uint256 result)
  {
    uint256 i = 0;
    uint256[] storage maturityBuckets = _issuedTokensMaturityBuckets[
      subscriber
    ];

    while (
      i < maturityBuckets.length &&
      (maturityBuckets[maturityBuckets.length - i - 1] + _maturityPeriod >=
        _custodianContract.getTimestamp())
    ) {
      result += _issuedTokensByMaturityBucket[subscriber][
        maturityBuckets[maturityBuckets.length - i - 1]
      ];

      i += 1;
    }
  }

  function balanceOf(address account) public view override returns (uint256) {
    return super.balanceOf(account);
  }

  function redeem(address subscriber, uint256 value) public override {
    return redeem(subscriber, subscriber, owner(), value);
  }

  function redeem(
    address subscriber,
    address paymentTokenDestination,
    address tradeTokenDestination,
    uint256 value
  ) public {
    if (msg.sender != subscriber) {
      throwError(ErrorCondition.WRONG_CALLER);
    }

    bytes1 reasonCode = _custodianContract.canRedeem(
      address(this),
      subscriber,
      value
    );

    if (matureBalanceOf(subscriber) < value || balanceOf(subscriber) < value) {
      reasonCode = ReasonCodes.INSUFFICIENT_BALANCE;
    }

    if (reasonCode != ReasonCodes.TRANSFER_SUCCESS) {
      emit RedeemFailed(subscriber, value, reasonCode);
    } else {
      increaseAllowance(address(escrowManager), value);
      EscrowOrder memory escrowOrder = EscrowOrder({
        tradeToken: address(this),
        tradeTokenAmount: value,
        tradeTokenDestination: tradeTokenDestination,
        issuerAddress: owner(),
        paymentToken: _paymentTokens[0],
        paymentTokenAmount: _redemptionSwapMultiple[0] * value,
        paymentTokenDestination: paymentTokenDestination,
        investorAddress: subscriber,
        collateral: _collateral * value,
        timeout: _settlementPeriod
      });
      uint256 orderId = escrowManager.startRedemptionEscrow(escrowOrder);
      emit RedemptionEscrowInitiated(
        orderId,
        escrowOrder.tradeToken,
        escrowOrder.tradeTokenAmount,
        escrowOrder.tradeTokenDestination,
        escrowOrder.issuerAddress,
        escrowOrder.paymentToken,
        escrowOrder.paymentTokenAmount,
        escrowOrder.paymentTokenDestination,
        escrowOrder.investorAddress,
        escrowOrder.collateral,
        escrowOrder.timeout
      );
    }
  }
}

// File contracts/TokenCreatorTvT.sol

pragma solidity ^0.8.0;

contract TokenCreatorTvT is Ownable {
  string public constant VERSION = "0.0.1";

  address internal escrowManagerAddress;

  constructor(address escrowManagerAddress_) {
    escrowManagerAddress = escrowManagerAddress_;
  }

  function publishToken(TokenTvTInput calldata input, address issuer)
    external
    onlyOwner
    returns (address tokenAddress)
  {
    TokenTvT deployedToken = new TokenTvT(
      input,
      msg.sender,
      escrowManagerAddress
    );
    deployedToken.transferOwnership(issuer);
    return address(deployedToken);
  }
}

// File contracts/TimeOracle.sol

pragma solidity ^0.8.0;

abstract contract TimeOracle {
  function getTimestamp() external view virtual returns (uint256);
}

// File contracts/CustodianContract.sol

pragma solidity ^0.8.0;

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

  mapping(address => TokenData) internal _tokens;
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
