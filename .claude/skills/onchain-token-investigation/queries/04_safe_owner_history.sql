-- 04_safe_owner_history — reconstruct a Gnosis Safe's owners & threshold over time.
-- Version-robust: Safe 1.4.1 indexes the owner in topic1; 1.3.0 puts it in data -> coalesce both.
-- Apply the events in order to get the CURRENT owner set & threshold. Set {{address}} = the Safe.
SELECT block_time, tx_hash, index AS log_index,
    CASE topic0
        WHEN 0x141df868a6331af528e38c83b7aa03edc19be66e37ae67f9285bf4f8e3c6a1a8 THEN 'SafeSetup'
        WHEN 0x9465fa0c962cc76958e6373a993326400c1c94f8be2fe3a952adfa7f60b2ea26 THEN 'AddedOwner'
        WHEN 0xf8d49fc529812e9a7c5c50e69c20f0dccc0db8fa95c98bc58cc9a4f1c1299eaf THEN 'RemovedOwner'
        WHEN 0x610f7ff2b304ae8903c3de74c60c6ab1f7d6226b3f52c5161905bb5ad4039c93 THEN 'ChangedThreshold'
    END AS event,
    CASE WHEN topic0 IN (0x9465fa0c962cc76958e6373a993326400c1c94f8be2fe3a952adfa7f60b2ea26,
                         0xf8d49fc529812e9a7c5c50e69c20f0dccc0db8fa95c98bc58cc9a4f1c1299eaf)
         THEN coalesce(bytearray_substring(topic1,13,20), bytearray_substring(data,13,20)) END AS owner_changed,
    CASE WHEN topic0 = 0x610f7ff2b304ae8903c3de74c60c6ab1f7d6226b3f52c5161905bb5ad4039c93
         THEN bytearray_to_uint256(data) END AS new_threshold,
    CASE WHEN topic0 = 0x141df868a6331af528e38c83b7aa03edc19be66e37ae67f9285bf4f8e3c6a1a8
         THEN bytearray_to_uint256(bytearray_substring(data,33,32)) END AS setup_threshold,
    CASE WHEN topic0 = 0x141df868a6331af528e38c83b7aa03edc19be66e37ae67f9285bf4f8e3c6a1a8
         THEN bytearray_to_uint256(bytearray_substring(data,129,32)) END AS setup_owner_count
FROM {{chain}}.logs
WHERE contract_address = {{address}}
  AND topic0 IN (0x141df868a6331af528e38c83b7aa03edc19be66e37ae67f9285bf4f8e3c6a1a8,
                 0x9465fa0c962cc76958e6373a993326400c1c94f8be2fe3a952adfa7f60b2ea26,
                 0xf8d49fc529812e9a7c5c50e69c20f0dccc0db8fa95c98bc58cc9a4f1c1299eaf,
                 0x610f7ff2b304ae8903c3de74c60c6ab1f7d6226b3f52c5161905bb5ad4039c93)
ORDER BY block_number, index;
-- Cross-check the reconstructed current set against Etherscan getOwners()/getThreshold()
-- or Safe UI (app.safe.global/settings/setup?safe=<chainPrefix>:<address>).
