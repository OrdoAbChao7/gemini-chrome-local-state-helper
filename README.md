<div align="center">
  <h1>gemini-chrome-local-state-helper</h1>
  <b>English</b> | <a href="./README_zh-CN.md"><b>中文</b></a>
</div>
<br>



<!-- portfolio-authenticity:start -->
## Project status

**Stage:** Narrow, offline recovery helper.

**Why I built it:** I built this to inspect and reversibly edit a small set of local Chrome values while keeping a full backup and avoiding remote scripts.

**Boundary:** It cannot grant Gemini access, change account eligibility, bypass enterprise policy, or override staged rollout. It is for a personal Windows profile only and should be used after checking official Chrome and policy prerequisites.

See [PROJECT_STATUS.md](./PROJECT_STATUS.md) for the evidence still needed and the maintenance rule.
<!-- portfolio-authenticity:end -->

> A small, offline PowerShell helper for backing up, inspecting, applying, and restoring a narrow set of Gemini/Glic-related Chrome Local State values on Windows.
>
> This project is not affiliated with Google. It does not grant Gemini access, change Google account eligibility, bypass organization policies, or guarantee feature availability. Gemini in Chrome remains subject to Google account, region, language, Chrome version, enterprise policy, and server-side rollout requirements.[1]

## What it does

This offline PowerShell project performs a narrow, reversible Local State operation for Gemini/Glic-related keys. It requires Chrome to be closed, creates a full-file backup, writes only allowlisted keys, validates the JSON, and provides a tested restore path.

- Only handles the minimal allowlist of keys: `glic.launcher_enabled`, `is_glic_eligible` for existing profiles, and optionally `variations_country` / `variations_safe_seed_session_consistency_country` / `permanent_country`.
- Does not download remote scripts, modify the registry or Chrome policies, or touch browser profiles, bookmarks, cookies, history, extensions, or system settings.
- Does not grant access to Gemini in Chrome or override account, regional, policy, or rollout requirements.[1]

Google’s official troubleshooting guidance recommends checking your Chrome version, Gemini-related entries in `chrome://policy`, supported region/language, and staged rollout status first.[1] This project cannot replace those prerequisites. Managed school or enterprise devices should not attempt to circumvent organizational policy.

## Safety mechanisms

| Mechanism | Behavior |
|---|---|
| Chrome process check | If any `chrome.exe` is detected, the script stops immediately and does not write files. |
| Full backup | Before writing, makes a full copy of the `Local State` file and records its SHA-256 and a change summary. |
| Key-level allowlist | Only processes the Gemini/Glic-related keys listed in this README. |
| Atomic write | Writes to a temporary file first, validates JSON, then replaces the original. |
| Post-write verification | Re-parses JSON after writing and verifies `glic.launcher_enabled`. |
| One-click restore | Saves a copy of the current file before restoring, and verifies the restored SHA-256. |
| No network activity | The script does not download, upload, or send any data. |

## Before you begin

Clone or download this project from GitHub. Do not use remote pipeline execution such as `irm | iex`. Fully exit Chrome before running the scripts; if needed, confirm there is no `chrome.exe` in Task Manager.

```powershell
git clone https://github.com/OrdoAbChao7/gemini-chrome-local-state-helper.git
cd gemini-chrome-local-state-helper
```

Check your current minimal status:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Inspect-GeminiChrome.ps1
```

Preview intended changes without writing files:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Enable-GeminiChrome.ps1 -Region US -DryRun
```

Apply once with backup:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Enable-GeminiChrome.ps1 -Region US
```

Default backup directory:

```text
%USERPROFILE%\Documents\ChromeLocalStateBackups
```

Restore the latest project backup:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Restore-GeminiChrome.ps1 -Latest
```

If you only want to adjust Glic-related values without modifying existing region keys:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Enable-GeminiChrome.ps1 -SkipRegion
```

## Tests

Tests do not read real browser data; they use a public synthetic Local State fixture in a temporary directory to verify enable, backup, restore, and file hash consistency.

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
```

## Known limitations

Chrome’s local configuration is not Google’s eligibility system. Even if the script verifies successfully, the Gemini icon may still not appear due to account, region, language, Chrome version, organization policy, or server-side rollout.[1] Chrome’s `Local State` is part of the user profile; run this only on your own personal device and keep at least one verifiable backup.

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
