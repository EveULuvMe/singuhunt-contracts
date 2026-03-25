# SinguHunt 部署指南

安全 claim proxy、trusted headers、ticket signer 與 EVE 內 smoke test：
見 `docs/SECURE_CLAIM.md`

## 前置需求

1. **Sui CLI** - 安裝: `suiup install sui@testnet`
2. **Node.js** >= 18 + **pnpm**
3. **EVE Vault** 錢包 (需 SUI 代幣作為 gas)
4. **EVE Frontier 客戶端** (啟用 Utopia 測試伺服器)

## 步驟 1: 環境設定

```bash
cd singuhunt
cp .env.example .env
# 編輯 .env 填入你的私鑰和地址
pnpm install
```

## 步驟 2: 部署 Move 合約

### 本地測試
```bash
cd move-contracts/singuhunt
sui move test
```

### 發布到 Utopia 測試網
```bash
cd move-contracts/singuhunt
sui client publish --build-env testnet
```

發布後，從輸出中提取以下資訊更新 `.env`:
- `SINGUHUNT_PACKAGE_ID` - 套件 Object ID
- `GAME_STATE_ID` - GameState shared object ID
- `ADMIN_CAP_ID` - AdminCap object ID

## 步驟 3: 建立佈告欄

如果你有一個 Smart Storage Unit (SSU):
```bash
pnpm create-bulletin -- --ssu <你的SSU_OBJECT_ID>
```

將輸出的 BulletinConfig ID 填入 `.env` 的 `BULLETIN_CONFIG_ID`。

## 步驟 4: 開始狩獵

### 手動啟動
```bash
pnpm start-hunt
```

### 自動排程 (每天隨機時間)
```bash
pnpm auto-hunt
```

## 步驟 5: 玩家互動

### 查詢狩獵狀態
```bash
pnpm query-hunt
```

### 拜訪佈告欄
```bash
pnpm visit-bulletin
```

### 收集奇點代幣
```bash
pnpm collect-token -- --index 0  # 收集第0個奇點
pnpm collect-token -- --index 3 --player B  # 玩家B收集第3個
```

### 兌換成就 NFT
```bash
pnpm claim-achievement
```

### 銷毀過期代幣
```bash
pnpm burn-expired
```

## EVE Frontier Utopia 伺服器設定

### 啟動器設定
- **Windows**: 在啟動器捷徑的目標欄位添加 `--frontier-test-servers=Utopia`
- **Mac**: 通過終端機以 Utopia 伺服器旗標啟動

### 遊戲內沙盒指令
- `/moveme` - 查看可用星系並瞬移
- `/giveitem <itemid> <quantity>` - 生成物品

## 遊戲座標系統

佈告欄 (起點/終點) 固定座標:
- 太陽系: 30000142
- 座標: (30000, 10000, 50000)
- 位於拉格朗日點 L1 附近

7 個奇點座標每天隨機生成，分散在周圍太陽系中。

## 合約架構

```
singuhunt::singuhunt    - 核心遊戲邏輯
  ├── GameState         - 共享遊戲狀態 (狩獵資訊、收集記錄)
  ├── HuntToken         - 每日限定代幣 (可轉讓，有到期時間)
  ├── AchievementNFT    - 永久靈魂綁定成就 (不可轉讓)
  └── AdminCap          - 管理員權限

singuhunt::bulletin_board - SSU 佈告欄擴展
  ├── BulletinConfig    - 佈告欄配置
  └── SinguHuntAuth     - SSU 擴展認證見證
```
