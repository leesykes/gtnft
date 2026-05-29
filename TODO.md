# GTNFT — TODO

## Migrate to latest Scaffold-ETH 2 ✓

**Strategy:** Fresh SE2 checkout, port custom code in — rather than upgrading in-place.
**Reference:** SE2 `main` @ `09d649e` (2026-05-28)
**Branch:** `migration/se2-latest` → PR #49

All migration steps complete. Branch open pending Vercel preview confirmation before merging to `main`.

- [x] Step 1 — Bootstrap (SE2 clone, deps, package rename, `.nvmrc`)
- [x] Step 2 — Smart contracts (Hardhat 3, rocketh deploy, stack-too-deep fix)
- [x] Step 3 — Network config (Optimism Sepolia, existing contract preserved)
- [x] Step 4 — Frontend (new SE2 style, `@scaffold-ui/components`, footer cleaned up)
- [x] Step 5 — Deployment config (`vercel.json` framework hint removed, branch pushed, PR #49 open)

---

## Outstanding work

### Housekeeping

- [ ] Rename `packages/hardhat/test/YourContract.ts` → `GTNFT.ts` and rewrite for GTNFT
- [ ] Remove unused `using HexStrings for uint160` from `GTNFT.sol` (library imported but never called)
- [ ] Add `.github/workflows/lint.yaml` back to the branch (was excluded from push — needs a token with `workflow` scope or manual push via SSH)

### Contract

- [ ] Verify GTNFT on Optimism Sepolia Etherscan: `yarn verify --network optimismSepolia`
- [ ] Write contract tests covering: mint pricing curve, collection limit enforcement, trait packing/unpacking, tokenURI base64 decode, SVG output validity
- [ ] Gas profile `tokenURI` — recursive SVG generation could be expensive for high-complexity tokens; measure worst-case gas

### Frontend

- [ ] Get production API keys: Alchemy (`ALCHEMY_API_KEY`) and WalletConnect (`NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID`) — current defaults are shared/rate-limited
- [ ] Add OG image and favicon specific to GTNFT (currently using SE2 defaults)
- [ ] Test mint flow end-to-end on Optimism Sepolia with a real wallet
- [ ] Check mobile layout on `/GTNFT` gallery and `/your-GTNFT` pages

### Infrastructure

- [ ] Set Node 22 in Vercel project settings (Settings → General → Node.js Version) before first production deploy
- [ ] Confirm Vercel preview deploy reads live contract on Optimism Sepolia correctly

---

### Done

- [x] SE2 migration (see above)
- [x] GTNFT rename (from YourCollectible)
- [x] Deployed to Optimism Sepolia at `0xF71Ea2f0A4ffC8f98Dee72D1C19401430EB3d746`
