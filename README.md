# PCL.Mac.Daemon

[PCL.Mac](https://github.com/CeciliaStudio/PCL.Mac) 守护进程，用于在启动器崩溃时自动导出日志。

## 使用方法

### 启动守护进程

```bash
daemon <pid> <flag_path>
```

- `pid`：PCL.Mac 进程的标识符。
- `flag_path`：正常退出标记文件路径。

当 PCL.Mac 进程退出后，守护进程会检查 `flag_path` 是否存在。  
- 如果不存在，表示正常退出，无需进一步操作。  
- 如果存在，守护进程会轮询 20 次（每次间隔 0.5 秒），监测 `~/Library/Logs/DiagnosticReports` 目录下是否有新文件。若发现文件名以 `PCL.Mac` 开头，则导出诊断报告。

### 报告导出说明

守护进程会在桌面创建名为 `PCL.Mac-crash-{crash_time_interval}` 的文件夹，包含以下内容：
- 诊断报告 (`.ips` 文件，来自 `~/Library/Logs/DiagnosticReports`)
- 启动器日志 (`.log` 文件，来自 `~/Library/Application Support/PCL-Mac/app.log`)
