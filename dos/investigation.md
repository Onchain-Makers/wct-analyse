# WCT 链上侦查记录本

> 目标：从官方白皮书出发，沿公开合约地址上链取证，逐步还原 WCT 的**代币流向、解锁机制、巨鲸地址**。
> 数据源：WalletConnect 官方文档 + Optimism 区块浏览器 + Dune Analytics（经 MCP）+ 本地合约源码。
> 截至：2026-06-01。所有持仓为 Optimism 主网净额（占全网绝大多数；少量经 NTT 桥到 ETH/Base）。

---

## ★ 执行摘要（先看这段）

1. **发行结构**：10 亿封顶，TGE 2024-11-06 一次性全量铸给主金库多签 `0xa86ca428512d0a18828898d2e656e9eb1b6ba6e7`，再三层下分（金库 → 分类归属合约/子多签 → 受益人）。无通胀。
2. **解锁机制 = 两层**：①合约级转账限制（`transferRestrictionsDisabledAfter`，2025-04-15 解禁）；②MerkleVester 归属合约族（4 年线性 + 1 年 cliff）。**2025-11 单月集中释放 4,814 万**，正是 cliff 到期，与白皮书严丝合缝。
3. **筹码高度集中**：协议自控（金库 36.9% + 锁仓归属 15.8% + 质押 8.5%）≈ **61%** 仍在 WalletConnect 体系手里；散户 7 万+ 地址仅持 **14.2%**。
4. **做市盘**：一个 EOA 钱包簇（中枢 `0x9a9c4219bb88918758ccf83928fa79a563031a16`）持 **10.9%** 作滚动库存，2025-04 解禁日精准启动，是 WCT 的做市/流动性操盘方。
5. **CEX 托管 11.9%**：币安最大（Binance 8/55 合计 ≈7,800 万），另有 Bithumb、OKX、Coinbase。
6. **真实自由流通盘很薄**：剔除协议、做市、CEX 后，分散在散户/LP 手里的约 14%（≈1.42 亿 WCT）。
7. **金库体系 = 同一操盘方的多签矩阵**（深挖，详见 [创世金库.md](创世金库.md) / [三大子金库.md](三大子金库.md)）：创世金库（3/5 Safe）把 10 亿的 85% 扇出给 83 个子金库 Safe（多为 2/3）。这些金库**共用一批轮换签名钥匙 + 同一 gas 代付后端 + 同一 4337 部署栈** → 实为**一个运营方（WalletConnect/基金会）统一管理**，按职能拆账：#1 是 vesting 加注泵、#2/#3 是大额持有+散发。
8. **资金链已端到端打通**：创世金库 → 子金库 cc9792 → MerkleVester（4 年线性）→ 解锁路由 `0x37badde9…`（Admin Timelock 拥有）→ **~83 个真受益人（64 个人 EOA + 15 个人多签）** = 团队/投资人 vesting 终点。另查实：#2/#3 各有 **1 亿 WCT 曾存入 BitGo 机构托管约 1 年（2025-02 → 2026-02-27 已全额赎回）**，NTT 跨链桥合约 `0x85c0129b…` 已定位。

---

## 第 1 步：设计层事实（白皮书 / Tokenomics）

