# 42Berry (42B)

## Overview

### Web3.0

Web 3.0 is a decentralized network that represents the next phase of the internet (Web 2.0). Unlike  its predecessors, Web 3.0 prioritizes user privacy and data ownership through blockchain and smart contracts, enabling direct interactions without middlemen. This approach aims to improve security, transparency, and trust in online activities, opening doors for new applications and services.

### Cryptocurrency and Cryptography

- Cryptocurrency is a type virtual currency that that relies on cryptography for security. Unlike traditional currencies, cryptocurrencies exist only in digital form and have no physical counterpart.  
- Cryptography is the process of securing communication and data from unauthorized access, using complex mathematical algorithms for the encryption, making it almost impossible to decipher.

### Token

The type of cryptocurrency that will be studied in this project is a Token, and more
specifically a *non-fungible* one: a token whose units are not interchangeable, each
carrying its own identity and its own metadata.
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

**42Berry (42B)** is an ERC-721 non-fungible token collection on Ethereum, built on the
OpenZeppelin libraries. It holds a single artwork, *Cross Coalition*, drawn from scratch
and pinned to IPFS; the contract stores only the URI of that pinned metadata. The
collection is capped at 42 pieces, matching the school the artwork depicts.

### What the token represents

A 42Berry token is not the artwork itself, and it grants no licence to reproduce it — it
is a tamper-proof certificate of ownership and provenance for one numbered edition of
*Cross Coalition*. Up to 42 certificates can ever exist for this piece, each independently 
tracked by `ERC721URIStorage` with its own owner and its own metadata URI, even though they 
all point back to the same drawing. `mint` is restricted to the contract owner, so new editions 
can only ever be issued by the project itself — nobody can mint themselves a copy. In the
current deployment, only edition `#1` has actually been minted; see the
[root README](../README.md#deployment) for its live token ID, owner and IPFS pointers.

### How it will be used

Once minted, a 42Berry token behaves like any standard ERC-721 asset. `ownerOf` proves
who holds a given edition, `tokenURI` lets any wallet or marketplace resolve its metadata
and render the artwork without bespoke integration, and `transferFrom` /
`safeTransferFrom` let the holder sell, gift, or otherwise transfer that edition to
someone else — the token never changes, only who holds it. In a wallet such as MetaMask,
or on a marketplace such as OpenSea, this plays out as a normal NFT: the artwork displays,
its coalition and edition attributes show from `metadata.json`, and trading it moves the
on-chain certificate, not a copy of the file, which stays pinned on IPFS regardless of who
owns the token.

The token carries no further utility beyond that certificate — no access rights, no
voting power, nothing gated behind holding it. Its purpose is the collectible itself: a
verifiable, transferable claim to one numbered edition of *Cross Coalition*, permanently
and publicly recorded on Ethereum.

## Contract Structure

### Imports:

- **ERC721URIStorage**: the ERC-721 standard plus a per-token metadata URI, so every token points at its own JSON descriptor on IPFS instead of sharing a collection-wide base URI.
- **Ownable**: ownership management, restricting minting to the owner of the contract.

```solidity
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
```

The contract identifier is `Berry42` rather than `42Berry` because a Solidity identifier
cannot begin with a digit; the token itself is still named "42Berry".

### State:

```solidity
uint256 private _nextTokenId = 1;
uint256 public constant MAX_SUPPLY = 42;
```

`_nextTokenId` starts at 1 rather than 0 so the on-chain identifier matches the edition
number printed on the artwork: token 1 is "42Berry #1", edition 1 of 42. `MAX_SUPPLY` is
`constant`, so the cap is fixed at compile time and cannot be raised afterwards, not even
by the owner.

### Constructor:

```solidity
constructor() ERC721("42Berry", "42B") Ownable(msg.sender) {}
```

The constructor initializes the collection with the name "42Berry" and symbol "42B", and
sets the deploying address as owner. Nothing is minted here: an artwork can only be minted
once its metadata has been pinned on IPFS and its URI is known.

### Functions:

#### mint

Mints a new artwork to the target address and binds it to its IPFS metadata. Restricted to
the owner so that nobody else can inflate the collection. The supply check is inclusive
because identifiers start at 1 — a strict `<` would cap the collection at 41 pieces.

```solidity
function mint(address to, string memory metadataURI) public onlyOwner returns (uint256) {
    require(to != address(0), "Cannot mint to the zero address");
    require(bytes(metadataURI).length > 0, "Metadata URI cannot be empty");
    require(_nextTokenId <= MAX_SUPPLY, "Collection is sold out");

    uint256 tokenId = _nextTokenId;
    _nextTokenId++;

    _safeMint(to, tokenId);
    _setTokenURI(tokenId, metadataURI);

    emit ArtworkMinted(to, tokenId, metadataURI);
    return tokenId;
}
```

`_safeMint` reverts when `to` is a contract that does not implement `onERC721Received`,
which prevents the artwork from being locked forever inside a contract unable to transfer
it. `_setTokenURI` writes the metadata URI permanently, which is why the URI must be
verified as publicly resolvable before minting — see `image/README.md`.

#### totalMinted

Returns how many artworks have been minted so far. The counter is the identifier the
*next* token will receive, and identifiers start at 1, so the number already minted is one
less than the counter.

```solidity
function totalMinted() public view returns (uint256) {
    return _nextTokenId - 1;
}
```

#### remainingSupply

Returns how many artworks can still be minted before the cap is reached. Derived from
`totalMinted()` so that the two can never disagree.

```solidity
function remainingSupply() public view returns (uint256) {
    return MAX_SUPPLY - totalMinted();
}
```

### Events:

```solidity
event ArtworkMinted(address indexed to, uint256 indexed tokenId, string metadataURI);
```

Emitted after a successful mint, so a front-end or indexer can react to it without having
to decode the generic ERC-721 `Transfer` event.

### ERC-721 Standard Functions

Inherited from OpenZeppelin:

- **tokenURI**: Returns the metadata URI of a given token, in the form `ipfs://<CID>`.
- **ownerOf**: Returns the address that owns a given token.
- **balanceOf**: Returns how many tokens an address owns.
- **safeTransferFrom**: Transfers a token, refusing recipients that cannot handle ERC-721.
- **transferFrom**: Transfers a token without that check.
- **approve**: Allows another address to transfer a specific token.
- **setApprovalForAll**: Allows an operator to transfer every token of the caller.
- **getApproved** / **isApprovedForAll**: Query the approvals above.
- **supportsInterface**: ERC-165 introspection; reports support for ERC-721 and its metadata extension.
- **name** / **symbol**: Return "42Berry" and "42B".
- **owner** / **transferOwnership** / **renounceOwnership**: Ownership management from `Ownable`.

---

## Additional Resources

- [Blockchain Demo](https://andersbrownworth.com/blockchain/)

- [Ethereum Converter](https://eth-converter.com/)

- [OpenZeppelin ERC-721](https://docs.openzeppelin.com/contracts/5.x/api/token/erc721)

## Sepolia Faucets

- [Google Cloud Web3](https://cloud.google.com/application/web3/faucet/ethereum/sepolia)

- [PoWFaucet] (https://faucets.pk910.de/)

- [Chainlink](https://faucets.chain.link/sepolia)
