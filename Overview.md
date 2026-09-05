# Overview: How This NFT Gets Made

A plain-language walkthrough of this project — no programming or crypto background
assumed. It follows the same example used throughout the repo: **42Berry**, a single
artwork called *Cross Coalition*.

## The big picture first

An NFT is basically a **certificate of ownership** that lives on a blockchain (a shared,
tamper-proof public ledger). It doesn't contain the artwork itself — that would be too
big and expensive to store on a blockchain. Instead, the certificate just points to where
the artwork lives, plus who owns the certificate. This project has three separate pieces
that all have to line up:

1. The **image** (the JPEG of *Cross Coalition*)
2. The **metadata** (a small text file describing the image — title, artist, attributes)
3. The **smart contract** (a small program on Ethereum that keeps track of who owns which
   certificate)

## 1. Pinning the image — what does "pinning" even mean?

The image itself is stored on **IPFS** (InterPlanetary File System), a network where
files are stored by *what they are* rather than *where they are*. When you upload a file
to IPFS, it gets a fingerprint called a **CID** (Content Identifier) — a long string like
`QmbqANbu...RiEAMx`. That fingerprint is generated from the file's contents, so if even
one pixel changed, the CID would be completely different. This is what makes it
trustworthy: the CID *is* proof of exactly what the file is.

