# Deployment & Interaction Guide

This guide provides instructions on how to deploy and interact with the smart contract using Remix IDE and MetaMask.

## Contract Address
```
0x7B5269f932A381B4CB034A7ECf160E77271D1528
```

## Required Setups
- [Remix IDE](https://remix.ethereum.org/)
- [MetaMask Wallet](https://metamask.io/)

## Deployment

Follow these steps to deploy the contract for the first time:

1. **Open Remix IDE:**
   - Navigate to [Remix IDE](https://remix.ethereum.org/) in your browser, and either choose or initiate a new Workspace.

2. **Upload 42Berry.sol:**
   - In the file explorer, upload `42Berry.sol` file located in the `code` folder of this repository.

3. **Compile the Contract:**
   - Click on the `Solidity compiler` tab on the left sidebar.
   - Choose the appropriate compiler in `Advanced Configurations`.
   - Click `Compile 42Berry.sol`.

4. **Deploy the Contract:**
   - Navigate to the `Deploy & run transactions` tab.
   - In the `Environment` dropdown, select `Remix VM` first to connect to a test address for demonstration purpose.
   - When you are ready to use your own address, select `Injected Provider - MetaMask` to connect your MetaMask wallet.
   - Ensure MetaMask is set to the correct network (Sepolia Testnet).

5. **Deploy:**
   - Click the `Deploy` button and confirm the transaction in MetaMask.

6. **Contract Deployed:**
   - After confirming the transaction, the contract will be deployed and visible under the `Deployed Contracts` section.
   - Save its address, you will be able to load this contract again somewhere else by entering the address to the `At Address` field (or just copy my deployed address above).

---

## Additional Resources

- [Contract Etherscan](https://sepolia.etherscan.io/address/0xC341Ae4d736087338a7B24F326a8A031DD4Cf00f)

- [Blockchain Demo](https://andersbrownworth.com/blockchain/)

- [Ethereum Converter](https://eth-converter.com/)

- [OpenZeppelin Library](https://docs.openzeppelin.com/contracts/5.x/api/token/erc20#ERC20)

## Sepolia Faucets

- [Google Cloud Web3](https://cloud.google.com/application/web3/faucet/ethereum/sepolia)

- [Chainlink](https://faucets.chain.link/sepolia)
