# Aociety

Godot 4.5.1 前端 + Python FastAPI 本地服务的 2D 开放世界社会经济模拟 Demo。

## 运行

1. 安装依赖

```powershell
pip install -r requirements.txt
```

2. 可选：配置 `.env` 或系统环境变量

关键变量：

- `ARK_API_KEY`
- `ARK_ENDPOINT_ID`
- `ARK_MODEL_ID`
- `ARK_MODEL_LABEL`
- `ARK_BASE_URL`
- `SHELL_MARKET_PULSE_SECONDS`，当前默认 `60`

说明：

- 没有 `ARK_API_KEY` 时，服务会自动回退到本地规则系统。
- AI 脉冲默认 60 秒一轮；总览带图，附近/高热角色优先带图，其余实体走纯文本分层刷新。

3. 启动

```powershell
.\run_demo.ps1
```

也可以分开启动：

```powershell
python -m uvicorn services.app:app --host 127.0.0.1 --port 8765 --reload
.\Godot_v4.5.1-stable_win64_console.exe --path .
```

## 控制

- `WASD` 移动
- `E` 交互
- `H` 展开账本
- `Tab` 查看模式

## 当前内容

- 4 个街区：贫民街、港口、工厂区、交易所
- 商品、股票、家族、公司、新闻、传言、回合结算
- 20 个 NPC 的街头行为、社交演出、关系记忆和 AI 口风
- 玩家实时搭话、场景截图、金融与舆论联动
