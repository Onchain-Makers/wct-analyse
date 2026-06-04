-- 08_wash_trading — per-address two-sided activity. Wash bot = bought ~= sold, net ~ 0,
-- but huge trade count & gross USD. That "volume" is manufactured, not real demand.
WITH t AS (
    SELECT tx_from AS addr,
        CASE WHEN token_bought_address={{token}} THEN token_bought_amount ELSE 0 END AS bought,
        CASE WHEN token_sold_address  ={{token}} THEN token_sold_amount  ELSE 0 END AS sold,
        amount_usd
    FROM dex.trades
    WHERE blockchain='{{chain}}' AND block_date BETWEEN DATE '{{start}}' AND DATE '{{end}}'
      AND (token_bought_address={{token}} OR token_sold_address={{token}})
)
SELECT addr,
       round(sum(bought)) AS tok_bought,
       round(sum(sold))   AS tok_sold,
       round(sum(bought)-sum(sold)) AS net_tok,   -- ~0 for wash bots
       count(*) AS total_trades,
       round(sum(amount_usd)) AS gross_usd
FROM t GROUP BY 1
ORDER BY total_trades DESC LIMIT 40;
