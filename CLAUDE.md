# CLAUDE.md

@AGENTS.md

---

## GTNFT — Project-Specific Guidance

This is **GTNFT** (Generative Tiling NFT), an on-chain generative art NFT collection. It is built on the SE2 stack above but has significant customisations. Read this section before starting any work.

### What This Project Is

- On-chain ERC721 collection — SVG artwork generated recursively from the token ID as a seed
- Deployed on **Optimism Sepolia** at `0xF71Ea2f0A4ffC8f98Dee72D1C19401430EB3d746`
- 3,728 token collection with a bonding curve (0.2% price increase per mint)
- Mint proceeds go to a hardcoded recipient address in the contract — do not change this without explicit instruction

### Node Version

This project requires **Node ≥ 22.10.0**. A `.nvmrc` is present at the repo root.

```bash
nvm use   # activates the correct version
```

All `yarn` commands will fail silently or with cryptic errors on Node 18. Always verify with `node --version` before running anything.

### Network Configuration

`packages/nextjs/scaffold.config.ts` targets **Optimism Sepolia** by default (`chains.optimismSepolia`). This is correct for production.

For local development against a local Hardhat node, change it temporarily:
```ts
targetNetworks: [chains.hardhat],  // local dev
```
Revert before committing.

### Contract Compilation

`GTNFT.sol` uses recursive SVG generation that hits Solidity's stack limit. It requires `viaIR: true` in the solc settings (`packages/hardhat/hardhat.config.ts`). Do not remove this.

If `yarn compile` or `yarn deploy` throws `MalformedAbiError: Not a valid ABI`, there are stale Hardhat 2 artifacts present. Fix:
```bash
rm -rf packages/hardhat/artifacts packages/hardhat/cache
yarn compile
```

### Deployment

The contract is already deployed — do not redeploy unless you are explicitly migrating or creating a new collection. The deployment artifacts in `packages/hardhat/deployments/optimismSepolia/` must be preserved so the frontend knows the contract address.

To deploy to local Hardhat node for testing:
```bash
yarn chain   # terminal 1
yarn deploy  # terminal 2 (targets local node)
```

### Vercel Deployment

The Vercel project (`gtnft-ls`) is configured with:
- **Root Directory**: `packages/nextjs`
- **vercel.json**: lives at `packages/nextjs/vercel.json`
- Install command `cd ../.. && corepack enable && yarn install --no-immutable` — this is intentional; it `cd`s to the repo root so the full monorepo installs correctly

Do not move `vercel.json` to the repo root — Vercel CLI cannot detect Next.js from the root `package.json` in this monorepo setup.

### Pre-commit Hook

`.husky/pre-commit` explicitly sets the Node 22 PATH and calls `yarn precommit` (not `yarn lint-staged`). This is intentional — the system default shell runs Node 18 which is incompatible with `listr2`.

### Key Files

| File | Purpose |
|------|---------|
| `packages/hardhat/contracts/GTNFT.sol` | Main contract — ERC721 with on-chain SVG |
| `packages/hardhat/deploy/00_deploy_gtnft.ts` | Deploy script (rocketh/hardhat-deploy v2 API) |
| `packages/nextjs/app/GTNFT/page.tsx` | Gallery page |
| `packages/nextjs/app/your-GTNFT/page.tsx` | My Collection page |
| `packages/nextjs/scaffold.config.ts` | Network config — change `targetNetworks` for local dev |
| `TODO.md` | Outstanding work — check here before starting new tasks |
