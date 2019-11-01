# shinshu68/development-env
- ベース Ubuntu 18.04

## 追加点
- aptのサーバをjaistのミラーに変更
- docker-composeをインストール
- localeをja_JPに設定
- LANGをja_JPに設定
- TZをAsia/Tokyoに設定
- コンテナに入った時にentrypoint.shでユーザを追加する

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
- truecolor

# やること
- ホストの$HOMEをボリュームする想定
- fishやnvimなどのリンク(初めに1回やればボリュームでホストに反映される)
- fisherのインストール
- `fisher install oh-my-fish/theme-bobthefish`
- fontの設定(?)
