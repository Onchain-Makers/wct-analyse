-- 02_first_hop — outflows from a treasury/node, grouped by recipient.
-- Use to fan out the entity graph one hop. Set {{treasury}} = the node you expand.
SELECT "to" AS recipient,
       count(*) AS n_transfers,
       sum(CAST(value AS double)/1e18) AS total_amount,
       min(evt_block_time) AS first_sent,
       max(evt_block_time) AS last_sent
FROM erc20_{{chain}}.evt_transfer
WHERE contract_address = {{token}}
  AND "from" = {{treasury}}
GROUP BY 1
ORDER BY total_amount DESC;
-- Then classify each recipient (next: 03/04) and decide expand vs stop:
-- contract/Safe/whitelisted/large-fresh-EOA = expand; CEX/retail = tag & stop.
