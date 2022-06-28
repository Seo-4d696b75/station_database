# README

## Top-level Schemas

*   [路線リスト](./line.md "すべての路線を含むリスト") – `-`

*   [駅リスト](./station.md "すべての駅を含みます") – `-`

## Other Schemas

### Objects

*   [Featureのプロパティ](./station-駅オブジェクト-properties-ボロノイ範囲-properties-featureのプロパティ.md "空のオブジェクトです") – `undefined#/items/properties/voronoi/properties/properties`

*   [geometry(LineString)](./station-駅オブジェクト-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring.md) – `undefined#/items/properties/voronoi/properties/geometry/oneOf/1`

*   [geometry(Polygon)](./station-駅オブジェクト-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon.md) – `undefined#/items/properties/voronoi/properties/geometry/oneOf/0`

*   [geometry(Polygon/LineString)](./station-駅オブジェクト-properties-ボロノイ範囲-properties-geometrypolygonlinestring.md) – `undefined#/items/properties/voronoi/properties/geometry`

*   [ボロノイ範囲](./station-駅オブジェクト-properties-ボロノイ範囲.md "原則としてポリゴンで表現されます") – `undefined#/items/properties/voronoi`

*   [路線オブジェクト](./line-路線オブジェクト.md) – `undefined#/items`

*   [駅オブジェクト](./station-駅オブジェクト.md "駅の情報") – `undefined#/items`

### Arrays

*   [LineStringの座標リスト](./station-駅オブジェクト-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring-properties-linestringの座標リスト.md) – `undefined#/items/properties/voronoi/properties/geometry/oneOf/1/properties/coordinates`

*   [Polygonの座標リスト](./station-駅オブジェクト-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon-properties-polygonの座標リスト.md "ボロノイ範囲は中空のないポリゴンのため、長さ１のリスト") – `undefined#/items/properties/voronoi/properties/geometry/oneOf/0/properties/coordinates`

*   [Polygonの座標リスト\[0\]](./station-駅オブジェクト-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon-properties-polygonの座標リスト-polygonの座標リスト0.md "始点と終点の座標が一致します") – `undefined#/items/properties/voronoi/properties/geometry/oneOf/0/properties/coordinates/items`

*   [座標点](./station-駅オブジェクト-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon-properties-polygonの座標リスト-polygonの座標リスト0-座標点.md "緯度・経度の組み合わせで座標を表します") – `undefined#/items/properties/voronoi/properties/geometry/oneOf/0/properties/coordinates/items/items`

*   [座標点](./station-駅オブジェクト-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring-properties-linestringの座標リスト-座標点.md "緯度・経度の組み合わせで座標を表します") – `undefined#/items/properties/voronoi/properties/geometry/oneOf/1/properties/coordinates/items`

*   [駅が登録されている路線](./station-駅オブジェクト-properties-駅が登録されている路線.md "路線コードのリストで表現されます") – `undefined#/items/properties/lines`
