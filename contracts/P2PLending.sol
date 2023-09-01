//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./core/TokenImplementer.sol";
import "./core/Calculator.sol";

contract P2PLending is TokenImplementer, Calculator {

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

  struct Credit {
    uint256 amount;
    uint256 repaidAmount;
    uint256 startedAt;
    uint256 endsAt;
    uint256 interestRate;
    uint256 collateralRate;
    address depositor;
    bool isActive;
  }

  // Array of depositors
  mapping(address => Depositor) public depositors;
  mapping(address => CreditOptions[]) public creditOptions;
  mapping(address => Borrower) public borrowers;
  mapping(address => Credit[]) public credits;

  modifier onlyDepositor() {
    require(depositors[msg.sender].amount > 0, "Not a depositor");
    _;
  }

  modifier onlyBorrower() {
    require(borrowers[msg.sender].collateralAmount > 0, "Not a borrower");
    _;
  }

  modifier onlyValidCreditOption(address _depositor, uint256 index) {
    require(creditOptions[_depositor][index].isActive, "Credit option is not active");
    _;
  }

  function _getAvailableCollateral(address _borrower) internal view returns (uint256) {
    return borrowers[_borrower].availableCollateralAmount; 
  }

  function _getRequiredCollateral(
    address _depositor, 
    uint256 _index, 
    uint256 _loanAmount
    ) internal view returns (uint256) {
      return (calcCollateralAmount(
        _loanAmount, 
        creditOptions[_depositor][_index].collateralRate
      ));
  }

  function repay(
    uint256 _index,
    uint256 _amount
  ) public onlyBorrower {
    require(credits[msg.sender][_index].isActive, "Credit is not active");

    uint256 leftAmount = credits[msg.sender][_index].amount - 
                          credits[msg.sender][_index].repaidAmount;

    uint256 timeDifference = block.timestamp - credits[msg.sender][_index].startedAt;
    uint256 interestRatePerSecond = calcInterestRatePerSecond(credits[msg.sender][_index].interestRate);
    uint256 interest = calcInterest(leftAmount, interestRatePerSecond, timeDifference);

    uint256 totalDebt = leftAmount + interest;

    require(_amount <= totalDebt, "Amount is too high");
    require(_amount > interest, "Amount is too low");

    // Claim repayment tokens from msg.sender
    getTokensFromUser(msg.sender, _amount);

    uint256 amountAfterInterest = _amount - interest;

    // Update borrower balances
    borrowers[msg.sender].loanRepaid += amountAfterInterest;

    // Update credit balances
    credits[msg.sender][_index].repaidAmount += amountAfterInterest;

    depositors[credits[msg.sender][_index].depositor].availableAmount += _amount;
    depositors[credits[msg.sender][_index].depositor].amount += interest;
  }

  function borrowMoney(
    address _depositor,
    uint256 _index,
    uint256 _amount,
    uint256 _duration
  ) public onlyBorrower onlyValidCreditOption(_depositor, _index) {

    uint256 requiredCollateral = _getRequiredCollateral(_depositor, _index, _amount);

    // Check if the borrower has enough collateral
    require(
      _getAvailableCollateral(msg.sender) >= requiredCollateral,
      "Collateral is too low"
    );

    // Check if requested amount is within the range of the credit option
    require(
      creditOptions[_depositor][_index].maxAmount >= _amount && 
      creditOptions[_depositor][_index].minAmount <= _amount,
      "Amount is too high or too low"
    );

    // Check if the depositor has enough available amount
    require(
      depositors[_depositor].availableAmount >= _amount,
      "Amount is too high"
    );

    // Check if the duration is within the range of the credit option
    require(
      creditOptions[_depositor][_index].maxDuration >= _duration,
      "Duration is too high"
    );

    // Update depositor balances
    depositors[_depositor].availableAmount -= _amount;

    // Update borrower balances
    borrowers[msg.sender].availableCollateralAmount -= requiredCollateral;
    borrowers[msg.sender].loanAmount += _amount;

    // Add New Credit
    credits[msg.sender].push(Credit(
      _amount,
      0,
      block.timestamp,
      block.timestamp + _duration,
      creditOptions[_depositor][_index].interestRate,
      creditOptions[_depositor][_index].collateralRate,
      _depositor,
      true
    ));

    // Transfer the tokens to the borrower
    transferTokensToUser(msg.sender, _amount);
    
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

  /**
   * @dev Function to withdraw tokens from the contract
   * 
   * @param amount The amount of tokens to withdraw
   */
  function withdrawMoney(uint256 amount) public onlyDepositor {
    require(depositors[msg.sender].availableAmount >= amount, "Amount is too high");
    depositors[msg.sender].availableAmount -= amount;
    depositors[msg.sender].amount -= amount;
    token.transfer(msg.sender, amount);
  }

  /**
   * Function to create credit options by a depositor
   * 
   * @param _maxAmount max amount of the loan
   * @param _minAmount min amount of the loan
   * @param _interestRate interest rate of the loan
   * @param _maxDuration max duration of the loan
   * @param _collateralRate collateral rate of the loan
   */
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
 
  /**
   * Adjust credit option by a depositor to make it active or inactive
   * 
   * @param index index of the credit option
   * @param isActive boolean to make the credit option active or inactive
   */
  function adjustCreditOption(uint256 index, bool isActive) public onlyDepositor {
    creditOptions[msg.sender][index].isActive = isActive;
  }

  /**
   * @dev Function to get the minimum allowed deposit
   * 
   * @param _amount The amount of tokens to deposit
   */
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

  /**
   * @dev Function to withdraw collateral tokens from the contract
   * 
   * @param amount The amount of tokens to withdraw
   */
  function withdrawCollateral(uint256 amount) public {
    require(borrowers[msg.sender].availableCollateralAmount >= amount, "Amount is too high");
    borrowers[msg.sender].availableCollateralAmount -= amount;
    borrowers[msg.sender].collateralAmount -= amount;
    collateral.transfer(msg.sender, amount);
  }

}