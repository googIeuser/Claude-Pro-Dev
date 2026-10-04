# Maintaining and publishing releases

Repository: [googIeuser/Claude-Pro-Dev](https://github.com/googIeuser/Claude-Pro-Dev). Maintainer: Musa ([googIeuser](https://github.com/googIeuser)).

## Source updates

Clone the existing repository rather than creating a second one:

```powershell
git clone https://github.com/googIeuser/Claude-Pro-Dev.git
Set-Location .\Claude-Pro-Dev
```

Use your own Git commit identity. Confirm it with `git config user.name` and `git config user.email`. Commits in this project should identify the maintainer; do not append automated co-author trailers.

Before pushing changes:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-release.ps1
claude plugin validate . --strict
claude plugin validate .\plugins\prodev --strict
claude plugin test .\plugins\prodev
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\release.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\install.Tests.ps1
git add .
git diff --cached --stat
git commit -m "Describe the change"
git push origin main
```

Include the refreshed root `install.ps1`; exclude ignored `dist/` assets. Review source files for private data. The archive allowlist does not sanitize secrets placed in included files.

The CI workflow checks PowerShell 5.1/7 with pinned Claude 2.1.287/2.1.289. It downloads native binaries using the official Claude installer. Native and isolated installer tests require no model credentials. Check actual results in [Actions](https://github.com/googIeuser/Claude-Pro-Dev/actions).

## Versioned releases

After the reviewed commit passes CI, create and push a matching tag:

```powershell
git tag v0.1.0
git push origin v0.1.0
```

Pushing a version tag triggers **Release**. It reruns CI and creates a GitHub release only after checks pass, with `install.ps1`, `claude-pro-dev-v0.1.0.zip` and `SHA256SUMS.txt`. The release job requires Actions enabled and permission for GITHUB_TOKEN to write contents; organization policy may block it. Check the job result before sharing a release download URL.

The initial source upload does not itself create a version tag or release. Enable private vulnerability reporting in repository settings and test the published installer in a clean Windows environment before extending live UI claims.

## Installation URLs

The source installer works after the root file is pushed to main:

```powershell
irm 'https://raw.githubusercontent.com/googIeuser/Claude-Pro-Dev/main/install.ps1' | iex
```

For a pinned version, use the release URL after the matching release appears:

```powershell
irm 'https://github.com/googIeuser/Claude-Pro-Dev/releases/download/v0.1.0/install.ps1' | iex
```

## Future versions

For v0.1 the installer/verifier deliberately expect 0.1.0. Update plugin/marketplace versions, expected-version checks/messages in `scripts/install.template.ps1` and `scripts/verify.ps1`, release test expectations, READMEs and CHANGELOG before changing version. Add `docs/releases/vX.Y.Z.md`, rebuild and rerun checks.

The builder names assets from the plugin manifest; Release rejects a mismatched tag. Do not reuse a published tag for changed code.
