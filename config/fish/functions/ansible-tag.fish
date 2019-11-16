function ansible-tag
    set -l cmd "ansible-playbook -K -i 'localhost,' -e '@$HOME/dotfiles/ansible/config.yml' $HOME/dotfiles/ansible/playbook.yml"
    if test (count $argv) -eq 0
        true
    else
        set -l newcmd $cmd
        set -l roles (ls $HOME/dotfiles/ansible/roles)
        for role in $argv
            contains $role $roles
            if test $status -eq 0
                set newcmd "$newcmd --tags '$role'"
            end
        end

        if test $cmd != $newcmd
            echo $newcmd
            eval $newcmd
        end
    end
end
