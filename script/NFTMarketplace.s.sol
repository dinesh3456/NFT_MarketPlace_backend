// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract NFTMarketplaceScript is Script {
    NFTMarketplace public marketplace;
    NFTMarketplace public proxy;

    bytes32 ADMIN_ROLE;
    bytes32 CREATOR_ROLE;
    bytes32 SELLER_ROLE;
    bytes32 BUYER_ROLE;

    function run() external returns (NFTMarketplace) {
        // Deploy the NFTMarketplace contract
        marketplace = new NFTMarketplace();

        // Deploy the transparent upgradeable proxy
        proxy = NFTMarketplace(
            address(
                new TransparentUpgradeableProxy(
                    address(marketplace), msg.sender, abi.encodeWithSignature("initialize(address)", msg.sender)
                )
            )
        );

        ADMIN_ROLE = marketplace.ADMIN_ROLE();
        CREATOR_ROLE = marketplace.CREATOR_ROLE();
        SELLER_ROLE = marketplace.SELLER_ROLE();
        BUYER_ROLE = marketplace.BUYER_ROLE();   


        _createAndListToken("https://tokenURI", 1 ether);


        return proxy;
    }

    function _createAndListToken(string memory _tokenURI, uint256 price) public returns(uint256 tokenId){
        vm.startPrank(msg.sender);
        proxy.grantRole(CREATOR_ROLE, msg.sender);
        vm.stopPrank();

        vm.startPrank(msg.sender);
        return proxy.createAndListToken(_tokenURI, price);
        
    }
}
