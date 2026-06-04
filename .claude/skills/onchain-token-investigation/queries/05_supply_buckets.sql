-- 05_supply_buckets — how much supply sits in each category. POINT-IN-TIME capable:
-- keep the evt_block_date <= {{cutoff}} filters for an as-of snapshot; drop them for "now".
-- Fill the IN-lists with the addresses YOU found (treasury/vesting/staking/MM/known-EOAs).
WITH flows AS (
    SELECT "to" AS addr, CAST(value AS double)/1e18 AS amt
    FROM erc20_{{chain}}.evt_transfer
    WHERE contract_address={{token}} AND evt_block_date <= DATE '{{cutoff}}'
    UNION ALL
    SELECT "from", -CAST(value AS double)/1e18
    FROM erc20_{{chain}}.evt_transfer
    WHERE contract_address={{token}} AND evt_block_date <= DATE '{{cutoff}}'
),
bal AS (
    SELECT addr, sum(amt) AS b FROM flows
    WHERE addr <> 0x0000000000000000000000000000000000000000
    GROUP BY 1 HAVING sum(amt) > 0.5
)
SELECT
    CASE
        WHEN b.addr IN ( /* treasury Safes */ )      THEN '1 treasury'
        WHEN b.addr IN ( /* vesting contracts */ )   THEN '2 vesting (locked)'
        WHEN b.addr IN ( /* staking contracts */ )   THEN '3 staking'
        WHEN b.addr IN ( /* MM cluster */ )          THEN '4 market maker'
        WHEN b.addr IN ( /* known allocation EOAs */ ) THEN '5 allocation EOA'
        WHEN c.address IS NOT NULL                    THEN '6 on CEX'
        WHEN s.is_smart_contract                      THEN '7 other contract'
        ELSE '8 retail EOA'
    END AS bucket,
    count(*) AS n_addr,
    round(sum(b.b)) AS amount
FROM bal b
LEFT JOIN cex.addresses  c ON c.blockchain='{{chain}}' AND c.address=b.addr
LEFT JOIN addresses.stats s ON s.blockchain='{{chain}}' AND s.address=b.addr
GROUP BY 1 ORDER BY 1;
-- "overhang" = supply still in treasury/MM/allocation hands NOT yet on CEX = future sell pressure.
