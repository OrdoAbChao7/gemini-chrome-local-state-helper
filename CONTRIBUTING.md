# Contributing

Thank you for improving this safety-focused helper.

Please keep changes offline by default, preserve the Chrome-closed check, full-file backup, key allowlist, atomic JSON write, post-write validation, and restore test. Do not add functionality that downloads or executes remote scripts, writes Chrome enterprise policies, edits the Windows registry, bypasses managed-device policy, or collects browser data.

Never commit a real Chrome `Local State`, backup, profile directory, account information, cookies, browsing history, logs containing personal paths, or secrets. Use the synthetic fixture under `tests/` for all test cases.

Before opening a pull request, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
```
