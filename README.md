# 駅データ  
日本全国の鉄道路線・駅のデータベース編集プロジェクト  
  
![](https://github.com/Seo-4d696b75/station_database/workflows/auto-build/badge.svg) ![](https://github.com/Seo-4d696b75/station_database/workflows/test/badge.svg)

<br/>
<table>
  <tr>
    <td><img src="https://user-images.githubusercontent.com/25225028/132442253-e92f5653-f4e9-47e6-9873-87f319513bca.gif" height="200"></td>
    <td><img src="https://user-images.githubusercontent.com/25225028/76631346-e7f67a80-6584-11ea-9f6b-5e8885887363.png" height="200"></td>
  </tr>
</table>

位置ゲーム【駅メモ！】内で使用されているデータベースに準拠

#### 主要なデータファイル

| ファイル名 | データ内容 | 形式 |  
|---|---|---|  
|[station.csv](out/main/station.csv)| 駅一覧 | CSV |  
|[station.json](out/main/station.json) | 駅一覧 | JSON |  
|[line.csv](out/main/line.csv)| 路線一覧 | CSV |  
|[line.json](out/main/line.json)| 路線一覧 | JSON |  


#### データセットの種類

`./out`以下に２種類のデータセットがあります  
- `main`: 駅メモと同様
- `extra`: [駅メモのデータセットに廃線・廃駅を独自に追加](https://github.com/Seo-4d696b75/station_database/wiki/extra)

# データの詳細
### 出典  

* [駅データ.jp](http://www.ekidata.jp/)  
  基本的な路線・駅の名称・位置情報など

* [【駅メモ！】ステーションメモリーズ！情報wiki](https://ek1mem0.wiki.fc2.com/)  
  [旧サイトから移転しました](https://ekimemo.wiki.fc2.com/)  
  上記の駅データ.jpとの差分をこちらの情報で埋めるのに利用

* [国土数値情報ダウンロードサービス](http://nlftp.mlit.go.jp/ksj/index.html)    
  4.交通＞鉄道 2008/2017年度版 を加工して使用  
  鉄道路線のポリライン情報のみ利用
  
* [wikipedia - 日本の廃止鉄道路線](https://ja.wikipedia.org/wiki/%E6%97%A5%E6%9C%AC%E3%81%AE%E5%BB%83%E6%AD%A2%E9%89%84%E9%81%93%E8%B7%AF%E7%B7%9A%E4%B8%80%E8%A6%A7)  
  独自追加の廃駅・廃路線のデータはこのサイトからスクリプトで自動取得

### データの更新
[公式のお知らせページ](https://ekimemo.com/news/)で駅情報更新が公表されると、

1. 今後の対応予定として[issueを自動登録します](https://github.com/Seo-4d696b75/station_database/issues?q=is%3Aissue+is%3Aopen+label%3A%E9%A7%85%E6%83%85%E5%A0%B1%E6%9B%B4%E6%96%B0)
2. 公表された更新日に合わせてデータ更新を実施します

実施された各更新内容は[Release Notesの一覧](https://github.com/Seo-4d696b75/station_database/releases)に表示されます。また現在の最新データのバージョン・場所等の情報は次のファイルで定義されています。  
- `main`データセット: [/latest_info.json](./latest_info.json)
- `extra`データセット: [/latest_info.extra.json](./latest_info.extra.json)

### 仕様  
[詳細はWikiページ参照](https://github.com/Seo-4d696b75/station_database/wiki/data)  

### 誤りの報告
[報告を受け付けています.こちらを参考にしてください.](./CONTRIBUTING.md)

### 開発
[こちらを参照して開発環境をセットアップできます](./src/README.md)

### テスト
GitHub Actions によるデータのテストが自動で走り結果が上部のバッジに表示されています。  

- format データ形式が仕様で定めた通りであるか確認
- consistency 更新前後でデータの欠損や予期せぬ変化がないか確認

# データを使う  

### 駅サガース
<img src="https://user-images.githubusercontent.com/25225028/81793250-145a5300-9544-11ea-81fa-bee3a8ecc8ac.png" height="150">  

[位置情報ゲーム「駅メモ！」の支援ツールサイト](https://ekisagasu.seo4d696b75.com/)  
駅や路線のデータを確認したり，チェックインする駅やレーダーでアクセスできる範囲をGoogleMap上で視覚化します．


### Station API
<img src="https://user-images.githubusercontent.com/25225028/172097592-58523958-feb4-4c5a-9a05-0291bca7c31d.png" height="150">

[このデータベースの駅情報をAPIで取得できます.](https://api.station.seo4d696b75.com/docs)  

URL: https://api.station.seo4d696b75.com/

---------------------------

当ページは、株式会社モバイルファクトリー「ステーションメモリーズ！」の画像を利用しております。  
該当画像の転載・配布等は禁止しております。  
© Mobile Factory, Inc.  

<a rel="license" href="http://creativecommons.org/licenses/by/4.0/"><img alt="クリエイティブ・コモンズ・ライセンス" style="border-width:0" src="https://i.creativecommons.org/l/by/4.0/88x31.png" /></a><br />この 作品 は <a rel="license" href="http://creativecommons.org/licenses/by/4.0/">クリエイティブ・コモンズ 表示 4.0 国際 ライセンス</a>の下に提供されています。
