//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./core/TokenImplementer.sol";

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