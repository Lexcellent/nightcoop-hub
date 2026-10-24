# Windows 原生运行指南

支持 Windows 10/11 x64，无需 Docker 或 WSL。源码需要支持 C++20（包括 `std::format`）的编译器。

## 编译

安装 Visual Studio 2022 或更新版本（也可使用 Build Tools），勾选：

- 使用 C++ 的桌面开发
- Windows SDK
- 适用于 Windows 的 C++ CMake 工具（CMake 3.24 或更新版本）

在项目根目录打开 PowerShell：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\hub\windows\build.ps1
```

脚本自动查找 CMake 并生成 x64 Release 版本：`build\windows\Release\nightcoop_hub.exe`。
第一次配置需要 Git 和网络，以获取与 Docker 构建相同的 ENet 固定版本。
已有离线源码时，可传入 `-EnetSourceDir D:\deps\enet`，该目录应检出到
`5a9c537fd464b3c6d3c55e1d3bd47588faf71b42`。

也可以从 Visual Studio 的开发者 PowerShell 手动构建：

```powershell
cmake -S . -B build/windows -A x64
cmake --build build/windows --config Release --parallel
```

## 启动

`start.ps1` 只负责启动，不会自动编译。请先完成上面的编译步骤，并确认
`build\windows\Release\nightcoop_hub.exe` 已存在。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\hub\windows\start.ps1
```

首次运行会生成 `data\hub-sign.key`，随后在控制台输出 fingerprint。备份此文件并限制其 Windows 文件权限，
只允许运行服务器的账户和管理员访问。Windows 使用文件 ACL，不使用 Linux 的 `0600` 权限模式。
后续启动复用该密钥，删除或更换密钥会改变服务器指纹。按 Ctrl+C 停止服务器。

看到下面的日志就表示服务已启动；保持窗口运行：

```text
hub: listening on 47800 ...
hub: listening on 47810 ...
2 threads: entry port 47800, the others' ports — 47810 (they must be open, like the entry one)
Ctrl-C to exit
```

这是两个线程的示例；默认 `-Shards auto` 会按可用 CPU 核数选择线程数，实际端口以启动日志为准。
监听成功表示本机服务已启动，公网是否可访问还取决于防火墙、路由器和云服务器安全组。

启动参数示例（每项参数的说明也写在脚本中）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\hub\windows\start.ps1 -Port 47800 -Shards 4 -MaxClients 512 -HubName 'My hub' -Region 'Asia'
```

需要其他参数时直接运行可执行文件：

```powershell
# 运行 5 秒，验证两个线程的监听、密钥加载和正常退出。
.\build\windows\Release\nightcoop_hub.exe 47800 --shards 2 --seconds 5 --sign-key data\hub-sign.key
# 随时查看公钥和指纹。
.\build\windows\Release\nightcoop_hub.exe --hub-public data\hub-sign.key
```

## 网络

两个线程使用 UDP **47800** 和 **47810**。下面的规则放行入口端口及更大的线程端口范围，
适用于以后增加线程的情况。

在管理员 PowerShell 中添加 Windows 防火墙入站规则（每台机器执行一次）：

```powershell
New-NetFirewallRule -DisplayName 'NightCoop hub entry' -Direction Inbound -Action Allow -Protocol UDP -LocalPort 47800
New-NetFirewallRule -DisplayName 'NightCoop hub shards' -Direction Inbound -Action Allow -Protocol UDP -LocalPort 47810-47873
```

如果服务器在路由器后面，还需要将这些 UDP 端口转发到服务器的局域网 IP；云服务器也需要放行安全组。
自定义入口端口时同步调整规则，其他线程从入口端口 + 10 开始监听。
将控制台输出的地址和指纹（例如 `hub.example.org#K3QF-9X2M-TV7A-0D4R`）交给玩家，
在游戏的“Server → Add an own server”中添加。

例如公网 IP 为 `203.0.113.7`，日志中的指纹为 `K3QF-9X2M-TV7A-0D4R`，游戏中填写：

```text
203.0.113.7#K3QF-9X2M-TV7A-0D4R
```

请替换成自己的公网 IP 和日志中的实际指纹。私钥文件 `hub-sign.key` 无需交给玩家。

## 复制到另一台 Windows 电脑

生成的 `build/` 目录不会提交到 Git，因此仅克隆或复制仓库源码不包含 EXE。
可以在目标电脑编译，也可以从已编译的电脑复制文件，保持以下目录结构：

```text
nightcoop-hub/
  build/windows/Release/nightcoop_hub.exe
  tools/hub/windows/start.ps1
  data/hub-sign.key                       # 迁移已有服务器时复制；新服务器首次启动时生成
```

缺少的目录可手动创建。Release 版静态链接 MSVC 运行库，目标电脑无需安装 Visual Studio。
如果是迁移已有服务器，请停止旧服务并安全复制其密钥，以保持原来的服务器指纹。

## 常见问题

| 现象 | 处理方式 |
|---|---|
| `Build the Release executable first` | 先运行 `build.ps1`，或将 EXE 放到项目根目录下的 `build\windows\Release\nightcoop_hub.exe` |
| `Install Visual Studio 2022 or newer...` | 安装上述 C++ 编译组件，或从已编译电脑复制 EXE |
| ENet 下载失败 | 检查 Git 网络或代理设置，或用 `build.ps1 -EnetSourceDir D:\deps\enet` 指定离线源码 |
| 已监听，但玩家连接不上 | 检查公网 IP、UDP 防火墙、安全组、路由器转发和日志中全部监听端口；运营商 NAT 环境需另行提供可访问的公网入口 |
| 游戏提示密钥不匹配 | 核对地址中的指纹；更换过密钥时需要更新游戏里保存的服务器指纹 |

Windows 版本沿用原有协议、加密和会话功能。Linux/Docker 的运行方式见
[原有指南](../docker/README.md)。
