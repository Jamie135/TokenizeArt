// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// ERC721URIStorage extends the base ERC721 standard with a per-token metadata URI,
// which lets every minted token point to its own JSON descriptor stored on IPFS
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Define a new contract called `Berry42`, which inherits from ERC721URIStorage and Ownable.
// The contract identifier is `Berry42` rather than `42Berry` because a Solidity identifier
// cannot begin with a digit; the token itself is still named "42Berry" in the constructor.
contract Berry42 is ERC721URIStorage, Ownable {

    // Incrementing counter used to assign a unique identifier to every minted token.
    // It starts at 1 rather than 0 so that the on-chain identifier matches the human
    // edition number printed on the artwork: token 1 is "42Berry #1", edition 1 of 42.
    uint256 private _nextTokenId = 1;

    // Hard cap on the number of artworks this collection can ever contain.
    // Declared constant so that it is fixed at compile time and cannot be raised
    // afterwards, not even by the owner.
    uint256 public constant MAX_SUPPLY = 42;

    // Emitted after a successful mint, so that a front-end or an indexer can react to it
    // without having to decode the generic ERC721 `Transfer` event
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
        // The counter starts at 1, so the last valid identifier is MAX_SUPPLY itself.
        // The comparison is inclusive for that reason: a strict `<` would cap the
        // collection at 41 artworks instead of 42.
        require(_nextTokenId <= MAX_SUPPLY, "Collection is sold out");

        // Reserve the current counter value for this token, then move the counter forward
        // so that two artworks can never share the same identifier
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;

        // `_safeMint` reverts when `to` is a contract that does not implement
        // `onERC721Received`, which prevents the artwork from being locked forever
        // inside a contract unable to transfer it
        _safeMint(to, tokenId);

        // Bind the token to its metadata, which in turn references the image on IPFS
        _setTokenURI(tokenId, metadataURI);

        emit ArtworkMinted(to, tokenId, metadataURI);
        return tokenId;
    }

    // Function to return how many artworks have been minted so far.
    // The counter is the identifier the *next* token will receive, and identifiers start
    // at 1, so the number already minted is one less than the counter.
    function totalMinted() public view returns (uint256) {
        return _nextTokenId - 1;
    }

    // Function to return how many artworks can still be minted before the cap is reached.
    // Derived from totalMinted() so that the two can never disagree.
    function remainingSupply() public view returns (uint256) {
        return MAX_SUPPLY - totalMinted();
    }
}
