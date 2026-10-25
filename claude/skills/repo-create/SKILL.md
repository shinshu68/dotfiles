---
name: repo-create
description: 新しいプロジェクトのディレクトリ(git init前で、CLAUDE.md と docs/plan.md がある状態)で、ローカルリポジトリの作成からmainブランチへの空コミット、マージ済みブランチを削除するGitHub Actionsワークフローの追加、developブランチの作成、GitHubリモートリポジトリの作成、main・developのpush、pj-statusスキルの対象一覧(WSL側のprojects.txt)への登録、さらにCLAUDE.mdやdocs/配下をコミットするための作業ブランチ(docs/add-project-docs)の作成・ステージ・commit-suggestの呼び出しまでを一気に行うスキル。リポジトリ名と一言の説明文はディレクトリ名・CLAUDE.md・docs/plan.mdから判断して候補を提示し、公開設定(public/private)と一緒に確認してから作成する。ユーザーが「/repo-create」と入力したとき、または「GitHubにリポジトリを作って」「リポジトリを初期化してGitHubに上げて」「git initからリモート作成までやって」「このプロジェクトをGitHubで管理し始めたい」のように、新しいプロジェクトのgit管理とリモート作成を始めたいと言ったときは必ずこのスキルを使うこと。
---

# リポジトリ作成 (/repo-create)

まだgit管理していないプロジェクトのディレクトリで、ローカルリポジトリの作成からGitHubへのpushまでを行うスキル。最終的に次の状態にする。

- ローカル: `main` に空コミット「:tada: First Commit」と、マージ済みブランチを削除するワークフローを追加するコミットがあり、そこから `develop` を作成済み
- リモート: GitHubに同じ名前のリポジトリがあり、`main` と `develop` がpush済み(`origin` に設定)
- pj-status: WSL 側の `~/.claude/skills/pj-status/projects.txt` にこのプロジェクトのディレクトリが追加済み
- 作業ブランチ: `develop` から `docs/add-project-docs` を作り、CLAUDE.md(モノレポ構成ならサブディレクトリのものも)と docs/ 配下をステージして、commit-suggest でコミットメッセージの候補を出した状態

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
- `.github/workflows/delete-merged-branch.yml` が既にないか(あれば `WARNING:`。手順5で上書きせず、既存のものをそのままコミットするか確認時に聞く)

### 2. リポジトリ名の候補を決める

次の順に材料を見て、**1つの候補名**を決める。

1. **CLAUDE.md / plan.md の見出し・概要**: `# <プロジェクト名>` のような見出しや、概要文にプロダクト名・ツール名が書かれていればそれを最優先にする。プロジェクトの意図が最もよく表れているため。
2. **ディレクトリ名**: ドキュメントから名前が読み取れない場合はディレクトリ名を使う。ディレクトリ名が既に妥当な名前ならそのまま使ってよい。

候補名の形式は、プロジェクトの言語・技術スタックの慣習に合わせて選ぶ。リポジトリ名はソリューション名やパッケージ名と一致させることが多いため、その言語で自然な形式にしておくと後でずれない。

| 形式 | 例 | 選ぶ場面 |
|---|---|---|
| kebab-case(小文字の英数字とハイフン) | `ime-indicator` | 既定。Web系、Python、Node.js、Go、Rust、シェルなど |
| PascalCase(単語の先頭を大文字、区切りなし) | `ImeIndicator` | C#/.NET(WPF、WinForms、ASP.NET Core、Unityなど)、PowerShellモジュール |

