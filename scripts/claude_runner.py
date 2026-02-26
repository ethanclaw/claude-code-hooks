#!/usr/bin/env python3
"""
Claude Code Runner - 后台启动 Claude Code (非阻塞)
"""

import argparse
import os
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description="Run Claude Code in background (non-blocking)")
    parser.add_argument("-p", "--prompt", required=True, help="Prompt for Claude Code")
    parser.add_argument("-w", "--workdir", default=os.getcwd(), help="Working directory")
    parser.add_argument("-m", "--model", help="Model to use")
    parser.add_argument("-o", "--output", required=True, help="Output file")
    parser.add_argument("--extra", help="Extra arguments for claude")
    parser.add_argument("--dangerously-skip-permissions", action="store_true", help="Skip permissions")
    args, unknown = parser.parse_known_args()
    
    # 构建命令
    cmd = ["claude", "--dangerously-skip-permissions"]
    
    if args.model:
        cmd.extend(["-m", args.model])
    
    # 添加 prompt
    cmd.extend(["-p", args.prompt])
    
    # 设置工作目录
    cwd = args.workdir
    if not os.path.isdir(cwd):
        cwd = os.getcwd()
    
    # 设置环境
    env = os.environ.copy()
    env["CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"] = "1"
    
    # 启动子进程（不等待）
    # 使用 nohup 保持后台运行
    subprocess.Popen(
        cmd,
        cwd=cwd,
        stdin=subprocess.DEVNULL,
        stdout=open(args.output, "w"),
        stderr=subprocess.STDOUT,
        env=env,
        start_new_session=True
    )
    
    print("Task started in background", file=sys.stderr)
    sys.exit(0)


if __name__ == "__main__":
    main()
