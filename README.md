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

The frontend is configured to target Optimism Sepolia by default. To develop against a local chain, first switch the target network in `packages/nextjs/scaffold.config.ts`:

```ts
targetNetworks: [chains.hardhat],  // change from chains.optimismSepolia
```

Then start the three services in separate terminals:

```bash
# Terminal 1 — start a local Hardhat blockchain
yarn chain

# Terminal 2 — compile and deploy contracts to the local network
yarn deploy

# Terminal 3 — start the Next.js frontend
yarn start
```

Visit `http://localhost:3000`. The app will connect to the local chain, and the faucet and block explorer links will appear in the footer.

When you're done with local development, revert `scaffold.config.ts` back to `chains.optimismSepolia` before pushing.

## Running against the live Optimism Sepolia contract

With `scaffold.config.ts` targeting `chains.optimismSepolia` (the default), just start the frontend — no local chain needed:

```bash
yarn start
```

The app will connect to the deployed contract at `0xF71Ea2f0A4ffC8f98Dee72D1C19401430EB3d746`.

## Deploying a new contract to Optimism Sepolia

Only needed if redeploying after contract changes. The existing contract is already live — see above to run against it.

1. Set up your `.env` files (see [Environment variables](#environment-variables) below).
2. Generate or import a deployer account:
   ```bash
   yarn generate        # create a new random account
   yarn account:import  # import an existing private key
   ```
3. Fund the deployer address with Optimism Sepolia ETH from the [Optimism faucet](https://app.optimism.io/faucet).
4. Deploy:
   ```bash
   yarn deploy --network optimismSepolia
   ```
5. Verify on Etherscan:
   ```bash
   yarn verify --network optimismSepolia
   ```
6. Update the contract address in `packages/hardhat/deployments/optimismSepolia/GTNFT.json` and regenerate the frontend ABI:
   ```bash
   yarn deploy --network optimismSepolia  # also runs generateTsAbis automatically
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
