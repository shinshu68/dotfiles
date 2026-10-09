---
name: repo-create
description: 新しいプロジェクトのディレクトリ(git init前で、CLAUDE.md と docs/plan.md がある状態)で、ローカルリポジトリの作成からmainブランチへの空コミット、developブランチの作成、GitHubリモートリポジトリの作成、main・developのpushまでを一気に行うスキル。リポジトリ名と一言の説明文はディレクトリ名・CLAUDE.md・docs/plan.mdから判断して候補を提示し、公開設定(public/private)と一緒に確認してから作成する。ユーザーが「/repo-create」と入力したとき、または「GitHubにリポジトリを作って」「リポジトリを初期化してGitHubに上げて」「git initからリモート作成までやって」「このプロジェクトをGitHubで管理し始めたい」のように、新しいプロジェクトのgit管理とリモート作成を始めたいと言ったときは必ずこのスキルを使うこと。
---

# リポジトリ作成 (/repo-create)

まだgit管理していないプロジェクトのディレクトリで、ローカルリポジトリの作成からGitHubへのpushまでを行うスキル。最終的に次の状態にする。

- ローカル: `main` に空コミット「:tada: First Commit」が1つあり、そこから `develop` を作成済み
- リモート: GitHubに同じ名前のリポジトリがあり、`main` と `develop` がpush済み(`origin` に設定)。PRマージ時にブランチを自動削除する設定が有効

## 前提条件

- カレントディレクトリがまだGitリポジトリではないこと
- ディレクトリ内に `CLAUDE.md` と `docs/plan.md` があること(名前と説明文を決める材料にする)
- `gh` CLIがインストール・認証済みであること
- gitの `user.name` / `user.email` が設定済みであること(コミットに必要)

## 手順

順番に意味がある。**名前・説明文・公開設定の確認を、git init より前に済ませる**。確認の段階でユーザーがやめた場合に、中途半端な `.git` を残さないため。

### 1. 状態確認スクリプトを実行する

```bash
bash scripts/check_status.sh
```

`ERROR:` が出たらその内容をユーザーに伝えて止まる。スキルの前提から外れた状態なので、勝手に直さない。

- `gh` の認証状態とGitHubユーザー名(`GH_USER:`)
- git の `user.name` / `user.email` の設定(未設定なら `ERROR:`)
- 既にGitリポジトリになっていないか(なっていれば `ERROR:`。親ディレクトリがリポジトリの場合も含む)
- ディレクトリ名(`DIR_NAME:`)
- `CLAUDE.md` と `docs/plan.md` の中身(無ければ `WARNING:`)

### 2. リポジトリ名の候補を決める

次の順に材料を見て、**1つの候補名**を決める。

1. **CLAUDE.md / plan.md の見出し・概要**: `# <プロジェクト名>` のような見出しや、概要文にプロダクト名・ツール名が書かれていればそれを最優先にする。プロジェクトの意図が最もよく表れているため。
2. **ディレクトリ名**: ドキュメントから名前が読み取れない場合はディレクトリ名を使う。ディレクトリ名が既に妥当な名前ならそのまま使ってよい。

候補名は次の形に整える。

- 小文字の英数字とハイフンのみ(kebab-case)。例: `ime-indicator`, `lol-analyzer`
- 見出しが日本語の場合は、内容を表す短い英語に訳す(例: 「IME切り替え表示」→ `ime-indicator`)
- `my-`, `new-`, `test-` のような意味の薄い接頭辞や、`project` のような汎用語は避ける
- ディレクトリ名とドキュメント上の名前が食い違うときは、ドキュメント側を候補にし、ディレクトリ名も別案として示す

候補が決まったら、名前の衝突を確認する。

```bash
gh repo view "<GH_USER>/<候補名>" >/dev/null 2>&1 && echo EXISTS || echo AVAILABLE
```

`EXISTS` なら同じ名前は使えないので、別の候補を考えてから提示する。

### 3. 説明文(description)を作る

