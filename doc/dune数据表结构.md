table: tokens.erc20
schema:
| name | type |
| --- | --- |
| blockchain | varchar |
| contract_address | varbinary |
| symbol | varchar |
| name | varchar |
| decimals | integer |


table: prices.day
schema:
| name | type |
| --- | --- |
| blockchain | varchar |
| contract_address | varbinary |
| symbol | varchar |
| timestamp | timestamp(3) with time zone |
| price | double |
| decimals | integer |
| volume | double |
| source | varchar |
| source_timestamp | timestamp(3) with time zone |

table: prices.hour
schema:
| name | type |
| --- | --- |
| blockchain | varchar |
| contract_address | varbinary |
| symbol | varchar |
| timestamp | timestamp(3) with time zone |
| price | double |
| decimals | integer |
| volume | double |
| source | varchar |
| source_timestamp | timestamp(3) with time zone |

table: prices.minute
schema:
| name | type |
| --- | --- |
| blockchain | varchar |
| contract_address | varbinary |
| symbol | varchar |
| timestamp | timestamp(3) with time zone |
| price | double |
| decimals | integer |
| volume | double |
| source | varchar |
| source_timestamp | timestamp(3) with time zone |

table: prices.latest
schema:
| name | type |
| --- | --- |
| blockchain | varchar |
| contract_address | varbinary |
| symbol | varchar |
| price | double |
| decimals | integer |
| timestamp | timestamp(3) with time zone |
| volume | double |
| source | varchar |

table: prices.tokens
schema:
| name | type |
| --- | --- |
| token_id | string |
| blockchain | string |
| symbol | string |
| contract_address | binary |
| decimals | integer |

