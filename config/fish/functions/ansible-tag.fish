function ansible-tag
    set -l args
    set -l roles (ls $HOME/dotfiles/ansible/roles)
    for role in $argv
        if contains $role $roles
            set -a args --tags $role
        end
    end

    # sudo のパスワードの確認と聞き直しは run.sh で行う
    if test (count $args) -ne 0
        echo $HOME/dotfiles/ansible/run.sh $args
        $HOME/dotfiles/ansible/run.sh $args
    end
end
