# cspell-dict-syntax

Code Spell Checker 用の辞書ファイル（`~/dotfiles/cspell/*.txt`）を色分けするローカル拡張機能。

## 書式

- `#` で始まる行：コメント（プロジェクト見出し・単語の説明）→ Dark+ では緑
- それ以外の行：1行1単語 → Dark+ では水色

## 対象ファイル

`package.json` の `filenamePatterns` で `**/dotfiles/cspell/*.txt` に限定している。
置き場所を変えるときはここを書き換えて再パッケージする。

## ビルドとインストール

```fish
cd ~/dotfiles/vscode/cspell-dict-syntax
npx @vscode/vsce package --skip-license --allow-missing-repository
code --install-extension cspell-dict-syntax-0.1.0.vsix
```
