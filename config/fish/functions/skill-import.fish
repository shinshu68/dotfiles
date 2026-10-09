function skill-import --description 'Windows側の受け渡しフォルダから、skill-exportで書き出したスキルをdotfilesへ取り込む'
    # 使い方:
    #   skill-import              受け渡しフォルダにあるスキルをすべて取り込む
    #   skill-import <name> ...   指定したスキルだけ取り込む
    #   skill-import -l           受け渡しフォルダの中身を表示するだけ
    #
    # 環境変数で上書きできる:
    #   SKILL_EXPORT_DIR  受け渡しフォルダ(既定: Windowsの %USERPROFILE%\skill-export)
    #   SKILL_DEST_DIR    取り込み先(既定: ~/dotfiles/claude/skills)
    argparse h/help l/list y/yes -- $argv; or return 1

    if set -q _flag_help
        echo 'usage: skill-import [-l] [-y] [name ...]'
        echo '  -l, --list  受け渡しフォルダの中身を表示する'
        echo '  -y, --yes   上書き時の確認を省略する'
        return 0
    end

    set -l src $SKILL_EXPORT_DIR
    if test -z "$src"
        set -l winhome (cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | string trim -r -c \r)
        if test -z "$winhome"
            echo 'skill-import: Windowsのユーザーフォルダを取得できません。SKILL_EXPORT_DIR を設定してください' >&2
            return 1
        end
        set src (wslpath -u "$winhome")/skill-export
    end

    set -l dest $SKILL_DEST_DIR
    test -z "$dest"; and set dest ~/dotfiles/claude/skills

    # 初回はフォルダを作るだけ(Claude側からフォルダを接続できるようにするため)
    if not test -d $src
        mkdir -p $src; or return 1
        echo "受け渡しフォルダを作成しました: $src"
        echo 'デスクトップアプリでこのフォルダへのアクセスを許可すると、skill-export が書き出せるようになります'
        return 0
    end

    set -l names $argv
    if test (count $names) -eq 0
        for d in $src/*/
            test -f $d/SKILL.md; and set -a names (basename $d)
        end
    end

    if set -q _flag_list; or test (count $names) -eq 0
        if test (count $names) -eq 0
            echo "取り込むスキルはありません ($src)"
        else
            printf '%s\n' $names
        end
        return 0
    end

    for name in $names
        set -l from $src/$name
        set -l to $dest/$name
        if not test -f $from/SKILL.md
            echo "skill-import: $from に SKILL.md がありません。スキップします" >&2
            continue
        end

        if test -d $to
            # 変わるファイルだけ表示する(ローカルにしかないファイルは取り込みでは消さない)
            set -l changes (diff -rq $from $to 2>/dev/null | string match -v -e "Only in $to" | string replace -r '^Files (.*?) and .* differ$' '変更: $1' | string replace -r '^Only in (.*): (.*)$' '追加: $1/$2' | string replace "$from/" '')
            if test (count $changes) -eq 0
                echo "[$name] 変更なし"
                rm -rf $from
                continue
            end
            echo "[$name] 更新される内容:"
            printf '  %s\n' $changes
            if not set -q _flag_yes
                read -l -P "  上書きしますか? [y/N] " ans
                if not string match -q -i -r '^y' -- $ans
                    echo "  スキップしました"
                    continue
                end
            end
            set -l only_local (diff -rq $from $to 2>/dev/null | string match -e "Only in $to" | string replace -r '^Only in (.*): (.*)$' '$1/$2' | string replace "$to/" '')
            if test (count $only_local) -gt 0
                echo "  ローカルにだけあるファイル(削除はしません):"
                printf '    %s\n' $only_local
            end
        end

        mkdir -p $to; or return 1
        cp -r $from/. $to/; or return 1
        # Windows経由だと実行権限が落ちるので付け直す
        if test -d $to/scripts
            chmod +x $to/scripts/* 2>/dev/null
        end
        # 取り込んだら受け渡しフォルダから消す(次回の書き出しに古いファイルが混ざらないように)
        rm -rf $from
        echo "[$name] $to に取り込みました"
    end
end
