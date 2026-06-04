-- 03_top_holders_labeled — current net balances + labels (CEX / Safe / EOA-or-contract / first funder).
-- Reveals whales and what they are. Net balance = inflows - outflows (mint counts as inflow).
WITH flows AS (
    SELECT "to" AS addr,  CAST(value AS double)/1e18 AS amt
    FROM erc20_{{chain}}.evt_transfer WHERE contract_address = {{token}}
    UNION ALL
    SELECT "from", -CAST(value AS double)/1e18
    FROM erc20_{{chain}}.evt_transfer WHERE contract_address = {{token}}
),
bal AS (
    SELECT addr, sum(amt) AS balance FROM flows
    WHERE addr <> 0x0000000000000000000000000000000000000000
    GROUP BY 1 HAVING sum(amt) > 1
    ORDER BY balance DESC LIMIT 50
)
SELECT b.addr, b.balance,
       c.cex_name, c.distinct_name AS cex_wallet,
       s.is_smart_contract, s.is_eoa, s.first_funded_by,
       sf.creation_version AS safe_version
FROM bal b
LEFT JOIN cex.addresses  c  ON c.blockchain='{{chain}}'  AND c.address  = b.addr
LEFT JOIN addresses.stats s ON s.blockchain='{{chain}}'  AND s.address  = b.addr
LEFT JOIN safe.safes_all sf ON sf.blockchain='{{chain}}' AND sf.address = b.addr
ORDER BY b.balance DESC;
