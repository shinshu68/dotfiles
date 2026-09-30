# dotfiles
shinshu68's dotfiles

WSL2 の Ubuntu 24.04 向けです。ansible で開発環境をセットアップします。

## Install
```shell
bash -c "$(curl -fsSL https://shinshu68.github.io/dotfiles/install)"
```

install スクリプトは次の順に実行します。何度実行しても、終わっている手順は飛ばします。

1. apt のミラーを jaist にする
2. ansible をインストールする
3. このリポジトリを `~/dotfiles` に clone する
4. ansible の playbook を実行する（途中で sudo のパスワードを聞かれます）

### 事前に必要なもの
- Windows に VS Code がインストールされていること（インストーラーの「PATH への追加」を有効にしておく。拡張機能を `code` コマンドで入れるため）
- Windows に [Cica](https://github.com/miiton/Cica) フォントがインストールされていること（VS Code のエディタとターミナルのフォントに使う）
- Windows で winget が使えること（Windows 側に Git for Windows と gh を入れるため）
- Windows の開発者モードが有効になっていること（Windows 側に設定ファイルのリンクを作るため）

## ansible のロール
| ロール | 内容 |
|---|---|
| apt | 基本的なパッケージのインストール |
| fish | fish と fisher のインストール、fish の設定ファイルのリンク、fisher プラグインのインストール |
| anyenv | anyenv と anyenv-update のインストール |
| python | pyenv と Python のインストール |
| pip | pip パッケージのインストール |
| node | n と Node.js (LTS) のインストール |
| claude | Claude Code のインストール、`~/.claude` への設定ファイルのリンク（WSL のときは Windows 側にもリンク） |
| winget | Windows 側への Git for Windows と gh のインストール（WSL のときだけ） |
| vscode | Windows 側の VS Code への settings.json のリンク、拡張機能のインストール（WSL のときだけ） |
| link | nvim / git / tmux の設定ファイルのリンク |

入れるパッケージやバージョン、リンクする設定ファイルは `ansible/config.yml` で管理しています。

### ロールを個別に実行する
ロール名をタグとして指定します。

```shell
~/dotfiles/ansible/run.sh --tags fish
```

fish を使っている場合は、`ansible-tag` 関数でも実行できます。

```shell
ansible-tag fish
```

## 手動でやること
### ログインシェルを fish にする
```shell
chsh -s /usr/bin/fish
```

### SSH の設定
```shell
ssh-keygen -t ed25519
```

### GitHub CLI にログインする
Claude Code の pr スキルと `contributions` 関数が gh を使います。

```shell
gh auth login
```

Git の操作に使うプロトコルは SSH を選びます。途中で SSH 公開鍵をアップロードするか聞かれるので、上で作った鍵をアップロードして GitHub に登録します。HTTPS を選んで Git の認証に gh を使う設定にすると、`~/.gitconfig`（このリポジトリの `git/config` へのリンク）に credential helper が書き込まれてしまいます。

install スクリプトは鍵がなくても動くように HTTPS で clone するので、鍵を登録したらリモートを SSH に切り替えます。

```shell
git -C ~/dotfiles remote set-url origin git@github.com:shinshu68/dotfiles.git
```

Windows 側の gh（winget で入れたもの）は WSL とは別にログインが必要なので、PowerShell でも同じコマンドを実行します。Windows 側には SSH 鍵を作らないので、プロトコルは HTTPS を選びます。

### Claude Code にログインする
`claude` を起動すると、初回はログインの手順が表示されます。Windows 側の VS Code の Claude Code 拡張は、拡張の画面からログインします。

## Docker で確認する
playbook の変更は、`ansible/` にある Docker 環境で確認できます。作業中のリポジトリをコンテナにマウントして実行します。

```shell
cd ~/dotfiles/ansible
docker compose run --rm ansible
```

コンテナの中で playbook を実行します。sudo のパスワードは空のまま Enter で通ります。

```shell
./ansible/run.sh
```

何も入っていない状態から install スクリプトを試すときは、`vanilla` のコンテナを使います。

```shell
docker compose run --rm vanilla
```
