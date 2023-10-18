// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./LockManager.sol";
import "./DIGATES.sol";

contract VoucherLock is ERC721, Ownable {

    struct Lock {
        uint256 expiration;
        bool expired;
    }

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string _basetokenURI;

    // Add a pause function only owner

    // Add an withdraw and receive and the mint price with the transfer fee
    // purchase price with a tax of 0.5%  

    //  totalsupply of 0 is unlimited
    uint public totalsupply = 0;
    
    uint constant MAX_VOUCERLOCK_MINT_PER_ADDRESS = 8;

    uint constant MAX_MINT_AWARD_PER_ADDRESS = 2;

    uint public constant VOUCERLOCK_DURATION = 180 days;
    
    uint constant TAX_FEE = 300;

    bool public _pause;

    string public constant NAME = "VoucherLock";

    string public constant SYMBOL = "VLock";

    uint256 public updateVoucherLockExpirationFee = 100000000 gwei;
    
    uint256 public mintFee;
   
    uint256 public _ownerOf;

//    uint256 internal isLocked;

    DIGATES public digates;

    LockManager public lockManager;

    mapping(address => uint256) public numMints;

    mapping(uint256 => Lock) public locks;

    event VoucherLockExpired(uint256 indexed tokenId);

    event deleteLock(uint256 indexed _LockId);

    //event Transfer(address indexed from, address indexed to, uint256 tokenId);

   // event awardTicket(address indexed mintedAward, uint256 tokenId);

   
   modifier onlyWhenNotPaused {
    require(!_pause, "Contract currently paused");
    _;
   }
    

    constructor(
        string memory baseURI,
        address payable _digate,
        address payable _lockManager
        ) ERC721("VoucherLock", "VLOCK") {
        digates = DIGATES(_digate);
        lockManager = LockManager(_lockManager);
        _basetokenURI = baseURI;
        transferOwnership(msg.sender);
    }

    function _initializeOwner() internal {
        _transferOwnership(msg.sender);
    }

    
    function mintVoucherLock(string memory uri) external payable returns (uint256) {
        require(msg.value >= mintFee, "Insuffcient minting fee paid");
        require(totalsupply > MAX_VOUCERLOCK_MINT_PER_ADDRESS, "max supply reached per address");
      //  locks[tokenId] = VoucherLock({
        //    expiration: block.timestamp + VOUCERLOCK_DURATION
       // });
        uint256 tokenId = _tokenIdCounter.current();
        _mint(msg.sender, tokenId);

        return tokenId;

        numMints[msg.sender]++;
        uint256 id;
        if (numMints[msg.sender] >= MAX_MINT_AWARD_PER_ADDRESS) {
            digates.mint(msg.sender, 2, id, "");
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _basetokenURI;
    }

    function _setMintFee(uint256 _mintFee) external onlyOwner {
        mintFee = _mintFee;
    }
    
    //function tokenURI(uint256 tokenId) public view override
    //(ERC721,) returns (string memory) {
    //    return ERC721URIStorage.tokenURI(tokenId);
  //  }

    function lockVoucher(uint256 _tokenId, uint256 _expiration) external payable {
        lockManager.createLock(_tokenId, _expiration);       
    }

   // function supportsInterface(bytes4 interfaceId) public view 
   // override(ERC721,) returns (bool) {
   //     return interfaceId == type(IERC721).interfaceId;
  //  }

    function expireVoucherLock(uint256 tokenId) external onlyOwner {
        require(block.timestamp >= locks[tokenId].expiration, "Voucher still valid");
        require(_exists(tokenId), "Lock does not exists");
        locks[tokenId].expired = false;

        emit VoucherLockExpired(tokenId);
    }

    function updateVoucherLockExpiration(uint256 tokenId, uint256 newExpiration) external onlyOwner {
        require(_exists(tokenId), "Lock does not exists");
        require(msg.value >= updateVoucherLockExpirationFee, "Insuffcient funds");
        locks[tokenId].expiration = newExpiration;
    }

    function _getTaxFee() internal view returns (uint256) {
        return TAX_FEE;
    }

    
    function revokeLock(uint256 _LockId) external onlyOwner {
        uint256 tokenId = _LockId;
        address owner = ownerOf(tokenId);
        require(owner(tokenId) != address(0), "No owner for the token or token doesn't exists");
        delete Lock[_LockId];

        emit deleteLock(_LockId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        uint256 taxFee = _getTaxFee();
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(!locks[tokenId].expired, "Lock expired");
        require(msg.value >= taxFee, "Insuffcient funds");
        super.transferFrom(from, to, tokenId );

      // emit Transfer(from, to, tokenId); 
    }

    function setPaused(bool val) public onlyOwner{
        _pause = val;
    }

    receive() external payable {}

    fallback() external payable {}

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
