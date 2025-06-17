"""
配置文件，存储 API keys 和其他配置信息
"""
from dotenv import load_dotenv
import os

# 加载环境变量
load_dotenv()

# Dune API 配置
DUNE_API_KEY = "NfhAJH0Y2al7DZACKw3adrTtyXI1o8Qx"

# 分析时间范围
START_DATE = "2025-05-25"
END_DATE = "2025-06-30"

# WCT 代币合约地址（需要补充）
WCT_CONTRACT_ADDRESS = "0xef4461891dfb3ac8572ccf7c794664a8dd927945"  # TODO: 需要补充实际的合约地址 