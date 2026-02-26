#!/bin/bash
# 卸载 Claude Code Hook

set -euo pipefail

CLAUDE_SETTINGS="$HOME/.claude/settings.json"

echo "=== Claude Code Hook 卸载 ==="
echo ""

if [ ! -f "$CLAUDE_SETTINGS" ]; then
    echo "Claude Code 设置文件不存在"
    exit 0
fi

# 备份
cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS.backup.uninstall.$(date +%Y%m%d)"
echo "📋 已备份当前配置"

# 移除 hooks 部分
# 使用 jq 删除 hooks 字段
jq 'del(.hooks)' "$CLAUDE_SETTINGS" > "${CLAUDE_SETTINGS}.tmp" && \
    mv "${CLAUDE_SETTINGS}.tmp" "$CLAUDE_SETTINGS"

echo "✅ 已移除 Hook 配置"
echo ""
echo "注意: config.yaml 和 output/ 目录未删除"
echo "如需完全清理，请手动删除: ~/.claude-code-hooks/"
