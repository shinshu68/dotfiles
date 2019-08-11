function ansible-tag
    set -l len (count $argv)
    set -l cmd "ansible-playbook -i 'localhost,' -e '@$HOME/dotfiles/ansible/config.yml' $HOME/dotfiles/ansible/playbook.yml"
    if test $len -eq 0
        false
    else
        set -l roles (ls $HOME/dotfiles/ansible/roles)
        for role in $argv
            contains $role $roles
            if test $status -eq 0
                set cmd "$cmd --tags '$role'"
            end
        end
        echo $cmd
        eval $cmd
    end
end
