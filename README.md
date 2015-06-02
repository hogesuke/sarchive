Sarchive [![Gem Version](https://badge.fury.io/rb/sarchive.svg)](http://badge.fury.io/rb/sarchive)
==========
「さくらのクラウド」のアーカイブ作成を簡単にコンソールから実行するためのgemです。

## 説明
このgemを使用することにより、コンソールから簡単に複数のディスクのアーカイブを作成できます。
また、アーカイブ作成時に古いアーカイブの削除を同時に行うことも可能です。  
cronで定期的に実行するように設定することで、面倒なバックアップ作業を自動化できます。

## インストール
    gem install sarchive
    
## 基本的な使い方
1. 設定ファイルの生成

        sarchive init [--path] (</path/to/config/sarchive.config.yml>)
デフォルトではカレントディレクトリに`sarchive.config.yml`を生成します。  
生成先を変更する場合は`--path`オプションでパスを指定してください。

2. 設定ファイルの編集  
実行に必要となるAPIキーや、アーカイブ作成対象のディスクを指定してください。

        token:   # コンパネで作成したAPIキーのaccess-tokenを指定してください
        secret:  # コンパネで作成したAPIキーのaccess-token-secretを指定してください
        disks:
          tk1v:  # 対象のゾーン名 (tk1a: 東京第1, is1a: 石狩第1, is1b: 石狩第2, tk1v: Sandbox)
            - 999999999999 # 対象ディスクのID
            - 999999999999 # 複数指定可
    
3. 実行

        sarchive exec [--path] (</path/to/config/sarchive.config.yml>)
デフォルトではカレントディレクトリの`sarchive.config.yml`をもとに実行します。  
読み込む設定ファイルを変更する場合は、`--path`オプションでパスを指定してください。

## その他の機能
### アーカイブ自動削除
アーカイブ作成と同時に古いアーカイブを削除することができます。  
以下のように設定ファイルを編集してください。

    auto_delete:
      enable: true  # trueを指定し自動削除を有効にしてください
      store:        # 何を基準にアーカイブを削除するかの設定です。counts, hoursのどちらか一方を指定してください
        # counts: 3
        # hours : 72

- `counts`  
数を基準に削除を行います。仮に3を指定した場合、新しい順に3個残して4つ目以降を削除します。  
- `hours`  
経過時間を基準に削除を行います。仮に72を指定した場合、作成から72時間より多く経過しているものを削除します。

## 注意事項
プロダクション環境で利用する前に[Sandbox](http://cloud-news.sakura.ad.jp/sandbox/)でテストすることを推奨します。  
本プログラムを使用して損害が発生した場合も、本プログラム作成者は一切の責任を負いません。

## TODO
- 実行結果のSlack通知機能

## Licence
MIT