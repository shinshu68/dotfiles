# dotfiles
shinshu68's dotfiles

WSL2 の Ubuntu 24.04 向けです。ansible で開発環境をセットアップします。

## Install
```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/shinshu68/dotfiles/master/install)"
```

install スクリプトは次の順に実行します。何度実行しても、終わっている手順は飛ばします。

1. apt のミラーを jaist にする
2. ansible をインストールする
3. このリポジトリを `~/dotfiles` に clone する
4. ansible の playbook を実行する（途中で sudo のパスワードを聞かれます）

### 事前に必要なもの
- Windows に VS Code がインストールされていること
- Windows の開発者モードが有効になっていること（Windows 側に VS Code の設定ファイルのリンクを作るため）

## ansible のロール
| ロール | 内容 |
|---|---|
| apt | 基本的なパッケージのインストール |
| fish | fish と fisher のインストール、fish の設定ファイルのリンク、fisher プラグインのインストール |
| anyenv | anyenv と anyenv-update のインストール |
| python | pyenv と Python のインストール |
| pip | pip パッケージのインストール |
| node | n と Node.js (LTS) のインストール |
| claude | Claude Code のインストール、`~/.claude` への設定ファイルのリンク |
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

作った公開鍵を GitHub に登録します。

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
