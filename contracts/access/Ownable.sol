//SPDX-License-Identifier: MIT

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