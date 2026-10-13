# Contributing

English and Turkish contributions are welcome. Please follow the [code of conduct](CODE_OF_CONDUCT.md).

## Choose the right channel

- Questions and installation help: [SUPPORT.md](SUPPORT.md).
- Reproducible bugs and focused proposals: [issue forms](https://github.com/googIeuser/Claude-Pro-Dev/issues/new/choose). Search existing issues first.
- Security vulnerabilities: the private channel in [SECURITY.md](SECURITY.md), not a public issue or pull request.

For substantial changes, describe the user problem and proposed behavior in an issue before investing in a large implementation. Small corrections can go straight to a pull request. Keep one problem per pull request and explain dependency, settings, permission, and subscription-usage implications.

## Development setup

Use Windows PowerShell 5.1 or PowerShell 7 and Claude Code 2.1.293+. Claude's native engine runs the plugin tests; no package manager is needed.

Keep changes focused. Preserve project instructions and Claude permissions. Avoid background polling, unsolicited model requests/agents, raw secret logging and broad truncation. Explain the benefit before adding dependencies.

For behavior changes add a regression test that fails before the fix. Native tests live in `plugins/prodev/tests/`; installer/release tests live in `tests/` and use temporary folders. Test permission-chain behavior with synthetic events, not destructive real commands. Use fake secrets. Advisor/team prompt behavior needs a signed-in manual scenario; static text checks do not prove model behavior.

Run the README validation/build commands, then also run:

```powershell
pwsh.exe -NoProfile -File .\tests\release.Tests.ps1
pwsh.exe -NoProfile -File .\tests\install.Tests.ps1
```

Rebuild after changing embedded files and include refreshed root `install.ps1`. Do not commit `dist/`, account configuration, transcripts, private paths or credentials. The archive allowlist does not sanitize included source files.

Describe the problem, resulting behavior and validation in pull requests. Explain model/tool overhead, false positives or possible evidence loss. Report live UI and A/B results separately from native tests; use [the benchmark protocol](docs/BENCHMARK.md).

When investigating native Mods compatibility, use `/plugin-types` to generate types for your installed version. Do not commit account-specific generated output.

## Review and license

Use the pull request template to explain the result and verification. State which checks were not run and why; documentation-only changes do not need a paid model test. Maintainer feedback may request a smaller scope or additional evidence. Contributions are distributed under this project's [MIT license](LICENSE).

## Türkçe

Türkçe ve İngilizce katkı kabul edilir. [Davranış kurallarına](CODE_OF_CONDUCT.md) uy. Kullanım sorularında [destek rehberini](SUPPORT.md), güvenlik açıklarında [özel bildirim kanalını](SECURITY.md) kullan. Büyük işe başlamadan önce problemi ve önerilen davranışı issue'da anlat; küçük düzeltme doğrudan PR olabilir.

Windows PowerShell 5.1/7 ve Claude Code 2.1.293+ kullan. Davranış değişikliğinde hatayı önce gösteren regresyon testi ekle. README'deki doğrulama ve paket komutlarını çalıştır; gömülü dosyalar değiştiğinde kökteki `install.ps1` dosyasını yeniden üret. Belgeler için ücretli/canlı model testi gerekmez.

PR'da problemi, değişen davranışı, çalıştırılan/çalıştırılmayan kontrolleri ve model kullanımına etkisini belirt. Gerçek sırları, hesap ayarlarını, konuşma kayıtlarını, kişisel yolları veya `dist/` çıktısını commit etme. Katkılar projenin MIT lisansı kapsamındadır.