- 技術スタックは CLAUDE.md / plan.md の「技術スタック」「技術選定」などから読み取る。判断がつかなければ kebab-case にする
- ディレクトリ名が既にどちらかの形式で、技術スタックとも合っていれば、その形式を優先する
- 両方の形式の候補を作り、**どちらがこのプロジェクトで自然かを推奨として1つ決める**。推奨の理由は、表のどの場面に当たるかを具体的に1行で書く(例: 「C#/WPFのプロジェクトで、ソリューション名・名前空間がPascalCaseになるため」「Pythonのツールで、GitHub上ではkebab-caseが一般的なため」)。形式の最終判断はユーザーが決めたいことが多いので、推奨しない方も必ず選べるようにする
- 技術スタックが読み取れずkebab-caseにした場合は、推奨の理由に「技術スタックが判断できなかったため既定のkebab-case」と正直に書く。根拠のない推奨に見せないため
- 見出しが日本語の場合は、内容を表す短い英語に訳す(例: 「IME切り替え表示」→ `ime-indicator` / `ImeIndicator`)
- 略語は形式に合わせる。PascalCaseでは `IME` を `Ime` のように先頭だけ大文字にする(.NETの命名規則で、3文字以上の略語はこう書くため)
- `my-`, `new-`, `test-` のような意味の薄い接頭辞や、`project` のような汎用語は避ける
- ディレクトリ名とドキュメント上の名前が食い違うときは、ドキュメント側を候補にし、ディレクトリ名も別案として示す

候補が決まったら、名前の衝突を確認する。

```bash
gh repo view "<GH_USER>/<候補名>" >/dev/null 2>&1 && echo EXISTS || echo AVAILABLE
```

`EXISTS` なら同じ名前は使えないので、別の候補を考えてから提示する。GitHubのリポジトリ名は大文字小文字を区別しないため、`ImeIndicator` と `imeindicator` は同じ名前として衝突する(このコマンドも区別せずに判定する)。別案の形式も同じように確認する。

### 3. 説明文(description)を作る

GitHubのリポジトリ一覧で、名前の横に出る一言の説明を作る。後から一覧を見たときに何のリポジトリか思い出せることが目的。

- CLAUDE.md や plan.md の概要・目的から、**何をするものか**を日本語で一言(40文字程度まで)にまとめる。例: 「IMEのオン/オフを画面に表示するWindows用ツール」
- 文末に句点は付けない。技術スタックや経緯は入れず、内容だけを書く
- 内容が判断できない場合は、推測で書かずに確認時に入力してもらう

### 4. ユーザーに確認する

リモートの作成は取り消しにくい(publicなら即座に誰でも見られる)ので、ここで必ず確認を取る。次をまとめて1回で聞く。

- **リポジトリ名**: PascalCase と kebab-case の2つの候補を並べ、推奨する方に「(推奨)」を付ける。名前の由来(例: 「CLAUDE.mdの見出し『IME切り替え表示』から」)と、その形式を推奨する理由をそれぞれ1行で添える
- **説明文**: 手順3で作った一言
- **公開設定**: public / private のどちらにするか(既定値は決めず毎回聞く)

AskUserQuestion が使える環境ならそれを使い、名前は推奨する形式を1つ目に置いてラベルの末尾に「(推奨)」を付け、もう一方の形式を2つ目にした2択にする(例: `ImeIndicator (推奨)` / `ime-indicator`)。各選択肢の説明に、その形式が合う場面を短く書く(自由入力は「Other」でできる)。説明文は「この内容で作成」「修正する」の選択肢にする。

### 5. ローカルリポジトリを作成する

確認が取れたら、ローカル側を準備する。

```bash
git init -b main
git commit --allow-empty -m ":tada: First Commit"

mkdir -p .github/workflows
cp <このスキルのディレクトリ>/assets/delete-merged-branch.yml .github/workflows/
git add .github/workflows/delete-merged-branch.yml
git commit -m ":construction_worker: マージ済みブランチを自動削除するワークフローを追加"

git switch -c develop
```

- 最初のコミットは**空コミット**にする。コミットメッセージは `:tada: First Commit` の1行だけ
- 2つ目のコミットで、PRマージ後にGitHub上の作業ブランチを削除するワークフロー(`assets/delete-merged-branch.yml`)を追加する。中身は書き換えずにそのままコピーする
- どちらのコミットも、メッセージは上の1行だけにする。本文や `Co-Authored-By` などの行は付けない。どのプロジェクトでも同じ最初のコミットにそろえる運用のため
- `git add` はワークフローファイルだけを指定する。CLAUDE.md や docs/plan.md はステージもコミットもしない(後でユーザーが通常の作業としてコミットするため)
- `develop` はワークフローを追加した後の `main` から作る。PRのマージ先(`develop`、リリース時は `main`)の両方にワークフローが入っていないと、マージしても動かないため

#### ワークフローについて

リポジトリ設定の「Automatically delete head branches」は使わない。この設定は `develop` → `main` のリリースPRをマージしたときに `develop` まで削除してしまうため。同梱のワークフローは次の条件をすべて満たすときだけ、PRのブランチを削除する。

- PRがマージされた(マージせずに閉じたPRのブランチは残す)
- ブランチがこのリポジトリのもの(フォークからのPRは対象外)
- ブランチが `main` でも `develop` でもない

ワークフローを編集したい場合は、スキル内の `assets/delete-merged-branch.yml` を直す。

### 6. リモートリポジトリを作成してpushする

```bash
gh repo create "<リポジトリ名>" --<public|private> --description "<説明文>" --source=. --remote=origin
git push -u origin main
git push -u origin develop
```

- `gh repo create` では `--push` を付けない。`--push` は現在のブランチ(`develop`)しかpushしないため、2つのブランチを明示的にpushする
- `main` を先にpushする。空のリポジトリに最初にpushしたブランチがGitHub上のデフォルトブランチになるため、`main` をデフォルトにするにはこの順番が必要
- 途中で失敗したら、どこまで終わったかを伝えて止まる(例: ローカルは作成済みでリモート作成に失敗)。やり直しのために `.git` を消すなどの後始末は勝手にしない

### 7. pj-status の対象に登録する

リモートの作成とpushが終わったら、このプロジェクトのディレクトリを pj-status スキルの対象一覧に追加する。新しいプロジェクトを作るたびに手で書き足す手間をなくし、登録漏れを防ぐため。

```bash
bash scripts/register_pj_status.sh
```

- 一覧は **WSL 側の `~/.claude/skills/pj-status/projects.txt`** で一元管理している。スクリプトは Windows 側(Git Bash)から実行された場合も `wsl.exe` 経由で WSL の中のこのファイルを編集し、パスも WSL の形式(`~/...` など)に変換して書く。Windows 側の `projects.txt` を探したり作ったりはしない
- プロジェクトディレクトリ(カレントディレクトリ)で実行する。ホームの下なら `~/work/xxx` のように `~` で書かれる
- バックログ名の指定(`| バックログ名`)は付けない。pj-status はリモート origin のリポジトリ名からバックログを探すので、リモート作成後なら名前が合うため
- 出力の最終行で結果がわかる: `ADDED:`(追加した)、`ALREADY:`(登録済みなので何もしていない)、`ERROR:`(追加できなかった)。`projects.txt` が無ければひな形から作られ、`INFO:` が出る
- `ERROR:` でもリポジトリ作成そのものは終わっているので、止まらずに次の手順へ進み、報告で理由と「手で `projects.txt` に追加してほしい」ことを伝える

### 8. 結果を伝える

作成したリポジトリのURL(`gh repo create` の出力に含まれる)と、`main`・`develop` をpushしたこと、マージ済みブランチを削除するワークフローを入れたこと、pj-status の対象に追加したか(手順7の結果)を短く伝える。この報告は手順9・10より**先に**出す。このあとコミットメッセージの候補が続くので、リポジトリ作成の結果が候補の下に埋もれないようにするため。

### 9. プロジェクトのドキュメント用ブランチを作ってステージする

CLAUDE.md や docs/ 配下のドキュメントは、`develop` に直接コミットせず、作業ブランチからPRで入れる。ほかの作業と同じ流れ(ブランチ → コミット → `/pr` → マージ → `/pr-done`)にそろえるため。

まず対象のファイルを洗い出す。

```bash
git ls-files --others --exclude-standard -- ':(glob)**/CLAUDE.md' ':(glob)docs/**' ':(exclude,glob)**/node_modules/**'
```

1件以上あれば、ブランチを作ってステージする。

```bash
git switch -c docs/add-project-docs
git ls-files -z --others --exclude-standard -- ':(glob)**/CLAUDE.md' ':(glob)docs/**' ':(exclude,glob)**/node_modules/**' | xargs -0 -r git add --
git status --short
```

- ブランチは `develop`(手順6の時点でいるブランチ)から作る。名前は `docs/add-project-docs` で固定
- ステージするのは次の2種類:
  - **すべての階層の `CLAUDE.md`**: ルートの `CLAUDE.md` に加えて、モノレポ構成で各サブプロジェクトのディレクトリに置かれた `CLAUDE.md`(例: `apps/mobile/CLAUDE.md`、`packages/ui/CLAUDE.md`)も含める。単一プロジェクトならルートの1つだけが対象になる
  - **ルートの `docs/` 配下のすべて**: project-init が plan.md 以外に docs/ 配下の複数ファイルを作っている場合があるので、ファイル名を決め打ちせず `docs/` ごと入れる
- `**/node_modules/**` の中の `CLAUDE.md` は、依存パッケージに同梱されたもので自分のプロジェクトのドキュメントではないので除外する。`.gitignore` で無視されているファイルも `--exclude-standard` で除外される
- `CLAUDE.local.md` は個人用のローカル設定なのでステージしない(ファイル名が `CLAUDE.md` と完全に一致するものだけが対象になるので、上のコマンドのままで含まれない)
- それ以外の未追跡ファイル(ソースコード、`.env`、`.claude/`、サブプロジェクト内の `docs/` など)はステージしない。意図せずコミットされると困るものが混ざりうるため。`git status --short` に `??` で残ったファイルがあれば、報告で「ステージしていないファイル」として名前だけ伝える
- ステージした `CLAUDE.md` が複数ある場合(モノレポ構成)は、報告でそのパスを一覧で伝える。どのサブプロジェクトのものが入ったかを確認できるようにするため
- 洗い出しの結果が0件(`CLAUDE.md` も `docs/` もない)の場合は、ブランチを作らずに手順10も飛ばし、ドキュメントが見つからなかったことを伝えて終わる

### 10. commit-suggest を呼ぶ

ステージできたら、`commit-suggest` スキルを呼び出してコミットメッセージの候補を出す。commit-suggest は最初にスペルチェック(spell-check スキル)を行うので、その確認にもそのまま対応する。

- `git commit` はこのスキルでは実行しない。候補から選んでコミットするのはユーザーに任せる(`/commit <番号>` で選べる)
- 候補を出したあと、最後に「コミット後は `/pr` で develop 向けのPRを作成できます」と一言だけ添える

## エッジケース

| 状況 | 対応 |
|---|---|
| `gh` 未インストール/未認証 | インストールや `gh auth login` を促して停止 |
| gitの user.name / user.email が未設定 | `git config --global` での設定を促して停止 |
| 既にGitリポジトリになっている | 停止して伝える。このスキルはgit init前のディレクトリ用 |
| CLAUDE.md や docs/plan.md がない | 警告として伝え、ディレクトリ名から名前の候補を作る。説明文は確認時に入力してもらう |
| 同名リポジトリが既にある | 別の候補を考えて提示する |
| 確認の段階でユーザーがやめた | 何も作成していないので、そのまま終わる |
| CLAUDE.md・docs/ 以外の未追跡ファイルがある | ステージせず、ファイル名だけ伝える |
| モノレポ構成でサブディレクトリにも CLAUDE.md がある | すべてステージし、報告でパスを一覧で伝える(node_modules 内のもの、CLAUDE.local.md は除く) |
| pj-status への登録が `ERROR:` になった | 止まらずに続け、報告で理由と手での追加をお願いする |
| 既に pj-status に登録されている(`ALREADY:`) | 何もせず、登録済みだったことだけ伝える |
| `.github/workflows/delete-merged-branch.yml` が既にある | 上書きせず、既存のファイルをそのままコミットしてよいか確認時に聞く |
