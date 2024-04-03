## NFTMarketplace backend

**The NFTMarketplace is build using Foundry. It is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust. The NFTMarketplace contract allows users to mint, list, and purchase NFTs. It includes a withdraw function that allows users to withdraw their balance from the contract.**

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

**Tests for the NFTMarketplace contract are located in the test directory. These tests cover the main functionalities of the contract, including minting NFTs, setting prices, and withdrawing balances.**

**To run the tests, use the forge test command:**

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/NFTMarketplaceScript.sol:NFTMarketplaceScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

