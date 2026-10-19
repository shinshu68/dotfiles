# bobthefish 風の bash プロンプト
# - 特殊グリフ (Powerline / Nerd Fonts) や絵文字は使わず、背景色付きのブロックで区切る
# - 追加のインストールは不要 (bash と git だけで動く)
# - ~/.bashrc から `source /path/to/prompt.bash` で読み込む

# 対話シェル以外では何もしない
[[ $- == *i* ]] || return 0

# ---- 設定 (必要なら ~/.bashrc で source する前に上書きする) ----
# 1: パスの途中のディレクトリを先頭1文字に短縮する / 0: 短縮しない
: "${PROMPT_SHORTEN_PATH:=1}"
# 直前のコマンドがこの秒数以上かかったら所要時間を表示する (0 で無効)
: "${PROMPT_DURATION_MIN:=5}"

# ---- 色 (256色。数値は xterm の 256 色番号) ----
__prompt_c_status_bg=0     # 終了ステータス・ジョブの背景
__prompt_c_path_bg=238     # パスの背景
__prompt_c_path_dim=245    # 途中のディレクトリ
__prompt_c_path_cur=255    # 今いるディレクトリ (太字)
__prompt_c_git_clean=70    # git: 変更なし
__prompt_c_git_staged=178  # git: ステージ済みの変更あり
__prompt_c_git_dirty=160   # git: 未ステージの変更あり
__prompt_c_git_fg=0        # git の文字色 (dirty 以外)
__prompt_c_time_bg=236     # 所要時間の背景

# 色のエスケープ。\001 \002 (PS1 の \[ \] と同じ意味) で囲み、readline に文字幅0として扱わせる
__prompt_esc() { printf '\001\e[%sm\002' "$1"; }
__prompt_reset="$(__prompt_esc 0)"

# 背景色付きのブロックを1つ追加する
# 引数: 背景色 文字色 本文 (本文には他のエスケープを含めてよい)
__prompt_seg() {
    __prompt_ps1+="$(__prompt_esc "48;5;$1")$(__prompt_esc "38;5;$2") $3 ${__prompt_reset}"
}

