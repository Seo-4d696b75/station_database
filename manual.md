2018/10/21

**駅データ収集のマニュアル**

# 変更履歴
2019/02/28  
固定データファイルの名称を変更
駅詳細データに関してバージョン毎にデータを保存して管理するように変更



# 固定データファイル一覧

* prefecture.csv	都道府県コードの一覧表、以下都道府県はこのコードで表現する
* color.csv	HTMLカラーコードの一覧表 解析時に必要
	

# 基本情報の収集
**毎回**  
作業ディテクトリ： ./${version}/  
これがそのままバージョン区分になるのでディレクトリ管理は徹底すべし

## 取得方法
駅データ.jp　の無償APIを利用  
[ＡＰＩの詳細](./ekidata_API.txt)  
	  
./extriever.rb で全駅分を一括ダウンロード可能  
`$ ruby ../extriever.rb`
	
### 出力ファイル
		lines_raw.json		全路線のデータ(コード、路線名)
		
			[
			{"code":11101,"name":"JR函館本線(函館～長万部)"},
			....
			]
		
		stations_raw.json	全駅のデータ(コード、駅名、緯度、経度、路線コードリスト)
		
			[
			{"code":1110101,"name":"函館","lon":140.726413,"lat":41.773709,"lines":[11101,99108]},
			....
			]
		
(注意)この段階では駅メモ仕様と差異あり
	
# 差分の解決
**毎回**

作業ディテクトリ： ./${version}/
	
