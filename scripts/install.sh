#!/bin/bash
# 安装 Claude Code Hook
# 用法:
#   ./install.sh              # 当前目录作为项目目录
#   ./install.sh skill       # 作为 Skill 安装到 workspace/skills/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="${1:-local}"

# 确定根目录
if [ "$MODE" = "skill" ]; then
    # Skill 模式：安装到 workspace/skills/
    WORKSPACE_ROOT="$HOME/.openclaw/workspace-coder"
    SKILLS_DIR="$WORKSPACE_ROOT/skills/claude-hooks"
    
    echo "=== Skill 模式安装 ==="
    echo "目标目录: $SKILLS_DIR"
    
    # 创建目录
    mkdir -p "$SKILLS_DIR"
    
    # 拷贝文件（排除 .git）
    rsync -a --exclude='.git' --exclude='output' --exclude='logs' "$SCRIPT_DIR/" "$SKILLS_DIR/"
    
    ROOT_DIR="$SKILLS_DIR"
    echo "📁 已复制项目到: $ROOT_DIR"
else
    # 本地模式：当前目录即为项目目录
    ROOT_DIR="$SCRIPT_DIR"
    echo "=== 本地模式安装 ==="
fi

echo "📁 项目根目录: $ROOT_DIR"
echo ""

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
echo "📂 目录创建完成"

# Claude Code 设置文件
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
CLAUDE_HOOK_SCRIPT="$ROOT_DIR/hooks/stop.sh"

echo ""
echo "⚠️  即将修改 Claude Code 配置..."
echo "   设置文件: $CLAUDE_SETTINGS"
echo "   Hook 脚本: $CLAUDE_HOOK_SCRIPT"
echo ""

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

# 构建 hook 配置
HOOK_JSON=$(cat <<EOF
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
)

# 读取现有配置并合并
if [ -f "$CLAUDE_SETTINGS" ]; then
    local temp_file
    temp_file=$(mktemp)
    jq -s '.[0] * .[1]' "$CLAUDE_SETTINGS" <(echo "$HOOK_JSON") > "$temp_file"
    mv "$temp_file" "$CLAUDE_SETTINGS"
else
    echo "$HOOK_JSON" > "$CLAUDE_SETTINGS"
fi

echo "✅ 安装完成!"
echo ""
echo "使用方式："
if [ "$MODE" = "skill" ]; then
    echo "  $SKILLS_DIR/scripts/dispatch.sh -p '任务描述'"
else
    echo "  $ROOT_DIR/scripts/dispatch.sh -p '任务描述'"
fi
echo ""
echo "查看配置: $CLAUDE_SETTINGS"
