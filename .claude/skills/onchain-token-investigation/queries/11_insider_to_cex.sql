-- 11_insider_to_cex — estimate proceeds: monthly NET token into CEX valued at that month's price.
-- For insiders the cost basis ~ $0, so this approximates $ raised. FLOOR estimate: tokens staged
-- cheap and sold higher later show up at the staging price (the actual CEX sale price is invisible).
WITH cexset AS (SELECT address FROM cex.addresses WHERE blockchain='{{chain}}'),
px AS (
    SELECT date_trunc('month', block_date) AS m,
           sum(amount_usd)/NULLIF(sum(CASE WHEN token_bought_address={{token}} THEN token_bought_amount
                                           WHEN token_sold_address={{token}}  THEN token_sold_amount END),0) AS price
    FROM dex.trades WHERE blockchain='{{chain}}' AND block_date >= DATE '{{start}}'
      AND (token_bought_address={{token}} OR token_sold_address={{token}}) GROUP BY 1
),
mv AS (
    SELECT date_trunc('month', t.evt_block_time) AS m, CAST(t.value AS double)/1e18 AS amt,
           (t."to"   IN (SELECT address FROM cexset)) AS to_cex,
           (t."from" IN (SELECT address FROM cexset)) AS from_cex
    FROM erc20_{{chain}}.evt_transfer t
    WHERE t.contract_address={{token}} AND t.evt_block_date >= DATE '{{start}}'
),
flow AS (SELECT m, sum(CASE WHEN to_cex AND NOT from_cex THEN amt
                            WHEN from_cex AND NOT to_cex THEN -amt ELSE 0 END) AS net_into_cex
         FROM mv GROUP BY 1)
SELECT f.m AS month, round(f.net_into_cex) AS net_into_cex, round(px.price,4) AS avg_price,
       round(f.net_into_cex*px.price) AS est_usd,
       round(sum(f.net_into_cex) OVER (ORDER BY f.m)) AS cumulative_net
FROM flow f JOIN px ON px.m=f.m ORDER BY f.m;
-- To attribute to specific insiders, restrict the transfer source to your insider IN-list.
