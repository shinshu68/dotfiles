#!/usr/bin/env bash
# gh-grass: GitHub の contributions グラフ（草）をターミナルに表示する
# 使い方: bash gh-grass.sh [ユーザー名]   (省略時はログイン中のユーザー)
# 必要なもの: gh (gh auth login 済み), jq, TrueColor 対応ターミナル
set -euo pipefail

for cmd in gh jq; do
  command -v "$cmd" >/dev/null || { echo "エラー: $cmd が見つかりません" >&2; exit 1; }
done

user="${1:-$(gh api user --jq .login)}"

query='
query($login: String!) {
  user(login: $login) {
    contributionsCollection {
      contributionCalendar {
        totalContributions
        weeks {
          contributionDays { date weekday contributionLevel contributionCount }
        }
      }
    }
  }
}'

# ターミナル幅から表示できる週数を計算（曜日ラベル4文字 + 1週あたり3文字）
cols="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"
max_weeks=$(( (cols - 4) / 3 ))
(( max_weeks < 1 )) && max_weeks=1

gh api graphql -f query="$query" -f login="$user" | jq -r --argjson maxw "$max_weeks" '
  # GitHub ダークテーマ相当の配色 (R;G;B)
  def rgb: {
    NONE:            "22;27;34",
    FIRST_QUARTILE:  "14;68;41",
    SECOND_QUARTILE: "0;109;50",
    THIRD_QUARTILE:  "38;166;65",
    FOURTH_QUARTILE: "57;211;83"
  }[.];
  # 1マス = 背景色付きの半角スペース2つ + 区切り1つ
  def cell: if . == null then "   " else "\u001b[48;2;\(rgb)m  \u001b[0m " end;
  def months: ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
  def pad($n): if $n > 0 then " " * $n else "" end;

  .data.user.contributionsCollection.contributionCalendar
  # 幅に収まらない場合は古い週から切り捨てる
  | (.weeks | length) as $all
  | .weeks |= .[(-$maxw):]
  | . as $c
  | "\($c.totalContributions) contributions in the last year"
      + (if ($c.weeks | length) < $all
         then " (showing last \($c.weeks | length) weeks)" else "" end),
    # 月ラベル行
    "    " + ($c.weeks | to_entries
      | reduce .[] as $w ({s: "", p: ""};
          ($w.value.contributionDays[0].date[5:7]) as $m
          | if $m != .p and ((.s | length) == 0 or (.s | length) < $w.key * 3)
            then .s += pad($w.key * 3 - (.s | length)) + months[($m | tonumber) - 1]
            else . end
          | .p = $m)
      | .s),
    # 曜日ごと（日〜土）に1行ずつ描画
    (range(0; 7) as $d
      | (["    ","Mon ","    ","Wed ","    ","Fri ","    "][$d])
        + ([$c.weeks[]
            | [.contributionDays[] | select(.weekday == $d) | .contributionLevel][0]
            | cell] | join(""))),
    "",
    # 凡例
    "    Less " + (["NONE","FIRST_QUARTILE","SECOND_QUARTILE","THIRD_QUARTILE","FOURTH_QUARTILE"]
                   | map(cell) | join("")) + "More",
    "",
    # 最後の日（今日）のコントリビューション数
    ($c.weeks[-1].contributionDays[-1]
      | "Today (\(.date)): \(.contributionCount) contribution\(if .contributionCount == 1 then "" else "s" end)")
'