# パスを「途中のディレクトリは薄く、最後だけ太字」で整形する
# 引数: 表示するパス
__prompt_format_path() {
    local p=$1 parent last
    if [[ $p == / ]]; then
        printf '%s' "$(__prompt_esc "1;38;5;${__prompt_c_path_cur}")/"
        return
    fi
    parent=${p%/*}
    last=${p##*/}
    if [[ $p != */* ]]; then
        parent=""
    elif [[ -z $parent ]]; then
        parent="/"
    else
        parent+="/"
    fi
    if (( PROMPT_SHORTEN_PATH )) && [[ -n $parent && $parent != / ]]; then
        # 各要素を先頭1文字に短縮する (隠しディレクトリは . の次の1文字まで残す)
        local IFS=/ part out=""
        local -a parts
        read -ra parts <<< "${parent%/}"
        for part in "${parts[@]}"; do
            if [[ -z $part ]]; then
                out+="/"
                continue
            fi
            [[ $part == "~" ]] && { out+="~/"; continue; }
            if [[ $part == .* ]]; then out+="${part:0:2}/"; else out+="${part:0:1}/"; fi
        done
        parent=$out
    fi
    printf '%s%s%s%s' \
        "$(__prompt_esc "38;5;${__prompt_c_path_dim}")" "$parent" \
        "$(__prompt_esc "1;38;5;${__prompt_c_path_cur}")" "$last"
}

# HOME を ~ に置き換える
__prompt_tilde() {
    local p=$1
    if [[ $p == "$HOME" ]]; then
        p="~"
    elif [[ $p == "$HOME"/* ]]; then
        p="~${p#"$HOME"}"
    fi
    printf '%s' "$p"
}

# git ブロックを追加する。git リポジトリ内ならリポジトリのルートを __prompt_git_root に入れる
__prompt_git() {
    __prompt_git_root=""
    command -v git >/dev/null 2>&1 || return

    local root
    root=$(git rev-parse --show-toplevel 2>/dev/null) || return
    [[ -n $root ]] || return
    __prompt_git_root=$root

    # 1回の git status でブランチ・ahead/behind・変更の有無をまとめて取る
    local line branch="" oid="" ahead=0 behind=0 staged=0 dirty=0 untracked=0 st
    st=$(git status --porcelain=v2 --branch 2>/dev/null)
    while IFS= read -r line; do
        case $line in
            "# branch.oid "*)  oid=${line#"# branch.oid "} ;;
            "# branch.head "*) branch=${line#"# branch.head "} ;;
            "# branch.ab "*)
                read -r _ _ ahead behind <<< "$line"
                ahead=${ahead#+}
                behind=${behind#-}
                ;;
            "? "*) untracked=1 ;;
            [12u]" "*)
                # 2文字目がインデックス (ステージ済み)、3文字目がワークツリーの状態
                [[ ${line:2:1} != . ]] && staged=1
                [[ ${line:3:1} != . ]] && dirty=1
                ;;
        esac
    done <<< "$st"

    # detached HEAD のときはコミットハッシュの先頭7桁を出す
    if [[ $branch == "(detached)" || -z $branch ]]; then
        branch="${oid:0:7}"
        [[ $oid == "(initial)" ]] && branch="(initial)"
        branch="->${branch}"
    fi

    local flags=""
    (( dirty ))     && flags+="*"
    (( staged ))    && flags+="~"
    git rev-parse --verify --quiet refs/stash >/dev/null 2>&1 && flags+='$'
    (( untracked )) && flags+="..."
    if (( ahead > 0 && behind > 0 )); then
        flags+=" +${ahead}-${behind}"
    elif (( ahead > 0 )); then
        flags+=" +${ahead}"
    elif (( behind > 0 )); then
        flags+=" -${behind}"
    fi

    local bg=$__prompt_c_git_clean fg=$__prompt_c_git_fg
    if (( dirty || untracked )); then
        bg=$__prompt_c_git_dirty
        fg=255
    elif (( staged )); then
        bg=$__prompt_c_git_staged
    fi

    local text=$branch
    [[ -n $flags ]] && text+=" ${flags}"
    __prompt_git_seg=("$bg" "$fg" "$text")
}

# 秒数を 1h2m3s の形にする
__prompt_format_duration() {
    local s=$1 out=""
    (( s >= 3600 )) && out+="$((s / 3600))h"
    (( s >= 60 ))   && out+="$((s % 3600 / 60))m"
    out+="$((s % 60))s"
    printf '%s' "$out"
}

__prompt_build() {
    local last_status=$?   # 最初に取らないと上書きされる
    __prompt_ps1=""
    __prompt_git_seg=()

    # 1. 終了ステータス・バックグラウンドジョブ・root
    local status_text="" jobs_count
    (( last_status != 0 )) && status_text+="$(__prompt_esc "1;38;5;9")!${last_status}"
    # \j (ジョブ数) をプロンプト展開で取る。サブシェルを作らないので正確で速い
    jobs_count='\j'
    jobs_count=${jobs_count@P}
    (( jobs_count > 0 )) && status_text+="${status_text:+ }$(__prompt_esc "1;38;5;14")%${jobs_count}"
    (( EUID == 0 )) && status_text+="${status_text:+ }$(__prompt_esc "1;38;5;11")#"
    [[ -n $status_text ]] && __prompt_seg "$__prompt_c_status_bg" 255 "$status_text"

    # 2. パス + git (bobthefish と同じく「リポジトリまで / git / リポジトリ内のパス」の順)
    __prompt_git
    if [[ -n $__prompt_git_root && $PWD == "$__prompt_git_root"* ]]; then
        local sub=${PWD#"$__prompt_git_root"}
        __prompt_seg "$__prompt_c_path_bg" "$__prompt_c_path_cur" \
            "$(__prompt_format_path "$(__prompt_tilde "$__prompt_git_root")")"
        __prompt_seg "${__prompt_git_seg[@]}"
        if [[ -n $sub ]]; then
            __prompt_seg "$__prompt_c_path_bg" "$__prompt_c_path_cur" \
                "$(__prompt_format_path "${sub#/}")"
        fi
    else
        __prompt_seg "$__prompt_c_path_bg" "$__prompt_c_path_cur" \
            "$(__prompt_format_path "$(__prompt_tilde "$PWD")")"
        (( ${#__prompt_git_seg[@]} )) && __prompt_seg "${__prompt_git_seg[@]}"
    fi

    # 3. 直前のコマンドの所要時間
    if [[ -n ${__prompt_cmd_start-} ]]; then
        local elapsed=$((SECONDS - __prompt_cmd_start))
        if (( PROMPT_DURATION_MIN > 0 && elapsed >= PROMPT_DURATION_MIN )); then
            __prompt_seg "$__prompt_c_time_bg" 250 "$(__prompt_format_duration "$elapsed")"
        fi
    fi
    unset __prompt_cmd_start

    # ブランチ名などに \ や $ が含まれても PS1 として解釈されないよう、
    # 組み立てた文字列は変数に入れて PS1 からは参照するだけにする
    # SSH 接続中は bobthefish の theme_newline_cursor と同じく改行してから入力させる
    if [[ -n ${SSH_CLIENT-} ]]; then
        PS1='${__prompt_ps1}\n\$ '
    else
        PS1='${__prompt_ps1} '
    fi
}

PROMPT_COMMAND="__prompt_build${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
# コマンドの実行直前に開始時刻を記録する (PS0 は bash 4.4 以降)
# 部分文字列展開 (長さ0) のオフセットに代入式を書き、何も表示せずに変数だけ設定する
PS0='${SECONDS:__prompt_cmd_start=SECONDS:0}'
