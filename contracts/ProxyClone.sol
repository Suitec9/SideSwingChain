// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DeployerProxy {

    address public implementation;

    function setImplementation(address newImplementation) external {
        implementation = newImplementation;
    }

    receive() external payable {}

    fallback() external payable {
        address contractLogic = implementation;

    
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), contractLogic, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}