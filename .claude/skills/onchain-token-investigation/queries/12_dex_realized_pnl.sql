-- 12_dex_realized_pnl — on-chain "smart money": DEX realized PnL = sold USD - bought USD.
-- Require they actually BOUGHT (filters out insiders dumping free allocations) and netted a profit.
-- Wash bots (sold ~= bought) net ~0 and fall off. NOTE: only captures pure-DEX traders;
-- arbs who buy DEX and sell on CEX, and all CEX-only traders, are invisible.
WITH dex AS (
    SELECT tx_from AS addr,
        sum(CASE WHEN token_bought_address={{token}} THEN amount_usd ELSE 0 END) AS usd_spent,
        sum(CASE WHEN token_sold_address  ={{token}} THEN amount_usd ELSE 0 END) AS usd_recv,
        count(*) AS trades, min(block_time) AS first_t, max(block_time) AS last_t
    FROM dex.trades
    WHERE blockchain='{{chain}}' AND block_date >= DATE '{{start}}'
      AND (token_bought_address={{token}} OR token_sold_address={{token}})
    GROUP BY 1
)
SELECT addr, round(usd_spent) AS usd_bought, round(usd_recv) AS usd_sold,
       round(usd_recv - usd_spent) AS realized_pnl, trades, first_t, last_t
FROM dex
WHERE usd_spent > 20000 AND (usd_recv - usd_spent) > 20000
ORDER BY realized_pnl DESC LIMIT 40;
