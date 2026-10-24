# NightCoop hub — run your own server

*Русская версия инструкции — [tools/hub/docker/README.ru.md](tools/hub/docker/README.ru.md).*

The NightCoop hub is the small server that players of [NightCoop](https://nightcoop.net) (a co-op mod for Cyberpunk 2077)
meet through: it hands out session codes, helps two players behind home routers open a direct path to each other and relays
the game traffic when no direct path opens. The game itself is end-to-end encrypted between the players — the hub only
forwards sealed packets.

This repository holds only what the hub is built from. The mod itself is not here.

## Quick start (Windows)

Windows 10/11 x64 can run the hub directly, without Docker or WSL. Install Visual Studio 2022 or newer with
**Desktop development with C++** and **C++ CMake tools for Windows**, then run from the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\hub\windows\build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\hub\windows\start.ps1
```

Build before starting: `start.ps1` only launches an existing executable. The executable is
`build/windows/Release/nightcoop_hub.exe`; generated binaries are not included in Git. To run on another Windows x64
machine, copy the executable into the same relative directory alongside the startup script, or build on that machine.
The compiled Release executable uses the static MSVC runtime, so the destination machine does not need Visual Studio.

On first start, the hub creates `data/hub-sign.key` and prints its fingerprint. Keep the console open and back up this
key; subsequent starts reuse it. Press Ctrl+C to stop. Open the entry UDP port **47800** and the shard ports printed in
the log (for two threads: **47800** and **47810**) in Windows Firewall and any cloud security group or router forwarding
rules. Players add `YOUR_PUBLIC_IP#YOUR_FINGERPRINT` in **Server → Add an own server**.

See the [Windows guide (中文)](tools/hub/windows/README.md) for build troubleshooting, firewall commands and startup options.

## Quick start (Docker)

```sh
cd tools/hub/docker
cp .env.example .env          # optional: port, threads, name, region
docker compose up -d --build
docker compose logs hub | grep fingerprint
```

Open UDP **47800** and **47810–47873**, then give your players the address with the fingerprint, for example
`hub.example.org#K3QF-9X2M-TV7A-0D4R`. In the game: the mod menu "Co-op" → "Server: …" → "Add an own server".

**The full guide** — requirements, ports, keeping the key, updates, building without Docker:
[tools/hub/docker/README.md](tools/hub/docker/README.md).

## What is inside

| Path | What |
|---|---|
| `CMakeLists.txt` | native CMake build, including Windows x64 |
| `tools/hub/main.cpp` | the hub program (`nightcoop_hub`) |
| `src/` | the hub server, transport crypto and log |
| `tools/hub/windows/` | PowerShell build/start scripts and the Windows guide |
| `tools/hub/docker/` | Dockerfile, Compose file, settings example and the guide |
| `vendor/monocypher/` | Monocypher 4.0.2 — BSD-2-Clause or CC0 1.0 (`LICENCE.md`) |

ENet is not stored here: the build fetches the exact commit it is tested with from https://github.com/lsalzman/enet.
