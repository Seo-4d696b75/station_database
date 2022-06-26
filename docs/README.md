# README

## Top-level Schemas

*   [駅オブジェクト](./station.md "駅の情報") – `-`

## Other Schemas

### Objects

*   [Featureのプロパティ](./station-properties-ボロノイ範囲-properties-featureのプロパティ.md "空のオブジェクトです") – `undefined#/properties/voronoi/properties/properties`

*   [geometry(LineString)](./station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring.md) – `undefined#/properties/voronoi/properties/geometry/oneOf/1`

*   [geometry(Polygon)](./station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon.md) – `undefined#/properties/voronoi/properties/geometry/oneOf/0`

*   [geometry(Polygon/LineString)](./station-properties-ボロノイ範囲-properties-geometrypolygonlinestring.md) – `undefined#/properties/voronoi/properties/geometry`

*   [ボロノイ範囲](./station-properties-ボロノイ範囲.md "原則としてポリゴンで表現されます") – `undefined#/properties/voronoi`

### Arrays

*   [LineStringの座標リスト](./station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring-properties-linestringの座標リスト.md) – `undefined#/properties/voronoi/properties/geometry/oneOf/1/properties/coordinates`

*   [Polygonの座標リスト](./station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon-properties-polygonの座標リスト.md "ボロノイ範囲は中空のないポリゴンのため、長さ１のリスト") – `undefined#/properties/voronoi/properties/geometry/oneOf/0/properties/coordinates`

*   [Polygonの座標リスト\[0\]](./station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon-properties-polygonの座標リスト-polygonの座標リスト0.md "始点と終点の座標が一致します") – `undefined#/properties/voronoi/properties/geometry/oneOf/0/properties/coordinates/items`

*   [座標点](./station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon-properties-polygonの座標リスト-polygonの座標リスト0-座標点.md "緯度・経度の組み合わせで座標を表します") – `undefined#/properties/voronoi/properties/geometry/oneOf/0/properties/coordinates/items/items`

*   [座標点](./station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring-properties-linestringの座標リスト-座標点.md "緯度・経度の組み合わせで座標を表します") – `undefined#/properties/voronoi/properties/geometry/oneOf/1/properties/coordinates/items`

*   [駅が登録されている路線](./station-properties-駅が登録されている路線.md "路線コードのリストで表現されます") – `undefined#/properties/lines`
