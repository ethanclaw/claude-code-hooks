#!/bin/bash
# Claude Code Stop Hook
# 任务完成后自动触发

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

source "$ROOT_DIR/scripts/lib/config.sh"
source "$ROOT_DIR/scripts/lib/telegram.sh"
source "$ROOT_DIR/scripts/lib/output.sh"

# 初始化
init_config "$ROOT_DIR"

# 日志
log() {
    echo "[$(date -Iseconds)] $*" >> "$CONFIG_LOGS_DIR/hook.log"
}

log "=== Hook triggered ==="

# 读取 stdin（Claude Code 传递的上下文）
INPUT=""
if [ -t 0 ]; then
    log "stdin is tty, skip"
elif [ -e /dev/stdin ]; then
    INPUT=$(timeout 2 cat /dev/stdin 2>/dev/null || true)
fi

# 解析输入
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null || echo "")
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"' 2>/dev/null || echo "unknown")

log "session=$SESSION_ID cwd=$CWD event=$EVENT"

# 防重复：检查最近是否已处理
LOCK_FILE="$CONFIG_RESULTS_DIR/.hook-lock"
LOCK_AGE_LIMIT=30

if [ -f "$LOCK_FILE" ]; then
    LOCK_TIME=$(stat -f %m "$LOCK_FILE" 2>/dev/null || echo 0)
    NOW=$(date +%s)
    AGE=$(( NOW - LOCK_TIME ))
    if [ "$AGE" -lt "$LOCK_AGE_LIMIT" ]; then
        log "Duplicate hook within ${AGE}s, skipping"
        exit 0
    fi
fi
touch "$LOCK_FILE"

# 查找最新的任务
# 方法1：从 task-meta.json 读取
META_FILE=""
for meta in "$CONFIG_RESULTS_DIR"/*/meta.json; do
    [ -f "$meta" ] || continue
    META_FILE="$meta"
done

if [ -z "$META_FILE" ] || [ ! -f "$META_FILE" ]; then
    log "No task meta found, exiting"
    exit 0
fi

TASK_ID=$(basename "$(dirname "$META_FILE")")
TASK_DIR="$CONFIG_RESULTS_DIR/$TASK_ID"

log "Processing task: $TASK_ID"

# 读取 meta
TASK_NAME=$(jq -r '.task_name // "unknown"' "$META_FILE")
TELEGRAM_GROUP=$(jq -r '.telegram_group // ""' "$META_FILE")
WORKDIR=$(jq -r '.workdir // ""' "$META_FILE")
STARTED_AT=$(jq -r '.started_at // ""' "$META_FILE")

# 计算耗时
if [ -n "$STARTED_AT" ]; then
    END_TIME=$(date +%s)
    START_TIME=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$STARTED_AT" +%s 2>/dev/null || echo "$END_TIME")
    DURATION=$(( END_TIME - START_TIME ))
else
    DURATION=0
fi

# 读取输出
OUTPUT_FILE="$TASK_DIR/output.txt"
OUTPUT_CONTENT=""
if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
    OUTPUT_CONTENT=$(tail -c 5000 "$OUTPUT_FILE")
fi

# 解析输出
PARSED=$(parse_output "$OUTPUT_FILE")
SUMMARY=$(echo "$PARSED" | jq -r '.summary // ""' | head -c 500)

# 生成结果 JSON
RESULT_FILE="$TASK_DIR/result.json"
jq -n \
    --arg id "$TASK_ID" \
    --arg name "$TASK_NAME" \
    --arg status "done" \
    --arg duration "$DURATION" \
    --arg workdir "$WORKDIR" \
    --arg summary "$SUMMARY" \
    --argjson parsed "$PARSED" \
    '{
        task_id: $id,
        task_name: $name,
        status: $status,
        duration_seconds: ($duration | tonumber),
        cwd: $workdir,
        output: $parsed,
        summary: $summary,
        completed_at: (now | strftime("%Y-%m-%dT%H:%M:%S%z"))
    }' > "$RESULT_FILE"

log "Wrote result.json"

# 复制到 latest
cp "$RESULT_FILE" "$CONFIG_RESULTS_DIR/_latest.json"

# 发送 Telegram 通知
if [ -n "$TELEGRAM_GROUP" ]; then
    MSG=$(format_completion_message "$TASK_NAME" "done" "$SUMMARY" "$DURATION")
    if send_telegram "$TELEGRAM_GROUP" "$MSG"; then
        log "Telegram notification sent to $TELEGRAM_GROUP"
        # 更新 result 中的发送状态
        jq '.notify.telegram_sent = true' "$RESULT_FILE" > "${RESULT_FILE}.tmp" && mv "${RESULT_FILE}.tmp" "$RESULT_FILE"
    else
        log "Telegram notification failed"
    fi
fi

log "=== Hook completed ==="
exit 0
