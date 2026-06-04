-- 01_mints — all mint events (from = 0x0) → reveals the genesis treasury & TGE.
-- Replace {{token}} {{chain}}. value/1e18 assumes 18 decimals; adjust if not.
SELECT evt_block_time, evt_block_number, evt_tx_hash,
       evt_tx_from AS tx_initiator,         -- EOA that triggered the mint
       "to"        AS minted_to,            -- recipient (the treasury, for the genesis mint)
       CAST(value AS double)/1e18 AS amount,
       value       AS amount_raw
FROM erc20_{{chain}}.evt_transfer
WHERE contract_address = {{token}}
  AND "from" = 0x0000000000000000000000000000000000000000
ORDER BY evt_block_time;
-- Note: many small post-TGE mints are usually cross-chain bridge mints (NTT etc.),
-- not new issuance. The big day-0 mint to a single address = the master treasury.
