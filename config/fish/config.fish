set -x XDG_CONFIG_HOME $HOME/.config
set -x XDG_CACHE_HOME $HOME/.cache
set -x EDITOR nvim
set -x PATH ~/.local/bin $PATH

direnv hook fish | source

set PYENV_ROOT ~/.pyenv/bin
set -x PATH $PYENV_ROOT $PATH
status --is-interactive; and pyenv init - | source

set -x PATH "/usr/lib/go-1.10/bin" $PATH
set -x GOPATH $HOME/goprojects
set -x PATH $GOPATH/bin $PATH

set -x PATH $HOME/.anyenv/bin $PATH
