#!/usr/bin/env node
// driver.mjs — reproducibility driver for the WCT-analyse research repo.
//
// This repo has NO runnable app. It is an on-chain forensic investigation of
// the WCT token, delivered as markdown reports under docs/. Every finding is
// backed by a Dune SQL query (the "wct2026" series, saved in the user's Dune
// account). "Running" this project = reproducing/extending that analysis.
//
// This driver indexes the analysis so a future agent can reproduce it:
//   1. catalogs every Dune query ID referenced in the docs (+ which docs use it)
//   2. catalogs every on-chain address (the entity graph) with a context label
//   3. verifies the four phase docs exist
//   4. prints a reproducibility report
//
// Pure Node stdlib: no deps, no network, no DUNE_API_KEY required.
//
// Usage:
//   node .claude/skills/run-wct-analyse/driver.mjs            # human report
//   node .claude/skills/run-wct-analyse/driver.mjs --queries  # query IDs only (one per line)
//   node .claude/skills/run-wct-analyse/driver.mjs --addresses# addresses only
//   node .claude/skills/run-wct-analyse/driver.mjs --json     # machine-readable
//
// To RE-RUN the queries live you need a Dune account: open
// https://dune.com/queries/<id> for any listed id, or use dune-client with a
// DUNE_API_KEY (see requirements.txt). This driver does NOT call Dune.

import { readdirSync, readFileSync, statSync, existsSync } from "node:fs";
import { join, dirname, relative } from "node:path";
import { fileURLToPath } from "node:url";

// repo root = two levels up from .claude/skills/run-wct-analyse/
const REPO = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "..");
const DOCS = join(REPO, "docs");

function walk(dir) {
  const out = [];
  for (const e of readdirSync(dir, { withFileTypes: true })) {
    const p = join(dir, e.name);
    if (e.isDirectory()) out.push(...walk(p));
    else if (e.name.endsWith(".md")) out.push(p);
  }
  return out;
}

if (!existsSync(DOCS)) {
  console.error(`FAIL: docs/ not found at ${DOCS} — run from the WCT-analyse repo.`);
  process.exit(1);
}

const mdFiles = walk(DOCS).sort();
const rel = (p) => relative(REPO, p).replace(/\\/g, "/");

// --- 1. Dune query catalog -------------------------------------------------
// Authoritative form in docs: dune.com/queries/<id>. Also catch bare 7xxxxxx
// ids that appear near the word "query" (docs list some as "7633684/7633690").
const queries = new Map(); // id -> Set(docRel)
for (const f of mdFiles) {
  const txt = readFileSync(f, "utf8");
  for (const m of txt.matchAll(/dune\.com\/queries\/(\d+)/g)) add(queries, m[1], rel(f));
  for (const m of txt.matchAll(/quer(?:y|ies)[^\n]{0,40}?\b(7\d{6})\b/gi)) add(queries, m[1], rel(f));
}

// --- 2. Address / entity catalog ------------------------------------------
const addrs = new Map(); // addr(lower) -> {count, label, docs:Set}
for (const f of mdFiles) {
  for (const line of readFileSync(f, "utf8").split(/\r?\n/)) {
    for (const m of line.matchAll(/0x[0-9a-fA-F]{40}/g)) {
      const a = m[0].toLowerCase();
      const e = addrs.get(a) || { count: 0, label: "", docs: new Set() };
      e.count++; e.docs.add(rel(f));
      if (!e.label) { const lab = guessLabel(line, m[0]); if (lab) e.label = lab; }
      addrs.set(a, e);
    }
  }
}

// --- 3. Phase docs present? -----------------------------------------------
const phases = ["阶段一", "阶段二", "阶段三", "阶段四"];
const phaseStatus = phases.map((p) => ({
  phase: p,
  present: mdFiles.some((f) => rel(f).includes(`docs/${p}`)),
}));

function add(map, k, v) { (map.get(k) || map.set(k, new Set()).get(k)).add(v); }
function guessLabel(line, addr) {
  // grab a short bit of context after the address (table cell or "= xxx")
  const after = line.slice(line.indexOf(addr) + addr.length)
    .replace(/^[`\s|)=:：，,。.]+/, "").replace(/[|`].*$/, "").trim();
  return after.slice(0, 48);
}

const data = {
  queries: [...queries.entries()].map(([id, docs]) => ({ id, urls: `https://dune.com/queries/${id}`, docs: [...docs] }))
    .sort((a, b) => Number(a.id) - Number(b.id)),
  addresses: [...addrs.entries()].map(([a, e]) => ({ address: a, mentions: e.count, label: e.label, docs: [...e.docs] }))
    .sort((a, b) => b.mentions - a.mentions),
  phases: phaseStatus,
  docCount: mdFiles.length,
};

const arg = process.argv[2];
if (arg === "--json") { console.log(JSON.stringify(data, null, 2)); process.exit(0); }
if (arg === "--queries") { for (const q of data.queries) console.log(q.urls); process.exit(0); }
if (arg === "--addresses") { for (const a of data.addresses) console.log(`${a.address}  x${a.mentions}  ${a.label}`); process.exit(0); }

// --- human report ----------------------------------------------------------
const allPhases = data.phases.every((p) => p.present);
console.log("WCT-analyse — on-chain forensic investigation (no runnable app; reproduce via Dune)");
console.log("=".repeat(78));
console.log(`docs markdown files : ${data.docCount}`);
console.log(`phase docs present  : ${data.phases.map((p) => `${p.phase}${p.present ? "✓" : "✗"}`).join("  ")}`);
console.log(`dune queries cited  : ${data.queries.length}   (the analysis backbone)`);
console.log(`addresses cataloged : ${data.addresses.length}   (the on-chain entity graph)`);
console.log("");
console.log("Top entities by mentions (address  xN  label):");
for (const a of data.addresses.slice(0, 12)) console.log(`  ${a.address}  x${a.mentions}  ${a.label}`);
console.log("");
console.log("Dune query catalog (open any to inspect/re-run the SQL):");
for (const q of data.queries) console.log(`  ${q.urls}`);
console.log("");
console.log("Reproduce: open the query URLs above, or use dune-client with a DUNE_API_KEY");
console.log("(requirements.txt). This driver does not call Dune — it only indexes the repo.");
console.log("=".repeat(78));
console.log(allPhases ? "OK: all four phase docs present." : "WARN: a phase doc is missing.");
process.exit(allPhases ? 0 : 1);
