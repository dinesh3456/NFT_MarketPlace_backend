// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";


contract NFTMarketplaceTest is Test, ERC721Holder {
    NFTMarketplace marketplace;
    address payable owner;

    function setUp() public {
        owner = payable(address(this));
        marketplace = new NFTMarketplace();
        marketplace.assignCreatorRole(owner);
        marketplace.assignBuyerRole(owner);
    }

    function testCreateAndListToken() public {
        uint256 tokenId = marketplace.createAndListToken("https://tokenURI", 1 ether);
        assertEq(marketplace.getTokenURI(tokenId), "https://tokenURI");
        assertEq(marketplace.nftPrices(tokenId), 1 ether);
    }

    function testBuyNFT() public {
        uint256 tokenId = marketplace.createAndListToken("https://tokenURI", 1 ether);
        marketplace.buyNFT{value: 1 ether}(tokenId);
        assertEq(marketplace.ownerOf(tokenId), address(this));
    }   

}
