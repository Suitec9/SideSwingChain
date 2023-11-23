 // SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./KeysLibrary.sol";
import "./LockAccessControl.sol";

contract LockUpdate is LockAccessControl {

    struct Key {
        uint256 tokenId;
        address owner;
        uint256 expiration;
    }

    using KeysLibrary for Key;

    uint256 public constant KEY_DURATION = 270 days;
    
    uint256 public updateKeyFee = 0.009 ether;

    mapping(uint256 => uint256) public tokenExists;

    mapping(uint256 => KeysLibrary.Key) keys;
    
    event LockExpired(uint256 indexed tokenId);

    event keyUpdate(address indexed owner, uint256 tokenId, uint256 duration);
    
    // Voucher lock maybe 0 initial supply but it does expir.
    // Tracking of the duration while its still valid.
    function expireKey(uint256 tokenId) external {
        require(tokenExists[tokenId] == 1, "Lock does not exists");
        if (block.timestamp > KEY_DURATION) {
            keys[tokenId].expiration = 0; // Expired
            } else {
                keys[tokenId].expiration = KEY_DURATION - block.timestamp; // Remaining duration
            }
      
        emit LockExpired(tokenId);
    }
    
    // Checking if the voucher is still valid!
    function isExpired(uint256 tokenId) external view returns (bool) {
        return keys[tokenId].expiration == block.timestamp;
    }

    function updateKey(
        address owner,
        uint256 tokenId,
        uint256 duration
    ) external payable onlyAdmin  nonReentrancy {
        require(msg.sender != address(0), "invalid address");
        require(msg.value > 0, "no zero amounts");
        require(tokenExists[tokenId] == 1, "Lock does not exists");
        require(msg.value >= updateKeyFee, "Insuffcient funds");
        
        keys[tokenId].expiration = block.timestamp + KEY_DURATION;
        
        emit keyUpdate(owner, tokenId, duration);
    }
}