-- 09_cex_deposits_daily — daily GENUINE deposits into CEX (excludes exchange-internal transfers).
-- The strongest on-chain distribution signal: a deposit spike AT the price top = selling into strength.
WITH dep AS (
    SELECT t.evt_block_date AS d, CAST(t.value AS double)/1e18 AS amt, t."from" AS src
    FROM erc20_{{chain}}.evt_transfer t
    JOIN cex.addresses c ON c.blockchain='{{chain}}' AND c.address = t."to"
    WHERE t.contract_address={{token}} AND t.evt_block_date BETWEEN DATE '{{start}}' AND DATE '{{end}}'
)
SELECT d.d AS day,
       round(sum(CASE WHEN c2.address IS NULL     THEN d.amt ELSE 0 END)) AS genuine_deposits,
       round(sum(CASE WHEN c2.address IS NOT NULL THEN d.amt ELSE 0 END)) AS cex_internal,
       count(*) AS n
FROM dep d
LEFT JOIN cex.addresses c2 ON c2.blockchain='{{chain}}' AND c2.address = d.src
GROUP BY 1 ORDER BY 1;
-- For NET flow (deposits - withdrawals, removes cycling/MM churn), also subtract
-- transfers FROM cex addresses; gross deposits over-count re-deposited tokens.
