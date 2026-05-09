-- WCT contract first 100 events since deployment
-- DuneSQL / OP Mainnet
--
-- WCT / L2WCT token contract:
-- 0xeF4461891DfB3AC8572cCf7C794664A8DD927945

WITH wct_logs AS (
    SELECT
        block_time,
        block_number,
        tx_hash,
        tx_index,
        "index" AS log_index,
        contract_address,
        topic0,
        topic1,
        topic2,
        topic3,
        data
    FROM optimism.logs
    WHERE contract_address = 0xeF4461891DfB3AC8572cCf7C794664A8DD927945
)

SELECT
    row_number() OVER (
        ORDER BY block_number, tx_index, log_index
    ) AS event_no,
    block_time,
    block_number,
    tx_hash,
    tx_index,
    log_index,
    contract_address,
    CASE topic0
        WHEN 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef THEN 'Transfer(address,address,uint256)'
        WHEN 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925 THEN 'Approval(address,address,uint256)'
        WHEN 0x2f87881188ca7a4a72b2a8188d7697d59d5677dc09db49b18dcf826e7f468f44 THEN 'RoleGranted(bytes32,address,address)'
        WHEN 0xf6391f5c32d9c69d2a47ae817d48050a0a36612247951de9ea16e5396bb36d79 THEN 'RoleRevoked(bytes32,address,address)'
        WHEN 0xbd79b86ffe0ab8e877615151421ca5218b6f014a954e44bc90e0a93b1d888144 THEN 'RoleAdminChanged(bytes32,bytes32,bytes32)'
        WHEN 0x1cf3b03a6cf19fa2bdb5c60e2f229cb55d0a8cba27f819f48021006f7aeade0e THEN 'EIP712DomainChanged()'
        ELSE 'unknown'
    END AS event_signature,
    topic0,
    topic1,
    topic2,
    topic3,
    data
FROM wct_logs
ORDER BY block_number, tx_index, log_index
LIMIT 100;
