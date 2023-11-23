// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
//import { Ownable } from "@openzeppelin/contracts@v4.8.0/access/Ownable.sol";
import "./LockAccessControl.sol";
import "./KeysLibrary.sol";
import "./LockUpdate.sol";
import "./IKeyLock.sol";

contract LockManager is IKeyLock, LockAccessControl {

    struct Loan {
        address owner;
        address borrower;
        uint256 expiration;
    }

    struct Key {
        uint256 keys;
        address owner;
        uint256 expiresAt;
    }
    
    Counters.Counter private tokenIdCounter;
    
    using KeysLibrary for Key;
    
    using Counters for Counters.Counter;

    LockAccessControl lockAccessControl;

    LockUpdate lockUpdate;

    address payable public _owner;

  //  address payable public newOwner;

    bool private _pause;

    bool private _paused;

    /** block contracts? */
    bool private _blockContracts;
   // address public account;
    
  //  uint public constant KEY_LOAN_DURATION = 30;

  //  uint public totalsupply = 0;

  //  uint constant MAX_LOCK_MINT_PER_ADDRESS = 4;

    uint constant MAX_KEY_MINT_PER_ADDRESS = 18;

    uint256 public constant KEY_DURATION = 270 days;

    uint256 public constant LOAN_DURATION = 45 days;

//    uint public _initializeOwner;

    /**Number of blocks to count as nothing land */
    uint256 public constant DEADBLOCK_COUNT = 3;

    /** Deadblock start blockrum */
    uint256 public deadblockStart;

    uint256 public updateKeyExpirationFee = 0.05 ether;

    uint256 public transferKeyFee = 0.0001 ether;

    uint256 public lendingFee = 0.02 ether;  

    uint256 public createKeyFee =  0.08 ether;

    uint256 public createdKeyFeeAdmin = 0.0001 ether;

    uint256 public totalKeys;

    mapping(uint256 => Key) private keys;

    mapping(address => uint256) public mintsPerAddress;

    mapping(uint256 => Loan) public loans;

    mapping(address => bytes32) public keyHashes;

//    mapping(address => bytes32) public keyManagerRole;
 
    event createdKey(address indexed owner, uint256 expiresAt, bytes32 keyHash);

    event transferKeyOwnerShip(uint256 keyId, address indexed owner, address indexed newOwner, bytes32 key);

    event LoanCreated(uint256 keyId, address indexed borrower);

    event deleted(uint256 keyId);

    event LoanReturned(uint256 keyId);

    event BalanceWithdrawn(uint256 indexed balance);

  //  event Paused(address account);

  //  event Unpaused(address account);    
    
    modifier onlyWhenNotPaused {
        require(!_pause, "Contract currently paused");
        _;
    }

    /**
     * @dev Throws error if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
        /**
     * @dev Throws error if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
    }
    
    constructor()  {
        //_owner = payable(address(bytes20(bytes("0xbe32d6Ad5b0c5b72Be4BC5D0AEF52a36d1a4D7d2"))));       
        _owner = payable(msg.sender);
        lockAccessControl = new LockAccessControl();
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
      //  _transferOwnership(_msgSender());
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
  //  function transferOwnership(address newOwner) external payable onlyOwner {
  //      require(newOwner != address(0), " new owner is the zero address");
  //      _transferOwnership(newOwner);
  //  }

    function createKey(
        address owner,
        uint256 expiresAt,
        bytes32 keyHash
        ) external payable  onlyWhenNotPaused nonReentrancy onlyAdmin onlyMinter { 
        uint256 keyId = tokenIdCounter.current();
        require(msg.sender != address(0), "no zero address");
        require(msg.value >= createKeyFee, "Insufficient fund");
        require(msg.value > 0, "ZERO not allowed");
        require(mintsPerAddress[msg.sender] < MAX_KEY_MINT_PER_ADDRESS, "Reached limit per address");
        keys[keyId] = Key({
        owner: owner, 
        keys: 1,
        expiresAt: expiresAt = KEY_DURATION + block.timestamp
        });
        tokenIdCounter.increment();
        keyHashes[owner] = keyHash;

        mintsPerAddress[msg.sender]++; //Increment counter
  
        emit createdKey(owner, expiresAt, keyHash); 
    } 

    function AdminCreateKey(
        address owner,
        uint256 expiresAt,
        bytes32 keyHash
        ) external payable onlyAdmin onlyOwner {
            uint256 keyId = tokenIdCounter.current();
            require(msg.value >= createdKeyFeeAdmin, "Admin money?");
            require(mintsPerAddress[msg.sender] < MAX_KEY_MINT_PER_ADDRESS, "max reached");
        keys[keyId] = Key({
        owner: owner,
        keys: 1,
        expiresAt: expiresAt = KEY_DURATION + block.timestamp
        });
        tokenIdCounter.increment();
        keyHashes[owner] = keyHash;

        mintsPerAddress[msg.sender]++; //Increment counter
    }

    function burn(uint256 keyId) external  onlyBurner {
        delete(keyId);

        emit deleted(keyId);
    }
    
    function _unpause() external onlyOwner  {
        _paused = false;

   //     emit Paused(_msgSender());
    }

    function _setPause() external onlyOwner {
        _paused = true;

     //   emit Paused(_msgSender());
    }
    /** Sets contract blocker
    * @param _val Sould we block contracts?
    */
    function setBlockContracts(bool _val) external onlyOwner {
        _blockContracts = _val;
    }
    /**
    * Checks if the address is a contract   
    * @dev Contract will have a codesize.
    * @param _address Address in question. 
    */
    function _isContract(address _address) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }

    function getKey(uint256 keyId) external view returns (Key memory) {
        return keys[keyId];
    }

    // Applying the tax to the transfering of the non-transferable keys
  //  function _getTaxFee() internal pure returns (uint256) {
   //     return KEY_TAX_FEE;
   // }

    // These are non transferable keys so in order to transfer we charge a tax
    function transferKey(
        uint256 keyId,
        address payable owner,
        address payable newOwner,
        bytes32 key
        ) external payable nonReentrancy {        
        require(keyHashes[msg.sender] == key, "invalid key");
        require(keys[keyId].expiresAt > block.timestamp + KEY_DURATION, "Lock expired");
        require(msg.value >= transferKeyFee, "Insuffcient funds");
        require(keys[keyId].owner == msg.sender, "Not the key owner");
    
        keys[keyId].owner = newOwner;
        owner.transfer(msg.value);  
        
        emit transferKeyOwnerShip(keyId, owner, newOwner, key);
    }
    // Just initiated a key loan until the loan expires 
    // Expiration date has not been set yet.
    function lendKey(
        uint256 keyId,
        address borrower,
        address payable owner
        ) external payable nonReentrancy onlyWhenNotPaused {
        Loan storage loan = loans[keyId];
        loan.borrower = borrower;
        loan.expiration =  LOAN_DURATION + block.timestamp ;
        address  lender = keys[keyId].owner;
        require(lender == msg.sender, "Not the key owner");
        require(keys[keyId].expiresAt > block.timestamp + KEY_DURATION, "Lock expired");
        require(msg.value >= lendingFee, "Fee not met");
        owner.transfer(msg.value);
        
        emit LoanCreated(keyId, borrower);
    }

    // Loan has come to an end, return the key
    function returnKey(uint256 keyId) external nonReentrancy {
        Loan storage loan = loans[keyId];
        require(loan.borrower == msg.sender, "Not the key owner");
        
        delete loans[keyId];
        
        emit LoanReturned(keyId);
    }

    // Keys are still in use loan hasn't expired
    function isloaned(uint256 keyId) public view returns (bool) {
        return loans[keyId].expiration > block.timestamp;
    }
    
    function expireDateLock(uint256 tokenId) public  {
        lockUpdate.expireKey(tokenId);
    }

    function updateLock(
        address owner,
        uint256 tokenId,
        uint256 duration
        ) external payable onlyOwner nonReentrancy onlyWhenNotPaused {
        require(hasRole(ADMIN_ROLE, msg.sender), "must be admin");
        require(lockUpdate.isExpired(tokenId), "Not expired");

        lockUpdate.updateKey(owner, tokenId, duration);
    }
     /** Checks if address has inHumane reflexes or if it's a contract
    * @param _address Address in question 
    */
    function _checkIfBot(address _address) internal view returns (bool) {
        return (block.timestamp < DEADBLOCK_COUNT + deadblockStart || _isContract(_address))
        && ethReceived[msg.sender] == 0;
    }

    // Loose function in my opion should find out more about the
    // receive() function exploits
    receive() external payable nonReentrancy onlyWhenNotPaused {
        ////require(_isContract(msg.sender), "not allowed");
        ethReceived[msg.sender] += msg.value;
        //require(_checkIfBot(msg.sender), "not allowed");
    }

    // calling functions from the AccessControl.sol file 
    function grantAdminRole(address account) external payable  onlyWhenNotPaused {
      //  require(_checkIfBot(msg.sender), "not allowed");
        LockAccessControl(lockAccessControl).grantAdmin(account);
    }

    // calling functions from the AccessControl.sol file 
    function grantMinterRole(address account) external payable  onlyWhenNotPaused {
      //  require(_checkIfBot(msg.sender), "not allowed");
        LockAccessControl(lockAccessControl).grantMinter(account);
    }
 
    // Another call from the access control.
    function removeMinter(address minter) external onlyAdmin {
        require(_checkIfBot(msg.sender), "not allowed");
        lockAccessControl.revokeMinter(minter);
    }

    // The smart contracts are interacting with each other
    function revokeKeyManager(address accountRole) external onlyOwner {
        require(_checkIfBot(msg.sender), "not allowed");
         lockAccessControl.revokeAdmin(accountRole);

    }

    // Attempting to curve the vundrabilty hopefully this 
    // prevents non E.O.A from our contract
    fallback() external payable nonReentrancy {
        require(_checkIfBot(msg.sender), "not allowed");
    }
    
     /** 
     * @dev withdraw sends all the ether in the contract
     * to the owner of the contract 
     */
    function withdraw() public  onlyOwner  {
        uint256 amount = address(this).balance;
        (bool sent, ) = _owner.call {value: amount} ("");
        require(sent, "Failed to send Ether");
    }
}