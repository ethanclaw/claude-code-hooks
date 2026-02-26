#!/bin/bash
# 安装 Claude Code Hook

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Claude Code Hook 安装 ==="
echo ""

# 检测当前目录作为根目录
ROOT_DIR="$(cd "$ROOT_DIR" && pwd)"
echo "📁 项目根目录: $ROOT_DIR"

# 创建配置
CONFIG_FILE="$ROOT_DIR/config.yaml"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "📝 生成配置文件..."
    cat > "$CONFIG_FILE" <<EOF
# Claude Code Hooks 配置（自动生成）
root: "$ROOT_DIR"

# Claude Code 命令
command: "claude"

# 默认模型
default_model: ""

# Telegram 通知
notify:
  telegram:
    enabled: true
    default_group: "-5260404039"

# 输出目录
results:
  dir: "{root}/output"

# 日志目录  
logs:
  dir: "{root}/logs"
EOF
    echo "   已创建: $CONFIG_FILE"
else
    echo "   配置文件已存在"
fi

# 创建必要的目录
mkdir -p "$ROOT_DIR/output"
mkdir -p "$ROOT_DIR/logs"
echo "📂 确保目录存在... 完成"

# Claude Code 设置文件
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
CLAUDE_HOOK_SCRIPT="$ROOT_DIR/hooks/stop.sh"

echo ""
echo "⚠️  即将修改 Claude Code 配置..."
echo "   设置文件: $CLAUDE_SETTINGS"
echo "   Hook 脚本: $CLAUDE_HOOK_SCRIPT"
echo ""

# 创建 hooks 目录和脚本
mkdir -p "$ROOT_DIR/hooks"

# 检查 hook 脚本是否存在
if [ ! -f "$CLAUDE_HOOK_SCRIPT" ]; then
    echo "ERROR: Hook 脚本不存在: $CLAUDE_HOOK_SCRIPT" >&2
    exit 1
fi

# 备份现有设置
if [ -f "$CLAUDE_SETTINGS" ]; then
    cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS.backup.$(date +%Y%m%d)"
    echo "📋 已备份现有配置"
fi

# 读取现有配置
if [ -f "$CLAUDE_SETTINGS" ]; then
    # 使用 jq 合并（保留现有配置，添加 hooks）
    local temp_file
    temp_file=$(mktemp)
    
    # 读取并合并
    jq -s '.[0] * .[1]' "$CLAUDE_SETTINGS" \
        <(cat <<EOF
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_HOOK_SCRIPT",
            "timeout": 30
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command", 
            "command": "$CLAUDE_HOOK_SCRIPT",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
EOF
) > "$temp_file"
    
    mv "$temp_file" "$CLAUDE_SETTINGS"
else
    # 新建配置
    cat > "$CLAUDE_SETTINGS" <<EOF
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_HOOK_SCRIPT",
            "timeout": 30
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command", 
            "command": "$CLAUDE_HOOK_SCRIPT",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
EOF
fi

echo "✅ 安装完成!"
echo ""
echo "现在你可以："
echo "  1. 使用 dispatch.sh 派发后台任务"
echo "  2. 任务完成后会自动通知"
echo ""
echo "查看配置: $CLAUDE_SETTINGS"
