//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../access/Ownable.sol";

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