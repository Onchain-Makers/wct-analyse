-- 07_dex_venue_split — which DEX project/pair carries the volume (find the main battlefield pool).
SELECT project,
       CASE WHEN token_bought_address={{token}} THEN token_sold_symbol ELSE token_bought_symbol END AS paired_with,
       count(*) AS trades,
       round(sum(amount_usd)) AS volume_usd
FROM dex.trades
WHERE blockchain='{{chain}}' AND block_date BETWEEN DATE '{{start}}' AND DATE '{{end}}'
  AND (token_bought_address={{token}} OR token_sold_address={{token}})
GROUP BY 1,2 ORDER BY volume_usd DESC;
