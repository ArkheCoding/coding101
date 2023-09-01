//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract Calculator {

  uint256 public DECIMAL = 10 ** 18;
  uint256 public SECONDS_IN_YEAR = 31536000;

  function calcInterestRatePerSecond(uint256 interestRate) public view returns (uint256) {
    return interestRate/SECONDS_IN_YEAR;
  }

  function calcInterest(uint256 amount, uint256 interestRate, uint256 duration) public view returns (uint256) {
    return amount * interestRate * duration / DECIMAL;
  }

  function calcCollateralAmount(uint256 amount, uint256 collateralRate) public view returns (uint256) {
    return amount * collateralRate / DECIMAL;
  }

}