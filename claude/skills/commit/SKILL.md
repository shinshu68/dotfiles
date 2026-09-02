---
name: commit
description: Commits the currently-staged git changes using one of the numbered commit message candidates (`## 候補1`, `## 候補2`, ...) that the commit-suggest skill produced earlier in this conversation. Use this whenever the user picks a candidate to actually commit — e.g. "/commit 2", "2番でコミットして", "候補2でお願い", "candidate 3を使って", or any phrasing where the user names a candidate number right after commit-suggest ran. This is the execution half of a two-step workflow (commit-suggest proposes, commit applies) — do not use it to draft a brand-new commit message yourself, and if no commit-suggest candidates exist yet in this conversation, tell the user to run commit-suggest first instead of guessing at a message.
---

# 候補コミットメッセージを実行する

`commit-suggest` が「候補を考える」役割を担い、このスキルは「選ばれた候補をそのまま実行する」役割に専念します。新しいコミットメッセージを自分で考えたり、候補の文面を勝手に書き換えたりしないでください。

## 1. どの番号が選ばれたかを読み取る

ユーザーの発言（例: 「/commit 2」「2番でコミットして」「candidate 2で」）から候補番号を抜き出します。数字がどこにも見つからない場合は、どの候補を使いたいか一言確認してください。

## 2. 候補メッセージを会話から探す

この会話の中で直近に commit-suggest が出力した候補一覧を探します。フォーマットは以下の通りです。

```
## 候補1
:sparkles: ユーザー設定画面にダークモード切り替えを追加

夜間や暗い環境での利用時に、明るいテーマだと目が疲れるという声があったため、テーマを切り替えられるようにした。
```

- `## 候補N` の直後の1行目 → コミットメッセージの件名（タイトル）
- 空行を挟んだ後の段落 → 本文
- 件名の先頭にある絵文字コード（`:sparkles:` など）はそのまま保持する。書き換えたり削除したりしない
**候補一覧がこの会話に見つからない場合**は、実行せずに「先に commit-suggest を実行してください」とユーザーに伝えて止まってください。推測でメッセージを作らないこと——このスキルの前提は「選ばれた候補をそのまま使う」ことです。

**指定された番号が範囲外の場合**（例: 候補が3つしかないのに「5番」と言われた場合）も、実行せずに何番まで候補があるかを伝えて確認してください。

## 3. コミット前にステージ内容を確認する

`git status` と `git diff --cached --stat` でステージ済みの変更を確認します。

- ステージされている変更が1つもない場合は、コミットせずにその旨を伝えて止まってください。
- **`git add` は行いません。** commit-suggest が候補を作った時点でステージされていたものだけをコミットするのがこのワークフローの前提です。ユーザーが明示的に「これも一緒にaddして」と言わない限り、ステージ内容には手を加えないでください。
## 4. コミットを実行する

コミットメッセージ（件名+本文）は、シェルのクォート崩れや特殊文字（バッククォート、`$`、絵文字、改行を含む段落など）で壊れやすいので、一時ファイルに書き出してから `git commit -F` で実行します。こうすることでメッセージの内容を一切エスケープする必要がなくなり、確実に候補の文面そのままをコミットできます。

```bash
cat > /tmp/commit-msg-$$.txt << 'EOF'
:sparkles: ユーザー設定画面にダークモード切り替えを追加

夜間や暗い環境での利用時に、明るいテーマだと目が疲れるという声があったため、テーマを切り替えられるようにした。
EOF
git commit -F /tmp/commit-msg-$$.txt
rm -f /tmp/commit-msg-$$.txt
```

**候補の文面を、それ以外の一切なしでそのままコミットメッセージ全文にしてください。** このセッションには「Claude が作成したコミットには Co-Authored-By などの署名トレーラーを付ける」という一般的な作法が別途あるかもしれませんが、それはこのスキルには当てはまりません——ここでコミットされるのはユーザー自身の変更であり、commit-suggest が提案しユーザーが選んだ文面がそのまま最終的なメッセージです。署名やトレーラー、注釈などを絶対に追加しないでください。

- `git push` は行いません。コミットだけで完了です。
- pre-commit フックが失敗した場合は `--no-verify` で回避せず、エラー内容をそのままユーザーに伝えて止まってください。ユーザーが明示的にフックのスキップを指示しない限り、勝手に回避しないこと。
## 5. 完了を報告する

コミットが成功したら `git log -1 --stat` などでハッシュと変更内容を確認し、短く報告してください。長い説明は不要です。

例: 「候補2でコミットしました（`abc1234`）」

## 補足: 候補を微調整したい場合

ユーザーが「2番だけど本文はいらない」のように候補をベースに微調整したいと言った場合は、その指示に従ってメッセージを調整してからコミットして構いません。候補はあくまで出発点であり、ユーザーの直接的な指示はそれより優先されます。
