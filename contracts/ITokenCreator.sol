pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface ITokenCreator {
   
//   function PublishToken (string memory name,string memory symbol,uint8 decimals_,uint256 maxTotalSupply_, address issuer) 
//   external view returns (address tokenAddress)

   function PublishToken (string memory ,string memory ,uint8 ,uint256 , address  ) external  returns (address);
}
