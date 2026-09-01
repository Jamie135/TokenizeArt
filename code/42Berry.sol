// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// ERC721URIStorage extends the base ERC721 standard with a per-token metadata URI,
// which lets every minted token point to its own JSON descriptor stored on IPFS
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Define a new contract called `Berry42`, which inherits from ERC721URIStorage and Ownable.
contract Berry42 is ERC721URIStorage, Ownable {

    // Incrementing unique identifier to every minted token.
    uint256 private _nextTokenId = 1;

    // Hard cap on the number of artworks this collection can ever contain.
    uint256 public constant MAX_SUPPLY = 42;

    // Emitted after a successful mint, so that a front-end or an indexer can react to it
    event ArtworkMinted(address indexed to, uint256 indexed tokenId, string metadataURI);

    // Constructor that initializes the collection with the name "42Berry", symbol "42B".
    // It also sets the deploying address as the owner of the contract.
    // Unlike the fungible version of this token, nothing is minted here: an artwork can
    // only be minted once its metadata has been pinned on IPFS and its URI is known.
    constructor() ERC721("42Berry", "42B") Ownable(msg.sender) {}

    // Function to mint a new unique artwork to the targeted address.
    // Restricted to the contract owner so that nobody else can inflate the collection.
    // `metadataURI` is the IPFS URI of the token's metadata JSON, in the form ipfs://<CID>.
    // Returns the identifier of the freshly minted token.
    function mint(address to, string memory metadataURI) public onlyOwner returns (uint256) {
        require(to != address(0), "Cannot mint to the zero address");
        require(bytes(metadataURI).length > 0, "Metadata URI cannot be empty");
        require(_nextTokenId <= MAX_SUPPLY, "Collection is sold out");

        uint256 tokenId = _nextTokenId;
        _nextTokenId++;

        // `_safeMint` reverts when `to` is a contract that does not implement
        // `onERC721Received`, which prevents the artwork from being locked forever
        // inside a contract unable to transfer it
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, metadataURI);

        emit ArtworkMinted(to, tokenId, metadataURI);
        return tokenId;
    }

    // Function to return how many artworks have been minted so far.
    function totalMinted() public view returns (uint256) {
        return _nextTokenId - 1;
    }

    // Function to return how many artworks can still be minted before the cap is reached.
    function remainingSupply() public view returns (uint256) {
        return MAX_SUPPLY - totalMinted();
    }
}
