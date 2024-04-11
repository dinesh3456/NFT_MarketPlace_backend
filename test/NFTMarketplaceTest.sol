// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract NFTMarketplaceTest is Test {
    NFTMarketplace public marketplace;
    NFTMarketplace public proxy;
    address admin = address(1);
    address owner = address(2);
    address alice = address(3);
    address bob = address(4);
    
    bytes32 ADMIN_ROLE;
    bytes32 CREATOR_ROLE;
    bytes32 SELLER_ROLE;
    bytes32 BUYER_ROLE;

    function setUp() public {
        marketplace = new NFTMarketplace();
        (proxy) = NFTMarketplace(
            address(
                new TransparentUpgradeableProxy(
                    address(marketplace), admin, abi.encodeWithSignature("initialize(address)", owner)
                )
            )
        );

        ADMIN_ROLE = marketplace.ADMIN_ROLE();
        CREATOR_ROLE = marketplace.CREATOR_ROLE();
        SELLER_ROLE = marketplace.SELLER_ROLE();
        BUYER_ROLE = marketplace.BUYER_ROLE();
    }

    function testAccessGrant() public {
        vm.startPrank(owner);
        proxy.grantRole(CREATOR_ROLE, alice);
        vm.stopPrank();

        vm.startPrank(alice);
        proxy.createAndListToken("https://tokenURI", 1 ether);
        vm.stopPrank();
    }

    function testFailAccessGrant() public {
        vm.startPrank(alice);
        proxy.createAndListToken("https://tokenURI", 1 ether);
        vm.stopPrank();
    }

    function testSetPrice() public {
        vm.startPrank(owner);
        proxy.grantRole(CREATOR_ROLE, alice); 
        proxy.grantRole(SELLER_ROLE, bob);       
        vm.stopPrank();

        vm.startPrank(alice);
        proxy.createAndListToken("https://tokenURI", 1 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        
      
        proxy.setPrice(1, 2 ether);
        vm.stopPrank();
    }

    function testFailSetPrice() public {
        vm.startPrank(alice);
        proxy.createAndListToken("https://tokenURI", 1 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        proxy.setPrice(1, 2 ether);
        vm.stopPrank();
    }

    function testBuyToken() public {
        vm.startPrank(owner);
        proxy.grantRole(CREATOR_ROLE, alice); 
        proxy.grantRole(BUYER_ROLE, bob); 
           
        vm.stopPrank();

        vm.startPrank(alice);
        proxy.createAndListToken("https://tokenURI", 1 ether);
        vm.stopPrank();

       

        vm.startPrank(bob);   
        vm.deal(bob, 2 ether);    
        proxy.buyNFT{value: 1 ether}(1);
        vm.stopPrank();
    }
   
    function testFailBuyToken() public {
        vm.startPrank(alice);
        proxy.createAndListToken("https://tokenURI", 1 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        proxy.buyNFT{value: 1 ether}(1);
        vm.stopPrank();
    }

}
