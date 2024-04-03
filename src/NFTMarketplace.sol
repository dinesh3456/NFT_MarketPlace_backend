// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/** 
 * @title NFTMarketplace
 * @dev A NFT marketplace contract
 * This is a Solidity contract for a Non-Fungible Token (NFT) marketplace. It uses OpenZeppelin's ERC721 standard for NFTs, along with other OpenZeppelin contracts for access control, URI storage, reentrancy protection, and math operations.
 */

contract NFTMarketplace is AccessControl, ERC721URIStorage, ReentrancyGuard {


    using Math for uint256;

    /**
     * @notice Role definitions
     * @dev Role definitions for the marketplace contract
     * Roles: The contract defines several roles (Admin, Creator, Seller, Buyer) using OpenZeppelin's AccessControl. These roles are used to control access to certain functions.
     * Admin: The Admin role is the default admin role for the contract. The Admin role has the highest level of access and can grant and revoke other roles.
     * Creator: The Creator role is used to designate the creator of an NFT. The Creator role can create and list NFTs for sale.
     * Seller: The Seller role is used to designate the seller of an NFT. The Seller role can set the price of an NFT and sell an NFT to a buyer.
     * Buyer: The Buyer role is used to designate the buyer of an NFT. The Buyer role can buy an NFT from a seller.
     */

    bytes32 public constant ADMIN_ROLE = keccak256(abi.encodePacked("ADMIN_ROLE"));
    bytes32 public constant CREATOR_ROLE = keccak256(abi.encodePacked("CREATOR_ROLE"));
    bytes32 public constant SELLER_ROLE = keccak256(abi.encodePacked("SELLER_ROLE"));
    bytes32 public constant BUYER_ROLE = keccak256(abi.encodePacked("BUYER_ROLE"));

    /**
     * @dev Struct to represent a listed token
     * @param tokenId The ID of the token
     * @param owner The address of the token owner
     * @param creator The address of the token creator
     * @param price The price of the token
     * @param isListed A boolean flag indicating whether the token is listed for sale
     */

    struct ListedToken {
        uint256 tokenId;
        address payable owner;
        address payable creator;
        uint256 price;
        bool isListed;
    }

    uint256 private _tokenIdCounter; // Counter for token IDs
    address payable public owner;
    uint256 public constant CONTRACT_FEE_PERCENT = 5;// Contract fee percentage
    mapping(uint256 => uint256) public nftPrices; // Token ID => Price
    mapping(address => uint256) public balances; // Seller address => Balance
    mapping(uint256 => ListedToken) private idToListedToken; // Token ID => ListedToken
    
    event TokenListedSuccess(
        uint256 indexed id,
        address indexed owner,
        address indexed creator,
        uint256 price,
        bool isListed
    );
    event NFTPriceSet(uint256 indexed tokenId, uint256 price);
    event NFTSold(uint256 indexed tokenId, address indexed buyer, uint256 price);


    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol){
        owner = payable(msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

    }

    modifier onlyRoleCustom(bytes32 role) {
        require(hasRole(role, msg.sender), "NFTMarketplace: Caller is not in the required role");
        _;
    }

    /**
     * @notice Create and list a token for sale
     * @dev Creates a new token and lists it for sale
     * @param tokenURI The URI for the token metadata
     * @param price The price of the token
     * NFT Creation and Listing: The createAndListToken function allows a user with the Creator role to create a new NFT and list it for sale at a specified price.
     * The function increments the token ID counter, mints a new token, sets the token URI, and lists the token for sale with the specified price.
     * The function also emits an event to indicate the success of the token listing.
     * @return The ID of the newly created token
     * 
     */

    function createAndListToken(string memory tokenURI, uint256 price) public payable onlyRole(CREATOR_ROLE) returns (uint256) {
    _tokenIdCounter++;
    uint256 newTokenId = _tokenIdCounter;
    _safeMint(msg.sender, newTokenId);
    _setTokenURI(newTokenId, tokenURI);

    // List the token for sale
    address tokenOwner = ownerOf(newTokenId);
    require(tokenOwner != address(0), "NFTMarketplace: Token ID does not exist");

    nftPrices[newTokenId] = price;
    idToListedToken[newTokenId] = ListedToken({
        tokenId: newTokenId,
        owner: payable(msg.sender),
        creator: payable(ownerOf(newTokenId)),
        price: price,
        isListed: true
    });
    emit TokenListedSuccess(
        newTokenId,
        ownerOf(newTokenId),
        idToListedToken[newTokenId].creator,
        price,
        true
    );

    return newTokenId;
    }

    /**
     * @notice Set the price of an NFT
     * @dev Sets the price of an NFT that is listed for sale
     * @param _tokenId The ID of the token
     * @param _price The new price of the token
     * NFT Price Setting: The setPrice function allows a user with the Seller role to set the price of an NFT that is listed for sale.
     * The function updates the price of the NFT in the nftPrices mapping and emits an event to indicate the new price of the NFT.
     */

    function setPrice(uint256 _tokenId, uint256 _price) external onlyRole(SELLER_ROLE) {
        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner != address(0), "NFTMarketplace: Token ID does not exist");
        nftPrices[_tokenId] = _price;
        emit NFTPriceSet(_tokenId, _price);
    }

    /**
     * @notice Buy an NFT
     * @dev Allows a user to buy an NFT that is listed for sale
     * @param _tokenId The ID of the token
     * NFT Purchase: The buyNFT function allows a user with the Buyer role to buy an NFT that is listed for sale.
     * The function checks that the NFT is listed for sale and that the buyer has sent enough funds to purchase the NFT.
     * The function transfers the NFT to the buyer, calculates the contract fee and seller proceeds, updates the balances mapping, and emits an event to indicate the sale of the NFT.
     */

    function buyNFT(uint256 _tokenId) external payable onlyRole(BUYER_ROLE) nonReentrant {
        require(nftPrices[_tokenId] > 0, "NFTMarketplace: NFT not for sale");
        require(msg.value >= nftPrices[_tokenId], "NFTMarketplace: Insufficient funds");

        address seller = ownerOf(_tokenId);
        uint256 price = nftPrices[_tokenId];

        uint256 contractFee = (price * CONTRACT_FEE_PERCENT) / 100;

        uint256 sellerProceeds = (price - contractFee);

        (bool success, uint256 newBalance) = balances[seller].tryAdd(sellerProceeds);
        balances[seller] = newBalance;

    (success, newBalance) = balances[address(this)].tryAdd(contractFee);

    balances[address(this)] = newBalance;

    _transfer(seller, msg.sender, _tokenId);
    emit NFTSold(_tokenId, msg.sender, price);
    }
    /**
     * @notice Withdraw funds
     * @dev Allows a user to withdraw their funds from the marketplace
     * Withdrawal: The withdraw function allows a user to withdraw their funds from the marketplace.
     * The function transfers the user's balance to the user's address and sets the balance to zero.
     */

    function withdraw() external nonReentrant  {
        require(balances[msg.sender] > 0, "NFTMarketplace: No balance to withdraw");
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "NFTMarketplace: Transfer failed");
    }

     /**
     * @notice Assign a role to an address
     * @dev Allows the contract owner to assign a role to an address
     * @param _address The address to assign the role to
     * Role Assignment: The assignRole function allows the contract owner to assign a role to an address.
     * The function uses OpenZeppelin's grantRole function to assign the role to the address.
     */

    function assignCreatorRole(address _address) external  onlyRole(DEFAULT_ADMIN_ROLE){
        grantRole(CREATOR_ROLE, _address);
    }

    /**
     * @param _address The address to assign the role to
     * Role Assignment: The assignRole function allows the contract owner to assign a role to an address.
     * The function uses OpenZeppelin's grantRole function to assign the role to the address.
     */

    function assignBuyerRole(address _address) external  onlyRole(DEFAULT_ADMIN_ROLE){
        grantRole(BUYER_ROLE, _address);
    }

    /*
    * @param _address The address to assign the role to
    * Role Assignment: The assignRole function allows the contract owner to assign a role to an address.
    * The function uses OpenZeppelin's grantRole function to assign the role to the address.
    */

    function assignSellerRole(address _address) external  onlyRole(DEFAULT_ADMIN_ROLE){
        grantRole(SELLER_ROLE, _address);
    }

    /**
     * @param _address The address to assign the role to
     * Role Assignment: The assignRole function allows the contract owner to assign a role to an address.
     * The function uses OpenZeppelin's grantRole function to assign the role to the address.
     */

    function assignAdminRole(address _address) external  onlyRole(DEFAULT_ADMIN_ROLE){
        grantRole(ADMIN_ROLE, _address);
    }

    /**
     * @param _address The address to revoke the role from
     * Role Revocation: The revokeRole function allows the contract owner to revoke a role from an address.
     * The function uses OpenZeppelin's revokeRole function to revoke the role from the address.
     */

    function revokeRole(address _address, bytes32 _role) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(_role, _address);
    }

    /**
     * @param _tokenId The ID of the token
     * @return The URI of the token
     * Token URI Retrieval: The getTokenURI function allows a user to retrieve the URI of a token by its ID.
     * The function calls the tokenURI function from the ERC721URIStorage contract to retrieve the token URI.
     */

    function getTokenURI(uint256 _tokenId) external view returns (string memory) {
        return tokenURI(_tokenId);
    }

    /**
     * get all listed tokens
     * @return listedTokens
     * iterate through all tokens and return only the listed ones
     */

    function getAllNfts() public view returns (ListedToken[] memory) {
    ListedToken[] memory listedTokens = new ListedToken[](_tokenIdCounter);
    uint256 index = 0;
    for (uint256 i = 1; i <= _tokenIdCounter; i++) {
        if (idToListedToken[i].isListed) {
            listedTokens[index] = idToListedToken[i];
            index++;
        }
    }
    return listedTokens;
}

