// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library KeysLibrary {
    
    struct Key {
        uint256 keys;
        uint256 creationTime;
        address owner;
        uint256 expiration;
    }
    
    function createKey(
        mapping(uint256 => Key) storage keys,
        uint256 keyId,
        address owner,
        uint256 expiresAt
        ) internal {
            keys[keyId] = Key(keyId, block.timestamp, owner, expiresAt);
    }
    
    function getKey(
        mapping(uint256 => Key) storage keys,
        uint256 keyId) internal view returns (Key memory) {
            return keys[keyId];
    }
}