But IPFS by itself doesn't guarantee anyone keeps a copy of your file around forever —
nodes can drop files they aren't interested in. **Pinning** just means telling a service
"keep a copy of this file available, don't let it disappear." That's the job
[Filebase](https://filebase.com) does here: you upload the JPEG to a Filebase bucket, and
Filebase promises to keep serving that file to the IPFS network.

The [`image/pin.sh check`](image/pin.sh) script exists because of a real problem this
project hit: a pinning provider's *own* gateway will always answer for your file (of
course it can, it's sitting right there in their storage) — but that tells you nothing
about whether the wider public IPFS network can actually find it. The script deliberately
checks *other* independent gateways (ipfs.io, dweb.link, w3s.link) instead of Filebase's
own, because that's the only way to know a stranger's wallet or OpenSea will actually be
able to load the image.

## 2. Why store the image *and* metadata separately, and why not just put the image on the blockchain?

Putting a whole image on Ethereum would be enormously expensive (you pay "gas" fees
proportional to the data you store on-chain) and pointless — blockchains are good at
recording small facts ("who owns what"), not hosting media files.

So the pattern is:

- The **image** goes on IPFS and gets its own CID.
- A small **metadata.json** file gets created that *describes* the artwork and *points
  at* the image's CID (`"image": "ipfs://Qmbq...`).
- That metadata file is *itself* also uploaded to IPFS and gets its own CID.
- Only that **second** CID (the metadata's) ever gets written onto the blockchain.

That's why the order in [`pin.sh`](image/pin.sh) matters: image first, then metadata,
because the metadata file needs to already know the image's CID before it can be uploaded
and fingerprinted. If you did it backwards, you'd end up with a metadata file pointing at
nothing.

So the chain of pointers looks like this:

```
Blockchain token  →  metadata.json (on IPFS)  →  image.jpg (on IPFS)
   (tiny, cheap)         (tiny)                      (the actual art)
```

This is why the deployment guide stresses that `_setTokenURI` is *permanent* — once that
metadata CID is written into the contract, it can never be changed. If the metadata
weren't reachable, you'd have a broken NFT forever. That's exactly what the `check` step
guards against before minting.

## 3. Compiling the smart contract — what does that actually do?

The smart contract, [`code/42Berry.sol`](code/42Berry.sol), is written in a programming
language called **Solidity**. Computers (or rather, the thousands of computers that run
the Ethereum network) can't execute Solidity text directly — it has to be translated into
a low-level format called **bytecode** that the Ethereum Virtual Machine can run. That
translation step is **compiling**.

In this project's workflow this happens in **Remix**, a code editor that runs in the
browser: you paste in `42Berry.sol`, click "Compile," and it checks the code for errors
and produces the bytecode (plus an "ABI," a description of what functions the contract
has, so other tools know how to call it). Nothing is on the blockchain yet at this point
— compiling just proves the code is valid and turns it into something deployable.

## 4. Deploying the smart contract — what does that do?

**Deploying** means actually publishing that compiled bytecode onto the blockchain,
permanently, at a brand-new address. Once deployed, the contract exists as its own
independent "account" on the network with the code and address `0x136e45c3...` — and from
then on, anyone can interact with it.

Practically, in Remix you connect a MetaMask wallet (set to the Sepolia test network — a
practice version of Ethereum with fake, free money, so nothing real is at risk), click
Deploy, and confirm the transaction in MetaMask. MetaMask signs the transaction with your
private key (proving *you* authorized it) and broadcasts it to the network. A moment
later, the contract exists on-chain.

Importantly: **deploying does not create any NFTs**. The constructor deliberately mints
nothing — look at [`code/42Berry.sol:26`](code/42Berry.sol#L26):
`constructor() ERC721("42Berry", "42B") Ownable(msg.sender) {}`. All it does is name the
collection ("42Berry"/"42B") and record the deployer as owner. It's an empty, ready
collection — like printing blank certificates with a serial-number counter, but nothing
filled in yet.

## 5. Minting — how the NFT actually gets created

**Minting** is calling the contract's `mint` function, which is the one moment the
artwork and the blockchain get linked together. You call it with two things:

- **who** should own the new token (a wallet address)
- **where** its metadata lives (`ipfs://QmV84K3R4LWjJr1xwBVNvgzsmnvnNgxUyRkHLohgNbraJa` —
  the metadata CID from step 2)

Inside the contract ([`code/42Berry.sol:32-48`](code/42Berry.sol#L32-L48)), minting does
four things:

1. Checks you're not minting to a broken/empty address, that the metadata URI isn't
   empty, and that the collection isn't already full (capped at 42 pieces — matching the
   "42" theme).
2. Assigns the next serial number (token `#1`, since this collection starts counting
   at 1).
3. Records that the target address now owns token `#1`.
4. Permanently attaches the metadata URI to that token number.

This only runs once, ever, per token — and only the contract's owner is allowed to call
it, so nobody else can create fake 42Berry NFTs from this contract.

## 6. What the finished NFT actually represents

After minting, what exists is:

- **On the blockchain (Sepolia):** an entry inside the contract saying "token #1 is owned
  by `0xaf6e74C8...`, and its metadata is at `ipfs://QmV84K3...`." This is the only part
  that's truly the "NFT" — everything else is just data it points to.
- **On IPFS (via Filebase):** the metadata JSON (name, description, artist, attributes)
  and, one hop further, the actual JPEG artwork.

So owning this NFT means: an Ethereum wallet address is permanently and publicly
recorded, on a tamper-proof ledger, as the holder of certificate #1 out of a fixed
collection of 42, whose descriptor unambiguously points at one specific, unchangeable
image. It's not the image "living inside your wallet" — it's more like a deed that says
"you hold title #1 to this specific artwork," where the artwork itself sits in
decentralized storage that anyone (marketplaces like OpenSea, wallets like MetaMask) can
independently fetch and display just by following the pointer chain.

That's the whole loop: pin the art → pin a description that names the art → compile the
rulebook contract → deploy the rulebook onto the blockchain → mint one certificate that
binds an owner to that description, forever.

## 7. Is Sepolia "really" the blockchain, or just a practice sandbox?

It's genuinely the blockchain — not a simulation running on someone's laptop. Sepolia is
a real, public, decentralized network with its own validators, its own blocks, its own
gas costs, and its own permanent history, and anyone in the world can look up 42Berry's
contract on [Sepolia Etherscan](https://sepolia.etherscan.io/address/0x560f24b7c8A86B973261807689DB159890D712c5)
right now. Once the deploy transaction is confirmed, the bytecode sits at that address
forever, exactly the same way a mainnet contract would.

The only things that make it a "testnet" rather than "the real thing":

- Its ETH is free from a faucet and worthless outside of testing — nobody is spending
  real money to mint or deploy here.
- It exists specifically so mistakes are cheap. If `42Berry.sol` had a bug, redeploying
  costs nothing but time.
- Unlike mainnet, testnets are occasionally retired outright. Ethereum has shut down and
  reset previous testnets before (Ropsten, Rinkeby, Kovan). If that ever happened to
  Sepolia, this deployment and its minted token would disappear with it — the one
  permanence guarantee mainnet has that a testnet doesn't.

So "deployed to Sepolia" means the contract is truly, publicly on a blockchain today —
just one whose long-term survival isn't guaranteed the way mainnet's is.

## 8. Could someone else take our CID and mint it as their own NFT?

This splits into two very different questions, and mixing them up is an easy mistake.

**Can someone mint a second 42Berry token on *our* contract?** No. Look at
[`code/42Berry.sol:32`](code/42Berry.sol#L32) — `mint` is guarded by `onlyOwner`, which
checks that whoever is calling it is the wallet that deployed the contract
(`0xaf6e74C8...`). If anyone else's wallet calls `mint` on `0x560f24b7...712c5`, the
Ethereum Virtual Machine itself rejects the transaction before anything happens. This
isn't a promise or a rule written in a README — it's enforced by the same code that runs
on every validator, so there's no way around it without that private key.

**Can someone copy our CID into a *different*, brand-new contract?** Yes, and nothing
technical stops them. IPFS has no login or permissions — a CID like
`ipfs://QmUHT1PRmpgkJ6v3cGeTgkbqLT6fV6ipPPhPoVQqpuZiiw` is public by design, that's the
whole point of content-addressed storage. Anyone can fetch that image and metadata,
deploy their own separate ERC-721 contract, and call *their* `mint` (which they'd own,
so they're allowed to) with a token URI pointing at the exact same CID. This is the same
thing as a "right-click save" copycat NFT that shows up on marketplaces sometimes.

**Why that doesn't fake or devalue the original:** an NFT's authenticity was never based
on the artwork data being secret — it's based on *provenance*: which contract, and which
wallet minted it. A copycat lives at a different contract address, minted by a different
wallet, and both facts are permanently visible on-chain. Anyone checking can compare that
against the canonical details in [`README.md`](README.md) — contract `0x560f24b7...712c5`,
owner `0xaf6e74C8...8905` — and immediately tell a clone from the original, no matter how
identical the image looks. It's the same reason a photocopy of a signed print isn't the
signed print, even pixel-for-pixel.

---

See [`README.md`](README.md) for the project summary and live deployment details,
[`documentation/README.md`](documentation/README.md) for the technical deep dive on the
contract, and [`deployment/README.md`](deployment/README.md) for the step-by-step
deploy/mint instructions.