/**
 * get all listed tokens
 * @return listedTokens
 * iterate through all the tokens which the owner owns and return only the listed ones 
 */

function getMyNfts() public view returns (ListedToken[] memory) {
    ListedToken[] memory listedTokens = new ListedToken[](_tokenIdCounter);
    uint256 counter = 0;
    for (uint256 i = 1; i <= _tokenIdCounter; i++) {
        if (ownerOf(i) == msg.sender) {
            listedTokens[counter] = idToListedToken[i];
            counter++;
        }
    }
    // Resize the array to remove any empty slots
    assembly { mstore(listedTokens, counter) }
    return listedTokens;
}

/**
 * 
 * @param tokenId The ID of the token
 * @return listedToken
 * get the listed token for a specific token ID
 */

    function getListedTokenForId(uint256 tokenId) public view returns (ListedToken memory) {
        return idToListedToken[tokenId];
    }

    /**
     * 
     * @param interfaceId The interface ID
     * @return Whether the contract supports the interface
     * Interface Support: The supportsInterface function overrides the supportsInterface function from the ERC721URIStorage and AccessControl contracts.
     */

    function supportsInterface(bytes4 interfaceId) public view override(ERC721URIStorage, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * returns the tokenId
     */

    function getTokenIdCounter() public view returns (uint256) {
        return (_tokenIdCounter);
    }

    /**
     * 
     * @param _tokenId The ID of the token
     * checks if the token is listed
     * checks if the caller is the seller
     * checks if the caller has enough funds
     * transfers the token to the buyer
     * calculates the contract fee and seller proceeds
     * updates the balances mapping
     */

    function sellNfts(uint256 _tokenId) public payable onlyRole(SELLER_ROLE) {
        require(idToListedToken[_tokenId].isListed, "NFTMarketplace: NFT not listed");
        require(hasRole(SELLER_ROLE, msg.sender), "NFTMarketplace: Caller is not a seller");
        require(msg.value >= idToListedToken[_tokenId].price, "NFTMarketplace: Insufficient funds");
        address seller = idToListedToken[_tokenId].owner;
        uint price = idToListedToken[_tokenId].price;

        idToListedToken[_tokenId].owner = payable(msg.sender);

        ERC721(address(this)).approve(msg.sender, _tokenId);

        balances[seller] += msg.value * 95 / 100;
        balances[address(this)] += msg.value * 5 / 100;

        payable(seller).transfer(msg.value * 95 / 100);
        payable(owner).transfer(msg.value * 5 / 100);

        emit NFTSold(_tokenId, msg.sender, price);
    } 
}
