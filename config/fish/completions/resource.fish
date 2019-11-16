set -l link_files 'all'
for file in (find $XDG_CONFIG_HOME/fish | grep '\.fish$')
    if islink $file
        set link_files $link_files (basename $file)
    end
end

# リストを文字列に結合する
set link_files (echo $link_files | string join ' ')

complete --command resource -x -a $link_files
