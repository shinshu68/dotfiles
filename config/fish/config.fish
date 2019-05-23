set -x XDG_CONFIG_HOME $HOME/.config
set -x XDG_CACHE_HOME $HOME/.cache
set -x EDITOR nvim

direnv hook fish | source

set -x PATH "/usr/lib/go-1.10/bin" $PATH
set -x GOPATH $HOME/goprojects
set -x PATH $GOPATH/bin $PATH

set -x PATH $HOME/.anyenv/bin $PATH
anyenv init - fish | source

set -q SSH_CLIENT
if test $status -eq 0
    set -g theme_powerline_fonts no
    set -g theme_newline_cursor yes
end
