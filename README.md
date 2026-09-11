# Hati Homebrew tap

PC側のHatiセットアップとターミナルUIを配布する個人用tapです。

```sh
brew install tamoharu/hati/hati
hati setup
```

Hatiを導入済みの場合の更新:

```sh
brew update
brew upgrade tamoharu/hati/hati
hati pair --copy
```

接続先PCで招待リンクをコピーし、もう一方のPCのHatiの「接続先を追加」に貼り付けます。
SSH先などでは `hati pair --link` で表示したリンクをコピーしてください。
有効期限は5分・1台限りで、接続完了までコマンドを開いたままにします。

旧名称の版から切り替える場合は、作業完了後に設定・履歴を移行し、アプリでQRを再登録してください。
常駐への変更は作業完了後の `hati restart` で反映します。招待リンク用コマンドは更新直後から利用できます。

[セットアップと操作](https://github.com/tamoharu/hati-setup) · [移行手順](https://github.com/tamoharu/hati-setup/blob/main/docs/RENAMING.md) · [リリース](https://github.com/tamoharu/hati-setup/releases/latest)

macOS / Linux、Node.js 24、tmux、OpenSSL、ビルド用Rustに対応。Linuxでのクリップボードコピーにはwl-clipboard / xclip / xselを使います。iPhoneアプリ本体・ソースは含みません。
