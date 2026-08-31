# 42Berry (42B)

## Overview

### Web3.0

Web 3.0 is a decentralized network that represents the next phase of the internet (Web 2.0). Unlike  its predecessors, Web 3.0 prioritizes user privacy and data ownership through blockchain and smart contracts, enabling direct interactions without middlemen. This approach aims to improve security, transparency, and trust in online activities, opening doors for new applications and services.

### Cryptocurrency and Cryptography

- Cryptocurrency is a type virtual currency that that relies on cryptography for security. Unlike traditional currencies, cryptocurrencies exist only in digital form and have no physical counterpart.  
- Cryptography is the process of securing communication and data from unauthorized access, using complex mathematical algorithms for the encryption, making it almost impossible to decipher.

### Token

The type of cryptocurrency that will be studied in this project is a Token.
Unlike coins (e.g. Bitcoin, Ethereum) that operate on their own independent blockchain, Tokens use an existing blockchain to perform their wide-range functionalities that are managed by a smart contract.
Coins are primarily used as a medium of exchange, data storage, or transaction payment. Whereas Tokens represent a variety of assets or utilities, such as digital assets, access to platform-specific services, or even voting rights within a decentralized application (dApp).

### Smart Contracts

Smart contracts are self-executing contracts with the terms of the agreement directly written into code. These contracts are hosted on a blockchain and are automatically executed when predefined conditions are met. Smart contracts play a pivotal role in decentralized applications (dApps) and advanced functionalities, requiring robust blockchains capable of handling complex computations and data.

### Blockchain

Blockchain is a type of distributed database designed to record, store, and transmit data securely across a decentralized network. It removes the need for a central authority by allowing participants (nodes) to manage and verify data collectively. The data is stored in “blocks” that are linked together in a chronological order, forming a continuous “chain,” which makes the entire system resistant to modification and tampering.

#### How does it work

- **Transaction Creation**: A transaction is initiated by a user (e.g., sending cryptocurrency, executing a smart contract, or storing data). This transaction is broadcast to the network.

- **Verification**: Nodes (computers on the network) verify the transaction using a consensus mechanism, ensuring that the data is valid and complies with the rules of the blockchain.

- **Block Creation**: Once verified, the transaction is bundled together with others into a "block." The block is then added to the chain in chronological order.

- **Consensus Mechanism**: The network reaches consensus on the validity of the block, depending on the type of blockchain, either through PoW, PoS, or other mechanisms. This process ensures that the blockchain remains consistent across all nodes.

- **Finalization**: Once consensus is reached, the new block is added to the chain, and the ledger is updated across all participants in the network.

## Contract Overview

**42Berry (42B)** is an ERC20-compliant token built on the Ethereum blockchain using OpenZeppelin libraries. 
This token represents a bounty system inspired by the anime One Piece, offering some basic operations such as bounty increase, bounty decrease and bounty transfering. We will consider that the value of one 42B token is equal to one million berries from the One Piece verse.

## Contract Structure

### Imports:

The contract uses OpenZeppelin libraries to ensure security, reliability, and simplicity:

- **ERC20**: Provides the standard ERC20 functionality for fungible tokens.
- **Ownable**: Allows for ownership management, restricting certain functions to the owner of the contract.

### Rank Mapping:

The rank will determine the scale of the bounty to increase or decrease, the contract will map them to an integer:

- STAR (mapped to 0)
- CROWN (mapped to 1)

```solidity
enum Rank {
    STAR,
    CROWN
}
```

### Constructor:

The contract's constructor initializes the ERC20 token with:
- **Name**: "42Berry"
- **Symbol**: "42B"
- The contract sets the `msg.sender` as the owner during deployment using `Ownable`.
- The contract also call the `_mint()` method from OpenZeppelin to mint `initialSupply` amount of tokens for the the contract owner

```solidity
uint256 public initialSupply = 10000 * 10 ** 18;
uint256 public constant maxBounty = 5000 * 10 ** 18;

constructor() ERC20("42Berry", "42B") Ownable(msg.sender) {
    _mint(msg.sender, initialSupply);
}
```

