# Security

## Supported versions

Security fixes target the latest code on `main` (currently Pro Dev **0.3.3**). Older revisions are not maintained separately; update before reproducing a report. Claude Code itself is maintained by Anthropic; report host defects through Anthropic's channels.

## Report a vulnerability privately

Use **[Security → Report a vulnerability](https://github.com/googIeuser/Claude-Pro-Dev/security/advisories/new)**. This repository accepts private vulnerability reports through GitHub. Do not open a public issue containing exploit details, credentials, private code, or account information.

Include the affected version/commit, Claude Code and PowerShell versions, impact, minimal reproduction with synthetic data, expected/actual behavior, and any proposed mitigation. If the private form is temporarily unavailable, open only a non-sensitive issue asking for a private channel; keep vulnerability details private.

Musa ([googIeuser](https://github.com/googIeuser)) reviews reports as time permits and coordinates fixes and disclosure through the advisory. There is no guaranteed response or resolution deadline. Please keep details private while a report is assessed. Ordinary bugs and questions belong in [SUPPORT.md](SUPPORT.md).

## Security boundaries

Pro Dev v0.3 retains best-effort output redaction and removes its command/file-name guard. It is not a sandbox or complete secret-protection system. Keep normal project security controls and Claude permission checks.

`/prodev-checks run <name>` explicitly runs a program from the reviewed `.prodev.json` as your user through the Mods process API. This is separate from model tool-call approval; project scripts are executable code and can perform arbitrary work. No profile is run automatically. Only profile structure and size are validated; commands and paths are not screened by keyword.

Redaction coverage limits include user prompts, tool inputs, old transcripts, other plugins and tool-written logs. A hook failure can preserve the original result. Advisor and team workflows retain Claude Code permissions and use the signed-in account's allowance; they add no separate credential storage or service.

Do not include real credentials in issues, screenshots, transcripts or pull requests. Use synthetic examples. Revoke or rotate exposed credentials with their provider.

Release checksums verify consistency, not publisher identity.

## Türkçe

Güvenlik düzeltmeleri `main` üzerindeki güncel sürüme uygulanır; eski sürümler ayrı bakıma alınmaz. Açığı [Security → Report a vulnerability](https://github.com/googIeuser/Claude-Pro-Dev/security/advisories/new) üzerinden özel olarak bildir. Etkilenen sürümü/commit'i, ortamı, etkisini ve sahte verilerle en küçük tekrar örneğini ekle. Açık ayrıntılarını, kimlik bilgilerini veya hesap dosyalarını herkese açık issue'ya koyma.

Bildirimleri Musa inceler; yanıt veya çözüm süresi taahhüt edilmez. Kanal geçici olarak kullanılamıyorsa yalnızca hassas bilgi içermeyen bir özel iletişim isteği aç. Normal sorular ve hatalar için [destek rehberini](SUPPORT.md) kullan. Pro Dev bir sandbox değildir; Claude Code izinlerini koru ve `.prodev.json` içindeki programları çalıştırmadan önce incele.
