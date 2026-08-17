# Safe command examples

All examples assume Chrome is completely closed. Start with a read-only check and a dry run.

```powershell
# Read only
powershell -ExecutionPolicy Bypass -File .\scripts\Inspect-GeminiChrome.ps1

# Preview only; no backup and no write
powershell -ExecutionPolicy Bypass -File .\scripts\Enable-GeminiChrome.ps1 -Region US -DryRun

# Apply with a full-file backup
powershell -ExecutionPolicy Bypass -File .\scripts\Enable-GeminiChrome.ps1 -Region US

# Inspect after restart
powershell -ExecutionPolicy Bypass -File .\scripts\Inspect-GeminiChrome.ps1

# Restore the most recent helper-created backup
powershell -ExecutionPolicy Bypass -File .\scripts\Restore-GeminiChrome.ps1 -Latest
```

Do not use this project to bypass school or company policies. If `chrome://policy` shows `GeminiSettings` or `GeminiActOnWebSettings` configured by an organization, contact its administrator instead.[1]

[1]: https://support.google.com/chrome/a/answer/17034724?hl=zh-Hans "Google: Troubleshoot Gemini in Chrome"
