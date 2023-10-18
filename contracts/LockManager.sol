// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

  contract LockManager is ERC721, AccessControl, Ownable  {

    bytes32 public constant KEY_MANAGER_ROLE = keccak256("KEY_MANAGER_ROLE"); 

    struct Lock {
        uint256 expiration;
        bool expired;
    }

    struct Key {
        uint256 expiration;
        uint256 tokenId;
        address owner;
    }
    
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string _basetokenURI;

    uint public constant LOCK_DURATION = 90;

    uint public _initializeOwner;

    uint public constant KEY_DURATION = 60;

    uint public totalsupply = 0;

    uint constant MAX_LOCK_MINT_PER_ADDRESS = 4;

    uint constant MAX_KEY_MINT_PER_ADDRESS = 12;

    uint constant LOCK_TAX_FEE = 300;

    uint constant KEY_TAX_FEE = 300;
    

    uint256 public updateExpirationFee = 100000000 gwei;

    uint256 public updateKeyExpirationFee = 50000000 gwei;

    uint256 public createLockFee = 1 ether;  

    uint256 public createKeyFee =  5000000000 gwei;  

    uint256 public totalKeys;

    uint256 public ownerOf;

    string public constant NAME = "KeysLocks";

 

   // event deleteLock(uint256 indexed _LockId);

    event updateKey(uint256 indexed _keyId, uint256 indexed _expiresAt);
    
    event updateLock(uint256 indexed _tokenId, uint256 _expiration);

    event LockExpired(uint256 indexed tokenId);

   // event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  //event transferKey(uint256 indexed _keyId, address indexed _newOwner);


  modifier onlyKeyManager() {
        require(hasRole(KEY_MANAGER_ROLE, msg.sender), "Not a Key Manager Yet!!");
        _;
    }

    constructor(string memory baseURI, address initialOwner) ERC721("keysLock", "KLC") {
        _basetokenURI = baseURI;
       // _initializeOwner(msg.sender);
        _setupRole(KEY_MANAGER_ROLE, msg.sender);
    }

    function createLock(uint256 _tokenId, uint256 _expiration) external payable returns (uint256) {
        require(msg.value >= createLockFee, "Insufficient fund");
        Lock storage lock = locks[_tokenId];
        lock.expiration = _expiration;
        lock.expired = false;
        _tokenIdCounter.increment();
        _mint(msg.sender, _tokenId);

        locks[_tokenId] = Lock(
            block.timestamp + LOCK_DURATION,
            false
        );

        return _tokenId;

        emit LockCreated(_tokenId, _expiration);
    }

    function createKey(
        address _owner, 
        uint256 _expiresAt, 
        uint256 _tokenId) external onlyRole(KEY_MANAGER_ROLE) {
            require(msg.value >= createKeyFee, "Insufficient fund");
            _tokenIdCounter.increment();
            _mint(msg.sender, _tokenId);
            uint id = totalKeys++;
            keys[id] = Key({
                expiration: _expiresAt,
                tokenId: _tokenId,
                owner: _owner
            });

            emit KeyCreated(id, _owner, _expiresAt);
    }

    
    function updateExpiration(uint256 _tokenId, uint256 _expiration) external onlyKeyManager {
        require(msg.value >= updateExpirationFee, "Insufficient fee!! Fund the transaction");
        locks[_tokenId].expiration = _expiration;
        
        emit updateLock (_tokenId, _expiration);
    }

    function supportsInterface(bytes4 interfaceId) public view
     override(ERC721,AccessControl ) returns (bool) {
        return interfaceId == type(IERC721).interfaceId;
        
        super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _basetokenURI;
    }

   // function updateExpirationKeyFee(uint256 _fee, uint256 _keyId) external onlyKeyManager {
     //   updateExpirationFee = _fee;

       // emit updateKey(_keyId, _expiresAt);
   // }

    function expireLock(uint _tokenId) external onlyKeyManager {
        locks[_tokenId].expired = true;
        emit LockExpired(_tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        uint256 taxFee = _getTaxFee();
        require(!locks[tokenId].expired, "Lock expired");
        require(msg.value >= taxFee, "Insuffcient funds");
        super.transferFrom(from, to, tokenId );

       // emit Transfer(from, to, tokenId); 
    }

    function _getTaxFee() internal view returns (uint256) {
        return LOCK_TAX_FEE;
    }

    function getKey(uint256 _keyId) external view returns (Key memory) {
        return keys[_keyId];
    }

    function updateKeyExpiration(uint256 _keyId, uint256 _expiresAt) external onlyRole(KEY_MANAGER_ROLE) {
        Key storage key = keys[_keyId];
        require(msg.value >= updateKeyExpirationFee, "Insufficient fee!! Fund the transaction");
        require(key.expiration > block.timestamp, "Key expired !");

        key.expiration = _expiresAt;

        emit updateKey( _keyId,  _expiresAt);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId,string memory uri) 
    internal {
        super._beforeTokenTransfer(from, to, tokenId, "");
    }

    function transferKeyOwnership(uint256 _keyId, address _newOwner) external onlyRole(KEY_MANAGER_ROLE) {
        Key storage key = keys[_keyId];
        require(key.owner != address(0), "Invalid key");
        require(msg.value > 0, "Can't transfer with depleted funds or amount of zero");
        uint256 taxFee = _getKeyTaxFee();
 
        key.owner = _newOwner;

     //   emit transferKey(_keyId, _newOwner);
    }

    function _getKeyTaxFee() internal view returns (uint256) {
        return KEY_TAX_FEE;
    }

    function revokeKey(uint256 _keyId) external onlyRole(KEY_MANAGER_ROLE) {
        uint256 tokenId = _keyId;
        require(_ownerOf(tokenId) != address(0), "No owner for the token or token doesn't exists");
        delete keys[_keyId];

        emit deleteKey(_keyId);
    }

    
  //  function revokeLock(uint256 _LockId) external onlyRole(KEY_MANAGER_ROLE) {
   //     uint256 tokenId = _LockId;
     //   require(_ownerOf(tokenId) != address(0), "No owner for the token or token doesn't exists");
     //   delete Lock[_LockId];

    //    emit deleteLock(_LockId);
   // }


    receive() external payable {}

    fallback() external payable {}

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}