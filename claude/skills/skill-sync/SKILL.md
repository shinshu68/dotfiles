---
name: skill-sync
description: dotfiles側(WSLのClaude Codeなど)で更新したスキルを、デスクトップ版Claudeに登録されているスキルへ反映するスキル。WSLのfish関数 skill-push がWindowsの受け渡しフォルダ(%USERPROFILE%\skill-sync)に置いたスキルを読み込み、登録済みの版との差分を見せたうえで .skill ファイルにまとめて送り、「Save skill」ボタンで反映できるようにする。ユーザーが「/skill-sync」と入力したとき、または「skill-push したので反映して」「Claude Code で直したスキルをデスクトップにも入れて」「dotfiles のスキルをアプリ側に反映したい」「デスクトップ版のスキルを最新にして」のように、dotfiles側のスキルの変更をデスクトップ版へ取り込みたいと言ったときは必ずこのスキルを使うこと。逆向き(デスクトップ版で作ったスキルをdotfilesへ書き出す)は skill-export の役目なので、そちらを使う。
---

# skill-sync

dotfiles 側で更新したスキルを、デスクトップ版 Claude に登録されているスキルへ反映する。
skill-export(デスクトップ版 → dotfiles)の逆向き。

```
WSL:   skill-push <名前> ...   → %USERPROFILE%\skill-sync\<名前>\ にコピー(ユーザーが実行)
アプリ: /skill-sync            → 差分を見せて <名前>.skill を送る → ユーザーが「Save skill」で反映
```

## 前提と、この流れになっている理由

- デスクトップアプリからは WSL 側(`\\wsl.localhost\...`)も `%USERPROFILE%\.claude` も読めない
  (前者はネットワークパス扱いでブリッジが扱えず、後者は Claude 自身のデータフォルダとして保護されている)。
  そこで、WSL 側の fish 関数 `skill-push` が普通の Windows フォルダへコピーしておく。
- スキルの登録は、`.skill` ファイルを会話に送ったときに出るカードの「Save skill」ボタンで行う。
  scripts/ なども含めてフォルダごと置き換えられるのはこの方法なので、SKILL.md だけを扱う提案カードは使わない。
- `skill-push` は毎回、受け渡しフォルダを空にしてからコピーする。だから受け渡しフォルダにあるスキルは
  すべて「今回反映したいもの」として扱ってよい。デスクトップ側からはファイルを削除できないので、
  後片付けはせず次回の `skill-push` に任せる。

```
SYNC_DIR = %USERPROFILE%\skill-sync     # Windows側の受け渡しフォルダ
```

ユーザーが会話中に別のフォルダを指示したら、そちらを優先する。

## 手順

PC用のツールは `mcp__remote-devices__` で始まる(見当たらなければ ToolSearch で探す)。

### 1. 受け渡しフォルダを確認する

1. `get_device_info` の `connectedFolders` に `SYNC_DIR` があるか見る。無ければ
   `device_request_folder_access` で `~/skill-sync` へのアクセスを1回だけ求める。
   フォルダが存在しないと言われたら、「WSL で `skill-push <スキル名>` を実行してから、もう一度 `/skill-sync` を」と伝えて止まる。
2. `device_list_dir`(recursive)で中身を見る。直下にあって `SKILL.md` を含むフォルダが、反映対象のスキル。
   1つも無ければ、同じく `skill-push` の実行を案内して止まる。
3. ユーザーがスキル名を指定していれば、そのスキルだけに絞る。

### 2. ファイルを取り込む

`device_stage_files` で、対象スキルのファイルをすべて取り込む(1回50ファイルまでなので、多ければ分ける)。
取り込み先は `/mnt/user-data/uploads/skill-sync/<名前>/...` になる。
取り込んだファイルが見当たらないときは、少し待ってからもう一度読む。

### 3. 差分を確認して .skill を作る

```bash
python3 <このスキルのディレクトリ>/scripts/package_skills.py /mnt/user-data/uploads/skill-sync --out /mnt/user-data/outputs/skill-sync --only <名前> [<名前> ...]
```

`--only` には、手順1で決めた対象のスキル名(PC の受け渡しフォルダに今あるもの)を全部渡す。必須にしてある。
取り込み先の `/mnt/user-data/uploads/skill-sync/` には、同じセッションで前回取り込んだスキルが
残っていることがあり、フォルダの中身だけで対象を決めると前回分が混ざるため。

スクリプトがやること:
- 登録済みの版(インストール済みスキルの置き場所を自動で探す)とファイル単位で比べ、状態を判定する
  - `new`: まだ登録されていない / `updated`: 変更あり / `unchanged`: 変更なし / `error`: SKILL.md の不備など
- `new` と `updated` だけ `<out>/<名前>.skill` を作る(`evals/` や `*-workspace` など skill-creator の作業用ファイルは除く)
- 差分を `<out>/report.md` に、状態を `<out>/summary.json` に書く(標準出力にも report.md と同じ内容が出る)

登録済みの SKILL.md はフロントマターの値が引用符付きに書き換えられていることがあるが、
その違いだけなら変更なしとして扱うようになっている。

インストール済みスキルが見つからないと `new` になる。登録済みのはずのスキルが `new` になったら、
置き場所の探し方が環境に合っていない可能性がある。このスキル自身のディレクトリの親フォルダや
`/mnt/skills/*` を見て、見つけた場所を `--installed-root` で渡して実行し直す。

### 4. 差分を見せて .skill を送る

まず report.md をもとに、スキルごとの状態と変更点を短く伝える。
SKILL.md の変更は、何がどう変わったかを数行で要約する(差分をそのまま全部貼らない。
ユーザーは dotfiles 側で変更内容を把握しているので、反映前の確認ができれば十分)。

- `unchanged` のスキルは「反映済みなので送らない」と伝える。
- `error` のスキルは理由を伝え、dotfiles 側で直して `skill-push` し直すよう案内する。
- `new` のスキルは「デスクトップ版にはまだ無いので、新規に登録されます」と一言添える(取り違え防止)。

続けて、作った `.skill` ファイルを `SendUserFile` でまとめて送る(1回の呼び出しで全部)。

### 5. 報告

短く伝える:
- 送ったスキルの名前と、それぞれのカードの「Save skill」を押すと反映されること
  (スキルごとに1回ずつ押す必要がある)
- 受け渡しフォルダは次回の `skill-push` で片付くので、そのままでよいこと

このスキルの役目は .skill を送るところまで。dotfiles 側のファイルの編集や git 操作は行わない。
