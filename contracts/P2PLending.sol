//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./core/TokenImplementer.sol";

contract P2PLending is TokenImplementer {

  struct Depositor {
    uint256 amount;
    uint256 availableAmount;
    uint256 interestRate;
    address belongsTo;
    uint256 maxPerAddress;
  }

  struct Borrower {
    uint256 collateralAmount;
    uint256 loanAmount;
    address belongsTo;
    uint256 availableCollateral;
  }

  // Array of depositors
  Depositor[] public depositors;

  /**
   * @dev Function to deposit tokens into the contract
   * 
   * @param _amount The amount of tokens to deposit
   * @param _interestRate interest rate in percent
   * @param _maxPerAddress maximum amount of tokens that can be loaned to a single address
   */
  function depositMoney(
    uint256 _amount,
    uint256 _interestRate,
    uint256 _maxPerAddress
  ) public {

    // Check if the amount is greater than the minimum allowed
    require(_amount >= getMinimumAllowedDeposit(), "Amount is too low");

    // Withdraw the tokens from the user
    getTokensFromUser(msg.sender, _amount);

    // Create a new depositor
    Depositor memory newDepositor = Depositor({
      amount: _amount,
      availableAmount: _amount,
      interestRate: _interestRate,
      belongsTo: msg.sender,
      maxPerAddress: _maxPerAddress
    });

    // Add the depositor to the array
    depositors.push(newDepositor);
  }

}