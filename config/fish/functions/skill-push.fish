# dotfiles で管理しているスキルを、デスクトップ版 Claude へ反映するために
# Windows 側の受け渡しフォルダ(%USERPROFILE%\skill-sync)へコピーする。
# コピー後、デスクトップ版で /skill-sync を実行すると .skill にまとめて登録できる。
# skill-import(デスクトップ版 → dotfiles)の逆向き。
#
# 使い方: skill-push <スキル名> [<スキル名> ...]
#   引数なし、または -h/--help で使い方と、コピーできるスキルの一覧を表示する。
#
# 環境変数で場所を変えられる:
#   SKILL_PUSH_SRC  コピー元(既定: ~/dotfiles/claude/skills)
#   SKILL_SYNC_DIR  受け渡しフォルダ(既定: Windows の %USERPROFILE%\skill-sync)
function skill-push --description 'dotfiles のスキルをデスクトップ版 Claude 反映用の受け渡しフォルダへコピーする'
    argparse h/help -- $argv
    or return 1

    set -l src_root $HOME/dotfiles/claude/skills
    set -q SKILL_PUSH_SRC; and set src_root $SKILL_PUSH_SRC

    if set -q _flag_help; or test (count $argv) -eq 0
        echo "使い方: skill-push <スキル名> [<スキル名> ...]"
        echo "コピーできるスキル ($src_root):"
        for d in $src_root/*/
            test -f $d/SKILL.md; and echo "  "(basename $d)
        end
        return 0
    end

    # 受け渡しフォルダを決める(Windows のユーザーフォルダの下)
    set -l dest $SKILL_SYNC_DIR
    if test -z "$dest"
        # cmd.exe は WSL 側のカレントディレクトリだと警告を出すため、/mnt/c で実行する
        set -l winhome (env -C /mnt/c cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | string trim -c \r)
        if test -z "$winhome"
            echo "エラー: Windows のユーザーフォルダを取得できませんでした(SKILL_SYNC_DIR で指定できます)" >&2
            return 1
        end
        set dest (wslpath -u "$winhome")/skill-sync
    end

    # 先に全部の名前を確認してから、受け渡しフォルダを空にする
    # (途中で失敗して、前回分と今回分が混ざった状態にしないため)
    set -l names
    for arg in $argv
        set -l name (basename (string trim -r -c / -- $arg))
        if not test -f $src_root/$name/SKILL.md
            echo "エラー: $src_root/$name/SKILL.md が見つかりません" >&2
            return 1
        end
        contains -- $name $names; or set -a names $name
    end

    # 受け渡しフォルダは毎回空にする。デスクトップ側は削除できないため、ここで片付ける
    mkdir -p $dest; or return 1
    find $dest -mindepth 1 -delete; or return 1

    for name in $names
        mkdir -p $dest/$name
        # skill-creator の作業用ファイルなどは登録に不要なので除く(-h でシンボリックリンクは実体をコピー)
        tar -C $src_root/$name -ch \
            --exclude=./evals --exclude='*-workspace' --exclude='*.skill' \
            --exclude=__pycache__ --exclude='*.pyc' -f - . | tar -C $dest/$name -xf -
        or begin
            echo "エラー: $name のコピーに失敗しました" >&2
            return 1
        end
        set -l n (find $dest/$name -type f | count)
        echo "コピーしました: $name ($n ファイル)"
    end

    echo "→ $dest"
    echo "デスクトップ版 Claude で /skill-sync を実行すると反映できます"
end
