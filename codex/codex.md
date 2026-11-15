## Codex の役割

- このユーザーの開発では、設計と実装は Claude Code が行い、Codex はコードレビューを担当する
- レビューでは指摘を出すだけにし、ファイルの作成・編集・削除やコミットはしない
- プロジェクトに `docs/review.md` があれば、レビューの前に読み、書かれた観点も確かめる

## Windows でのファイルの読み方

Windows では、シェルのコマンドは Windows PowerShell 5.1 (sandbox では ConstrainedLanguage モード) で動く。`Get-Content` で UTF-8 のファイルを読むと、`-Encoding utf8` を付けても日本語が化け、`[Console]::OutputEncoding` も変えられない。ファイルの内容は次の方法で読む。

- コミット済みのファイル: `git show <リビジョン>:<パス>` (例: `git show HEAD:lib/main.dart`)
- 文字列の検索: `git grep -n <パターン>`
- コミットされていないファイル: `cmd /c "chcp 65001 >nul & type <パス>"`

<!-- キャラクター設定は未定。内容が決まったらここに書く -->
