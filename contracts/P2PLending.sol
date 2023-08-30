//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./interfaces/IERC20.sol";
import "./access/Ownable.sol";

contract P2PLending is Ownable {

  struct Depositor {
    uint256 amount;
    uint256 availableAmount;
    uint256 interestRate;
    address belongsTo;
    uint256 maxPerAddress;
  }

  // Array of depositors
  Depositor[] public depositors;

  // Address of the token that is allowed to be deposited
  address public allowedToken;

  // Minimum amount of tokens that can be deposited
  uint256 public minimumAllowedDeposit;

  function setAllowedToken(address _tokenAddress) public onlyOwner {
    allowedToken = _tokenAddress;
  }

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
    require(_amount >= minimumAllowedDeposit, "Amount is too low");

    // Define the token interface
    IERC20 token = IERC20(allowedToken);

    // Transfer tokens from the sender to the contract
    require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

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