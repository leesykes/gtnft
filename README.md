# 🏗 GTNFT

🎨 GTNFT is an on-chain SVG NFT collection. The artwork and metadata are generated and stored entirely on-chain using deterministic randomness and real-time SVG generation — no IPFS, no web servers, no external dependencies.

🌐 **Live:** https://gtnft-ls.vercel.app

---

## Requirements

- [Node.js >= 20](https://nodejs.org/en/download/)
- [Yarn v4](https://yarnpkg.com/getting-started/install)
- [Git](https://git-scm.com/downloads)

---

## Local Development

> Clone the repo and install dependencies

```sh
git clone https://github.com/leesykes/gtnft.git
cd gtnft
yarn install
```

> Copy the environment file and add your API keys

```sh
cp packages/nextjs/.env.example packages/nextjs/.env.local
```

Edit `.env.local` and fill in:
- `NEXT_PUBLIC_ALCHEMY_API_KEY` — get one free at [alchemy.com](https://www.alchemy.com)
- `NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID` — get one free at [cloud.walletconnect.com](https://cloud.walletconnect.com)

The app ships with shared demo keys so you can prototype immediately, but they are rate-limited and not suitable for production.

> Start a local blockchain

```sh
yarn chain
```

> In a second terminal, deploy the contracts locally

```sh
yarn deploy
```

> In a third terminal, start the frontend

```sh
yarn start
```

📱 Open http://localhost:3000

> To redeploy contracts after making changes:

```sh
yarn deploy --reset
```

> **Note:** `yarn chain` starts a fresh chain on every run — all contract state is lost. You must re-run `yarn deploy` each time you restart `yarn chain` before the frontend will work correctly.

### Network

The target network is selected automatically based on environment:

| Environment | Default network |
|---|---|
| `yarn start` (local) | Hardhat (local node) |
| Vercel (production) | Optimism Sepolia |

No config changes are needed to switch between local and live development. To target a different live network, change `chains.optimismSepolia` in `packages/nextjs/scaffold.config.ts`.

---

## Contracts

Smart contracts live in `packages/hardhat/contracts/`:

- `GTNFT.sol` — the main NFT contract with on-chain SVG generation

---

## Deployment

The frontend deploys automatically to Vercel on every push to `main`. Environment variables (`NEXT_PUBLIC_ALCHEMY_API_KEY`, `NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID`) are configured in the Vercel project settings.

---

## Built with

- [Scaffold-ETH 2](https://scaffoldeth.io) — Ethereum development framework
- [Next.js 15](https://nextjs.org)
- [wagmi](https://wagmi.sh) / [viem](https://viem.sh)
- [Optimism Sepolia](https://docs.optimism.io/chain/networks)
