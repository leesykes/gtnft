# GTNFT — TODO

## Migrate to latest Scaffold-ETH 2 ✓

**Strategy:** Fresh SE2 checkout, port custom code in — rather than upgrading in-place.
**Reference:** SE2 `main` @ `09d649e` (2026-05-28) — merged via PR #49

---

## Outstanding work

### Housekeeping

- [ ] Remove unused `using HexStrings for uint160` from `GTNFT.sol` (library imported but never called)
- [ ] Add `.github/workflows/lint.yaml` (excluded from original push — needs a token with `workflow` scope or manual push via SSH)

### Contract

- [ ] Verify GTNFT on Optimism Sepolia Etherscan: `yarn verify --network optimismSepolia`
- [ ] Gas profile `tokenURI` worst-case — recursive SVG at max complexity; `tokenURI` already measured at ~432k gas average

### Frontend

- [ ] Get production API keys: Alchemy (`ALCHEMY_API_KEY`) and WalletConnect (`NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID`) — current defaults are shared/rate-limited
- [ ] Add OG image and favicon specific to GTNFT (currently using SE2 defaults)
- [ ] Test mint flow end-to-end on Optimism Sepolia with a real wallet
- [ ] Check mobile layout on `/GTNFT` gallery and `/your-GTNFT` pages

---

### Done

- [x] SE2 migration to Hardhat 3, Next.js 16, `@scaffold-ui` (PR #49)
- [x] GTNFT rename (from YourCollectible)
- [x] Deployed to Optimism Sepolia at `0xF71Ea2f0A4ffC8f98Dee72D1C19401430EB3d746`
- [x] Vercel deployment fixed — `vercel.json` moved to `packages/nextjs/`, Root Directory set to `packages/nextjs`
- [x] Debug Contracts nav link hidden in production, visible in dev (PR #50)
- [x] Contract tests — 10 tests covering mint mechanics, pricing curve, tokenURI, trait storage (PR #50)
- [x] Local dev network config — hardhat in `targetNetworks` for dev, burner wallet + faucet restored (PR #51)
