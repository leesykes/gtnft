# GTNFT — Generative Tiling NFT

On-chain generative art NFT collection deployed on Optimism Sepolia. Each token is a unique recursive tiling artwork generated entirely on-chain from the token ID as a seed.

- **Contract:** [`0xF71Ea2f0A4ffC8f98Dee72D1C19401430EB3d746`](https://sepolia-optimism.etherscan.io/address/0xF71Ea2f0A4ffC8f98Dee72D1C19401430EB3d746) on Optimism Sepolia
- **Collection size:** 3,728 tokens
- **Pricing:** Bonding curve — starts at 0.001 ETH, increases 0.2% per mint
- **Art:** Fully on-chain SVG, generated recursively from token ID + contract address hash

## Stack

Built on [Scaffold-ETH 2](https://scaffoldeth.io) — Next.js 16, Hardhat 3, wagmi, viem, RainbowKit, DaisyUI.

## Requirements

- [Node.js >= 22.10.0](https://nodejs.org/en/download/) — use `nvm use` in the project root
- [Yarn v4](https://yarnpkg.com/getting-started/install)
- [Git](https://git-scm.com/downloads)

## Local development

```bash
# Terminal 1 — local blockchain
yarn chain

# Terminal 2 — deploy contracts to local network
yarn deploy

# Terminal 3 — start frontend
yarn start
```

Visit `http://localhost:3000`.

## Deploy to Optimism Sepolia

1. Generate or import a deployer account:
   ```bash
   yarn generate        # new random account
   yarn account:import  # import existing private key
   ```
2. Fund the deployer with Optimism Sepolia ETH.
3. Deploy:
   ```bash
   yarn deploy --network optimismSepolia
   ```
4. Verify on Etherscan:
   ```bash
   yarn verify --network optimismSepolia
   ```

## Environment variables

Copy `.env.example` files in each package and fill in your own API keys for production:

```bash
cp packages/hardhat/.env.example packages/hardhat/.env
cp packages/nextjs/.env.example packages/nextjs/.env.local
```

Key vars: `ALCHEMY_API_KEY`, `ETHERSCAN_API_KEY`, `NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID`.

## Project structure

```
packages/
  hardhat/        Smart contracts, deploy scripts, tests
  nextjs/         Frontend (Next.js App Router)
```

## Contract notes

- Traits (palette, complexity, feature) are packed into a single `uint8` per token to minimise storage
- SVG generation uses `viaIR: true` to work around Solidity's 16-variable stack limit in recursive functions
- The recipient address for mint proceeds is hardcoded in the contract — change before redeploying a new collection
