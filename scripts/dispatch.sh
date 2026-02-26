#!/bin/bash
# Claude Code 任务派发脚本

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# 加载公共库
source "$SCRIPT_DIR/lib/common.sh"

# 默认值
PROMPT=""
TASK_NAME=""
WORKDIR="$(pwd)"
TELEGRAM_GROUP=""
MODEL=""
TIMEOUT=3600

# 解析参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--prompt)
                PROMPT="$2"
                shift 2
                ;;
            -n|--name)
                TASK_NAME="$2"
                shift 2
                ;;
            -w|--workdir)
                WORKDIR="$2"
                shift 2
                ;;
            -g|--group)
                TELEGRAM_GROUP="$2"
                shift 2
                ;;
            -m|--model)
                MODEL="$2"
                shift 2
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
        esac
    done
}

# 显示用法
usage() {
    cat <<EOF
用法: dispatch.sh [选项]

选项:
  -p, --prompt     任务描述（必需）
  -n, --name       任务名称
  -w, --workdir    工作目录
  -g, --group      Telegram 群组 ID
  -m, --model      模型 (sonnet/opus/haiku)
  -t, --timeout    超时时间（秒）
  -h, --help       显示帮助

示例:
  dispatch.sh -p "实现一个爬虫"
  dispatch.sh -p "重构项目" -n refactor -w ~/projects/myapp
EOF
}

main() {
    parse_args "$@"
    
    if [ -z "$PROMPT" ]; then
        echo "错误: 需要指定任务描述 (-p/--prompt)" >&2
        usage
        exit 1
    fi
    
    # 使用配置或默认值
    TELEGRAM_GROUP="${TELEGRAM_GROUP:-$CONFIG_DEFAULT_GROUP}"
    
    # 生成任务 ID
    local task_id
    task_id=$(generate_task_id)
    local task_name="${TASK_NAME:-$task_id}"
    
    # 创建任务目录
    local task_dir
    task_dir=$(setup_task_dir "$task_id")
    
    # 写入 meta.json
    jq -n \
        --arg id "$task_id" \
        --arg name "$task_name" \
        --arg prompt "$PROMPT" \
        --arg workdir "$WORKDIR" \
        --arg group "$TELEGRAM_GROUP" \
        --arg model "$MODEL" \
        --arg timeout "$TIMEOUT" \
        '{
            task_id: $id,
            task_name: $name,
            prompt: $prompt,
            workdir: $workdir,
            telegram_group: $group,
            model: $model,
            timeout: ($timeout | tonumber),
            started_at: (now | strftime("%Y-%m-%dT%H:%M:%S%z"))
        }' > "$task_dir/meta.json"
    
    # 启动时间
    local start_time
    start_time=$(date +%s)
    
    log "INFO" "Starting task $task_name (ID: $task_id)"
    echo "📋 任务: $task_name"
    echo "📁 工作目录: $WORKDIR"
    echo "📝 任务: ${PROMPT:0:50}..."
    echo ""
    
    # 启动 Claude Code（后台运行）
    local output_file="$task_dir/output.txt"
    local claude_args=(--print)
    
    # 添加模型参数
    [ -n "$MODEL" ] && claude_args+=(-m "$MODEL")
    
    # 构建 Claude Code 命令
    # 注意：Claude Code 使用 --dangerously-skip-permissions 绕过权限
    # 使用 -p 指定 prompt，--print 输出结果
    cd "$WORKDIR"
    
    {
        echo "Task: $PROMPT"
        echo "---"
        # 执行 Claude Code（Mac 没有 timeout，用 perl 实现超时）
        perl -e 'alarm shift; exec @ARGV' "$TIMEOUT" claude "${claude_args[@]}" -p "$PROMPT" 2>&1 || true
    } | tee "$output_file" &
    
    local pid=$!
    
    echo "🚀 任务已启动 (PID: $pid)"
    echo "📂 结果将保存在: $task_dir"
    echo "💡 使用 'tail -f $output_file' 查看进度"
    echo ""
    echo "任务ID: $task_id"
    
    # 保存 PID 供后续使用
    echo "$pid" > "$task_dir/pid"
    
    log "INFO" "Task $task_id started with PID $pid"
}

main "$@"
