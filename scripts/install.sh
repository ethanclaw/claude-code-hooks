#!/bin/bash
# 安装 Claude Code Hook
# 用法:
#   ./install.sh                          # 本地模式，当前目录
#   ./install.sh -w /path/to/workspace    # Skill 模式，指定 workspace
#   ./install.sh -w /path -c /path/to/.claude  # 同时指定 workspace 和 claude 配置目录

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 默认值
MODE="local"
WORKSPACE_DIR=""
CLAUDE_DIR=""

# 解析参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        -w|--workspace)
            WORKSPACE_DIR="$2"
            MODE="skill"
            shift 2
            ;;
        -c|--claude-dir)
            CLAUDE_DIR="$2"
            shift 2
            ;;
        -h|--help)
            echo "用法: $0 [-w workspace_dir] [-c claude_dir]"
            echo ""
            echo "选项:"
            echo "  -w, --workspace DIR   Skill 安装目录"
            echo "  -c, --claude-dir DIR  Claude 配置目录 (默认 ~/.claude)"
            exit 0
            ;;
        *)
            echo "未知选项: $1" >&2
            exit 1
            ;;
    esac
done

# 转换为绝对路径
resolve_path() {
    local path="$1"
    if [ -z "$path" ]; then
        echo ""
        return
    fi
    
    # 如果已经是绝对路径
    if [[ "$path" = /* ]]; then
        echo "$(cd "$path" 2>/dev/null && pwd)"
        return
    fi
    
    # 相对路径转换为绝对路径
    echo "$(cd "$(pwd)/$path" 2>/dev/null && pwd)"
}

# 确定 Claude 配置目录
if [ -z "$CLAUDE_DIR" ]; then
    CLAUDE_DIR="$HOME/.claude"
else
    CLAUDE_DIR=$(resolve_path "$CLAUDE_DIR")
fi

# 确定根目录
if [ "$MODE" = "skill" ]; then
    if [ -z "$WORKSPACE_DIR" ]; then
        echo "错误: skill 模式需要指定 -w/--workspace 参数" >&2
        exit 1
    fi
    
    WORKSPACE_DIR=$(resolve_path "$WORKSPACE_DIR")
    SKILLS_DIR="$WORKSPACE_DIR/skills/claude-hooks"
    
    echo "=== Skill 模式安装 ==="
    echo "Workspace: $WORKSPACE_DIR"
    echo "目标目录: $SKILLS_DIR"
    echo "Claude 配置: $CLAUDE_DIR"
    echo ""
    
    # 创建目录
    mkdir -p "$SKILLS_DIR"
    
    # 拷贝文件（排除 .git, output, logs）
    rsync -a --exclude='.git' --exclude='output' --exclude='logs' --exclude='config.yaml' "$SCRIPT_DIR/" "$SKILLS_DIR/"
    
    ROOT_DIR="$SKILLS_DIR"
    echo "📁 已复制项目到: $ROOT_DIR"
else
    ROOT_DIR="$SCRIPT_DIR"
    echo "=== 本地模式安装 ==="
    echo "项目目录: $ROOT_DIR"
    echo "Claude 配置: $CLAUDE_DIR"
fi

echo ""

# 转换为绝对路径
ROOT_DIR=$(resolve_path "$ROOT_DIR")
echo "📁 项目根目录: $ROOT_DIR"

# 创建配置
CONFIG_FILE="$ROOT_DIR/config.yaml"
echo "📝 生成配置文件..."

cat > "$CONFIG_FILE" <<EOF
# Claude Code Hooks 配置（自动生成）
root: "$ROOT_DIR"

# Claude Code 命令
command: "claude"

# 默认模型
default_model: ""

# Claude 配置目录
claude_dir: "$CLAUDE_DIR"

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

# 创建必要的目录
mkdir -p "$ROOT_DIR/output"
mkdir -p "$ROOT_DIR/logs"
echo "📂 目录创建完成"

# Claude Code 设置文件
CLAUDE_SETTINGS="$CLAUDE_DIR/settings.json"
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
    temp_file=$(mktemp)
    jq -s '.[0] * .[1]' "$CLAUDE_SETTINGS" <(echo "$HOOK_JSON") > "$temp_file"
    mv "$temp_file" "$CLAUDE_SETTINGS"
else
    echo "$HOOK_JSON" > "$CLAUDE_SETTINGS"
fi

echo "✅ 安装完成!"
echo ""
echo "使用方式："
echo "  $ROOT_DIR/scripts/dispatch.sh -p '任务描述'"
echo ""
echo "查看配置: $CLAUDE_SETTINGS"
