// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";


contract NFTMarketplaceTest is Test, ERC721Holder {
    NFTMarketplace marketplace;
    address payable owner;
    uint256 _tokenId = 1;
    uint256 _price = 1 ether;


    function setUp() public {
        owner = payable(address(this));
        marketplace = new NFTMarketplace("NFTMarketplace", "NFTM");
        marketplace.assignCreatorRole(owner);
        marketplace.assignBuyerRole(owner);
        marketplace.assignSellerRole(owner);
        marketplace.assignAdminRole(owner);

        marketplace.createAndListToken("https://tokenURI", 1 ether);
        marketplace.buyNFT{value: 1 ether}(_tokenId); // Buy the token
        marketplace.setPrice(_tokenId, _price); // Set price for the token

    }


    function testCreateAndListToken() public view {
        assertEq(marketplace.getTokenURI(_tokenId), "https://tokenURI");
        assertEq(marketplace.nftPrices(_tokenId), 1 ether);
    }

    function testBuyNFT() public {
        uint256 tokenId = marketplace.createAndListToken("https://tokenURI", 1 ether);
        marketplace.buyNFT{value: 1 ether}(tokenId);
        assertEq(marketplace.ownerOf(tokenId), address(this));
    }   

    // function testWithdraw() public {
    //     uint256 initialBalance = address(this).balance;
    //     marketplace.withdraw();
    //     assertEq(address(this).balance, initialBalance + 1 ether);
    // }

    function testFailWithdrawWithNoBalance() public {
        NFTMarketplace(address(0x123)).withdraw();
    }

    function testSetPrice() public view  {
        assertEq(marketplace.nftPrices(_tokenId), _price);
    }

    function testFailSetPriceWithoutSellerRole() public {
        // Assuming this address does not have the SELLER_ROLE
        address nonSeller = address(0x123);
        NFTMarketplace(nonSeller).setPrice(_tokenId, _price);
    }

    function testFailSetPriceWithNonexistentToken() public {
        uint256 nonexistentTokenId = 9999;
        marketplace.setPrice(nonexistentTokenId, _price);
    }



}
