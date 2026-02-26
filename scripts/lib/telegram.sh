#!/bin/bash
# Telegram 通知模块

# 发送 Telegram 消息
# 参数: group_id message
send_telegram() {
    local group="$1"
    local message="$2"
    
    if [ -z "$group" ]; then
        echo "ERROR: Telegram group ID required" >&2
        return 1
    fi
    
    # 使用 OpenClaw CLI 发送
    local openclaw_bin="/Users/ethan/.nvm/versions/node/v25.6.1/bin/openclaw"
    
    if [ -x "$openclaw_bin" ]; then
        "$openclaw_bin" message send \
            --channel telegram \
            --target "$group" \
            --message "$message" 2>/dev/null
        return $?
    fi
    
    # 备选：尝试 curl（需要环境变量配置）
    if [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
        local url="https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage"
        curl -s -X POST "$url" \
            -d "chat_id=$group" \
            -d "text=$message" \
            -d "parse_mode=Markdown"
        return $?
    fi
    
    echo "ERROR: No telegram sender available" >&2
    return 1
}

# 格式化任务完成消息
format_completion_message() {
    local task_name="$1"
    local status="$2"
    local summary="$3"
    local duration="$4"
    
    local emoji="✅"
    [ "$status" = "error" ] && emoji="❌"
    
    echo "🤖 *Claude Code 任务完成*
📋 任务: ${task_name}
⏱️ 用时: ${duration}s
📝 结果:
\`\`\`
${summary:0:800}
\`\`\`"
}
