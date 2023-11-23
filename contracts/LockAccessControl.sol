// SPDX-License-Identifier: GPL-3.0

//  (access/AccessControl.sol), this project uses @v4.8.0 not v5.0.0

pragma solidity ^0.8.17;

import  "@openzeppelin/contracts/access/AccessControl.sol";

contract LockAccessControl is AccessControl {
    // Voucher roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
      
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    
    bool public locked;

    uint256 public adminRoleFee = 0.18 ether;
    
    uint256 public minterRoleFee = 0.009 ether;
    
    mapping(address => uint256) public ethReceived;

    event roleGranted(address indexed account);

    event grantedBurner(address indexed account);

    event revokeBurnerRole(address indexed account);

    event MinterRoleGranted(address indexed account);

    event revokeMinterRole(address indexed account);

    event adminRoleGranted(address indexed account);

    event revokeAdminRole(address indexed account);

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender));
        _;
    }

    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE, msg.sender));
        _;
    }
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender));
        _; 
    }

    modifier nonReentrancy() {
        require(!locked, "can't reenter");
        locked = true;
        _;
        locked = false;
    }

   // function _setRole(bytes32 role, address account) internal {
   //     roles[role].members[account] = true;
  //  }

   // function _setupRole(bytes32 role, address account) internal {
    //    _setRole(role, account);
   // }

    constructor() { 
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // Granting burner Role is only valid to the admin
    function grantBurner(address account) public  {
        grantRole(BURNER_ROLE, account);

        emit grantedBurner(account);
    }

    function revokeBurner(address account) public  onlyMinter onlyAdmin {
        revokeRole(BURNER_ROLE, account);

        emit revokeBurnerRole(account);
    }

    // Use the modifiers' to delegate responsibilty by allowing 
    // others roles to grant the minter role
    function grantMinter(address account) public payable nonReentrancy  {
        // Same applies for minter as it was or is with Voucher Admin.
        // Invalid address not allowed.
        require(msg.sender != address(0));
        require(msg.value > 0 , "Fee not met");
        require(ethReceived[account] + msg.value >= minterRoleFee, "fee not met");

        grantRole(MINTER_ROLE, account);

        emit MinterRoleGranted(account);      
    }

    function revokeMinter(address account) public onlyAdmin  {
        revokeRole(MINTER_ROLE, account);

        emit revokeMinterRole(account);
    }
    function grantAdmin(address account) public payable nonReentrancy  {
        // Same applies for this main role as it is for the minter, voucherAdmin and burner roles.
        // Invalid address not allowed.
        require(msg.sender != address(0));
        // Fee sent must be greater than 0
        require(msg.value > 0 , "Fee not met");
        // purse collects the ether received and stores it with the address that sent the fee.
        require(ethReceived[account] + msg.value >= adminRoleFee, "fee not met");

        grantRole(ADMIN_ROLE, account);

        emit adminRoleGranted(account);      
    }
    // only the DEFAULT ADMIN can revoke the role of the admin.
    function revokeAdmin(address account) public onlyAdmin {
        revokeRole(ADMIN_ROLE, account);

        emit revokeAdminRole(account);
    }
}