## 差分修正データの用意
		
		merge.json
		[
		//路線名称の変更
		{"code":25001,"line":"小田急線","rename":"小田急小田原線"},
		//駅名の変更
		{"code":1131102,"station":"四ツ谷","rename":"四ツ谷(四ッ谷)"},
		//座標修正
		{"code":9941419,"station":"西新湊","lon":137.078499,"lat":36.781236},
		//路線・駅の追加(駅追加の順序は問わない)
		{"line":"JR江差線","closed":true,"add_station":[
			{"station":"江差","closed":true,"lat":41.856668,"lon":140.127777},
			{"station":"上ノ国","closed":true,"lat":41.805348,"lon":140.124108},
			{"station":"中須田","closed":true,"lat":41.786696,"lon":140.149400},
			{"station":"桂岡","closed":true,"lat":41.773062,"lon":140.165898},
			{"station":"宮越","closed":true,"lat":41.762314,"lon":140.185299},
			{"station":"湯ノ岱","closed":true,"lat":41.750461,"lon":140.243442},
			{"station":"神明(北海道)","closed":true,"lat":41.734285,"lon":140.265768},
			{"station":"吉堀","closed":true,"lat":41.684209,"lon":140.379271},
			{"station":"渡島鶴岡","closed":true,"lat":41.670888,"lon":140.412047},
			"木古内","札苅","泉沢","釜谷","渡島当別","茂辺地","上磯","清川口","久根別","東久根別","七重浜","五稜郭","函館"
		]},
		//駅の除去
		{"code":3101301,"station":"あすなろう四日市","remove":true},
		//登録駅・路線の除去
		{"code":24007,"line":"京王新線","remove":true,"remove_station":[
			"新線新宿","初台","幡ヶ谷","笹塚"
		]},
		
## 路線登録駅定義ファイルの用意
		
check_list.txt  
一行ごとに、東京メトロ丸ノ内線28....
		
## 差分解決ファイルとの結合
../merge.rb で処理する
		
		$ load("../merge.rb")
		$ parse = DataParser.new("./lines_raw.json","./stations_raw.json")
		//差分を解決、警告が出なくなるまで指示に従い処理すべし
		$ parse.merge("./merge.json")
		//駅数を確認する
		$ parse.check("./check_list.txt")
		$ parse.write()
		
### 出力ファイル
フォーマットは解決前のrawファイルと同等  
lines.json, stations.json
			
# 路線ポリラインデータ
**初回/差分**

以下作業ディレクトリ：./polyline/

## データの取得
http://nlftp.mlit.go.jp/ksj/gml/cgi-bin/download.php  
国土数値情報ダウンロードサービス  
(JPGIS2.1(GML)準拠及びSHAPE形式データ)  
2008年版  
		
N02-08.xml
	
## データの解析
そのままだと、XMLのオーバヘッドが巨大すぎて扱いづらいので変換  
jp.ac.u_tokyo.t.eeic.seo.station.LineMerge.java
		
`$ new LineMerge("./N02-08.xml", "出力ファイル");`
		
### 出力ファイル
			
			N02-08.json 
			
			[
			{"line":"名古屋鉄道>名古屋本線","point_list":[
				##配列"points"に経度・緯度の順に座標値を列挙
				##配列の順序通りに繋がった一本のポリラインを辺として、"start","end"属性でその辺の両端の頂点を指定
				##同じ頂点を端点にもつ辺々はその頂点で隣接している
				{"start":"0","end":"1","points":[137.366730,34.787040,....]},
				{"start":"1","end":"0","points":[137.359190,34.797160,....]},
				.....
			]
			}
			....
			]
		
## データの編集
	
そのままだと使い物にならないので頑張って編集  
jp.ac.u_tokyo.eeic.seo.station.LineCurveEditor.java
		
		$ new LineCurveEditor(
			"./N02-08.json", 
			"../${version}/lines.json", //差分を解決して得られた路線データ
			"確認ファイル", 			//編集した路線を記録するファイル
			"出力ファイルのディレクトリ"
		);

http://memopad.bitter.jp/web/GoogleMap/V3/myMap/tools/gpsDataDisplay.html
		
### 出力ファイル
			
			./raw/*.json
			
			{
			"code":11101,
			"line":"JR函館本線(函館～長万部)",
			"point_list":[
			  {"start":"函館","end":"五稜郭２","points":[
			    {"lon":140.725720,"lat":41.773660},
			    .....
			  ]},
			  .....
			]}
		
## データの確認と圧縮
		
データのフォーマット・整合性を確認
jp.ac.u_tokyo.eeic.seo.station.LineCurveEditor.java
		
		$ ../polyline_check.bat {version}
		
		もしくは
		$ new LineCurveEditor(
			"../${version}/lines.json", //差分を解決して得られた路線データ
			"./raw/",					//対象ファイルのディレクトリ
			"./solved/"					//確認済みのデータ保存先
		);
		
### 出力ファイル
			{
			"code":11101,
			"line":"JR函館本線(函館～長万部)",
			"point_list":[
			  {"start":"函館","end":"五稜郭２","pivot":[140.72572,41.77366],"points":[0,0,....]},
			  .....
			]}
			
# 駅詳細データの収集
**初回/差分**

作業ディレクトリ ./{version}/
	
## データの用意
有志によって整備されているwikiから各路線に登録された駅データを取得  
https://ekimemo.wiki.fc2.com/wiki/%E8%B7%AF%E7%B7%9A%E5%90%8D%E4%B8%80%E8%A6%A7
		
### ダウンロードリストの用意
上記の一覧から抽出するだけ
./details/list.txt
			
### 一括ダウンロード
./download.rb
			
			$ mkdir details
			$ copy *** details/list.txt
			$ mkdir details/raw
			$ ruby ../details.rb
			
./raw/ ディレクトリ下にHTMLファイルが路線数だけダウンロードされる
			
## 路線の読み仮名リストの用意
自分で用意するしかない。 ./details/lines_phonetic.txt
	
## データの編集
色々間違えや表記の揺れがあるので適切に指示を与える
		
		$ mkdir details/solved
		$ copy {previous}/*.json
		$ ../details.bat
		
		
### 出力ファイル
駅の詳細  

			./stations.json
			[
			{"code":1110101,"station":"函館","phonetic":"はこだて","prefecture":1},
			....
			]
			
路線の詳細は./solved/ディレクトリ下に保存  

			{
			"code":11101,
			"line":"JR函館本線(函館～長万部)",
			"phonetic":"じぇいあーるはこだてほんせん",
			"color":"#0072BC",
			"list_size":38,
			"station_list":[
  				{"code":1110101,"numbering":[{"symbol":"H","index":"75"}]},
  				....
  			]
  			}

# データの統合
**毎回**

作業ディレクトリ： ./${version}/   
出力ディレクトリ  ./${version}/out/  

ここまで集めてきた駅・路線データ、詳細データ、路線ポリラインデータを統合  
同時に駅のボロノイ境界を計算  
	
	`$ data_merge.bat {version}`
	
## 必要ファイル一覧	

	$ new DataMerge(
		"./lines.json",				//差分解決済み路線一覧データ
		"./stations.json",			//差分解決済み駅基本データ
		"../polyline/solved/",		//各路線のポリラインデータのディレクトリ
		"./details/lines/",		//各路線の詳細データのディレクトリ
		"./details/stations.json",	//駅詳細データ
		"./out/",					//出力先ディレクトリ
		"./out/stations.json"
	)
	
### 最終的なデータ仕様
	
		./out/lines.json
		[
			{
			"code":11101,
			"line":"JR函館本線(函館～長万部)",
			"phonetic":"じぇいあーるはこだてほんせん",
			"color":"#0072BC",
			"symbol":"H",
			"list_size":38
			},
			.....
		]
		
		./out/stations.json
		[
			{
			"code":1110101,
			"station":"函館",
			"phonetic":"はこだて",
			"prefecture":1,
			"lon":140.726413,
			"lat":41.773709,
			"lines":[1101....]
			},
			....
		]
		
		./out/lines/*.json
		{
			"code":11101,
			"line":"JR函館本線(函館～長万部)",
			"phonetic":"じぇいあーるはこだてほんせん",
			"color":"#0072BC",
			"symbol":"H",
			"list_size":38,
			"station_list":[
  				{"code":1110101,"numbering":[{"symbol":"H","index":"75"}]},
  				....
  			],
			"point_list":[
			  {"start":"函館","end":"五稜郭２","pivot":[140.725720,41.773660],"points":[0,0,....]},
			  .....
			]
		}
		
		
		./out/stations/stations_*-*.json
		{
			"stations":[
				{
				"code":1110101,
				"station":"函館",
				"phonetic":"はこだて",
				"prefecture":1,
				"lon":140.726413,
				"lat":41.773709,
				"lines":[1101......],
				"next":[....]
				},
				......
			],
			"voronoi":{
				"points":[127.660030,26.202208...],
				"groups":[
					{"lon":127500,"lat":26000,"size":250,"index":[0,1....]},
					.....
				]
			}
		}
		
### 圧縮データのフォーマット
全データをひとつのファイルに統合
		
		./out/data.json
		{
			"version":20180809,
			"stations":[
				....
			],
			"lines":[
				....
			],
			"block":[
				{
					"file":"stations_142.5-43.0.json",
					"data":{
						....
					}
				}
				...
			]
		}
		