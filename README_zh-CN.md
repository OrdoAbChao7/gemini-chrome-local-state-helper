<div align="center">
  <h1>gemini-chrome-local-state-helper</h1>
  <a href="./README.md"><b>English</b></a> | <b>中文</b>
</div>
<br>



<!-- portfolio-authenticity:start -->
## 项目状态

**当前阶段：**范围受限的离线恢复工具。

**为什么做这个项目：**我写这个工具是为了检查并可逆地修改少量 Chrome 本地字段，同时保留完整备份并避免使用远程脚本。

**适用边界：**它不能授予 Gemini 访问权限、改变账号资格、绕过企业策略或覆盖分阶段发布。它只适用于个人 Windows 配置文件，并应在检查官方 Chrome 和策略前置条件后使用。

关于仍需补充的验证证据和维护约定，请参阅 [PROJECT_STATUS.md](./PROJECT_STATUS.md)。
<!-- portfolio-authenticity:end -->

一个离线运行的 PowerShell 脚本，用于在 Windows 上对少量与 Gemini/Glic 相关的 Chrome Local State JSON 键进行备份、检查和编辑。

> **注意：** 本项目与 Google 无关。它不会赋予你 Gemini 访问权限、改变账号资格、绕过组织策略，或保证功能可用性。它只在 Chrome 关闭时编辑特定的 JSON 键（`glic.launcher_enabled`、`is_glic_eligible` 以及地区相关字段）。

## 安全机制

| 机制 | 行为 |
|---|---|
| Chrome 进程检查 | 检测到任何 `chrome.exe` 时立即停止，不写文件。 |
| 完整备份 | 写入前复制完整 `Local State` 文件，并记录 SHA-256 与修改摘要。 |
| 键级白名单 | 仅处理 README 列出的 Gemini/Glic 相关键。 |
| 原子写入 | 先写入临时文件、验证 JSON，再替换原文件。 |
| 读后验证 | 写入后重新解析 JSON，并验证 `glic.launcher_enabled`。 |
| 一键恢复 | 恢复前会再保存当前文件副本，并校验恢复后 SHA-256。 |
| 无网络行为 | 脚本不下载、上传或发送任何数据。 |

## 使用前提

请从 GitHub 克隆或下载该项目，务必不要使用 `irm | iex` 等远程管道执行方式。运行脚本前必须完全退出 Chrome；必要时在任务管理器确认没有 `chrome.exe`。

```powershell
git clone https://github.com/OrdoAbChao7/gemini-chrome-local-state-helper.git
cd gemini-chrome-local-state-helper
```

先检查当前最小状态：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Inspect-GeminiChrome.ps1
```

先预览拟修改项，不写文件：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Enable-GeminiChrome.ps1 -Region US -DryRun
```

执行一次带备份的配置操作：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Enable-GeminiChrome.ps1 -Region US
```

默认备份目录为：

```text
%USERPROFILE%\Documents\ChromeLocalStateBackups
```

恢复最近一次项目备份：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Restore-GeminiChrome.ps1 -Latest
```

如果只希望调整 Glic 相关值而不修改现有地区键：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Enable-GeminiChrome.ps1 -SkipRegion
```

## 测试

测试不读取真实浏览器数据；它在临时目录中使用公开的假 Local State 文件，验证启用、备份、恢复与文件哈希一致性。

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
```

## 已知边界

Chrome 本地配置不是 Google 的资格系统。即使脚本验证成功，Gemini 图标仍可能因为账号、地区、语言、Chrome 版本、组织策略或服务端灰度而不出现。[1] Chrome 的 `Local State` 是用户配置文件的一部分，因此请只在自己的个人设备上运行，并保留至少一个可验证备份。

## 项目结构

```text
scripts/
  Enable-GeminiChrome.ps1    # 安全应用：备份、白名单、原子写入、校验
  Restore-GeminiChrome.ps1   # 备份校验恢复
  Inspect-GeminiChrome.ps1   # 最小只读状态
examples/
  README.md                  # 支持的命令示例
 tests/
  fixtures.local-state.json  # 人工构造的样例文件；不含用户数据
  Run-Tests.ps1              # 离线集成测试
```

## 贡献

欢迎为安全性改进、测试、文档与兼容性研究提交贡献。请不要提交真实的 `Local State` 文件、备份、浏览器 Profile、账号信息、密钥或任何可识别的浏览数据。任何新的改动必须保留项目的核心保证：Chrome 关闭检查、完整备份、显式键白名单、JSON 校验以及可测试的恢复路径。

## 许可证

MIT。参见 [LICENSE](LICENSE)。

## 参考

[1]: https://support.google.com/chrome/a/answer/17034724?hl=zh-Hans "Google: Troubleshoot Gemini in Chrome"
