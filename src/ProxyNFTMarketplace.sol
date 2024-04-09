// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


/**
 * @title Proxy contract
 * @dev A proxy contract that delegates calls to an implementation contract.
 * This proxy contract is compatible with the UUPS (Universal Upgradeable Proxy Standard).
 */

contract NFTMarketplaceProxy is Proxy, AccessControl {
    // Storage slot for the address of the current implementation contract
    bytes32 private constant IMPLEMENTATION_SLOT = keccak256("implementation.address");
    bytes32 public constant ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");


    /**
     * @dev Modifier to check that the sender is the admin
     */
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Proxy: Caller is not the admin");
        _;
    }

    /**
     * @dev Constructor function
     * Sets the initial admin and implementation contract
     */
    constructor(address initialImplementation) {
        // Set the admin to the deployer of the contract
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Set the initial implementation contract
        _setImplementation(initialImplementation);
    }

    /**
     * @dev Function to upgrade the implementation contract
     * @param newImplementation Address of the new implementation contract
     */
    function upgradeTo(address newImplementation) external onlyAdmin {
        _setImplementation(newImplementation);
    }

    /**
     * @dev Function to get the current implementation contract address
     * @return Address of the current implementation contract
     */
    function implementation() public view onlyAdmin returns  (address)  {
        return _implementation();
    }

    /**
     * @dev Function to delegate calls to the implementation contract
     */
    fallback() external override payable {
        _delegate();
    }

    /**
     * @dev Function to delegate calls to the implementation contract
     */
    receive() external payable {
        _delegate();
    }

    /**
     * @dev Internal function to delegate calls to the implementation contract
     */
    function _delegate() private {
        // Get the current implementation contract address
        address _impl = _implementation();
        // Delegate call to the implementation contract
        assembly {
            // Get the gas and call data for the delegate call
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            // Check if the delegate call was successful, revert if it wasn't
            switch result
            case 0 {
                revert(0, 0)
            }
            default {
                // Get the returned data and size
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                // Return the data
                return(ptr, size)
            }
        }
    }

    
    /**
     * @dev Returns the address of the current implementation contract.
     * @return implementationAddress The address of the current implementation contract.
     */
    function _implementation() internal view override returns (address implementationAddress) {
        // Get the current implementation contract address from storage
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            implementationAddress := sload(slot)
        }
    }


    /**
     * @dev Internal function to set the implementation contract
     * @param newImplementation Address of the new implementation contract
     */
    function _setImplementation(address newImplementation) private {
        // Store the new implementation contract address in the implementation slot
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
    }
}
