#!/bin/bash
# 输出解析模块

# 解析 Claude Code 输出
# 参数: output_file
parse_output() {
    local output_file="$1"
    
    if [ ! -f "$output_file" ]; then
        echo '{"error": "output file not found"}'
        return 1
    fi
    
    # 提取关键信息
    local content
    content=$(cat "$output_file")
    
    # 统计文件修改
    local files_changed
    files_changed=$(echo "$content" | grep -E "^[MARC]\s+" | head -20 | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')
    
    # 提取摘要（最后几行）
    local summary
    summary=$(echo "$content" | tail -c 2000)
    
    # 输出 JSON
    jq -n \
        --arg summary "$summary" \
        --arg files "$files_changed" \
        '{
            summary: $summary,
            files_changed: (if $files == "" then [] else ($files | split(",") | map(select(. != ""))) end)
        }'
}

# 生成结果 JSON
generate_result() {
    local task_id="$1"
    local task_name="$2"
    local status="$3"
    local duration="$4"
    local output_file="$5"
    local meta_file="$6"
    
    # 解析输出
    local parsed
    parsed=$(parse_output "$output_file")
    
    # 读取元数据
    local workdir model group
    workdir=$(jq -r '.workdir // ""' "$meta_file" 2>/dev/null || echo "")
    model=$(jq -r '.model // ""' "$meta_file" 2>/dev/null || echo "")
    group=$(jq -r '.telegram_group // ""' "$meta_file" 2>/dev/null || echo "")
    
    # 生成结果
    jq -n \
        --arg id "$task_id" \
        --arg name "$task_name" \
        --arg status "$status" \
        --arg duration "$duration" \
        --arg workdir "$workdir" \
        --arg model "$model" \
        --arg group "$group" \
        --argjson parsed "$parsed" \
        '{
            task_id: $id,
            task_name: $name,
            status: $status,
            duration_seconds: ($duration | tonumber),
            cwd: $workdir,
            model: $model,
            output: $parsed,
            notify: {
                telegram_group: $group,
                telegram_sent: false
            }
        }'
}
