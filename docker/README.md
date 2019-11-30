# shinshu68/development-env
- ベース Ubuntu 18.04

## 追加点
- aptのサーバをjaistのミラーに変更
- docker-composeをインストール
- anyenvをクローン
- emojifyをインストール
- localeをja_JPに設定
- LANGをja_JPに設定
- TZをAsia/Tokyoに設定
- SSHのソケットがあればコンテナ内にも繋げる
- docker daemonをコンテナ内に繋げる
- コンテナに入った時にentrypoint.shでユーザを追加する
- 追加されたユーザは与えられたUID, GIDをもつ(ホストのユーザと揃えることを想定)
- 追加されたユーザはユーザ名と同じパスワードでsudo権限をもつ
- 追加されたユーザはdockerグループに追加される

## apt-add-repositoryしたリポジトリ
- docker-bionic/stable
- neovim-ppa/stable
- fish-shell/release-3
- ansible/ansible

## apt installしたパッケージ
- ansible
- build-essential
- cmake
- curl
- direnv
- docker-ce
- fish
- git
- gosu
- libbz2-dev
- libclang-6.0-dev
- libffi-dev
- liblzma-dev
- libncurses5-dev
- libreadline-dev
- libsqlite3-dev
- libssl-dev
- libxml2-dev
- libxmlsec1-dev
- llvm
- locales
- make
- neovim
- python
- python-pip
- python3
- python3-pip
- sudo
- time
- tk-dev
- tmux
- tree
- tzdata
- wget
- xz-utils
- zlib1g-dev

# やること
- ホストの$HOMEをボリュームする想定
- fishやnvimなどのリンク(初めに1回やればボリュームでホストに反映される)
  - `ln -s $HOME/dotfiles/config/fish/functions/func-link.fish ~/.config/fish/functions`
  - `func-link`
  - `ansible-tag link`
- fisherのインストール
  - `curl -Lo ~/.config/fish/functions/fisher.fish --create-dirs https://git.io/fisher`
- fishのテーマのインストール
  - `fisher install oh-my-fish/theme-bobthefish`
- fzfのインストール
  - `git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf; ~/.fzf/install`
- pyenvのインストール
  - `anyenv install --init`
  - `anyenv install pyenv`
- Pythonのインストール
  - `pyenv install 2.7.15`
  - `pyenv install 3.7.2`
  - `pyenv global 3.7.2 2.7.15`
  - `pyenv rehash`
- pip install
  - `pip install -r $HOME/dotfiles/docker/requirements.txt`
  - `pip2 install -r $HOME/dotfiles/docker/requirements.txt`
- fontの設定(?)
  - `font-setting`
