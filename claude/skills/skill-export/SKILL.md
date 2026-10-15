---
name: skill-export
description: デスクトップ版Claudeのセッションで今作成・更新したスキルを、SKILL.md や scripts/ などフォルダ構成ごとPC(Windows)の受け渡しフォルダへ書き出すスキル。書き出したスキルはWSL側のfish関数 skill-import でdotfilesに取り込む。ユーザーが「/skill-export」と入力したとき、または skill-creator でスキルを作り終えた・直したあとに「これをdotfilesに保存して」「ローカルに書き出して」「エクスポートして」「スキルのファイルを手元に落として」のように、そのスキルをローカルのファイルとして取り出したいと言ったときは必ずこのスキルを使うこと。スキルを新規作成・改善する作業そのものは skill-creator の役目なので、そちらを優先する。
---

# skill-export

このセッションで今作成・更新したスキルを1つ、PCの受け渡しフォルダへ書き出す。
アプリ上のスキルはクラウドの作業環境にあるだけで、ユーザーの手元には SKILL.md も scripts/ も残らない。
dotfilesでgit管理するには、フォルダ構成そのままでローカルに置く必要がある。

書き出すのは1回につき1スキル。まとめて書き出す運用はしない。

## 構成と、受け渡しフォルダを使う理由

```
EXPORT_DIR = %USERPROFILE%\skill-export     # Windows側の受け渡しフォルダ
```

- 呼び出し元は基本的に **Windows版のデスクトップアプリ**。
- dotfilesはWSL側にあり、`%USERPROFILE%\.claude\skills` はそこへのシンボリックリンクになっている。
  しかしデスクトップアプリから**どちらにも直接は書けない**:
  - `%USERPROFILE%\.claude` はClaude自身のデータフォルダとして保護されていて、接続できない
  - WSL側(`\\wsl.localhost\...`)はネットワークパス扱いで、ブリッジが扱えない
- そこで、普通のWindowsフォルダ `EXPORT_DIR` にいったん書き出し、WSL側でユーザーが
  fish関数 `skill-import` を実行してdotfilesへ取り込む。実行権限の付け直し、既存ファイルとの差分表示、
  取り込み後の受け渡しフォルダの掃除は `skill-import` が行うので、このスキルではやらない。
- ユーザーが会話中に別のパスを指示したら、そちらを優先する。

## 手順

### 1. 対象のスキルを特定する

会話の流れから「今作成・更新したスキル」を特定する。ほとんどの場合、skill-creator が作業ディレクトリに
作ったスキルフォルダ(SKILL.md があるフォルダ)がそれにあたる。ユーザーに聞き直さなくてよい。

- 作業ディレクトリのフォルダが見つかれば、そのパスを使う。インストール済みの版より新しいので、
  こちらを優先する(更新した内容を書き出すのが目的のため)。
- 作業ディレクトリに無く、ユーザーがスキル名を言っている場合だけ、インストール済みのスキル名を使う。
- 候補が2つ以上あって判断できないときだけ、どれを書き出すか一言聞く。

### 2. ファイルをまとめる

`--out` は `/mnt/user-data/outputs/` の下にする。PCへ書き込むツール(`device_commit_files`)は
この下のファイルしか受け付けないため。

```bash
python3 <このスキルのディレクトリ>/scripts/export_skill.py <スキルフォルダのパス or スキル名> --out /mnt/user-data/outputs/skill-export
```

スクリプトがやること:
- スキルフォルダを `<out>/<name>/` にコピーする(`evals/`, `*-workspace/`, `*.skill` など skill-creator の作業用ファイルは除く)
- 同じ内容の `<out>/<name>.zip` を作る(PCに書けなかったときの予備)
- `<out>/files.json` にスキルフォルダ内の相対パス・サイズ・sha256を記録する

### 3. 受け渡しフォルダへ書き出す

PC用のツールは `mcp__remote-devices__` で始まる(見当たらなければ ToolSearch で探す)。

1. **フォルダの確認**: `get_device_info` の `connectedFolders` に `EXPORT_DIR` があるか見る。
   無ければ `device_request_folder_access` で `~/skill-export` へのアクセスを1回だけ求める。
   フォルダが存在しないと言われたら、「WSLで `skill-import` を一度実行すると受け渡しフォルダが作られる」と
   伝えて、zipを送る(下の「書き出せなかった場合」)。
2. **残りものの確認**: `EXPORT_DIR\<name>\` が既にあれば、前回書き出してまだ取り込んでいないものが残っている。
   書き出しはファイルを上書きするだけで削除はできないため、そのままだと前回の不要なファイルが混ざる。
   報告で「前回の書き出しが残っていたので、`skill-import` の差分表示で確認してほしい」と一言添える。
3. **書き出し**: `device_commit_files` で、`files.json` の各ファイルを
   `stagedPath = /mnt/user-data/outputs/skill-export/<name>/<path>`、
   `devicePath = <EXPORT_DIRの実パス>\<name>\<path>`(`/` は `\` に読み替える)として、1回の呼び出しでまとめて書く。
   ファイルはバイト単位でそのまま書かれるので、改行コード(LF)は変わらない。
4. **確認**: 結果の `rejected` が空であることを確かめる。

**書き出せなかった場合**(PCとつながっていない、フォルダが無い、拒否されたなど)は、
`<name>.zip` を SendUserFile で送り、理由を一言添える。

### 4. 報告

短く伝える:
- 書き出したスキル名と場所(`EXPORT_DIR\<name>`)
- 「WSLで `skill-import` を実行するとdotfilesに取り込まれます」
- 前回の書き出しが残っていた場合はその旨

このスキルの役目はエクスポートまで。`skill-import` の実行や、`git add`・コミット・コミットメッセージの提案などは
ユーザーが自分で行うので、実行も提案もしない(`skill-import` の案内だけはする)。
