#!/bin/bash
# 配置加载模块

# 自动检测项目根目录
detect_root() {
    local script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # scripts/lib/common.sh -> 上两级是根目录
    echo "$(dirname "$(dirname "$script_path")")"
}

# 加载配置
load_config() {
    local root="${1:-$(detect_root)}"
    local config_file="$root/config.yaml"
    
    if [ ! -f "$config_file" ]; then
        echo "ERROR: config.yaml not found at $config_file" >&2
        return 1
    fi
    
    # 解析 YAML 简单值（不支持复杂 YAML，仅支持 key: value）
    while IFS=: read -r key value; do
        # 跳过注释和空行
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${key// }" ]] && continue
        
        # 去除空白
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        case "$key" in
            root) CONFIG_ROOT="$value" ;;
            command) CONFIG_CLAUDE_CMD="$value" ;;
            default_model) CONFIG_DEFAULT_MODEL="$value" ;;
            default_group) CONFIG_DEFAULT_GROUP="$value" ;;
            results_dir) CONFIG_RESULTS_DIR="$value" ;;
            logs_dir) CONFIG_LOGS_DIR="$value" ;;
        esac
    done < "$config_file"
    
    # 替换 {root} 占位符
    CONFIG_RESULTS_DIR="${CONFIG_RESULTS_DIR//\{root\}/$root}"
    CONFIG_LOGS_DIR="${CONFIG_LOGS_DIR//\{root\}/$root}"
    CONFIG_ROOT="$root"
}

# 默认配置
CONFIG_ROOT=""
CONFIG_CLAUDE_CMD="claude"
CONFIG_DEFAULT_MODEL=""
CONFIG_DEFAULT_GROUP=""
CONFIG_RESULTS_DIR=""
CONFIG_LOGS_DIR=""

# 初始化
init_config() {
    local root="${1:-$(detect_root)}"
    load_config "$root"
    
    # 设置默认值
    CONFIG_CLAUDE_CMD="${CONFIG_CLAUDE_CMD:-claude}"
    CONFIG_RESULTS_DIR="${CONFIG_RESULTS_DIR:-$root/output}"
    CONFIG_LOGS_DIR="${CONFIG_LOGS_DIR:-$root/logs}"
    CONFIG_DEFAULT_GROUP="${CONFIG_DEFAULT_GROUP:--5260404039}"
}
