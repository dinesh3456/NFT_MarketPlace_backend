// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract NFTMarketplaceScript is Script {

    function run() external payable returns (address){
        address proxy = deployProxy();
        return proxy;
    }

    function deployProxy() public returns (address) {
        vm.startBroadcast();
        NFTMarketplace marketplace = new NFTMarketplace();
        ERC1967Proxy proxy = new ERC1967Proxy(address(marketplace),"");
        NFTMarketplace(address(proxy)).initialize();
        vm.stopBroadcast();
        return address(proxy);
    }
}
