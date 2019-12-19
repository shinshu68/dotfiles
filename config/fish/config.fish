umask 022

eval (dircolors -c $HOME/dotfiles/config/dircolors)

set -g theme_powerline_fonts yes
set -g theme_display_git_master_branch yes

if test -x /usr/bin/direnv
    direnv hook fish | source
end

if test -d $HOME/.anyenv
    set -x PATH $HOME/.anyenv/bin $PATH
    anyenv init - fish | source
end

set -x PATH $HOME/dotfiles/bin $PATH
set -x XDG_CONFIG_HOME $HOME/.config
set -x XDG_CACHE_HOME $HOME/.cache
set -x EDITOR nvim

set -x USER_ID (id -u)
set -x GROUP_ID (id -g)

if test -f $XDG_CONFIG_HOME/fish/user_aliases.fish
    source $XDG_CONFIG_HOME/fish/user_aliases.fish
end

if test -f $HOME/.env.fish
    source $HOME/.env.fish
end

if test -d $HOME/goprojects
    set -x PATH "/usr/lib/go-1.10/bin" $PATH
    set -x GOPATH $HOME/goprojects
    set -x PATH $GOPATH/bin $PATH
end

if test -d $HOME/.local/bin
    set -x PATH $HOME/.local/bin $PATH
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

if test -d $HOME/.cargo/bin
    set -x PATH $HOME/.cargo/bin $PATH
end

if not functions -q standard_cd
    functions --copy cd standard_cd

    function cd
        standard_cd $argv; and ls
    end
end

if set -q SSH_CLIENT
    set -g theme_powerline_fonts no
    set -g theme_newline_cursor yes
end

if not set -q COLORTERM
    set -x COLORTERM truecolor
end

if not set -q SSH_AGENT_PID && test -f $HOME/.ssh/id_rsa
    set -l ssh_grep (ps aux | grep "^$USER" | grep "ssh-agent -c")
    if test $status -eq 0
        set -l ssh_pid (echo $ssh_grep | awk '{print $2}')
        kill -9 $ssh_pid
    end
    eval (ssh-agent -c) 2>/dev/null >/dev/null
    ssh-add ~/.ssh/id_rsa 2>/dev/null >/dev/null
end

if not set -q DOCKER_HOST && test -x $HOME/bin/rootlesskit
    sh ~/dotfiles/bin/start-docker.sh 2>/dev/null >/dev/null
    set -x PATH $HOME/bin $PATH
    set -l user_id (id -u)
    set -x DOCKER_HOST unix:///run/user/$user_id/docker.sock
end

set -x FZF_LEGACY_KEYBINDINGS 0
if test $SHLVL -eq 1 -a -x /usr/bin/tmux
    set -x FZF_TMUX 1
    set -x FZF_TMUX_HEIGHT 25%
    set -x FZF_DEFAULT_OPTS '--reverse'

    tmux ls 2>/dev/null >/dev/null
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

if set -q INSIDE_DOCKER
    set -g theme_display_docker_machine yes
end