GitHubのリポジトリ一覧で、名前の横に出る一言の説明を作る。後から一覧を見たときに何のリポジトリか思い出せることが目的。

- CLAUDE.md や plan.md の概要・目的から、**何をするものか**を日本語で一言(40文字程度まで)にまとめる。例: 「IMEのオン/オフを画面に表示するWindows用ツール」
- 文末に句点は付けない。技術スタックや経緯は入れず、内容だけを書く
- 内容が判断できない場合は、推測で書かずに確認時に入力してもらう

### 4. ユーザーに確認する

リモートの作成は取り消しにくい(publicなら即座に誰でも見られる)ので、ここで必ず確認を取る。次をまとめて1回で聞く。

- **リポジトリ名**: 候補名と、そう判断した根拠を1行(例: 「CLAUDE.mdの見出し『IME切り替え表示』から」)。別案があれば併記
- **説明文**: 手順3で作った一言
- **公開設定**: public / private のどちらにするか(既定値は決めず毎回聞く)

AskUserQuestion が使える環境ならそれを使い、名前と説明文は「この内容で作成」「修正する」の選択肢にする。

### 5. ローカルリポジトリを作成する

確認が取れたら、ローカル側を準備する。

```bash
git init -b main
git commit --allow-empty -m ":tada: First Commit"
git switch -c develop
```

- 最初のコミットは**空コミット**にする。CLAUDE.md や docs/plan.md はステージもコミットもしない(後でユーザーが通常の作業としてコミットするため)
- コミットメッセージは `:tada: First Commit` の1行だけにする。本文や `Co-Authored-By` などの行は付けない。どのプロジェクトでも同じ最初のコミットにそろえる運用のため
- `develop` は `main` の空コミットから作る

### 6. リモートリポジトリを作成してpushする

```bash
gh repo create "<リポジトリ名>" --<public|private> --description "<説明文>" --source=. --remote=origin
git push -u origin main
git push -u origin develop
```

- `gh repo create` では `--push` を付けない。`--push` は現在のブランチ(`develop`)しかpushしないため、2つのブランチを明示的にpushする
- `main` を先にpushする。空のリポジトリに最初にpushしたブランチがGitHub上のデフォルトブランチになるため、`main` をデフォルトにするにはこの順番が必要
pushが終わったら、リポジトリ設定の「Automatically delete head branches」を有効にする。PRをマージしたときにGitHub上の作業ブランチが自動で消え、リモートに不要なブランチが溜まらないようにするため。

```bash
gh repo edit "<GH_USER>/<リポジトリ名>" --delete-branch-on-merge
gh repo view "<GH_USER>/<リポジトリ名>" --json deleteBranchOnMerge --jq .deleteBranchOnMerge
```

2つ目のコマンドで `true` が返ることを確認する。

- 途中で失敗したら、どこまで終わったかを伝えて止まる(例: ローカルは作成済みでリモート作成に失敗)。やり直しのために `.git` を消すなどの後始末は勝手にしない

### 7. 結果を伝える

作成したリポジトリのURL(`gh repo create` の出力に含まれる)と、`main`・`develop` をpushしたこと、マージ後のブランチ自動削除を有効にしたこと、現在 `develop` ブランチにいることを短く伝える。CLAUDE.md と docs/plan.md はまだ未コミットであることも一言添える。

## エッジケース

| 状況 | 対応 |
|---|---|
| `gh` 未インストール/未認証 | インストールや `gh auth login` を促して停止 |
| gitの user.name / user.email が未設定 | `git config --global` での設定を促して停止 |
| 既にGitリポジトリになっている | 停止して伝える。このスキルはgit init前のディレクトリ用 |
| CLAUDE.md や docs/plan.md がない | 警告として伝え、ディレクトリ名から名前の候補を作る。説明文は確認時に入力してもらう |
| 同名リポジトリが既にある | 別の候補を考えて提示する |
| 確認の段階でユーザーがやめた | 何も作成していないので、そのまま終わる |
