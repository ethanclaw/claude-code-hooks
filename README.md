# Claude Code Hooks

后台调用 Claude Code 执行任务，任务完成后自动通知。

## 功能

- **后台执行**：在后台启动 Claude Code，不阻塞当前会话
- **自动通知**：任务完成后自动发送 Telegram 通知
- **结果保存**：所有输出自动保存到本地
- **多形态使用**：可作为 CLI 工具、Skill、或库函数调用

## 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/ethanclaw/claude-code-hooks.git ~/.claude-code-hooks
cd ~/.claude-code-hooks
```

### 2. 安装 Hook ⚠️

```bash
./scripts/install.sh
```

**这会修改 `~/.claude/settings.json`，添加 Claude Code Stop Hook。**

安装过程：
- 自动检测项目路径
- 生成 config.yaml
- 合并 hooks 到 Claude Code 配置

### 3. 派发任务

```bash
# 基础用法
./scripts/dispatch.sh -p "实现一个 Python 爬虫"

# 完整参数
./scripts/dispatch.sh \
  -p "重构项目测试" \
  -n my-task \                # 任务名称
  -w ~/projects/myapp \      # 工作目录
  -g "-5260404039" \         # Telegram 群组 ID
  -m opus                    # 模型
```

## 参数说明

| 参数 | 说明 |
|------|------|
| `-p, --prompt` | 任务描述（必需）|
| `-n, --name` | 任务名称，默认随机 ID |
| `-w, --workdir` | 工作目录，默认当前目录 |
| `-g, --group` | Telegram 群组 ID，不传则使用配置默认值 |
| `-m, --model` | 模型（sonnet/opus/haiku），默认用 Claude Code 配置 |
| `-t, --timeout` | 超时时间（秒），默认 3600 |

## 输出目录

```
{root}/
├── output/
│   └── {task-id}/
│       ├── meta.json      # 任务参数
│       ├── output.txt     # 原始输出
│       └── result.json    # 解析结果
├── logs/
│   └── {date}.log         # 日志
└── config.yaml            # 自动生成
```

## 卸载

```bash
./scripts/uninstall.sh
```

这会从 `~/.claude/settings.json` 中移除 hooks 配置。

## 注意事项

1. **安装时会修改 Claude 配置**：install.sh 会修改 `~/.claude/settings.json`
2. **Telegram 通知需要群组 ID**：可在 config.yaml 中设置默认群组
3. **任务在后台运行**：dispatch 会立即返回，任务在后台执行

## 作为 Skill 使用

放入 OpenClaw skills 目录即可：

```bash
cp -r ~/.claude-code-hooks ~/.openclaw/workspace-coder/skills/claude-hooks
```

## 作为库调用

```bash
source ~/.claude-code-hooks/scripts/lib/common.sh

dispatch_task "任务描述" "/work/dir" "task-name"
```
