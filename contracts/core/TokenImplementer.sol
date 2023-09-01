//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../interfaces/IERC20.sol";
import "./Settings.sol";

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

  function transferTokensToUser(address to, uint256 amount) internal {
    require(token.transfer(to, amount), "Transfer failed");
  }

  function setCollateralToken(address _collateralToken) public onlyOwner {
    collateralToken = _collateralToken;
    collateral = IERC20(collateralToken);
  }

  function getCollateralFromUser(address from, uint256 amount) public {
    require(collateral.transferFrom(from, address(this), amount), "Transfer failed");
  }

}