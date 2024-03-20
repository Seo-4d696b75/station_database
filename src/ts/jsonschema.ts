
import { writeFileSync } from "fs";
import { jsonDelaunayList } from "./model/delaunay";
import { jsonLineList } from "./model/line";
import { jsonLineDetail } from "./model/lineDetail";
import { jsonStationList } from "./model/station";
import { jsonKdTree, jsonKdTreeSegment } from "./model/tree";

// station.json
writeFileSync("out/schema/station.schema.json", JSON.stringify(jsonStationList, undefined, 2))
// line.json
writeFileSync("out/schema/line.schema.json", JSON.stringify(jsonLineList, undefined, 2))
// line/*.json
writeFileSync("out/schema/line_detail.schema.json", JSON.stringify(jsonLineDetail, undefined, 2))
// delaunay.json
writeFileSync("out/schema/delaunay.schema.json", JSON.stringify(jsonDelaunayList, undefined, 2))
// tree.json
writeFileSync("out/schema/tree.schema.json", JSON.stringify(jsonKdTree, undefined, 2))
// tree/*.json
writeFileSync("out/schema/tree_segment.schema.json", JSON.stringify(jsonKdTreeSegment, undefined, 2))
