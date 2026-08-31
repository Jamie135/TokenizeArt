// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Define a new contract called `CrossGuild`, which inherits from ERC20 and Ownable
contract CrossGuild is ERC20, Ownable {

    // map STAR and CROWN rank to 0 and 1
    enum Rank {
        STAR,
        CROWN
    }

    // Initialize the initial supply of the token to ten thousands and the maximum bounty to five thousands
    uint256 public initialSupply = 10000 * 10 ** 18;
    uint256 public constant maxBounty = 5000 * 10 ** 18;

    // Constructor that initializes the token with the name "42Berry", symbol "42B"
    // It sets the contract owner amount of tokens to initialSupply
    // It also sets the sender address to be the owner of the contract
    constructor() ERC20("42Berry", "42B") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    // Function to mint new tokens for the targeted address
    function increaseBounty(address account, Rank rank, uint256 tier) public onlyOwner {
        require(account != owner(), "Cannot increase bounty for the owner");
        require(tier >= 1 && tier <= 5, "Invalid tier");

        uint256 amount = calculateAmount(rank, tier);
        require(balanceOf(account) + amount <= maxBounty, "Account bounty too high");
        _mint(account, amount);
    }

    // Function to burn tokens for the targeted address
    function decreaseBounty(address account, Rank rank, uint256 tier) public onlyOwner {
        require(account != owner(), "Cannot decrease bounty for the owner");
        require(tier >= 1 && tier <= 5, "Invalid tier");

        uint256 amount = calculateAmount(rank, tier);
        require(balanceOf(account) >= amount, "Account bounty too low");
        _burn(account, amount);
    }

    // Function to transfer tokens from the contract owner to the bounty claimer's address
    function claimBounty(address claimer, address captured) public onlyOwner {
        require(claimer != owner() && captured != owner(), "The owner cannot claim or be captured");
        
        uint256 capturedBalance = balanceOf(captured);
        require(totalSupply() >= capturedBalance, "Insufficient total supply");

        _transfer(msg.sender, claimer, capturedBalance);
        _burn(captured, capturedBalance);
    }

    // Function to mint tokens for the contract owner
    function negotiateHostage() public onlyOwner {
        uint256 currentSupply = initialSupply;
        require(currentSupply > balanceOf(msg.sender), "No bounty has been claimed yet!");
        
        uint256 amount = currentSupply - balanceOf(msg.sender) + (100 * 10 ** 18);
        _mint(msg.sender, amount);
        initialSupply = balanceOf(msg.sender);
    }

    // Function to calculate the token amount
    function calculateAmount(Rank rank, uint256 tier) internal pure returns (uint256) {
        uint256 baseAmount = 0;
        if (rank == Rank.STAR) {
            baseAmount = 100;
        } else if (rank == Rank.CROWN) {
            baseAmount = 1000;
        }
        return baseAmount * tier * 10 ** 18;
    }
}
