"""
WCT 代币分析脚本
分析 2025 年 5 月底到 6 月期间的暴涨回落事件
"""
from dune_client.client import DuneClient
from dune_client.types import QueryParameter
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime
from config import DUNE_API_KEY, START_DATE, END_DATE, WCT_CONTRACT_ADDRESS

class WCTAnalyzer:
    def __init__(self):
        self.client = DuneClient(DUNE_API_KEY)
        self.contract_address = WCT_CONTRACT_ADDRESS.lower()
        
    def get_price_volume_data(self):
        """
        获取价格和交易量数据
        """
        query = f"""
        WITH price_data AS (
            SELECT 
                DATE_TRUNC('hour', block_time) as hour,
                AVG(CAST(value AS DOUBLE) / 1e18) as price,
                SUM(CAST(value AS DOUBLE) / 1e18) as volume
            FROM ethereum.traces
            WHERE contract_address = '{self.contract_address}'
            AND block_time >= '{START_DATE}'
            AND block_time <= '{END_DATE}'
            GROUP BY 1
            ORDER BY 1
        )
        SELECT 
            hour,
            price,
            volume,
            MIN(price) OVER () as min_price,
            MAX(price) OVER () as max_price,
            MIN(volume) OVER () as min_volume,
            MAX(volume) OVER () as max_volume
        FROM price_data
        """
        
        # 创建查询参数
        query_params = [
            QueryParameter("contract_address", self.contract_address),
            QueryParameter("start_date", START_DATE),
            QueryParameter("end_date", END_DATE)
        ]
        
        # 执行查询
        result = self.client.refresh(query, query_params)
        return pd.DataFrame(result)
    
    def get_holder_stats(self):
        """
        获取持有者统计信息
        """
        query = f"""
        WITH holder_stats AS (
            SELECT 
                "from" as address,
                -CAST(value AS DOUBLE) / 1e18 as amount
            FROM ethereum.traces
            WHERE contract_address = '{self.contract_address}'
            AND block_time >= '{START_DATE}'
            AND block_time <= '{END_DATE}'
            
            UNION ALL
            
            SELECT 
                "to" as address,
                CAST(value AS DOUBLE) / 1e18 as amount
            FROM ethereum.traces
            WHERE contract_address = '{self.contract_address}'
            AND block_time >= '{START_DATE}'
            AND block_time <= '{END_DATE}'
        )
        SELECT 
            address,
            SUM(amount) as balance,
            COUNT(*) as transaction_count
        FROM holder_stats
        GROUP BY address
        HAVING SUM(amount) > 0
        ORDER BY balance DESC
        """
        
        # 创建查询参数
        query_params = [
            QueryParameter("contract_address", self.contract_address),
            QueryParameter("start_date", START_DATE),
            QueryParameter("end_date", END_DATE)
        ]
        
        # 执行查询
        result = self.client.refresh(query, query_params)
        return pd.DataFrame(result)
    
    def find_top_profitable_addresses(self):
        """
        找出最大获益地址
        """
        query = f"""
        WITH trades AS (
            SELECT 
                "from" as address,
                -CAST(value AS DOUBLE) / 1e18 as amount,
                block_time,
                block_number
            FROM ethereum.traces
            WHERE contract_address = '{self.contract_address}'
            AND block_time >= '{START_DATE}'
            AND block_time <= '{END_DATE}'
            
            UNION ALL
            
            SELECT 
                "to" as address,
                CAST(value AS DOUBLE) / 1e18 as amount,
                block_time,
                block_number
            FROM ethereum.traces
            WHERE contract_address = '{self.contract_address}'
            AND block_time >= '{START_DATE}'
            AND block_time <= '{END_DATE}'
        ),
        profit_calc AS (
            SELECT 
                address,
                SUM(amount) as net_profit,
                COUNT(*) as trade_count,
                MIN(block_time) as first_trade,
                MAX(block_time) as last_trade
            FROM trades
            GROUP BY address
            HAVING SUM(amount) > 0
        )
        SELECT 
            address,
            net_profit,
            trade_count,
            first_trade,
            last_trade
        FROM profit_calc
        ORDER BY net_profit DESC
        LIMIT 20
        """
        
        # 创建查询参数
        query_params = [
            QueryParameter("contract_address", self.contract_address),
            QueryParameter("start_date", START_DATE),
            QueryParameter("end_date", END_DATE)
        ]
        
        # 执行查询
        result = self.client.refresh(query, query_params)
        return pd.DataFrame(result)
    
    def plot_price_volume(self, data):
        """
        绘制价格和交易量图表
        """
        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(15, 10))
        
        # 价格图表
        ax1.plot(data['hour'], data['price'], label='Price')
        ax1.set_title('WCT Price Over Time')
        ax1.set_xlabel('Time')
        ax1.set_ylabel('Price')
        ax1.grid(True)
        
        # 交易量图表
        ax2.bar(data['hour'], data['volume'], label='Volume')
        ax2.set_title('WCT Trading Volume Over Time')
        ax2.set_xlabel('Time')
        ax2.set_ylabel('Volume')
        ax2.grid(True)
        
        plt.tight_layout()
        plt.savefig('wct_price_volume.png')
        plt.close()
    
    def analyze(self):
        """
        运行完整分析
        """
        print("开始分析 WCT 代币数据...")
        
        # 1. 获取价格和交易量数据
        print("获取价格和交易量数据...")
        price_volume_data = self.get_price_volume_data()
        self.plot_price_volume(price_volume_data)
        
        # 2. 获取持有者统计
        print("获取持有者统计信息...")
        holder_stats = self.get_holder_stats()
        
        # 3. 找出最大获益地址
        print("分析最大获益地址...")
        top_addresses = self.find_top_profitable_addresses()
        
        # 输出分析结果
        print("\n分析结果摘要:")
        print(f"最低价格: {price_volume_data['min_price'].iloc[0]:.8f}")
        print(f"最高价格: {price_volume_data['max_price'].iloc[0]:.8f}")
        print(f"最小交易量: {price_volume_data['min_volume'].iloc[0]:.2f}")
        print(f"最大交易量: {price_volume_data['max_volume'].iloc[0]:.2f}")
        print(f"持有者数量: {len(holder_stats)}")
        print("\n前5个最大获益地址:")
        print(top_addresses.head().to_string())
        
        return {
            'price_volume': price_volume_data,
            'holder_stats': holder_stats,
            'top_addresses': top_addresses
        }

if __name__ == "__main__":
    analyzer = WCTAnalyzer()
    results = analyzer.analyze()
    print("\n分析完成！结果已保存到 wct_price_volume.png") 