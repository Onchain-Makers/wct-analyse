-- 1. 基础价格和交易量数据（按小时）
WITH hourly_data AS (
    SELECT 
        DATE_TRUNC('hour', block_time) as hour,
        AVG(price) as price,
        SUM(amount_raw / 1e18) as volume,
        COUNT(*) as trade_count
    FROM (
        SELECT 
            t.block_time,
            p.price,
            t.amount_raw
        FROM erc20.transfers t
        LEFT JOIN prices.hour p 
            ON p.timestamp = DATE_TRUNC('hour', t.block_time)
            AND p.contract_address = '0xef4461891dfb3ac8572ccf7c794664a8dd927945'
        WHERE t.contract_address = '0xef4461891dfb3ac8572ccf7c794664a8dd927945'
        AND t.block_time >= '2025-05-01'
        AND t.block_time <= '2025-06-15'
    ) combined
    GROUP BY 1
    ORDER BY 1
)
SELECT 
    hour,
    price,
    volume,
    trade_count,
    MIN(price) OVER () as min_price,
    MAX(price) OVER () as max_price,
    MIN(volume) OVER () as min_volume,
    MAX(volume) OVER () as max_volume
FROM hourly_data;

-- 2. 价格波动率分析（按天）
WITH daily_stats AS (
    SELECT 
        DATE_TRUNC('day', block_time) as day,
        AVG(price) as avg_price,
        STDDEV(price) as price_stddev,
        MIN(price) as min_price,
        MAX(price) as max_price,
        (MAX(price) - MIN(price)) / MIN(price) * 100 as daily_volatility
    FROM (
        SELECT 
            t.block_time,
            p.price
        FROM erc20.transfers t
        LEFT JOIN prices.day p 
            ON p.timestamp = DATE_TRUNC('day', t.block_time)
            AND p.contract_address = '0xef4461891dfb3ac8572ccf7c794664a8dd927945'
        WHERE t.contract_address = '0xef4461891dfb3ac8572ccf7c794664a8dd927945'
        AND t.block_time >= '2025-05-01'
        AND t.block_time <= '2025-06-15'
    ) combined
    GROUP BY 1
    ORDER BY 1
)
SELECT 
    day,
    avg_price,
    price_stddev,
    min_price,
    max_price,
    daily_volatility,
    AVG(daily_volatility) OVER (ORDER BY day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as weekly_volatility
FROM daily_stats;

-- 3. 交易量集中度分析
WITH trade_sizes AS (
    SELECT 
        DATE_TRUNC('day', block_time) as day,
        amount_raw / 1e18 as trade_size,
        NTILE(10) OVER (PARTITION BY DATE_TRUNC('day', block_time) ORDER BY amount_raw / 1e18) as size_decile
    FROM erc20.transfers
    WHERE contract_address = '0xef4461891dfb3ac8572ccf7c794664a8dd927945'
    AND block_time >= '2025-05-01'
    AND block_time <= '2025-06-15'
)
SELECT 
    day,
    size_decile,
    COUNT(*) as trade_count,
    SUM(trade_size) as total_volume,
    AVG(trade_size) as avg_trade_size
FROM trade_sizes
GROUP BY 1, 2
ORDER BY 1, 2;

-- 4. 价格与交易量相关性分析
WITH hourly_correlation AS (
    SELECT 
        DATE_TRUNC('hour', block_time) as hour,
        AVG(price) as price,
        SUM(amount_raw / 1e18) as volume,
        COUNT(*) as trade_count
    FROM (
        SELECT 
            t.block_time,
            p.price,
            t.amount_raw
        FROM erc20.transfers t
        LEFT JOIN prices.hour p 
            ON p.timestamp = DATE_TRUNC('hour', t.block_time)
            AND p.contract_address = '0xef4461891dfb3ac8572ccf7c794664a8dd927945'
        WHERE t.contract_address = '0xef4461891dfb3ac8572ccf7c794664a8dd927945'
        AND t.block_time >= '2025-05-01'
        AND t.block_time <= '2025-06-15'
    ) combined
    GROUP BY 1
)
SELECT 
    CORR(price, volume) as price_volume_correlation,
    CORR(price, trade_count) as price_trade_count_correlation,
    CORR(volume, trade_count) as volume_trade_count_correlation
FROM hourly_correlation;

-- 5. 价格变动与交易量关系
WITH price_changes AS (
    SELECT 
        DATE_TRUNC('hour', block_time) as hour,
        AVG(price) as price,
        SUM(amount_raw / 1e18) as volume,
        LAG(AVG(price)) OVER (ORDER BY DATE_TRUNC('hour', block_time)) as prev_price
    FROM (
        SELECT 
            t.block_time,
            p.price,
            t.amount_raw
        FROM erc20.transfers t
        LEFT JOIN prices.hour p 
            ON p.timestamp = DATE_TRUNC('hour', t.block_time)
            AND p.contract_address = '0xef4461891dfb3ac8572ccf7c794664a8dd927945'
        WHERE t.contract_address = '0xef4461891dfb3ac8572ccf7c794664a8dd927945'
        AND t.block_time >= '2025-05-01'
        AND t.block_time <= '2025-06-15'
    ) combined
    GROUP BY 1
)
SELECT 
    hour,
    price,
    volume,
    ((price - prev_price) / prev_price * 100) as price_change_percent,
    CASE 
        WHEN price > prev_price THEN 'up'
        WHEN price < prev_price THEN 'down'
        ELSE 'unchanged'
    END as price_direction
FROM price_changes
WHERE prev_price IS NOT NULL
ORDER BY 1; 