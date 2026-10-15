# skill-push の補完: dotfiles にあるスキル名を候補に出す
function __skill_push_names
    set -l src_root $HOME/dotfiles/claude/skills
    set -q SKILL_PUSH_SRC; and set src_root $SKILL_PUSH_SRC
    for d in $src_root/*/
        test -f $d/SKILL.md; and basename $d
    end
end

complete -c skill-push -f -a '(__skill_push_names)'
complete -c skill-push -s h -l help -d '使い方とスキル一覧を表示'
