// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

interface IKeyLock {
    function burn(uint256 keyId) external;
    
  //  function adminMint(address to, uint256 tokenId) external payable;
    
  //  function adminPublicMint(address to, uint256 tokenId) external payable;
    
 //   function _balanceOf(address owner) external view returns (uint256);
    
 //   function getBalance(address owner) external  view returns (uint256);
    
    function updateLock(address owner, uint256 tokenId, uint256 duration) external payable;
    
   // function transferToken(
   //     uint256 tokenId,
   //     address payable owner,
   //     address newOwner
   //     ) external payable;

}