# cspell-dict-syntax

Code Spell Checker 用の辞書ファイル (`~/dotfiles/config/cspell/*.txt`) を色分けするローカル拡張機能。

## 書式

- `#` で始まる行：コメント (プロジェクト見出し・単語の説明)→ Dark+ では緑
- それ以外の行：1行1単語 → Dark+ では水色

## 対象ファイル

`package.json` の `filenamePatterns` で次の2つに限定している。

- `**/dotfiles/config/cspell/*.txt`：dotfiles の実体を開いたとき
- `**/.config/cspell/*.txt`：WSL・Windows の `~/.config/cspell` (実体へのリンク) から開いたとき

置き場所を変えるときはここを書き換え、`version` を上げてから Ansible を実行する。

## ビルドとインストール

dotfiles の Ansible (vscode ロール) が、`vscode/extensions/` 直下の package.json があるフォルダを
`.vsix` にして Windows 側の VS Code に入れる。同じバージョンが入っていれば何もしないので、
中身を変えたら `package.json` の `version` を上げる。

```fish
~/dotfiles/ansible/run.sh --tags vscode
```