### Functions:

#### increaseBounty

This function allows the contract owner to increase (mint) new tokens and assign them to a specified address.
The amount of minted tokens will depends on the target's rank and tier.

```solidity
function increaseBounty(address account, Rank rank, uint256 tier) public onlyOwner {
    require(account != owner(), "Cannot increase bounty for the owner");
    require(tier >= 1 && tier <= 5, "Invalid tier");

    uint256 amount = calculateAmount(rank, tier);
    require(balanceOf(account) + amount <= maxBounty, "Account bounty too high");
    _mint(account, amount);
}
```

#### decreaseBounty

This function allows the contract owner to decrease (burn) a specified amount of tokens from a specified address.
The amount of burned tokens will depends on the target's rank and tier.

```solidity
function decreaseBounty(address account, Rank rank, uint256 tier) public onlyOwner {
    require(account != owner(), "Cannot decrease bounty for the owner");
    require(tier >= 1 && tier <= 5, "Invalid tier");

    uint256 amount = calculateAmount(rank, tier);
    require(balanceOf(account) >= amount, "Account bounty too low");
    _burn(account, amount);
}
```

#### claimBounty

This function allows the contract owner to transfer tokens from his account to the bounty claimer, the amount of tokens transfered will be based on the bounty (balance) of the captured address.
After the transfer, all tokens from the captured address will be burnt.

```solidity
function claimBounty(address claimer, address captured) public onlyOwner {
    require(claimer != owner() && captured != owner(), "The owner cannot claim or be captured");
    
    uint256 capturedBalance = balanceOf(captured);
    require(totalSupply() >= capturedBalance, "Insufficient total supply");

    _transfer(msg.sender, claimer, capturedBalance);
    _burn(captured, capturedBalance);
}
```

#### negotiateHostage

This function allows the contract owner to redeem all his claimed tokens with an additional 100.

```solidity
function negotiateHostage() public onlyOwner {
    uint256 currentSupply = initialSupply;
    require(currentSupply > balanceOf(msg.sender), "No bounty has been claimed yet!");
    
    uint256 amount = currentSupply - balanceOf(msg.sender) + (100 * 10 ** 18);
    _mint(msg.sender, amount);
    initialSupply = balanceOf(msg.sender);
}
```

#### calculateAmount

This function calculates the amount of token based on the rank and the tier of the target.

```solidity
function calculateAmount(Rank rank, uint256 tier) internal pure returns (uint256) {
    uint256 baseAmount = 0;
    if (rank == Rank.STAR) {
        baseAmount = 100;
    } else if (rank == Rank.CROWN) {
        baseAmount = 1000;
    }
    return baseAmount * tier * 10 ** 18;
}
```

### ERC20 Standard Functions 
- approve: Allows owner to approve another address to spend tokens on their behalf.
- renounceOwner: Renounce ownership.
- transfer: Allows owner to transfer tokens to other addresses.
- transferFrom: Allows approved addresses to transfer tokens on behalf of token holders.
-tranferOwnership: Transfer the ownership to another address.
- allowance: Returns the amount of tokens that an address is allowed to spend on behalf of another address.
- balanceOf: Returns the token balance of a specific address.
- decimals: Returns the number of decimal places used for the token.
- name: Returns the name of the token.
- owner: Returns the owner address.
- symbol: Returns the symbol of the token.
- totalSupply: Returns the total supply of the token.

---

## Additional Resources

- [Contract Etherscan](https://sepolia.etherscan.io/address/0xC341Ae4d736087338a7B24F326a8A031DD4Cf00f)

- [Blockchain Demo](https://andersbrownworth.com/blockchain/)

- [Ethereum Converter](https://eth-converter.com/)

- [OpenZeppelin Library](https://docs.openzeppelin.com/contracts/5.x/api/token/erc20#ERC20)

## Sepolia Faucets

- [Google Cloud Web3](https://cloud.google.com/application/web3/faucet/ethereum/sepolia)

- [Chainlink](https://faucets.chain.link/sepolia)
