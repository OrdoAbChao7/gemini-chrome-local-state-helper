# Gemini Chrome Local State Helper

[English](#english) | [中文](#中文)

> A small, offline PowerShell helper for **backing up, inspecting, applying, and restoring** a narrow set of Gemini/Glic-related Chrome Local State values on Windows.
>
> **This project is not affiliated with Google. It does not grant Gemini access, change Google account eligibility, bypass organization policies, or guarantee feature availability.** Gemini in Chrome remains subject to Google account, region, language, Chrome version, enterprise policy, and server-side rollout requirements.[1]

## 中文

### 这是什么

这是一个可离线运行的 PowerShell 项目，用于自动化一套可恢复的 Chrome `Local State` 配置操作。它只处理以下最小白名单键：`glic.launcher_enabled`、已存在 Profile 的 `is_glic_eligible`、以及可选的 `variations_country` / `variations_safe_seed_session_consistency_country` / `permanent_country`。它不会下载脚本，不会改注册表、Chrome Policy、浏览器 Profile、书签、Cookie、历史记录、扩展或系统设置。

Google 的官方排障页建议先检查 Chrome 版本、`chrome://policy` 中的 Gemini 策略、支持的地区/语言以及逐步推出状态。[1] 本项目不能替代这些条件。尤其是受学校或企业管理的设备，不应绕过组织策略。

### 安全机制

| 机制 | 行为 |
|---|---|
| Chrome 进程检查 | 检测到任何 `chrome.exe` 时立即停止，不写文件。 |
| 完整备份 | 写入前复制完整 `Local State` 文件，并记录 SHA-256 与修改摘要。 |
| 键级白名单 | 仅处理 README 列出的 Gemini/Glic 相关键。 |
| 原子写入 | 先写入临时文件、验证 JSON，再替换原文件。 |
| 读后验证 | 写入后重新解析 JSON，并验证 `glic.launcher_enabled`。 |
| 一键恢复 | 恢复前会再保存当前文件副本，并校验恢复后 SHA-256。 |
| 无网络行为 | 脚本不下载、上传或发送任何数据。 |

### 使用前提

请从 GitHub 克隆或下载该项目，**不要**使用 `irm | iex` 等远程管道执行方式。运行脚本前必须完全退出 Chrome；必要时在任务管理器确认没有 `chrome.exe`。

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

### 测试

测试不读取真实浏览器数据；它在临时目录中使用公开的假 Local State 文件，验证启用、备份、恢复与文件哈希一致性。

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
```

### 已知边界

Chrome 本地配置不是 Google 的资格系统。即使脚本验证成功，Gemini 图标仍可能因为账号、地区、语言、Chrome 版本、组织策略或服务端灰度而不出现。[1] Chrome 的 `Local State` 是用户配置文件的一部分，因此请只在自己的个人设备上运行，并保留至少一个可验证备份。

## English

### What it does

This offline PowerShell project performs a narrow, reversible Local State operation for Gemini/Glic-related keys. It requires Chrome to be closed, creates a full-file backup, writes only allowlisted keys, validates the JSON, and provides a tested restore path.

It does **not** modify the registry or Chrome policies, download remote code, touch browser profiles, bookmarks, cookies, history, extensions, or system settings. It does not grant access to Gemini in Chrome or override account, regional, policy, or rollout requirements.[1]

### Quick start

```powershell
git clone https://github.com/OrdoAbChao7/gemini-chrome-local-state-helper.git
cd gemini-chrome-local-state-helper
powershell -ExecutionPolicy Bypass -File .\scripts\Inspect-GeminiChrome.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\Enable-GeminiChrome.ps1 -Region US -DryRun
powershell -ExecutionPolicy Bypass -File .\scripts\Enable-GeminiChrome.ps1 -Region US
```

Restore the latest project backup:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Restore-GeminiChrome.ps1 -Latest
```

Run offline tests against a synthetic fixture:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
```

## Project structure

```text
scripts/
  Enable-GeminiChrome.ps1    # safe apply: backup, allowlist, atomic write, verification
  Restore-GeminiChrome.ps1   # verified backup restoration
  Inspect-GeminiChrome.ps1   # minimal read-only status
examples/
  README.md                  # supported command examples
 tests/
  fixtures.local-state.json  # synthetic fixture; no user data
  Run-Tests.ps1              # offline integration test
```

## Contributing

Contributions are welcome for safety improvements, tests, documentation, and compatibility research. Do not submit real `Local State` files, backups, browser profiles, account details, secrets, or personally identifiable browsing data. Any new mutation must retain the project’s core guarantees: Chrome-closed check, full backup, explicit key allowlist, JSON validation, and tested restoration.

## License

MIT. See [LICENSE](LICENSE).

## References

[1]: https://support.google.com/chrome/a/answer/17034724?hl=zh-Hans "Google: Troubleshoot Gemini in Chrome"
