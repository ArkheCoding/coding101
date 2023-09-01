// SPDX-License-Identifier: MIT

// File contracts/access/Ownable.sol

pragma solidity 0.8.19;

contract Ownable {
  
  address private owner;

  modifier onlyOwner() {
    require(msg.sender == owner, "Only the owner can call this function");
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  function setOwner(address newOwner) public onlyOwner {
    owner = newOwner;
  }
}

pragma solidity 0.8.19;

contract Settings is Ownable {

  // Minimum amount of tokens that can be deposited
  uint256 private minimumAllowedDeposit;
  mapping (address => uint256) private minimumAllowedDeposits;
  uint256 private exchangeRate;

  // Set the minimum allowed deposit for a specific address
  function adjustSpecificAddress(address _address, uint256 _minimumAllowedDeposit) public onlyOwner {
    minimumAllowedDeposits[_address] = _minimumAllowedDeposit;
  }

  // Set the minimum allowed deposit
  function setMinimumAllowedDeposit(uint256 _minimumAllowedDeposit) public onlyOwner {
    minimumAllowedDeposit = _minimumAllowedDeposit;
  }

  function getSpecificMinimumDeposit(address _address) public view returns (uint256) {
    return minimumAllowedDeposits[_address];
  }

  // Get the minimum allowed deposit
  function getMinimumAllowedDeposit() public view returns (uint256) {
    return getSpecificMinimumDeposit(msg.sender) != 0 ? 
      getSpecificMinimumDeposit(msg.sender) : 
      minimumAllowedDeposit;
  }

}

pragma solidity 0.8.19;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

pragma solidity 0.8.19;

contract TokenImplementer is Settings {

  // Address of the token that is allowed to be deposited
  address public allowedToken;
  IERC20 public token;

  address public collateralToken;
  IERC20 public collateral;

  // Adjust the allowed token
  function setAllowedToken(address _tokenAddress) public onlyOwner {
    allowedToken = _tokenAddress;
    token = IERC20(allowedToken);
  }

  // Transfer tokens from the sender to the contract
  function getTokensFromUser(address from, uint256 amount) public {
    require(token.transferFrom(from, address(this), amount), "Transfer failed");
  }

  function setCollateralToken(address _collateralToken) public onlyOwner {
    collateralToken = _collateralToken;
    collateral = IERC20(collateralToken);
  }

  function getCollateralFromUser(address from, uint256 amount) public {
    require(collateral.transferFrom(from, address(this), amount), "Transfer failed");
  }

}

pragma solidity 0.8.19;

contract P2PLending is TokenImplementer {

  struct Depositor {
    uint256 amount;
    uint256 availableAmount;
  }

  struct CreditOptions {
    uint256 maxAmount;
    uint256 minAmount;
    uint256 interestRate;
    uint256 maxDuration;
    uint256 collateralRate;
    bool isActive;
  }

  struct Borrower {
    uint256 collateralAmount;
    uint256 availableCollateralAmount;
    uint256 loanAmount;
    uint256 loanRepaid;
  }

  // Array of depositors
  mapping(address => Depositor) public depositors;
  mapping(address => CreditOptions[]) public creditOptions;
  mapping(address => Borrower) public borrowers;

  modifier onlyDepositor() {
    require(depositors[msg.sender].amount > 0, "Not a depositor");
    _;
  }

  /**
   * @dev Function to deposit tokens into the contract
   * 
   * @param _amount The amount of tokens to deposit
   */
  function depositMoney(
    uint256 _amount
  ) public {
    // Check if the amount is greater than the minimum allowed
    require(_amount >= getMinimumAllowedDeposit(), "Amount is too low");

    // Withdraw the tokens from the user
    getTokensFromUser(msg.sender, _amount);

    // Update depositor balances
    depositors[msg.sender].amount += _amount;
    depositors[msg.sender].availableAmount += _amount;
  }

  function withdrawMoney(uint256 amount) public onlyDepositor {
    require(depositors[msg.sender].availableAmount >= amount, "Amount is too high");
    depositors[msg.sender].availableAmount -= amount;
    depositors[msg.sender].amount -= amount;
    token.transfer(msg.sender, amount);
  }

  function addCreditOption(
    uint256 _maxAmount,
    uint256 _minAmount,
    uint256 _interestRate,
    uint256 _maxDuration,
    uint256 _collateralRate
  ) public onlyDepositor {
    creditOptions[msg.sender].push(
      CreditOptions(
        _maxAmount,
        _minAmount,
        _interestRate,
        _maxDuration,
        _collateralRate,
        true
      )
    );
  }
 
  function adjustCreditOption(uint256 index, bool isActive) public onlyDepositor {
    creditOptions[msg.sender][index].isActive = isActive;
  }


  function depositCollateral(
    uint256 _amount
  ) public {
    // Check if the amount is greater than the minimum allowed
    require(_amount >= getMinimumAllowedDeposit(), "Amount is too low");

    // Withdraw the tokens from the user
    getCollateralFromUser(msg.sender, _amount);

    // Update depositor balances
    borrowers[msg.sender].collateralAmount += _amount;
    borrowers[msg.sender].availableCollateralAmount += _amount;
  }

  function withdrawCollateral(uint256 amount) public {
    require(borrowers[msg.sender].availableCollateralAmount >= amount, "Amount is too high");
    borrowers[msg.sender].availableCollateralAmount -= amount;
    borrowers[msg.sender].collateralAmount -= amount;
    collateral.transfer(msg.sender, amount);
  }

}
