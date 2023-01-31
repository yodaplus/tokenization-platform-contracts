// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.3.2

//SPDX-License-Identifier: Unlicensed

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
    function allowance(address owner, address spender) external view returns (uint256);

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
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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


// File @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol@v4.3.2



pragma solidity ^0.8.0;


/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
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
  uint256 issuerCollateral;
  uint256 insurerCollateral;
  address collateralProvider;
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
  bytes1 public constant KYC_INCOMPLETE = hex"A1";
  bytes1 public constant COUNTRY_NOT_ALLOWED = hex"A2";
  bytes1 public constant INVESTOR_CLASSIFICATION_NOT_ALLOWED = hex"A3";
  bytes1 public constant INVESTOR_NOT_WHITELISTED = hex"A4";
}


// File contracts/TokenBase.sol

pragma solidity ^0.8.0;






abstract contract TokenBase is ERC20Burnable, Pausable, Ownable, ReasonCodes {
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
    onlyOwner
    whenNotPaused
  {
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


// File contracts/TokenTvTTypes.sol

pragma solidity ^0.8.0;

enum TokenType {
  Subscription,
  LiquidityPool
}
enum IssueType {
  Normal,
  NAV
}

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
  uint256 issuerCollateralShare;
  uint256 insurerCollateralShare;
  address collateralProvider;
  bytes32 documentName;
  string documentUri;
  bytes32 documentHash;
  TokenType tokenType;
  address issuerSettlementAddress;
  IssueType issueType;
}


// File contracts/interfaces/ITokenHooks.sol

pragma solidity ^0.8.0;

interface ITokenHooks {
  function onIssue(
    address subscriber,
    uint256 value,
    uint256 orderId
  ) external;

  function onRedeem(
    address subscriber,
    uint256 value,
    uint256 orderId
  ) external;

  function burnTokens(uint256 amount) external;
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;




contract TokenTvT is TokenBase, ITokenHooks {
  string public constant VERSION = "0.0.1";
  string public constant TYPE = "TokenTvT";

  address[] public paymentTokens;
  uint256[] internal _issuanceSwapMultiple;
  uint256[] internal _redemptionSwapMultiple;
  uint256 public maturityPeriod;
  uint256 internal _settlementPeriod;
  uint256 internal _collateral;
  uint256 internal _issuerCollateral;
  uint256 internal _insurerCollateral;
  address internal _collateralProvider;

  address internal _issuerSettlementAddress;
  IssueType internal _issueType;
  struct Document {
    bytes32 docHash; // Hash of the document
    string uri; // URI of the document that exist off-chain
  }

  mapping(bytes32 => Document) internal _documents;

  mapping(address => mapping(uint256 => uint256))
    internal _issuedTokensByMaturityBucket;
  mapping(address => uint256[]) internal _issuedTokensMaturityBuckets;

  mapping(address => uint256) internal investorTranches;

  event TokenIssuanceSwapRatioUpdated(uint256 ratio);

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
    uint256 issuerCollateral,
    uint256 insurerCollateral,
    address collateralProvider,
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
    uint256 issuerCollateral,
    uint256 insurerCollateral,
    address collateralProvider,
    uint256 timeout
  );

  constructor(
    TokenTvTInput memory input,
    address custodianContract,
    address escrowManagerAddress
  )
    TokenBase(input.name, input.symbol, input.maxTotalSupply, custodianContract)
  {
    paymentTokens = input.paymentTokens;
    _issuanceSwapMultiple = input.issuanceSwapMultiple;
    _redemptionSwapMultiple = input.redemptionSwapMultiple;
    maturityPeriod = input.maturityPeriod;
    _settlementPeriod = input.settlementPeriod;
    _collateral = input.collateral;
    _issuerCollateral = input.issuerCollateralShare;
    _insurerCollateral = input.insurerCollateralShare;
    _collateralProvider = input.collateralProvider;
    _issuerSettlementAddress = input.issuerSettlementAddress;
    _issueType = input.issueType;

    escrowManager = IEscrowInitiate(escrowManagerAddress);
    _documents[input.documentName] = Document(
      input.documentHash,
      input.documentUri
    );
  }

  function burnTokens(uint256 amount) public virtual override {
    if (msg.sender != address(escrowManager)) {
      throwError(ErrorCondition.WRONG_CALLER);
    }
    _burn(owner(), amount);
  }

  function updateTokenIssuanceSwapRatio(uint256 ratio) external onlyIssuer {
    if (ratio < 0) {
      throwError(ErrorCondition.WRONG_INPUT);
    }

    _issuanceSwapMultiple[0] = ratio;
    emit TokenIssuanceSwapRatioUpdated(ratio);
  }

  function getIssuanceSwapRatio() external view returns (uint256) {
    return _issuanceSwapMultiple[0];
  }

  function issue(
    address subscriber,
    uint256 value,
    uint256 tranche
  ) public override onlyIssuer {
    return
      issue(subscriber, _issuerSettlementAddress, subscriber, value, tranche);
  }

  function issue(
    address subscriber,
    address paymentTokenDestination,
    address tradeTokenDestination,
    uint256 value,
    uint256 tranche
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

    // save investor tranche
    investorTranches[subscriber] = tranche;

    address tokenOwner = owner();

    if (reasonCode != ReasonCodes.TRANSFER_SUCCESS) {
      if (reasonCode == ReasonCodes.KYC_INCOMPLETE) {
        throwError(ErrorCondition.KYC_INCOMPLETE);
      } else if (reasonCode == ReasonCodes.COUNTRY_NOT_ALLOWED) {
        throwError(ErrorCondition.COUNTRY_NOT_ALLOWED);
      } else if (
        reasonCode == ReasonCodes.INVESTOR_CLASSIFICATION_NOT_ALLOWED
      ) {
        throwError(ErrorCondition.INVESTOR_CLASSIFICATION_NOT_ALLOWED);
      } else {
        throwError(ErrorCondition.CUSTODIAN_VALIDATION_FAIL);
      }
    } else {
      _mint(tokenOwner, value);
      increaseAllowance(address(escrowManager), value);
      EscrowOrder memory escrowOrder = EscrowOrder({
        tradeToken: address(this),
        tradeTokenAmount: value,
        tradeTokenDestination: tradeTokenDestination,
        issuerAddress: tokenOwner,
        paymentToken: paymentTokens[0],
        paymentTokenAmount: _issuanceSwapMultiple[0] * value,
        paymentTokenDestination: paymentTokenDestination,
        investorAddress: subscriber,
        collateral: _collateral * value,
        issuerCollateral: _issuerCollateral * value,
        insurerCollateral: _insurerCollateral * value,
        collateralProvider: _collateralProvider,
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
        escrowOrder.issuerCollateral,
        escrowOrder.insurerCollateral,
        escrowOrder.collateralProvider,
        escrowOrder.timeout
      );
    }
  }

  function onIssue(
    address subscriber,
    uint256 value,
    uint256 orderId
  ) external override {
    if (msg.sender != address(escrowManager)) {
      throwError(ErrorCondition.WRONG_CALLER);
    }

    uint256 timestamp = _custodianContract.getTimestamp();

    _issuedTokensByMaturityBucket[subscriber][timestamp] += value;
    _issuedTokensMaturityBuckets[subscriber].push(timestamp);

    emit Issued(subscriber, value, ReasonCodes.TRANSFER_SUCCESS, orderId);
  }

  function onRedeem(
    address subscriber,
    uint256 value,
    uint256 orderId
  ) external override {
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
      (maturityBuckets[i] + maturityPeriod < _custodianContract.getTimestamp())
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

    emit Redeemed(
      subscriber,
      value,
      ReasonCodes.TRANSFER_SUCCESS,
      orderId,
      totalSupply()
    );
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
      (maturityBuckets[i] + maturityPeriod < _custodianContract.getTimestamp())
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
      (maturityBuckets[maturityBuckets.length - i - 1] + maturityPeriod >=
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
    uint256 redeemPrice = _redemptionSwapMultiple[0] * value;
    // SENIOR_TRANCHE = 0
    // JUNIOR TRANCHE = 1
    if (_issueType == IssueType.NAV && investorTranches[subscriber] == 1) {
      redeemPrice = _issuanceSwapMultiple[0] * value;
    }
    if (reasonCode != ReasonCodes.TRANSFER_SUCCESS) {
      throwError(ErrorCondition.CUSTODIAN_VALIDATION_FAIL);
    } else {
      increaseAllowance(address(escrowManager), value);
      EscrowOrder memory escrowOrder = EscrowOrder({
        tradeToken: address(this),
        tradeTokenAmount: value,
        tradeTokenDestination: tradeTokenDestination,
        issuerAddress: _issuerSettlementAddress,
        paymentToken: paymentTokens[0],
        paymentTokenAmount: redeemPrice,
        paymentTokenDestination: paymentTokenDestination,
        investorAddress: subscriber,
        collateral: _collateral * value,
        issuerCollateral: _issuerCollateral * value,
        insurerCollateral: _insurerCollateral * value,
        collateralProvider: _collateralProvider,
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
        escrowOrder.issuerCollateral,
        escrowOrder.insurerCollateral,
        escrowOrder.collateralProvider,
        escrowOrder.timeout
      );
    }
  }

  function getDocument(bytes32 _name)
    external
    view
    returns (string memory, bytes32)
  {
    return (_documents[_name].uri, _documents[_name].docHash);
  }
}
