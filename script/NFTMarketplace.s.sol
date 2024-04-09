// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";
import {NFTMarketplaceProxy} from "../src/ProxyNFTMarketplace.sol";

contract NFTMarketplaceScript is Script {

    function run() external payable returns (address){
        address proxy = deployProxy();
        return proxy;
    }

    function deployProxy() public returns (address) {
        vm.startBroadcast();
        NFTMarketplace marketplace = new NFTMarketplace();
        NFTMarketplaceProxy proxy = new NFTMarketplaceProxy(address(marketplace));
        NFTMarketplace(address(proxy)).initialize();
        vm.stopBroadcast();
        return address(proxy);
    }
}
