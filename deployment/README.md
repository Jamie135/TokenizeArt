# Deployment & Interaction Guide

This guide provides instructions on how to deploy and interact with the smart contract using Remix IDE and MetaMask.

## Contract Address

Not yet deployed — fill this in with the address Remix reports after step 5 below.

```
<deployed contract address>
```

## IPFS

The artwork and its ERC-721 descriptor are pinned on [Filebase](https://filebase.com);
the contract stores only the metadata URI. `deployment/ipfs.json` holds the same values
in machine-readable form, and the table below is generated from it by `image/pin.sh record`.

<!-- ipfs:begin -->
| | CID | Gateway |
|---|---|---|
| Artwork (JPEG) | `QmbqANbuYccExnQK7jfM6ey8xM6Df11LQ8h3sXT3RiEAMx` | [view](https://ipfs.io/ipfs/QmbqANbuYccExnQK7jfM6ey8xM6Df11LQ8h3sXT3RiEAMx) |
| Metadata (JSON) | `QmV84K3R4LWjJr1xwBVNvgzsmnvnNgxUyRkHLohgNbraJa` | [view](https://ipfs.io/ipfs/QmV84K3R4LWjJr1xwBVNvgzsmnvnNgxUyRkHLohgNbraJa) |

Token URI passed to `mint`:

```
ipfs://QmV84K3R4LWjJr1xwBVNvgzsmnvnNgxUyRkHLohgNbraJa
```
<!-- ipfs:end -->

Both CIDs resolve through independent public gateways (ipfs.io, dweb.link, w3s.link), not
just Filebase's own — which is the property that matters, since wallets and marketplaces
resolve `ipfs://` through their own infrastructure. Verify with `./image/pin.sh check`.

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
   - Save its address and record it under *Contract Address* above. You can load the contract again later by entering that address in the `At Address` field.

## Minting the artwork

Deploying creates an empty collection: the constructor mints nothing, because a token
cannot exist before its metadata has a URI. Minting is a separate owner-only call.

1. **Check the metadata is reachable** — `./image/pin.sh check` must print `OK - reachable from public IPFS`. `_setTokenURI` is permanent, so a token minted against an unresolvable URI can never be repaired.

2. **Call `mint`** under the deployed contract, with your wallet address and the token URI from the *IPFS* section above:

   ```
   mint(<recipient address>, "ipfs://<metadata CID>")
   ```

3. **Verify** — `tokenURI(1)` returns that URI, `ownerOf(1)` returns the recipient, and `totalMinted()` returns 1. Identifiers start at 1, so `tokenURI(0)` reverts.

4. **View it** — import the contract address into MetaMask under *NFTs*, or open the token on [Sepolia Etherscan](https://sepolia.etherscan.io/).

---

## Additional Resources

- [Blockchain Demo](https://andersbrownworth.com/blockchain/)

- [Ethereum Converter](https://eth-converter.com/)

- [OpenZeppelin ERC-721](https://docs.openzeppelin.com/contracts/5.x/api/token/erc721)

## Sepolia Faucets

- [Google Cloud Web3](https://cloud.google.com/application/web3/faucet/ethereum/sepolia)

- [Chainlink](https://faucets.chain.link/sepolia)
