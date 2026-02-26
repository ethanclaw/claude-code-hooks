#!/bin/bash
# 查看任务结果

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

source "$ROOT_DIR/scripts/lib/config.sh"

init_config "$ROOT_DIR"

RESULTS_DIR="$CONFIG_RESULTS_DIR"

show_usage() {
    cat <<EOF
用法: results.sh [task-id]

查看任务结果。如果不指定 task-id，显示最近的任务列表。

示例:
  results.sh           # 列出所有任务
  results.sh task-xxx # 查看具体任务
EOF
}

list_tasks() {
    echo "=== 任务列表 ==="
    echo ""
    
    if [ ! -d "$RESULTS_DIR" ] || [ -z "$(ls -A "$RESULTS_DIR" 2>/dev/null)" ]; then
        echo "暂无任务"
        return
    fi
    
    for task_dir in "$RESULTS_DIR"/*/; do
        [ -d "$task_dir" ] || continue
        [ "$(basename "$task_dir")" = "_latest" ] && continue
        
        local task_id
        task_id=$(basename "$task_dir")
        
        local meta_file="$task_dir/meta.json"
        local result_file="$task_dir/result.json"
        
        if [ -f "$result_file" ]; then
            local name status
            name=$(jq -r '.task_name // "unknown"' "$result_file")
            status=$(jq -r '.status // "unknown"' "$result_file")
            local duration
            duration=$(jq -r '.duration_seconds // 0' "$result_file")
            
            local emoji="✅"
            [ "$status" = "error" ] && emoji="❌"
            
            echo "$emoji $task_id"
            echo "   任务: $name"
            echo "   状态: $status | 用时: ${duration}s"
            [ -f "$ echo ""
        elifmeta_file" ]; then
            local name
            name=$(jq -r '.task_name // "unknown"' "$meta_file")
            echo "🔄 $task_id"
            echo "   任务: $name"
            echo "   状态: 运行中"
            echo ""
        fi
    done
}

show_task() {
    local task_id="$1"
    local task_dir="$RESULTS_DIR/$task_id"
    
    if [ ! -d "$task_dir" ]; then
        echo "任务不存在: $task_id"
        exit 1
    fi
    
    local result_file="$task_dir/result.json"
    local output_file="$task_dir/output.txt"
    
    if [ -f "$result_file" ]; then
        echo "=== 任务结果 ==="
        jq '.' "$result_file"
    else
        echo "任务结果尚未生成"
    fi
}

main() {
    if [ $# -eq 0 ]; then
        list_tasks
    else
        show_task "$1"
    fi
}

main "$@"
