# dotfiles
shinshu68's dotfiles

WSL2 の Ubuntu 24.04 と、その Windows 側の環境向けです。Windows 側は winget configure、WSL 側は ansible でセットアップします。

## Install
Windows 側 → WSL 側の順に実行します。どちらも何度実行しても、終わっている手順は飛ばします。

### 1. Windows 側
PowerShell で実行します。

```powershell
iex ((New-Object System.Net.WebClient).DownloadString('https://shinshu68.github.io/dotfiles/install.ps1'))
```

install.ps1 は次の順に実行します。

1. 私用の PC かどうかを聞く（初回だけ。答えは `%USERPROFILE%\.dotfiles-windows.json` に保存します）
2. `windows/base.dsc.yaml` を winget configure で適用する（開発者モードの有効化と、会社・私用の両方で使うアプリのインストール。UAC の確認が1回出ます）
3. 私用の PC なら `windows/personal.dsc.yaml` も適用する
4. [Cica](https://github.com/miiton/Cica) フォントをユーザー用フォントとしてインストールする
5. 私用の PC なら [ImeCenterView](https://github.com/shinshu68/ImeCenterView) をビルドして、スタートアップに登録し、起動する
6. Ubuntu が入っていなければ、WSL と Ubuntu-24.04 をインストールする
7. 次にやることを表示する

WSL を新しく入れたときは、必要なら Windows を再起動し、スタートメニューから Ubuntu 24.04 を起動して Linux のユーザーを作ってから、WSL 側の手順に進みます。

事前に必要なのは、Windows で winget が使えること（Microsoft Store の「アプリ インストーラー」）だけです。

### 2. WSL 側
Ubuntu で実行します。

```shell
bash -c "$(curl -fsSL https://shinshu68.github.io/dotfiles/install)"
```

install スクリプトは次の順に実行します。

1. apt のミラーを jaist にする
2. ansible をインストールする
3. このリポジトリを `~/dotfiles` に clone する
4. ansible の playbook を実行する（途中で sudo のパスワードを聞かれます）

## Windows 側に入れるアプリ
| ファイル | 入れる PC |
|---|---|
| `windows/base.dsc.yaml` | 会社・私用の両方 |
| `windows/personal.dsc.yaml` | 私用の PC だけ |

アプリを増やすときは、どちらかのファイルに `Microsoft.WinGet.DSC/WinGetPackage` のリソースを追加して install.ps1 を再実行します。パッケージの ID は `winget search <名前>` で調べます。

私用の PC かどうかの答えを変えたいときは、保存したファイルを消してから install.ps1 を再実行します。

```powershell
Remove-Item $env:USERPROFILE\.dotfiles-windows.json
```

### ImeCenterView
winget にない自作アプリなので、install.ps1 がソースからビルドします。

| 場所 | 内容 |
|---|---|
| `%LOCALAPPDATA%\dotfiles\src\ImeCenterView` | ビルド用の clone（main ブランチ） |
| `%LOCALAPPDATA%\Programs\ImeCenterView` | ビルドした exe の配置先 |

install.ps1 を再実行すると最新のソースを取得し、新しいコミットがあるときだけビルドし直して起動し直します。スタートアップの登録は、次のコマンドで解除できます。

```powershell
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'ImeCenterView'
```

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
WSL と Windows のそれぞれで鍵を作ります。WSL では Ubuntu で実行します。

```shell
ssh-keygen -t ed25519
```

Windows では PowerShell で実行します（Windows に標準で入っている OpenSSH を使います）。鍵は `%USERPROFILE%\.ssh` にでき、Git for Windows もこの鍵を使います。

```powershell
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

Windows 側の gh（install.ps1 で入れたもの）は WSL とは別にログインが必要なので、PowerShell でも `gh auth login` を実行します。WSL と同じくプロトコルは SSH を選び、Windows で作った鍵をアップロードします。鍵のタイトルは、WSL の鍵と見分けがつくように PC 名と `windows` などを含めておきます。

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

## Windows 側の変更を確認する
install.ps1 は、clone したリポジトリから実行すると、GitHub Pages ではなく手元の `windows/` のファイルを使います。ブランチの変更は、WSL のリポジトリを指定して PowerShell で試せます。

```powershell
powershell -ExecutionPolicy Bypass -File \\wsl.localhost\Ubuntu\home\shinshu\dotfiles\install.ps1
```

`-ExecutionPolicy Bypass` は、WSL 上のスクリプトがネットワーク上のファイルとして扱われ、実行ポリシーで止められるのを避けるために付けています。パスの `Ubuntu` はディストリビューション名なので、環境に合わせて変えます。

YAML の書式だけなら、Windows を変更しない `winget configure validate` で確かめられます。

```powershell
winget configure validate --file \\wsl.localhost\Ubuntu\home\shinshu\dotfiles\windows\base.dsc.yaml
```
