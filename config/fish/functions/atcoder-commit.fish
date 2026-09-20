function atcoder-commit
    # 引数があればそのファイルを add、なければカレントディレクトリ以下をすべて add
    if test (count $argv) -eq 0
        git add .
    else
        git add $argv
    end
    or return 1

    # コミット予定（ステージ済み）のファイル名を取得
    set -l files (git diff --cached --name-only)
    if test (count $files) -eq 0
        echo "コミットする変更がありません"
        return 1
    end

    # 拡張子を削除
    set -l names (path change-extension '' $files)

    # :thumbsup: ディレクトリ名 ファイル名 ファイル名 ...
    set -l dir (path basename $PWD)
    set -l msg ":thumbsup: $dir "(string join ' ' $names)

    git commit -m "$msg"
end