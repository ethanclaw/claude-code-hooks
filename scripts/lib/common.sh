#!/bin/bash
# 公共函数库

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# scripts/lib -> scripts -> 根目录，需要上两级
LIB_ROOT="$(dirname "$(dirname "$LIB_DIR")")"

# 加载模块
source "$LIB_DIR/config.sh"
source "$LIB_DIR/telegram.sh"
source "$LIB_DIR/output.sh"

# 初始化配置
init_config "$LIB_ROOT"

# 生成任务 ID
generate_task_id() {
    echo "task-$(date +%Y%m%d)-$(head -c 4 /dev/urandom | xxd -p)"
}

# 创建任务目录
setup_task_dir() {
    local task_id="$1"
    local task_dir="$CONFIG_RESULTS_DIR/$task_id"
    mkdir -p "$task_dir"
    echo "$task_dir"
}

# 日志
log() {
    local level="$1"
    shift
    local date
    date=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$date] [$level] $*" >> "$CONFIG_LOGS_DIR/$(date +%Y-%m-%d).log"
}

# 派发任务的公共函数
dispatch_task() {
    local prompt="$1"
    local workdir="${2:-.}"
    local model="${3:-}"
    
    local task_id
    task_id=$(generate_task_id)
    local task_name="${task_name:-$task_id}"
    local group="${group:-$CONFIG_DEFAULT_GROUP}"
    
    local task_dir
    task_dir=$(setup_task_dir "$task_id")
    
    # 写入 meta.json
    jq -n \
        --arg id "$task_id" \
        --arg name "$task_name" \
        --arg prompt "$prompt" \
        --arg workdir "$workdir" \
        --arg group "$group" \
        --arg model "$model" \
        '{
            task_id: $id,
            task_name: $name,
            prompt: $prompt,
            workdir: $workdir,
            telegram_group: $group,
            model: $model,
            started_at: (now | strftime("%Y-%m-%dT%H:%M:%S%z"))
        }' > "$task_dir/meta.json"
    
    log "INFO" "Dispatched task $task_name (ID: $task_id)"
    echo "$task_id"
}
