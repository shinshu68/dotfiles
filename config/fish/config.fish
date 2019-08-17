umask 022

eval (dircolors -c ~/dotfiles/config/dircolors)

direnv hook fish | source

set -x PATH $HOME/.anyenv/bin $PATH
anyenv init - fish | source

set -x PATH $HOME/dotfiles/bin $PATH
set -x XDG_CONFIG_HOME $HOME/.config
set -x XDG_CACHE_HOME $HOME/.cache
set -x EDITOR nvim

if test -f $HOME/.config/fish/user_aliases.fish
    source $HOME/.config/fish/user_aliases.fish
end

if test -f $HOME/.env.fish
    source $HOME/.env.fish
end

if test -d $HOME/goprojects
    set -x PATH "/usr/lib/go-1.10/bin" $PATH
    set -x GOPATH $HOME/goprojects
    set -x PATH $GOPATH/bin $PATH
end

if test -d $HOME/lib/zapcc/build/bin
    set -x PATH $HOME/lib/zapcc/build/bin/ $PATH
end

if test -d $HOME/development/flutter
    set -x PATH $HOME/development/flutter/bin $PATH
end

if test -d $HOME/development/android-studio
    set -x PATH $HOME/development/android-studio/bin $PATH
end

functions -q standard_cd
if test $status -ne 0
    functions --copy cd standard_cd

    function cd
        standard_cd $argv; and ls
    end
end

set -q SSH_CLIENT
if test $status -eq 0
    set -g theme_powerline_fonts no
    set -g theme_newline_cursor yes
end

if test -f $HOME/.ssh/config -a -f $HOME/.ssh/id_rsa
    eval (ssh-agent -c) ^/dev/null >/dev/null
    ssh-add ~/.ssh/id_rsa ^/dev/null >/dev/null
end

systemctl --user status docker ^/dev/null >/dev/null
if test -x $HOME/bin/rootlesskit -a $status -ne 0
    sh ~/dotfiles/bin/start-docker.sh ^/dev/null >/dev/null
    set -x PATH $HOME/bin $PATH
    set -x DOCKER_HOST unix:///run/user/1000/docker.sock
end

set -x FZF_LEGACY_KEYBINDINGS 0
if test $SHLVL -eq 1 -a -x /usr/bin/tmux
    set -x FZF_TMUX 1
    set -x FZF_TMUX_HEIGHT 25%
    set -x FZF_DEFAULT_OPTS '--reverse'

    tmux ls ^/dev/null >/dev/null
    if test $status -eq 0
        set -l tmux_ls (tmux ls)
        set -l tmux_status (string split ' ' $tmux_ls)[-1]
        if test $tmux_status = '(attached)'
            tmux
        else
            tmux a
        end
    else
        tmux
    end
end
