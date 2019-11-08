# shinshu68/development-env
- ベース Ubuntu 18.04

## 追加点
- aptのサーバをjaistのミラーに変更
- docker-composeをインストール
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

## apt installしたパッケージ
- apt-transport-https
- ca-certificates
- cmake
- curl
- direnv
- docker-ce
- fish
- git
- gosu
- libclang-6.0-dev
- locales
- neovim
- python
- python-pip
- python3
- python3-pip
- software-properties-common
- sudo
- time
- tmux
- tree
- tzdata

## pip installしたパッケージ
- PyGithub
- beautifulsoup4
- flake8
- gitPython
- inquirer
- jedi
- matplotlib
- neovim
- numpy
- pipreqs
- pyperclip
- pyyaml
- readchar
- requests
- toml
- truecolor

# やること
- ホストの$HOMEをボリュームする想定
- fishやnvimなどのリンク(初めに1回やればボリュームでホストに反映される)
- fisherのインストール `curl -Lo ~/.config/fish/functions/fisher.fish --create-dirs https://git.io/fisher`
- fishのテーマのインストール `fisher install oh-my-fish/theme-bobthefish`
- fzfのインストール `git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf; ~/.fzf/install`
- fontの設定(?)
