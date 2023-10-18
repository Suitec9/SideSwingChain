// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./VoucherLock.sol";
import "./FeeToken.sol";

/// @custom:security-contact BoomMagicalGang@duck.com 
contract DIGATES is Initializable, OwnableUpgradeable, PausableUpgradeable, ERC1155BurnableUpgradeable, ERC1155SupplyUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor

    VoucherLock public voucherLock;

    FeeToken public feeToken;

    //Pausable public pauser;

    uint public _initializeOwner;

    uint256 public mintFee = 0.02 ether;

    uint256 public transferFeePercent = 1;

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 tokenId, 
        uint256 value);

   // uint256 public transferFee = 0.006 ether;


   // event burnVoucherLockTicket(address indexed _from);

    constructor(address payable _voucherLock, address initialOwner) {
        _initializeOwner();
        voucherLock = VoucherLock(_voucherLock);
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC1155_init("");
        __Ownable_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        require(msg.value >= mintFee, "Insuffcient minting fee paid");
        _mint(account, id, amount, data);
        payable(owner()).transfer(msg.value);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function awardVoucherLock(address _to) external {
        require (voucherLock.numMints(_to) >= 2, "Not enough vouchers minted");
        _mint(_to, 0, 2, "");
    }
    
    function burnVoucherLockTicket(address _from) external {
        _burn(_from, 0, 2);

       // emit burnVoucherLockTicket(address _from);
    }

    function calcFee(uint256 tokenId) public view returns (uint256) {
        uint256 feeAmount = (mintFee * transferFeePercent) / 100;
        return feeAmount;
    }

    function transferWithFee(uint256 tokenId, address to) external {
        uint256 fee = calcFee(tokenId);
        feeToken.safeTransferFrom(msg.sender, owner, fee);

        ERC1155Upgradeable._transfer(msg.sender, to, tokenId, 1);

        emit TransferSingle(operator, msg.sender, to, tokenId, 1);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
       
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
    internal
    whenNotPaused
    override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
{
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
}


    receive() external payable {}

    fallback() external payable {}

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
