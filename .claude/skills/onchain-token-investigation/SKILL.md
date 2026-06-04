---
name: onchain-token-investigation
description: Methodology + ready-to-run Dune SQL templates for investigating ANY token on-chain. Use when the user wants to investigate / analyze / 调查 / 链上分析 a new token — its mint & distribution, treasury/whale mapping, vesting & unlocks, pump-and-dump / market-maker manipulation, smart-money vs dumb-money, or to find alpha signals around a TGE/unlock. Reusable across tokens and chains; runs queries via the Dune MCP.
---

# On-chain Token Investigation

A reusable playbook distilled from a full forensic teardown of one token (WCT:
mint → treasury fan-out → vesting → pump-and-dump → winners/losers → alpha
model). Apply it to any new token. The worked example lives in the
`Onchain-Makers/wct-analyse` repo (`docs/阶段一…四`) — read it when you want a
concrete reference for any step.

**You investigate by writing DuneSQL and running it via the Dune MCP.** The
`queries/` folder next to this file holds parameterized templates generalized
from the verified WCT queries — copy one, replace the `{{placeholders}}`, run it.

## Mindset (心法 — non-negotiable)
- **Find the un-fakeable data layer and read it with discipline.** Crypto = on-chain. Grade every claim **✅实证 / 🔶推断 / ⛔不可知** and never overclaim.
- **CEX is a black box.** On-chain shows deposits/withdrawals, *not* order-book fills, prices, buyers, or identities. The biggest real selling/buying is invisible — say so.
- **Published addresses are the cover page.** The token/timelock/config the project lists are "operational" contracts; the *money* (treasury, sub-treasuries, vesting, allocation EOAs, MM wallets) is **one hop away** — found via the Mint event, not published.
- **Keep Dune queries cheap.** Always filter on partition columns (`block_date`, `contract_address`, `topic0`); prefer spell tables. Unfiltered scans of `<chain>.logs`/`.transactions` are expensive and can get an account banned.

## Inputs
- token contract address + chain (e.g. `0x…`, `optimism`). 
- optional: official docs (address list, TGE/unlock date), to seed the recon.

## Phase 1 — Recon & fund flow (who got what)
**T0 reads (instant, view/state):** totalSupply, proxy→implementation + ProxyAdmin, AccessControl roles, any transfer-restriction/unlock timestamp, `allowedFrom/allowedTo` whitelist (= insiders pre-authorized to move during lockup), config contract (often points to the whole system → auto-expands your address map).
**Then on-chain:**
1. **Mints** → the genesis treasury (not published). → `queries/01_mints.sql`
2. **First-hop distribution** from treasury → sub-treasuries / vesting / distributors. → `02_first_hop.sql`
3. **Expand the entity graph** (self-expanding): classify each big recipient, then **prune** — CEX/retail = tag & stop; Safe/contract/whitelisted/large-fresh-EOA = expand & monitor. Recurse (treasury→sub→vester→router→beneficiaries).
4. **Top holders + labels**; **Safe owner/threshold history** (version-robust decode). → `03_top_holders_labeled.sql`, `04_safe_owner_history.sql`
5. **Supply buckets** — how much sits in treasury / vesting / staking / MM / CEX / retail (can freeze point-in-time). → `05_supply_buckets.sql`

## Phase 2 — Manipulation / pump-dump detection
- **Price & volume** daily (DEX VWAP); **DEX venue/pool split**. → `06_price_volume_daily.sql`, `07_dex_venue_split.sql`
- **Wash-trading detector**: per-address two-sided buy≈sell, net≈0, huge trade count = fake volume (price marked up, not bid up). → `08_wash_trading.sql`
- **CEX genuine-deposit daily timeline** (exclude exchange-internal): a deposit spike at the price top = distribution into strength. → `09_cex_deposits_daily.sql`
- **Net-distributor leaderboard** in the window. → `10_net_distributors.sql`

## Phase 3 — Smart money vs dumb money
- **Insider→CEX offload, valued at deposit-time price** = estimated proceeds (their cost ≈ $0). → `11_insider_to_cex.sql`
- **DEX net buyers' balance & PnL** (bag holders); most "buyers" are arbs who offload — the real dumb money (CEX retail) is invisible.
- **DEX realized-PnL leaderboard** (sold-USD − bought-USD) = on-chain smart money; exclude wash bots (net≈0) and insiders. → `12_dex_realized_pnl.sql`

## Phase 4 — Alpha signals & monitoring
The repeatable TGE pump-dump archetype + the **S1–S8 signal chain** (S2 ammo-loading to fresh EOAs pre-unlock · S3 CEX staging · S4 MM-fleet activation · S5 wash volume · S6 CEX-deposit spike at the top · S8 unlock calendar), the **self-expanding monitoring model**, and the **market-maker tactics playbook** are written up in `wct-analyse/docs/阶段四：阿尔法启示/`. Reuse them; the alpha is in the *pre-dump prep* visible on-chain (S2/S3/S6).

## Point-in-time discipline (avoid hindsight)
To test "could I have judged this live?", cap **every** query with `WHERE block_time <= DATE '{{cutoff}}'` — no future data. Replay decision dates and only then advance the clock.

## Data sources (Dune; run via MCP)
`erc20_{{chain}}.evt_transfer` (raw transfers), `dex.trades` (price/vol/taker, has `amount_usd`), `cex.addresses` (exchange labels), `safe.safes_all` (is-it-a-Safe + version), `addresses.stats` (contract/EOA, first funder), `tokens.transfers` (multichain w/ USD). Safe owner events decode from `<chain>.logs` topic0s (note: 1.4.1 indexes owner in topic1, 1.3.0 in data — `coalesce` both).

## Deliverable
Phased markdown reports + a Dune query catalog. Use full addresses (never `0x…` abbreviations). Grade evidence ✅/🔶/⛔. State the CEX-black-box limit explicitly. Don't make legal "manipulation" claims — describe behavior + timing.

## Placeholders used in `queries/`
`{{token}}` = contract address, no quotes (e.g. `0xeF44…7945`) · `{{chain}}` = `optimism`/`ethereum`/`base`/… · `{{start}}`/`{{end}}`/`{{cutoff}}` = `DATE '2025-04-15'` etc. · `{{treasury}}`/`{{address}}` = a specific node you're expanding.
