# dotfiles
shinshu68's dotfiles

## Install
```shell
bash -c "$(curl -sSL git.io/shinshu68.dot)"
```

or

```shell
curl -sSL git.io/shinshu68.dot | bash
```

## 手動でやらなきゃいけないことリスト (elementary OS版)
できるところは自動化したい

### 日本語変換
```shell
im-config でfcitxを選択
fcitx-config-gtk3 & で確認
再起動
```

### シェル変更
```shell
chsh -s $(which fish)
```

### フォント設定
```shell
font-setting
```

### SSHの設定
```shell
ssh-keygen
GitHubに登録
```

### 色々インストール
```shell
app_installer all
ansible-tag others
```

### mozcの日本語変換強化
```shell
docker run -d --name mozc-ut2 shufo/mozc-ut2:bionic
mkdir deb
docker cp mozc-ut2:/app/ ./deb/
docker rm mozc-ut2
sudo dpkg -i ./mozc-data_*.deb ./mozc-server_*.deb ./mozc-utils-gui_*.deb ./ibus-mozc_*.deb
```