来源：[WalletConnect Docs - Token Dynamics](https://docs.walletconnect.network/token-dynamics/intro)

- **总量**：1,000,000,000 WCT（10 亿，封顶，初始无通胀）
- **分配比例**（官方文档口径，6 类）：
  | 类别 | 比例 | 数量 |
  |---|---|---|
  | WalletConnect Foundation 基金会 | 27.0% | 270,000,000 |
  | Airdrops 空投 | 18.5% | 185,000,000 |
  | Team 团队（WalletConnect + Reown） | 18.5% | 185,000,000 |
  | Rewards 奖励池 | 17.5% | 175,000,000 |
  | Previous Backers 早期投资人 | 11.5% | 115,000,000 |
  | Core Development 核心开发 | 7.0% | 70,000,000 |
- **解锁规则**：Core Development / Team / Previous Backers 适用 **4 年线性解锁 + 1 年 cliff（悬崖）**，自 TGE 起算。
- **可转让时间点**：WCT 在 **2025-04-15** 才完全可转让（此前受转账限制，由社区治理投票开启）。
  - ⭐ 与合约对应：[L2WCT.sol](../src/contracts/WCT/L2WCT%20(implementation)/src/L2WCT.sol) 中的 `transferRestrictionsDisabledAfter` + `allowedFrom/allowedTo` 即此机制的链上实现。
- **TGE / 初始铸造**：2024-11-06 16:29:03（见下文链上证据），向单一地址铸造 10 亿全量。

> ⚠️ 注意：第三方站点（CryptoRank/Tokenomist）把分配拆成 9~10 类（含 Binance Users 5%、Public Sale 4%、Market Maker 2.2%、Token Warrants 11.25% 等），是对官方 6 大类的细分口径，后续以官方 6 类为基准，细分仅作参考。

---

## 第 2 步：合约地址全景（线索地图）

来源：[WalletConnect Docs - Contracts](https://docs.walletconnect.network/contracts)
> ✅ 已用官方页面**截图逐行核对**（2026-06-01）——WebFetch 转述与页面一致。
> 以太坊主网 WCT 地址经核对为 `0xeF4461891DfB3AC8572cCf7C794664A8DD927945`（与 OP/Base 三链同址）；早前搜索出现的 `0xA3016046cdf9323D7529FB0cb637A69D75d8e0d7` 非官方文档口径，列为待查小尾巴，暂不采信。

**WCT Token（三链同地址，确定性部署）**
- Ethereum (chainid 1)：`0xeF4461891DfB3AC8572cCf7C794664A8DD927945`
- Optimism (chainid 10)：`0xeF4461891DfB3AC8572cCf7C794664A8DD927945` ← **本次侦查主战场（L2WCT）**
- Base (chainid 8453)：`0xeF4461891DfB3AC8572cCf7C794664A8DD927945`
- Solana：`WCTk5xWdn5SYg56twGj32sUF3W4WFQ48ogezLBuYTBY`

**Optimism 治理与分发生态（关键嫌疑人名单）**
| 角色 | 地址 | 作用 |
|---|---|---|
| Admin Timelock | `0x61cc6aF18C351351148815c5F4813A16DEe7A7E4` | 管理员时间锁（升级/高权限操作延迟执行） |
| Manager Timelock | `0xB5EFe3783Db55B913C79CBdB81C9d2C0a993f5f0` | 管理员时间锁（MANAGER_ROLE 类操作） |
| WalletConnectConfig | `0xd2f149fAA66DC4448176123f850C14Ff14f978B3` | 协议配置中心 |
| Pauser | `0x9163de7F22A9f3ad261B3dBfbB9A42886816adE7` | 紧急暂停 |
| StakeWeight | `0x521B4C065Bbdbe3E20B3727340730936912DfA46` | 质押仓位管理（ve 模型） |
| StakingRewardDistributor | `0xF368F535e329c6d08DFf0d4b2dA961C4e7F3fCAF` | 质押奖励分发 |
| Airdrop (Season 1) | `0x4ee97a759AACa2EdF9c1445223b6Cd17c2eD3fb4` | 第一季空投分发 |

**已知初始铸造接收方**
- `0xa86ca428512d0a18828898d2e656e9eb1b6ba6e7` — TGE 时 mint 全量 10 亿（待标注：疑似金库/分发母地址）

### 2.1 发行/分配核心合约（官方合约页**未列**，由链上挖出）

> ⚠️ 重要：官方 Contracts 页只列"协议运行核心合约"，**不含**代币发行分配的执行体。下列合约对"10 亿如何分出去"最关键，但需自行上链发现。
> 证据来源：Dune 转账聚合（金额可信）+ Etherscan/WebFetch 合约名（中等强度，**尚未用 Dune 解码表/字节码硬核对**）。

| 合约/地址 | 角色 | 证据强度 |
|---|---|---|
| `0xa86ca428512d0a18828898d2e656e9eb1b6ba6e7` | **创世主金库**（Gnosis Safe 多签），收下全部 10 亿 mint，再向下分发 | 🔶 Etherscan 显示 GnosisSafeProxy |
| `0xc401d6c0b79b5df63c530b6f02aaac1ae5c5cb90` | **子金库 Safe**（收 186.25M） | 🔶 Etherscan 显示 GnosisSafeProxy（已验证源码） |
| `0x51f651b1482f7ef18bcbbbf0307035ba9703f25c` | **子金库 Safe**（收 193.75M） | 🔶 Etherscan 显示 SafeProxy（源码未验证） |
| `0x2ff1cdf8fe00ae6952baa32e37d84d31a31e2ec2` | **MerkleVester 归属/解锁合约** | 🔶 Etherscan 显示 MerkleVester |
| `0x648bddee207da25e19918460c1dc9f462f657a19` | **MerkleVester 归属/解锁合约** | 🔶 Etherscan 显示 MerkleVester |
| `0x85d0964d328563d502867ff6899c6f73d2e59fd1` | **MerkleVester 归属/解锁合约** | 🔶 Etherscan 显示 MerkleVester |

- MerkleVester 族 = 白皮书"4 年线性 + 1 年 cliff"的**真正链上执行体**（Merkle 树记额度，受益人凭 proof 领取）。
- "金库 → 子金库/归属合约 → 受益人"的三层结构目前仍是**推断**（第二跳尚未打通）。

### 2.2 理论上应存在、但官方页未给（🔶待链上确认）

| 合约 | 为什么应该存在 |
|---|---|
| **代理实现合约（L2WCT impl）** | `0xeF4461891DfB3AC8572cCf7C794664A8DD927945` 是代理；本地源码有 [L2WCT.sol](../src/contracts/WCT/L2WCT%20(implementation)/src/L2WCT.sol)，但链上实现地址未确认 |
| **ProxyAdmin** | 透明代理升级机制的另一半（本地有 TransparentUpgradeableProxy 源码） |
| **NTT Manager / Transceiver** | ✅ **已找到**：`0x85c0129be5226c9f0cf4e419d2fefc1c3fca25cf`（`NttManagerWithExecutor`，Wormhole NTT 跨链桥管理合约，executor `0x85B704501f6AE718205C0636260768C4e72ac3e7`）。子金库经它把 WCT 跨链送出。详见 [三大子金库.md](三大子金库.md) A 段。 |
| **Governor 治理投票合约** | 文档有 Governance 栏目却无地址；2025-04-15 解禁就是治理投票通过的 |

> 下一步可做：用 Dune 解码表 / 字节码把 2.1 的 🔶 升级为 ✅，并把 2.2 的合约在链上找出来。

---

## 第 3 步：链上取证 — 创世铸造与第一跳分发

数据源：Dune `erc20_optimism.evt_transfer`（注：主金库累计向 **132,943 个不同地址**直接转出过 WCT；详见 [创世金库.md ②](创世金库.md)）

### 3.0 铸造（mint）全量核查 — ✅ 已坐实

查询：[wct2026 - WCT mint events](https://dune.com/queries/7627691)（已存入 minner_qi 账号 `wct2026` 文件夹）
口径：mint = `from = 0x0` 的 Transfer。OP 上共 **461 笔** mint。

**① 创世铸造（唯一的"发行"铸造）**

| 字段 | 值 |
|---|---|
| 时间 | 2024-11-06 16:29:03 UTC |
| 区块 | 127,655,883 |
| 交易哈希 | `0x862c1bcc474911b58848643076462289d08937376d2c15de8375ca3cd6ad9c12` |
| 交易发起人 (tx_from) | `0x36bde71c97b33cc4729cf772ae268934f7ab70b2`（🔶 疑似部署者/管理员 EOA，待定性） |
| 接收方 (to) | `0xa86ca428512d0a18828898d2e656e9eb1b6ba6e7`（创世主金库 Safe） |
| 数量 | **1,000,000,000 WCT**（1e27 wei，全量一次铸足） |

**② 其余 460 笔 = 跨链桥入痕迹（NTT）** ✅ 已确认
- 全部发生在 2025-04-24 之后，金额零散（0.01 ~ 数千 WCT），多数"发起人 = 接收方"（用户自助桥入）。
- 性质：WCT 从他链桥到 OP 时在 OP 侧 mint、源链 burn，**不增加全网总量**，与发行分配无关。
- 后续分析的"发行/分配"只认创世这 1 笔。

- **创世铸造**：2024-11-06 16:29:03，从 `0x0` 铸造 10 亿 WCT 给主金库 `0xa86ca428512d0a18828898d2e656e9eb1b6ba6e7`（= Gnosis Safe 多签）。
- **第一跳分发**（母金库 → 各子地址，Top）：
  | 接收方 | 数量(WCT) | 身份 |
  |---|---|---|
  | `0xcc97929655e472c2ad608acd854c03fa15899e31` | 200,235,537 | **Safe 1.4.1**（最大子金库，仍在收） |
  | `0x51f651b1482f7ef18bcbbbf0307035ba9703f25c` | 193,750,000 | **Safe 1.4.1**（子金库） |
  | `0xc401d6c0b79b5df63c530b6f02aaac1ae5c5cb90` | 186,250,001 | **Safe 1.3.0L2**（子金库） |
  | `0xf853f030927762dc0f4afab429e3b04568b61c61` | 100,000,000 | ⭐ **合约（非 Safe，待查）** |
  | `0x6f99ee719c2628288372e9972a136d44bddda8e4` | 53,939,189 | **Safe 1.4.1**（子金库） |
  | `0x2db7b3cfa309dc898b21a6cd62f7b75d91637f25` | 50,000,000 | **Safe 1.4.1**（子金库） |
  | `0xc859e2b8c9fc18aa43a6c737e5a8b7f14dcba496` | 26,601,046 | **Safe 1.4.1**（子金库） |
  | `0x3ba13bbe97d4243cc4d6a715eb0c4864030ec884` | 20,000,000 | **Safe 1.4.1**（子金库） |
  | `0xcaa061a3d0278956d728970673af1d9bbeb89d28` | 15,000,000 | **Safe 1.4.1**（子金库） |
  | `0x5f01c4bce00612ef4fd3ac896497586f6922aff4` | 11,786,358 | **Safe 1.4.1**（子金库） |
  | `0xf368f535e329c6d08dff0d4b2da961c4e7f3fcaf` | 6,616,390 | **StakingRewardDistributor**（合约图实锤） |
  - 解读（✅ 已对账，详见 [创世金库.md ②](创世金库.md)）：10 亿流出中 **~85%（765.6M）进了 83 个 Safe 子多签**，是"母多签 → 几十个子多签"的扇出结构；唯一非 Safe 大户为合约 `0xf853f030…`（1 亿）；MerkleVester 归属合约不从金库直接拿钱（经子金库二次转入）。

## 第 4 步：解锁机制（链上实体）

WCT 的解锁由两套机制叠加：

**(A) 合约级转账限制**（早期锁仓）— [L2WCT.sol](../src/contracts/WCT/L2WCT%20(implementation)/src/L2WCT.sol)
- `transferRestrictionsDisabledAfter`：在此时间戳前，普通地址之间禁止转账。
- `allowedFrom` / `allowedTo` 白名单：金库、分发合约等可在锁仓期内照常转账（用于初始分发）。
- 对应白皮书"2025-04-15 才完全可转让"。`disableTransferRestrictions()` 一次性永久关闭。

**(B) MerkleVester 归属合约族**（线性/cliff 解锁的真正载体）
- 链上发现**至少 3 个 MerkleVester 合约**（按分配类别拆分）：
  | 合约 | 当前持仓 | 类型 |
  |---|---|---|
  | `0x2ff1cdf8fe00ae6952baa32e37d84d31a31e2ec2` | 113,991,461 | MerkleVester |
  | `0x648bddee207da25e19918460c1dc9f462f657a19` | 23,385,096 | MerkleVester |
  | `0x85d0964d328563d502867ff6899c6f73d2e59fd1` | 20,335,356 | MerkleVester |
  - 机制：Merkle 树记录每个受益人的额度，支持 **calendar（指定时间点解锁）** 与 **interval（区间线性解锁）** 两种 schedule，受益人凭 merkle proof `withdraw()` 领取。对应白皮书的 4 年线性 + 1 年 cliff。
  - 含可取消(revoke)、转让受益人、claim fee 等管理功能（角色：BENEFACTOR / FEE_SETTER / POST_CLAIM_HANDLER_MANAGER）。

**(C) Timelock**：Admin/Manager 两个时间锁合约延迟执行高权限操作（升级、改配置）。

## 第 5 步：巨鲸地址与标签（当前持仓 Top，OP）

数据源：Dune 净持仓 + `cex.addresses` + `addresses.stats` + Etherscan 名称

| # | 地址 | 持仓(WCT) | 占比* | 身份 |
|---|---|---|---|---|
| 1 | `0xc401d6c0b79b5df63c530b6f02aaac1ae5c5cb90` | 173,443,845 | 17.3% | **Gnosis Safe 子金库**（多签） |
| 2 | `0x2ff1cdf8fe00ae6952baa32e37d84d31a31e2ec2` | 113,991,461 | 11.4% | **MerkleVester 归属合约** |
| 3 | `0x9a9c4219bb88918758ccf83928fa79a563031a16` | 103,664,833 | 10.4% | ⚠️ **纯 EOA，无标签**（最大未解释巨鲸） |
| 4 | `0xa86ca428512d0a18828898d2e656e9eb1b6ba6e7` | 98,251,461 | 9.8% | **主金库 Gnosis Safe**（创世接收方，留存） |
| 5 | `0x51f651b1482f7ef18bcbbbf0307035ba9703f25c` | 97,215,751 | 9.7% | **Safe 多签**（子金库） |
| 6 | `0x521b4c065bbdbe3e20b3727340730936912dfa46` | 83,521,340 | 8.4% | **StakeWeight 质押合约**（被质押锁定） |
| 7 | `0xf977814e90da44bfa03b6295a0616a897441acec` | 61,206,318 | 6.1% | **币安 Binance 8**（CEX） |
| 8 | `0x648bddee207da25e19918460c1dc9f462f657a19` | 23,385,096 | 2.3% | **MerkleVester 归属合约** |
| 9 | `0x85d0964d328563d502867ff6899c6f73d2e59fd1` | 20,335,357 | 2.0% | **MerkleVester 归属合约** |
| 10 | `0xacd03d601e5bb1b275bb94076ff46ed9d753435a` | 16,715,491 | 1.7% | **币安 Binance 55**（CEX） |
| 11 | `0x2d4056313020f3a614c51a1b9b6aa765e27e4f8c` | 15,104,293 | 1.5% | **Bithumb 354**（CEX） |
| 12 | `0xb5216cb558cb018583bed009ee25ca73eb27bb1d` | 9,490,621 | 0.9% | **OKX 237**（CEX） |
| 13 | `0x5122e9aa635c13afd2fc31de3953e0896bac7ab4` | 4,029,563 | 0.4% | **Coinbase 39**（CEX） |

\* 占比按 10 亿总量估算。

**初步画像**
- **协议自控**（金库多签 + 归属合约 + 质押）≈ 6+9.8+9.7+11.4+2.3+2.0+8.4 ≈ **60%+** 仍由 WalletConnect 体系合约/多签掌握 → 流通盘其实很集中。
- **CEX 托管**：币安(两个)+Bithumb+OKX+Coinbase Top 榜合计 ≈ **1.2 亿+**，币安独占大头（≈7800 万）。
- **疑点 #1**：`0x9a9c4219bb88918758ccf83928fa79a563031a16`（EOA，1.036 亿/10.4%）——非合约、无标签却持有超 10%，需追溯它从哪来、是否在抛售。最大优先级。
- **疑点 #2**：第一跳里 `0xcc97929655e472c2ad608acd854c03fa15899e31`（累计收 2 亿）与 `0xf853f030927762dc0f4afab429e3b04568b61c61`（1 亿）身份未明，需进一步追踪。

## 第 6 步：破解疑点 #1 — `0x9a9c4219bb88918758ccf83928fa79a563031a16` 是做市商钱包簇中枢

追踪其转账对手方后，定性为 **做市/流动性操盘集群（market maker）**，而非普通巨鲸：
- **双向高频对倒**：与下面一组 EOA 反复对倒，每对手方上百笔、数千万~上亿来回：
  - `0x3004980d30c770f34663b9258d03e27d62f07315`
  - `0x55655795b99478dea3dbbbf3e652bfc6d69d895b`
  - `0xa263d9b6f558fa14dd0ef1d2d982410b85a108a7`
  - `0x8e19f9d8f9d7aa37afb35ee9825de3c538754c43`
  - `0xcfd186f58b5afb37faa8264253e6e08dc214e0c7`
  - `0x90e0dc0d61784c7411b21004649222928e9bfdd6`
  - `0x759ecdcf47d74421f54a689d0add56a08a0ed281`
- **中枢净额 = 库存**：累计流入 ≈ 5.8 亿、流出 ≈ 4.75 亿，净留存 ≈ 1.036 亿（即当前持仓），毛流量远大于净额 = 典型做市，不是单向抛售。
- **同一操盘方播种**：舰队由两个母钱包资助 ——
  - `0x460faed1dfdb29a347bacfbd80bd1a4204c455c8`：2025-04-10（**解禁前 5 天**）资助第一批：
    - `0xee81ecd8828841253d752dce8ab9588af21ff0ee`
    - `0x90e0dc0d61784c7411b21004649222928e9bfdd6`
    - `0xcfd186f58b5afb37faa8264253e6e08dc214e0c7`
    - `0x759ecdcf47d74421f54a689d0add56a08a0ed281`
    - `0x8e19f9d8f9d7aa37afb35ee9825de3c538754c43`
  - `0x9aa7339636fc99b3f4bf657fc60232df3c7e1ef0`：2025-12-01 资助第二批：
    - `0x55655795b99478dea3dbbbf3e652bfc6d69d895b`
    - `0xa263d9b6f558fa14dd0ef1d2d982410b85a108a7`
    - `0x3004980d30c770f34663b9258d03e27d62f07315`
  - 中枢 `0x9a9c4219bb88918758ccf83928fa79a563031a16` 本身首笔由 `0xee81ecd8828841253d752dce8ab9588af21ff0ee` 资助 → 同一操盘方。
- **时间卡点**：全部活动起于 2025-04-15/16（转账解禁日），与"上市做市"剧本完全吻合。
- ⭐ 结论：该 10.4% 并非个人巨鲸囤币，而是 MM 的滚动库存；真实"自由流通"需把它从散户口径中剔除。

## 第 7 步：解锁释放节奏（MerkleVester 月度流出）

数据源：三个 MerkleVester 合约的月度对外转账（Dune query 7626733）

| 月份 | 释放(WCT) | 领取笔数 | 备注 |
|---|---|---|---|
| 2025-02 | 255,383 | 1 | 测试性 |
| 2025-04 | 255,383 | 1 | 测试性 |
| 2025-05 | 5,127,683 | 3 | 解禁后首波 |
| **2025-11** | **48,144,655** | 117 | ⭐ **1 年 cliff 到期，集中解锁** |
| 2025-12 | 18,939,497 | 51 | |
| 2026-01 | 5,787,263 | 116 | 转入线性月供 |
| 2026-02 | 7,806,900 | 59 | |
| 2026-03 | 14,559,115 | 125 | |
| 2026-04 | 9,362,375 | 130 | |
| 2026-05 | 12,035,013 | 117 | |
- 形态：长期近乎为零 → 2025-11 cliff 断崖式释放 → 此后每月线性。完全印证白皮书"1 年 cliff + 4 年线性"。累计经 vester 释放 ≈ 1.22 亿。

## 第 8 步：全供应分桶（当前持仓，OP）

数据源：Dune query 7626745（净持仓分类，CEX 桶用 `cex.addresses` 全量匹配）

| 类别 | 地址数 | 持仓(WCT) | 占比 |
|---|---|---|---|
| 金库多签（Treasury） | 3 | 368,911,058 | **36.9%** |
| 归属合约锁仓（Vesting locked） | 3 | 157,711,914 | 15.8% |
| 质押（Staking） | 2 | 84,517,611 | 8.5% |
| 做市商钱包簇（Market maker） | 4* | 108,744,294 | 10.9% |
| 交易所托管（CEX） | 37 | 119,220,928 | 11.9% |
| 散户 / LP / 其他 | 70,223 | 142,097,654 | 14.2% |

\* 做市簇仅统计了当前仍有净余额的成员；其余成员净额已归零。合计 ≈ 9.81 亿（差额 ≈1,900 万为桥到 ETH/Base 等）。

**结论**：
- **协议方掌控 ≈ 61%**（金库+锁仓+质押），筹码极度集中，话语权仍在 WalletConnect 基金会/团队。
- **可流通的"真实交易盘" ≈ MM 10.9% + CEX 11.9% + 散户 14.2% ≈ 37%**，其中近三分之一是做市库存。
- 散户虽多达 7 万+ 地址，但人均持仓极小，合计仅 14.2%。

## 第 9 步：金库体系深挖汇总（专档：[创世金库.md](创世金库.md)、[三大子金库.md](三大子金库.md)）

### 9.1 金库矩阵（同一操盘方）
| 金库 | 类型 | 当前留存 | 角色 |
|---|---|---|---|
| 创世主金库 `0xa86ca428512d0a18828898d2e656e9eb1b6ba6e7` | 3/5 Safe 1.3.0L2 | 9,825 万 | 10 亿全量接收 + 母分发 |
| 子金库#1 `0xcc97929655e472c2ad608acd854c03fa15899e31` | 2/3 Safe 1.4.1 (4337) | ≈0（过手） | **MerkleVester 加注泵** |
| 子金库#2 `0x51f651b1482f7ef18bcbbbf0307035ba9703f25c` | 2/3 Safe 1.4.1 (4337) | 9,722 万 | 持有 + 散发 |
| 子金库#3 `0xc401d6c0b79b5df63c530b6f02aaac1ae5c5cb90` | 2/3 Safe 1.3.0L2 | 1.734 亿 | 最大持有 + 大规模散发 |

- **同源证据**：`0xcd742d837dCaC90EbB6FFe62aa9710850dc841B1` 同时是创世 owner#3 与 #3 当前 owner；`0x2fb4c320…` 横跨 #1/#3；gas 代付合约 `0xd152f549545093347a162dce210e7293f1452150` 横跨创世/#1；两个 1.4.1 子金库共用 4337 部署器 `0xf9d64d54…`。
- **安全**：门槛主体 2/3~3/5；#1/#2 早期有过几周的 1/2 窗口（暴露有限），#3 与创世全程不降。

### 9.2 vesting 资金链（团队/投资人解锁）
`创世金库 → cc9792 → MerkleVester 0x2ff1cdf8…（收 1.87 亿，已放 39%，余 1.14 亿锁至~2028） → 解锁路由 0x37badde9…（Admin Timelock 拥有，纯过手） → ~83 受益人（64 个人EOA 5,343 万 + 15 个人多签 1,851 万）`
- Top 受益人与全网 Top 持仓榜吻合（如 `0xd4ca0fb58552876df6e9422dcfc5b07b0db2c229`、`0x2dabc7b42c579757bbb4246563de6b6bba0fd8b1`），链路自洽。

### 9.3 机构托管与跨链（子金库#2/#3 的"其他合约"桶 2.4 亿解码）
| 去向 | 金额 | 合约 |
|---|---|---|
| **BitGo 机构托管**（多签 OpethWalletSimple ×2，**~1 年托管往返，2026-02-27 已全额赎回回 #2/#3**；另 ForwarderV4 20M） | 2×1 亿（已平）+ 20M | `0x3635457359ecba79b00d8f237318dd87f30c7246`、`0x9ce1b7d493cb094c5148d0adcbc24b66b70fd60d`、`0xb8f922f6ac679f386a892647fd0a3f15e0e0c2e5` |
| **NTT 跨链桥**（OP→ETH/Base/Solana） | ≈1,280 万 | `0x85c0129be5226c9f0cf4e419d2fefc1c3fca25cf`（NttManagerWithExecutor） |
| 子金库直接散发给数千 EOA（#2 2,282 个 / #3 5,545 个） | #3 ≈1.08 亿等 | 性质（空投/奖励）待查 |

> ⭐ 修正：原"全供应分桶"把上述 BitGo 托管、子金库散发的去向计入"散户/其他"或"金库"，深挖后应理解为 **机构托管 + 受控散发**，散户真实自由流通比表面更低。

## 复现用 Dune 查询清单
| 查询 | ID / URL |
|---|---|
| 母金库第一跳分发 | [7626680](https://dune.com/queries/7626680) |
| 当前 Top 持仓 | [7626691](https://dune.com/queries/7626691) |
| Top 持仓 + 标签 | [7626702](https://dune.com/queries/7626702) |
| 巨鲸 0x9a9c4219 进出 | [7626718](https://dune.com/queries/7626718) |
| 做市簇标签 | [7626723](https://dune.com/queries/7626723) |
| MerkleVester 月度解锁 | [7626733](https://dune.com/queries/7626733) |
| 全供应分桶 | [7626745](https://dune.com/queries/7626745) |
| 金库 mint 全量核查 | [7627691](https://dune.com/queries/7627691) |
| 创世金库去向分类 | [7628282](https://dune.com/queries/7628282) |
| 子金库 #1/#2/#3 身份+配置 | 7633684/7633690/7633938/7633943 |
| 子金库去向（#1 / #2#3） | 7633892 / 7633970 |
| 其他合约桶（BitGo/NTT） | [7634601](https://dune.com/queries/7634601) |
| MerkleVester→路由→受益人 | 7634661 / 7634682 / 7634724 |

> 全部查询以 `wct2026` 前缀保存在 minner_qi 账号 `wct2026` 文件夹。

## 仍可深挖（下一步）
- [x] ~~给第一跳大额接收方 `0xcc97929655…`（2 亿）、`0xf853f030…`（1 亿）定性~~ → cc9792=子金库#1（vesting泵）；0xf853f030 见创世金库②（合约，待细查）。
- [x] ~~跨链 NTT 桥定位~~ → NttManagerWithExecutor `0x85c0129b…` 已找到。
- [ ] **BitGo 两个 1 亿托管钱包后续去向**（是否减持/回流交易）。
- [ ] **#2/#3 数千 EOA 散发的性质**（空投 vs 奖励，金额分布）。
- [ ] 另两个 MerkleVester（`0x648bddee…`/`0x85d0964d…`）的受益人是否同一批。
- [ ] 做市簇是否净流向 CEX（真实抛压）。
- [ ] 质押参与度随时间变化、StakingRewardDistributor 发奖节奏。
