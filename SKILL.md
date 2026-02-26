---
name: claude-hooks
description: 后台调用 Claude Code 执行任务，任务完成后自动通知。支持派发任务、结果查看、Hook 管理。
metadata: {"openclaw":{"emoji":"🪝"}}
---

# Claude Code Hooks

后台调用 Claude Code 执行任务，任务完成后自动通知。

## 能力

### dispatch
在后台启动 Claude Code 执行任务。

```bash
claude-hooks dispatch -p "任务描述" [-n name] [-w workdir] [-g group] [-m model]
```

### install
注册 Claude Code Hook 到 ~/.claude/settings.json

```bash
claude-hooks install
```

### uninstall
移除已注册的 Hook

```bash
claude-hooks uninstall
```

### results
查看任务结果

```bash
claude-hooks results [task-id]
```
