-- 10_net_distributors — who NET-distributed (sent more than received) in a window.
-- Wash bots net ~0 and fall off; what's left are the real sellers/distributors.
WITH flows AS (
    SELECT "to" AS addr, CAST(value AS double)/1e18 AS amt
    FROM erc20_{{chain}}.evt_transfer
    WHERE contract_address={{token}} AND evt_block_date BETWEEN DATE '{{start}}' AND DATE '{{end}}'
    UNION ALL
    SELECT "from", -CAST(value AS double)/1e18
    FROM erc20_{{chain}}.evt_transfer
    WHERE contract_address={{token}} AND evt_block_date BETWEEN DATE '{{start}}' AND DATE '{{end}}'
),
net AS (SELECT addr, sum(amt) AS net_change FROM flows
        WHERE addr <> 0x0000000000000000000000000000000000000000 GROUP BY 1)
SELECT n.addr, round(-n.net_change) AS net_out,
       c.cex_name, s.is_smart_contract, s.is_eoa, sf.creation_version AS safe_version
FROM net n
LEFT JOIN cex.addresses  c  ON c.blockchain='{{chain}}'  AND c.address=n.addr
LEFT JOIN addresses.stats s ON s.blockchain='{{chain}}'  AND s.address=n.addr
LEFT JOIN safe.safes_all sf ON sf.blockchain='{{chain}}' AND sf.address=n.addr
WHERE n.net_change < -50000
ORDER BY net_out DESC LIMIT 40;
