-- 06_price_volume_daily — daily DEX VWAP price + volume. The basic "what did the chart do".
WITH t AS (
    SELECT block_date, amount_usd,
        CASE WHEN token_bought_address={{token}} THEN token_bought_amount
             WHEN token_sold_address  ={{token}} THEN token_sold_amount END AS tok_amt
    FROM dex.trades
    WHERE blockchain='{{chain}}' AND block_date >= DATE '{{start}}'
      AND (token_bought_address={{token}} OR token_sold_address={{token}})
)
SELECT block_date,
       count(*) AS trades,
       round(sum(amount_usd)) AS volume_usd,
       round(sum(amount_usd)/NULLIF(sum(tok_amt),0), 6) AS vwap_price_usd
FROM t WHERE tok_amt > 0
GROUP BY 1 ORDER BY 1;
-- NOTE: most volume for a CEX-listed token is OFF-CHAIN; DEX is only part of the picture.
