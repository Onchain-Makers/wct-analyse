---
name: run-wct-analyse
description: Run, reproduce, or index the WCT-analyse on-chain investigation. Use when asked to "run wct-analyse", reproduce the WCT analysis, list the Dune queries / addresses behind the findings, verify the report set, or continue the WCT investigation. This repo has NO app — the driver indexes the analysis (Dune query catalog + address entity graph) so it can be reproduced/extended.
---

# Run WCT-analyse

**This repo is not an application — it is an on-chain forensic investigation.**
The deliverable is the markdown reports under `docs/` (four phases: 金库分发 →
5月拉高出货 → 聪明钱vs笨蛋钱 → 阿尔法启示). Every finding is backed by a Dune SQL
query (the `wct2026` series, saved in the user's Dune account, `minner_qi/wct2026`).
There is no server/GUI/CLI to launch; **"running" this project means reproducing
or extending that analysis.**

The driver (`.claude/skills/run-wct-analyse/driver.mjs`, pure Node stdlib — no
deps, no network, no API key) indexes the repo: it extracts the Dune query
catalog and the on-chain address/entity graph that back the reports, and
verifies the four phase docs exist. That index is what a future agent needs to
reproduce or build on the investigation.

Paths below are relative to the repo root (`<unit>/`).

## Prerequisites
- Node ≥ 18 (verified on `v22.14.0`). Nothing else — the driver is stdlib-only.

```bash
node --version   # v22.14.0 here
```

## Run (agent path) — index the analysis
```bash
node .claude/skills/run-wct-analyse/driver.mjs
```
Prints: doc count, per-phase presence (阶段一/二/三/四 ✓), the **53 Dune queries**
cited, the **185 addresses** cataloged (top entities with a context label), and a
reproduce hint. Exits 0 if all four phase docs are present, 1 otherwise.

Machine / focused modes (all verified):
```bash
node .claude/skills/run-wct-analyse/driver.mjs --queries    # query URLs, one per line (53)
node .claude/skills/run-wct-analyse/driver.mjs --addresses  # "address  xN  label"
node .claude/skills/run-wct-analyse/driver.mjs --json        # full catalog as JSON
```

## Reproduce / re-run the analysis live (NOT run in this container — needs a Dune account)
The driver does **not** call Dune. To reproduce a finding's numbers:
- Open any URL from `--queries` (e.g. `https://dune.com/queries/7626680`) to read/run its SQL on dune.com, **or**
- Use `dune-client` (in `requirements.txt`) with a `DUNE_API_KEY` to execute the query IDs programmatically.

This session had no `DUNE_API_KEY` (the original analysis was done via the Dune
**MCP**, not the HTTP API), so the live-rerun path above is documented, not verified here.

## Continue the investigation
State, the agreed plan, and the exact resume point (currently a "time-machine
replay" frozen at 2025-04-22) live in the project memory at
`~/.claude/projects/d--qifumin-WCT-analyse/memory/` — read `MEMORY.md` first.
New work = new Dune queries (keep the `wct2026` prefix) + edits to the `docs/`
reports. Push needs `dangerouslyDisableSandbox` (sandbox blocks DNS).

## Gotchas
- **No app to launch / screenshot.** If you came expecting a server or GUI, there
  isn't one. The "run" surface is the index driver above.
- **The Dune queries live in the user's account, not in this repo.** The repo cites
  query *IDs/URLs*; the SQL bodies are on dune.com (`minner_qi/wct2026` folder).
  The driver catalogs the IDs; it cannot show the SQL.
- **Keep Dune queries cheap.** The user's Dune account was once banned by a heavy
  unfiltered scan of `optimism.logs`. Always filter on partition columns
  (`block_date`/`contract_address`) and prefer spell tables
  (`erc20_optimism.evt_transfer`, `dex.trades`). See the cost-discipline memory.
- **CEX is a black box** throughout the analysis — on-chain shows deposits, not
  order-book fills. That's a data limitation of the investigation, not a bug in
  the driver; findings labeled ⛔/🔶 reflect it.
- **`--addresses` labels are best-effort** context snippets scraped from the line
  after each address (sometimes narrative text, not a clean tag).
- **Phase dirs are non-ASCII** (`docs/阶段一：…`); the driver walks them fine via
  Node fs (UTF-8).

## Troubleshooting
- The commands above use a path relative to the repo root, so run them from inside
  `WCT-analyse/`. The driver itself anchors to its own location (repo = two levels
  up from the script), so an absolute path works from any cwd too.
- `FAIL: docs/ not found …` → only happens if `driver.mjs` was copied out of the
  repo (detached from `docs/`). Keep it under `.claude/skills/run-wct-analyse/`.
