# 壳与市场

Godot 4.5.1 前端 + Python 本地服务的黑客松纵切片。

## 运行

1. 安装依赖：

```powershell
pip install -r requirements.txt
```

2. 可选：配置 `.env` 或系统环境变量。

关键变量：

- `ARK_API_KEY`
- `ARK_ENDPOINT_ID`，默认是 `521e4c18-b3f9-4b54-af94-1f404328f300`
- `ARK_MODEL_LABEL`，默认是 `doubao2.0 mini`
- `ARK_BASE_URL`，默认是 `https://ark.cn-beijing.volces.com/api/v3`
- `SHELL_MARKET_PULSE_SECONDS`，默认 `300`

说明：

- 按火山方舟官方文档，真正用于鉴权的是 `ARK_API_KEY`，endpoint id 作为推理接入点标识使用，不应直接当 Bearer Token 硬编码。
- 当前服务默认没有 `ARK_API_KEY` 时会自动使用本地 mock 规则，游戏仍可完整运行。

3. 启动：

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
- `E` 打开附近交互点
- `F3` 显示或隐藏 NPC 听觉半径

## 当前内容

- 4 个区域：贫民街、港口、工厂区、交易所
- 3 个商品：面包、煤、罐头
- 3 支股票：蓝潮航运、黑石矿业、晨报传媒
- 20 个 NPC、3 个家族
- 实时轮播的 NPC 话语、局部传播和街区级新闻
- 结束一天触发完整结算

