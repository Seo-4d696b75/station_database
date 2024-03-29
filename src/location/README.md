# GoogleMap座標抽出したい

## セットアップ
### OCRツール
Tesseractを使用
```bash
brew install tesseract
```
### Python + ライブラリ
**推奨** Anaconda環境の使用  

```bash
conda create --name locate-station python=3.8
conda activate locate-station
pip install \
  numpy \
  matplotlib \
  opencv-python \
  pyperclip
``` 

### 各種設定
`./config.ini`に記述  
環境依存の値に注意

## 入力
- zoom_level=18の地図画像で目的位置にピン画像あり
- 該当位置周辺の地図画像で座標値既知のもの

## 出力
ピン画像の位置の緯度経度を計算

### 記録
[一覧](./location.txt)に記録しておきましょう

## 実行手順

### 目的画像（テンプレート画像）の用意
GoogleMap zoom_level=18を仮定する  
`src`ディレクトリ下に`{station_code}.jpg`の名前で保存  
  
[設定ファイル](./config.ini)の`pin`でピン画像を指定、
ピン画像内のピクセル単位での位置指定は`targetX`,`targetY`で指定する

### 入力画像（比較画像）の用意
同じ位置をGoogleMapでURLつきで表示した画像を`pattern`の示す位置に保存
`pattern`にマッチする画像ファイルでタイムスタンプが最新のものを選択する
**注意**
- 画像サイズに対し縦方向の地図表示範囲を表す`marginTop`,`marginBottom`を正しくピクセル単位で指定すること
- 横方向に関しては画像幅いっぱいまで地図描画の範囲と仮定する
- `density`で画像上のピクセルとHTMLオブジェクトのサイズpxを変換する比率を指定する。`density`=(ピクセル数)/(dip単位1)

### スクリプトの実行
`python locate.py {station_code}`  
両地図画像をテンプレートマッチングして対応位置を検知（平行移動のみ）して、ピン画像の座標を抽出する  
使用した比較画像は`des`ディレクトリ下に保存`{station_code}.jpg`

## 座標系の知識

[google map](https://developers.google.com/maps/documentation/javascript/coordinates#tile-coordinates)  
[メルカトル図法](https://en.wikipedia.org/wiki/Mercator_projection)  

### 投影法
**メルカトル図法**  
曲面上の点(Lat,Lng)をガウス平面上の一点に一意に投影する

### ワールド座標
**地球地表での座標(Lat,Lng)からメルカトル図法により投影された平面状の座標**  
x座標と経度値との比率はy座標に依らず一定。
一方でy座標と緯度値の比率はy座標に依る
GoogleMapでは256x256 pixelサイズのタイルを張り合わせることで表現している。
zoom=0のときこのタイルで全体(緯度±90、経度±180)が写るように定義されており、
このタイル状の座標（左上原点、[0-256]の範囲、直交座標系）でワールド座標を定める

### ピクセル座標
各ズームレベルにおいて256x256のタイルを敷き詰めたときのピクセルの位置
`(ワールド座標)*2^(zoomレベル)`  
あくまでタイル状でのピクセルの位置なので、実際のディスプレイ上で表示されたピクセルの位置ではない。

```
pixel coordinate : pixel on display = 256 : ‭387.18337004405286343612334801762
hxw = 914x1920
```

以下縮尺1:1の投影による座標変換(R=地球半径)
地球表面： `θ[-π,+π],φ[-π/2,+π/2]`  
直交座標系平面　`x[-Rπ,Rπ],y[-Rπ,Rπ]`    

```
x = Rθ  
y = R ln(tan(π/4+φ/2))  
``` 

なお定義によればyの値域は±∞だが、実際には便宜上`[-Rπ,Rπ]`で切っているためφ:±85°の範囲しか表現されていない

```
dx/dθ = R
dy/dφ = R/cosφ

dθ/dx = 1/R (const.)
dφ/dy = dθ/dx * cosφ
```


20m : 72
35.255170, 139.150023
35.257825, 139.156885
0.002655, 0.006861
2.9048140043763676148796498905908e-6‬, 0.0000035734375‬

緯度
500m
緯線方向 157 px >>(ディスプレイ倍率考慮)>> 157 / 1.5 px
1 px = 2^-zoom * 2Rπ cosφ / 256

35.679643
200 101
